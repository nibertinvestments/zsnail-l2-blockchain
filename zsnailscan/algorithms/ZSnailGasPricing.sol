// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ZSnailGasPricing
 * @dev Mathematical gas pricing algorithms for ZSnail L2 blockchain
 * @author ZSnail Blockchain Framework
 * @notice Implements competitive L2 gas pricing with dynamic adjustments
 */
contract ZSnailGasPricing is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // ============ CONSTANTS ============
    
    uint256 public constant ZSNAIL_DECIMALS = 18;
    uint256 public constant MIN_GAS_PRICE = 100000000000000000; // 0.1 ZSNAIL
    uint256 public constant MAX_GAS_PRICE = 10000000000000000000; // 10 ZSNAIL
    uint256 public constant BLOCK_TIME = 2000; // 2 seconds in milliseconds
    uint256 public constant MAX_BLOCK_SIZE = 30000000; // 30M gas limit
    uint256 public constant TARGET_UTILIZATION = 5000; // 50% in basis points
    uint256 public constant MAX_TPS = 25000;
    uint256 public constant PRICE_UPDATE_INTERVAL = 10; // Update every 10 blocks
    uint256 public constant PRICE_HISTORY_LENGTH = 1000;
    
    // ============ STATE VARIABLES ============
    
    uint256 public baseFee; // Base fee in wei (ZSNAIL)
    uint256 public currentBlock;
    uint256 public totalBlocks;
    uint256 public infrastructureCostPerDay; // In USD cents
    uint256 public usdToZsnailRate; // 1 USD = X ZSNAIL
    
    // Price history for analysis
    uint256[] public priceHistory;
    uint256[] public utilizationHistory;
    uint256 public priceHistoryIndex;
    
    // Current network state
    uint256 public currentTPS;
    uint256 public currentUtilization; // In basis points (10000 = 100%)
    uint256 public activeValidators;
    uint256 public maxValidators;
    
    // Time-based multipliers
    mapping(uint256 => uint256) public timeWeights; // hour => weight (in basis points)
    
    // ============ EVENTS ============
    
    event GasPriceUpdated(uint256 newPrice, uint256 blockNumber);
    event BaseFeeAdjusted(uint256 oldFee, uint256 newFee);
    event UtilizationUpdated(uint256 utilization, uint256 blockNumber);
    event TPSUpdated(uint256 tps, uint256 blockNumber);
    
    // ============ CONSTRUCTOR ============
    
    constructor() {
        // Initialize with calculated base fee: 0.29 ZSNAIL
        baseFee = 290000000000000000; // 0.29 ZSNAIL in wei
        infrastructureCostPerDay = 10000; // $100.00 in cents
        usdToZsnailRate = 12500; // 1 USD = 12,500 ZSNAIL
        maxValidators = 100;
        
        // Initialize time weights (basis points: 10000 = 1.0)
        _initializeTimeWeights();
        
        // Initialize price history arrays
        priceHistory = new uint256[](PRICE_HISTORY_LENGTH);
        utilizationHistory = new uint256[](PRICE_HISTORY_LENGTH);
    }
    
    // ============ CORE PRICING FUNCTIONS ============
    
    /**
     * @dev Calculate complete gas price using mathematical formula
     * P = BaseFee + PriorityFee + CongestionMultiplier + OperationalCost
     */
    function calculateGasPrice() external view returns (uint256) {
        uint256 priorityFee = _calculatePriorityFee();
        uint256 congestionMultiplier = _calculateCongestionMultiplier();
        uint256 operationalCost = _calculateOperationalCost();
        
        uint256 totalPrice = baseFee
            .add(priorityFee)
            .add(congestionMultiplier)
            .add(operationalCost);
            
        // Ensure price is within bounds
        if (totalPrice < MIN_GAS_PRICE) {
            totalPrice = MIN_GAS_PRICE;
        } else if (totalPrice > MAX_GAS_PRICE) {
            totalPrice = MAX_GAS_PRICE;
        }
        
        return totalPrice;
    }
    
    /**
     * @dev Calculate priority fee based on demand
     * F(d) = Fmin * (1 + (TPS_current / TPS_max)^2)
     */
    function _calculatePriorityFee() internal view returns (uint256) {
        uint256 minPriority = 100000000000000000; // 0.1 ZSNAIL
        
        if (currentTPS == 0) {
            return minPriority;
        }
        
        // Calculate demand factor: (TPS_current / TPS_max)^2
        uint256 demandFactor = currentTPS.mul(10000).div(MAX_TPS); // Scale to basis points
        uint256 demandFactorSquared = demandFactor.mul(demandFactor).div(10000);
        
        // F = Fmin * (1 + demandFactor^2)
        uint256 priorityMultiplier = uint256(10000).add(demandFactorSquared);
        
        return minPriority.mul(priorityMultiplier).div(10000);
    }
    
    /**
     * @dev Calculate congestion multiplier
     * C(u,t) = 1 + (u^3 * w(t))
     */
    function _calculateCongestionMultiplier() internal view returns (uint256) {
        if (currentUtilization == 0) {
            return baseFee; // Return base fee as baseline
        }
        
        // Get current hour for time weight
        uint256 currentHour = (block.timestamp / 3600) % 24;
        uint256 timeWeight = timeWeights[currentHour];
        
        // Calculate u^3 (utilization cubed)
        uint256 u = currentUtilization; // Already in basis points
        uint256 uCubed = u.mul(u).div(10000).mul(u).div(10000);
        
        // C = 1 + (u^3 * w(t))
        uint256 congestionFactor = uCubed.mul(timeWeight).div(10000);
        uint256 multiplier = uint256(10000).add(congestionFactor);
        
        return baseFee.mul(multiplier).div(10000).sub(baseFee); // Return additional cost
    }
    
    /**
     * @dev Calculate operational cost
     * O(s) = V(n) + S(d) + N(b)
     */
    function _calculateOperationalCost() internal view returns (uint256) {
        // Validator cost: (ActiveValidators / MaxValidators) * 0.05 ZSNAIL
        uint256 validatorCost = activeValidators
            .mul(50000000000000000) // 0.05 ZSNAIL
            .div(maxValidators);
        
        // Storage cost: Minimal for gas calculation
        uint256 storageCost = 1000000000000000; // 0.001 ZSNAIL
        
        // Network cost: Based on current TPS
        uint256 networkCost = currentTPS
            .mul(2000000000000000) // 0.002 ZSNAIL per 100 TPS
            .div(100);
        
        return validatorCost.add(storageCost).add(networkCost);
    }
    
    // ============ ADAPTIVE PRICING FUNCTIONS ============
    
    /**
     * @dev Update base fee based on historical utilization
     * Called every PRICE_UPDATE_INTERVAL blocks
     */
    function updateBaseFee() external {
        require(
            totalBlocks % PRICE_UPDATE_INTERVAL == 0,
            "Base fee update not due"
        );
        
        uint256 avgUtilization = _getAverageUtilization(100); // Last 100 blocks
        uint256 oldBaseFee = baseFee;
        
        // Adaptive base fee adjustment
        if (avgUtilization > 8000) { // > 80%
            baseFee = baseFee.mul(11250).div(10000); // Increase by 12.5%
        } else if (avgUtilization < 2000) { // < 20%
            baseFee = baseFee.mul(8750).div(10000); // Decrease by 12.5%
        }
        
        // Ensure base fee is within bounds
        if (baseFee < MIN_GAS_PRICE.div(4)) {
            baseFee = MIN_GAS_PRICE.div(4);
        } else if (baseFee > MAX_GAS_PRICE.div(4)) {
            baseFee = MAX_GAS_PRICE.div(4);
        }
        
        emit BaseFeeAdjusted(oldBaseFee, baseFee);
    }
    
    /**
     * @dev Update network state (TPS, utilization, validators)
     * Called by sequencer each block
     */
    function updateNetworkState(
        uint256 _currentTPS,
        uint256 _currentUtilization,
        uint256 _activeValidators
    ) external onlyOwner {
        currentTPS = _currentTPS;
        currentUtilization = _currentUtilization;
        activeValidators = _activeValidators;
        currentBlock = block.number;
        totalBlocks++;
        
        // Update price history
        _updatePriceHistory();
        
        emit TPSUpdated(_currentTPS, block.number);
        emit UtilizationUpdated(_currentUtilization, block.number);
        emit GasPriceUpdated(calculateGasPrice(), block.number);
    }
    
    // ============ ESTIMATION FUNCTIONS ============
    
    /**
     * @dev Estimate transaction cost for given gas usage
     */
    function estimateTransactionCost(uint256 gasUsed) external view returns (uint256) {
        uint256 gasPrice = calculateGasPrice();
        return gasUsed.mul(gasPrice);
    }
    
    /**
     * @dev Calculate batch transaction discount
     */
    function calculateBatchDiscount(uint256 txCount) external pure returns (uint256) {
        if (txCount <= 1) {
            return 10000; // No discount for single transactions
        }
        
        uint256 discountTxs = txCount > 100 ? 100 : txCount;
        uint256 discountBasisPoints = discountTxs.mul(50); // 0.5% per transaction
        
        return uint256(10000).sub(discountBasisPoints);
    }
    
    /**
     * @dev Get competitive analysis data
     */
    function getCompetitiveAnalysis() external view returns (
        uint256 zsnailPrice,
        uint256 targetL1Advantage,
        uint256 avgPriceWeek,
        uint256 priceVolatility
    ) {
        zsnailPrice = calculateGasPrice();
        targetL1Advantage = 9500; // Target 95% cheaper than L1
        avgPriceWeek = _getAveragePrice(5040); // 1 week of blocks
        priceVolatility = _calculateVolatility(168); // 24 hour volatility
    }
    
    // ============ UTILITY FUNCTIONS ============
    
    /**
     * @dev Initialize time weights for peak/off-peak pricing
     */
    function _initializeTimeWeights() internal {
        // Default weight: 1.0 (10000 basis points)
        for (uint256 i = 0; i < 24; i++) {
            timeWeights[i] = 10000;
        }
        
        // Peak hours (UTC 12-16, 20-24): 1.5x weight
        for (uint256 i = 12; i < 16; i++) {
            timeWeights[i] = 15000;
        }
        for (uint256 i = 20; i < 24; i++) {
            timeWeights[i] = 15000;
        }
        
        // Low hours (UTC 4-8): 0.7x weight
        for (uint256 i = 4; i < 8; i++) {
            timeWeights[i] = 7000;
        }
    }
    
    /**
     * @dev Update price history arrays
     */
    function _updatePriceHistory() internal {
        uint256 currentPrice = calculateGasPrice();
        
        priceHistory[priceHistoryIndex] = currentPrice;
        utilizationHistory[priceHistoryIndex] = currentUtilization;
        
        priceHistoryIndex = (priceHistoryIndex + 1) % PRICE_HISTORY_LENGTH;
    }
    
    /**
     * @dev Calculate average utilization over last N blocks
     */
    function _getAverageUtilization(uint256 blocks) internal view returns (uint256) {
        if (totalBlocks < blocks) {
            blocks = totalBlocks;
        }
        
        uint256 sum = 0;
        uint256 count = 0;
        
        for (uint256 i = 0; i < blocks && i < PRICE_HISTORY_LENGTH; i++) {
            uint256 index = (priceHistoryIndex + PRICE_HISTORY_LENGTH - 1 - i) % PRICE_HISTORY_LENGTH;
            sum = sum.add(utilizationHistory[index]);
            count++;
        }
        
        return count > 0 ? sum.div(count) : 0;
    }
    
    /**
     * @dev Calculate average price over last N blocks
     */
    function _getAveragePrice(uint256 blocks) internal view returns (uint256) {
        if (totalBlocks < blocks) {
            blocks = totalBlocks;
        }
        
        uint256 sum = 0;
        uint256 count = 0;
        
        for (uint256 i = 0; i < blocks && i < PRICE_HISTORY_LENGTH; i++) {
            uint256 index = (priceHistoryIndex + PRICE_HISTORY_LENGTH - 1 - i) % PRICE_HISTORY_LENGTH;
            sum = sum.add(priceHistory[index]);
            count++;
        }
        
        return count > 0 ? sum.div(count) : baseFee;
    }
    
    /**
     * @dev Calculate price volatility over last N blocks
     */
    function _calculateVolatility(uint256 blocks) internal view returns (uint256) {
        if (totalBlocks < blocks || blocks < 2) {
            return 0;
        }
        
        uint256 avgPrice = _getAveragePrice(blocks);
        uint256 sumSquaredDiffs = 0;
        uint256 count = 0;
        
        for (uint256 i = 0; i < blocks && i < PRICE_HISTORY_LENGTH; i++) {
            uint256 index = (priceHistoryIndex + PRICE_HISTORY_LENGTH - 1 - i) % PRICE_HISTORY_LENGTH;
            uint256 price = priceHistory[index];
            
            uint256 diff = price > avgPrice ? price.sub(avgPrice) : avgPrice.sub(price);
            sumSquaredDiffs = sumSquaredDiffs.add(diff.mul(diff));
            count++;
        }
        
        // Return square root of variance (standard deviation)
        return count > 1 ? _sqrt(sumSquaredDiffs.div(count.sub(1))) : 0;
    }
    
    /**
     * @dev Calculate square root using Babylonian method
     */
    function _sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        
        return y;
    }
    
    // ============ ADMIN FUNCTIONS ============
    
    /**
     * @dev Set infrastructure cost per day (in USD cents)
     */
    function setInfrastructureCost(uint256 _costCents) external onlyOwner {
        infrastructureCostPerDay = _costCents;
        _recalculateBaseFee();
    }
    
    /**
     * @dev Set USD to ZSNAIL exchange rate
     */
    function setUsdToZsnailRate(uint256 _rate) external onlyOwner {
        usdToZsnailRate = _rate;
        _recalculateBaseFee();
    }
    
    /**
     * @dev Emergency price override
     */
    function emergencyPriceOverride(uint256 _newBaseFee) external onlyOwner {
        require(_newBaseFee >= MIN_GAS_PRICE.div(4), "Base fee too low");
        require(_newBaseFee <= MAX_GAS_PRICE.div(4), "Base fee too high");
        
        uint256 oldBaseFee = baseFee;
        baseFee = _newBaseFee;
        
        emit BaseFeeAdjusted(oldBaseFee, baseFee);
    }
    
    /**
     * @dev Recalculate base fee from infrastructure cost
     */
    function _recalculateBaseFee() internal {
        // B = (IC / BPD) * PM * LD
        uint256 blocksPerDay = 86400 / (BLOCK_TIME / 1000); // 43,200 blocks
        uint256 costPerBlock = infrastructureCostPerDay.mul(10**16).div(blocksPerDay); // Convert cents to wei
        uint256 profitMargin = 12000; // 1.2x (20% profit) in basis points
        uint256 l2Discount = 100; // 0.01x (99% discount) in basis points
        
        baseFee = costPerBlock
            .mul(profitMargin)
            .div(10000)
            .mul(l2Discount)
            .div(10000)
            .mul(usdToZsnailRate)
            .div(100); // Convert from cents
    }
    
    // ============ VIEW FUNCTIONS ============
    
    /**
     * @dev Get current pricing components
     */
    function getPricingComponents() external view returns (
        uint256 _baseFee,
        uint256 _priorityFee,
        uint256 _congestionMultiplier,
        uint256 _operationalCost,
        uint256 _totalPrice
    ) {
        _baseFee = baseFee;
        _priorityFee = _calculatePriorityFee();
        _congestionMultiplier = _calculateCongestionMultiplier();
        _operationalCost = _calculateOperationalCost();
        _totalPrice = calculateGasPrice();
    }
    
    /**
     * @dev Get current network metrics
     */
    function getNetworkMetrics() external view returns (
        uint256 _currentTPS,
        uint256 _currentUtilization,
        uint256 _activeValidators,
        uint256 _maxValidators,
        uint256 _currentBlock,
        uint256 _totalBlocks
    ) {
        return (
            currentTPS,
            currentUtilization,
            activeValidators,
            maxValidators,
            currentBlock,
            totalBlocks
        );
    }
}