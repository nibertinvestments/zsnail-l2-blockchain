// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title OracleRegistry
 * @dev Registry and price aggregation for ZSnail L2 oracles
 */
contract OracleRegistry is Ownable, ReentrancyGuard {
    
    struct Oracle {
        address oracleAddress;
        string dataSource;
        string region;
        uint256 reputation;
        uint256 totalSubmissions;
        uint256 accurateSubmissions;
        bool isActive;
        uint256 joinedAt;
        uint256 lastSubmissionTime;
    }
    
    struct PriceData {
        uint256 price;
        uint256 timestamp;
        address oracle;
        bool isValid;
    }
    
    struct AggregatedPrice {
        uint256 price;
        uint256 timestamp;
        uint256 confidence; // Percentage (0-100)
        uint256 submissions;
    }
    
    // State variables
    mapping(address => Oracle) public oracles;
    mapping(string => mapping(uint256 => PriceData[])) public priceSubmissions; // symbol => timestamp => submissions
    mapping(string => AggregatedPrice) public latestPrices; // symbol => latest price
    address[] public oracleList;
    
    // Configuration
    uint256 public minOracles = 3;
    uint256 public maxDeviationPercent = 5; // 5% max deviation from median
    uint256 public updateInterval = 300; // 5 minutes
    uint256 public oracleTimeout = 3600; // 1 hour inactivity timeout
    
    // Supported price feeds
    string[] public supportedSymbols;
    mapping(string => bool) public isSymbolSupported;
    
    // Events
    event OracleRegistered(address indexed oracle, string dataSource, string region);
    event OracleDeactivated(address indexed oracle, string reason);
    event PriceSubmitted(address indexed oracle, string symbol, uint256 price, uint256 timestamp);
    event PriceAggregated(string symbol, uint256 price, uint256 confidence, uint256 submissions);
    event OracleSlashed(address indexed oracle, string reason);
    event SymbolAdded(string symbol);
    
    constructor(address initialOwner) Ownable(initialOwner) {
        // Initialize with common trading pairs
        _addSymbol("ETH/USD");
        _addSymbol("BTC/USD");
        _addSymbol("ZSNAIL/USD");
    }
    
    /**
     * @dev Register as an oracle
     */
    function registerOracle(
        string memory dataSource,
        string memory region
    ) external {
        require(bytes(dataSource).length > 0, "Data source required");
        require(bytes(region).length > 0, "Region required");
        require(!oracles[msg.sender].isActive, "Already registered");
        
        oracles[msg.sender] = Oracle({
            oracleAddress: msg.sender,
            dataSource: dataSource,
            region: region,
            reputation: 100, // Start with 100% reputation
            totalSubmissions: 0,
            accurateSubmissions: 0,
            isActive: true,
            joinedAt: block.timestamp,
            lastSubmissionTime: block.timestamp
        });
        
        oracleList.push(msg.sender);
        
        emit OracleRegistered(msg.sender, dataSource, region);
    }
    
    /**
     * @dev Submit price data
     */
    function submitPrice(
        string memory symbol,
        uint256 price
    ) external {
        require(oracles[msg.sender].isActive, "Not an active oracle");
        require(isSymbolSupported[symbol], "Symbol not supported");
        require(price > 0, "Price must be positive");
        
        uint256 currentTime = block.timestamp;
        uint256 roundedTime = (currentTime / updateInterval) * updateInterval;
        
        // Check if oracle already submitted for this round
        PriceData[] storage submissions = priceSubmissions[symbol][roundedTime];
        for (uint256 i = 0; i < submissions.length; i++) {
            require(submissions[i].oracle != msg.sender, "Already submitted for this round");
        }
        
        // Add submission
        submissions.push(PriceData({
            price: price,
            timestamp: currentTime,
            oracle: msg.sender,
            isValid: true
        }));
        
        // Update oracle stats
        oracles[msg.sender].totalSubmissions++;
        oracles[msg.sender].lastSubmissionTime = currentTime;
        
        emit PriceSubmitted(msg.sender, symbol, price, currentTime);
        
        // Try to aggregate if enough submissions
        _tryAggregatePrice(symbol, roundedTime);
    }
    
    /**
     * @dev Get latest price for symbol
     */
    function getLatestPrice(string memory symbol) external view returns (
        uint256 price,
        uint256 timestamp,
        uint256 confidence
    ) {
        AggregatedPrice memory latestPrice = latestPrices[symbol];
        return (latestPrice.price, latestPrice.timestamp, latestPrice.confidence);
    }
    
    /**
     * @dev Get price with age check
     */
    function getPriceWithAge(string memory symbol, uint256 maxAge) external view returns (
        uint256 price,
        uint256 timestamp,
        uint256 confidence,
        bool isValid
    ) {
        AggregatedPrice memory latestPrice = latestPrices[symbol];
        bool valid = (block.timestamp - latestPrice.timestamp) <= maxAge;
        return (latestPrice.price, latestPrice.timestamp, latestPrice.confidence, valid);
    }
    
    /**
     * @dev Try to aggregate price if conditions are met
     */
    function _tryAggregatePrice(string memory symbol, uint256 roundedTime) internal {
        PriceData[] storage submissions = priceSubmissions[symbol][roundedTime];
        
        if (submissions.length >= minOracles) {
            uint256 medianPrice = _calculateMedian(submissions);
            uint256 confidence = _calculateConfidence(submissions, medianPrice);
            
            // Update latest price
            latestPrices[symbol] = AggregatedPrice({
                price: medianPrice,
                timestamp: block.timestamp,
                confidence: confidence,
                submissions: submissions.length
            });
            
            // Update oracle reputation based on accuracy
            _updateOracleReputation(symbol, submissions, medianPrice);
            
            emit PriceAggregated(symbol, medianPrice, confidence, submissions.length);
        }
    }
    
    /**
     * @dev Calculate median price from submissions
     */
    function _calculateMedian(PriceData[] storage submissions) internal view returns (uint256) {
        uint256[] memory prices = new uint256[](submissions.length);
        
        // Copy valid prices
        uint256 validCount = 0;
        for (uint256 i = 0; i < submissions.length; i++) {
            if (submissions[i].isValid) {
                prices[validCount] = submissions[i].price;
                validCount++;
            }
        }
        
        require(validCount > 0, "No valid submissions");
        
        // Sort prices (simple bubble sort for small arrays)
        for (uint256 i = 0; i < validCount - 1; i++) {
            for (uint256 j = 0; j < validCount - i - 1; j++) {
                if (prices[j] > prices[j + 1]) {
                    uint256 temp = prices[j];
                    prices[j] = prices[j + 1];
                    prices[j + 1] = temp;
                }
            }
        }
        
        // Return median
        if (validCount % 2 == 0) {
            return (prices[validCount / 2 - 1] + prices[validCount / 2]) / 2;
        } else {
            return prices[validCount / 2];
        }
    }
    
    /**
     * @dev Calculate confidence based on price deviation
     */
    function _calculateConfidence(
        PriceData[] storage submissions,
        uint256 medianPrice
    ) internal view returns (uint256) {
        uint256 validSubmissions = 0;
        uint256 closeSubmissions = 0;
        
        for (uint256 i = 0; i < submissions.length; i++) {
            if (submissions[i].isValid) {
                validSubmissions++;
                
                // Check if price is within acceptable deviation
                uint256 deviation = submissions[i].price > medianPrice ? 
                    submissions[i].price - medianPrice : 
                    medianPrice - submissions[i].price;
                    
                if ((deviation * 100 / medianPrice) <= maxDeviationPercent) {
                    closeSubmissions++;
                }
            }
        }
        
        if (validSubmissions == 0) return 0;
        
        // Confidence = percentage of submissions within acceptable deviation
        return (closeSubmissions * 100 / validSubmissions);
    }
    
    /**
     * @dev Update oracle reputation based on submission accuracy
     */
    function _updateOracleReputation(
        string memory symbol,
        PriceData[] storage submissions,
        uint256 medianPrice
    ) internal {
        for (uint256 i = 0; i < submissions.length; i++) {
            address oracleAddr = submissions[i].oracle;
            uint256 deviation = submissions[i].price > medianPrice ? 
                submissions[i].price - medianPrice : 
                medianPrice - submissions[i].price;
                
            if ((deviation * 100 / medianPrice) <= maxDeviationPercent) {
                // Accurate submission
                oracles[oracleAddr].accurateSubmissions++;
                if (oracles[oracleAddr].reputation < 100) {
                    oracles[oracleAddr].reputation++;
                }
            } else {
                // Inaccurate submission
                if (oracles[oracleAddr].reputation > 0) {
                    oracles[oracleAddr].reputation--;
                }
                
                // Slash oracle if reputation too low
                if (oracles[oracleAddr].reputation < 20) {
                    oracles[oracleAddr].isActive = false;
                    emit OracleSlashed(oracleAddr, "Low reputation");
                    emit OracleDeactivated(oracleAddr, "Slashed for low reputation");
                }
            }
        }
    }
    
    /**
     * @dev Get oracle information
     */
    function getOracle(address oracle) external view returns (
        string memory dataSource,
        string memory region,
        uint256 reputation,
        uint256 totalSubmissions,
        uint256 accurateSubmissions,
        bool isActive
    ) {
        Oracle memory o = oracles[oracle];
        return (o.dataSource, o.region, o.reputation, o.totalSubmissions, o.accurateSubmissions, o.isActive);
    }
    
    /**
     * @dev Get active oracle count
     */
    function getActiveOracleCount() external view returns (uint256 count) {
        for (uint256 i = 0; i < oracleList.length; i++) {
            if (oracles[oracleList[i]].isActive) {
                count++;
            }
        }
    }
    
    /**
     * @dev Clean up inactive oracles
     */
    function cleanupInactiveOracles() external {
        for (uint256 i = 0; i < oracleList.length; i++) {
            address oracle = oracleList[i];
            
            if (oracles[oracle].isActive && 
                block.timestamp - oracles[oracle].lastSubmissionTime > oracleTimeout) {
                
                oracles[oracle].isActive = false;
                emit OracleDeactivated(oracle, "Inactivity timeout");
            }
        }
    }
    
    /**
     * @dev Add supported symbol
     */
    function addSymbol(string memory symbol) external onlyOwner {
        _addSymbol(symbol);
    }
    
    function _addSymbol(string memory symbol) internal {
        require(!isSymbolSupported[symbol], "Symbol already supported");
        supportedSymbols.push(symbol);
        isSymbolSupported[symbol] = true;
        emit SymbolAdded(symbol);
    }
    
    /**
     * @dev Get all supported symbols
     */
    function getSupportedSymbols() external view returns (string[] memory) {
        return supportedSymbols;
    }
    
    // Admin functions
    function updateMinOracles(uint256 _minOracles) external onlyOwner {
        require(_minOracles > 0, "Must require at least 1 oracle");
        minOracles = _minOracles;
    }
    
    function updateMaxDeviation(uint256 _maxDeviationPercent) external onlyOwner {
        require(_maxDeviationPercent <= 50, "Deviation too high");
        maxDeviationPercent = _maxDeviationPercent;
    }
    
    function updateUpdateInterval(uint256 _updateInterval) external onlyOwner {
        require(_updateInterval >= 60, "Interval too short");
        updateInterval = _updateInterval;
    }
    
    function forceAggregatePrice(string memory symbol) external onlyOwner {
        uint256 currentTime = block.timestamp;
        uint256 roundedTime = (currentTime / updateInterval) * updateInterval;
        _tryAggregatePrice(symbol, roundedTime);
    }
}