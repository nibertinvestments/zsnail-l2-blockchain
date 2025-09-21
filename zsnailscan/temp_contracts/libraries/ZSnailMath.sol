// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ZSnailMath
 * @dev Custom mathematical library for ZSnail L2 blockchain operations
 * @notice Provides gas-optimized mathematical functions for L2 calculations
 */
library ZSnailMath {
    
    /**
     * @dev Custom sqrt implementation optimized for L2 gas costs
     * @param x Input number to calculate square root
     * @return Square root of x
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        
        return y;
    }
    
    /**
     * @dev Safe addition with overflow protection
     * @param a First operand
     * @param b Second operand
     * @return Sum of a and b
     */
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ZSnailMath: addition overflow");
        return c;
    }
    
    /**
     * @dev Safe subtraction with underflow protection
     * @param a First operand
     * @param b Second operand
     * @return Difference of a and b
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "ZSnailMath: subtraction underflow");
        return a - b;
    }
    
    /**
     * @dev Safe multiplication with overflow protection
     * @param a First operand
     * @param b Second operand
     * @return Product of a and b
     */
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        
        uint256 c = a * b;
        require(c / a == b, "ZSnailMath: multiplication overflow");
        return c;
    }
    
    /**
     * @dev Safe division with zero protection
     * @param a Dividend
     * @param b Divisor
     * @return Quotient of a and b
     */
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "ZSnailMath: division by zero");
        return a / b;
    }
    
    /**
     * @dev Calculate percentage with precision
     * @param value Base value
     * @param percentage Percentage (in basis points, 10000 = 100%)
     * @return Calculated percentage of value
     */
    function percentage(uint256 value, uint256 percentage) internal pure returns (uint256) {
        return safeMul(value, percentage) / 10000;
    }
    
    /**
     * @dev Calculate compound interest for staking rewards
     * @param principal Initial amount
     * @param rate Interest rate (in basis points)
     * @param periods Number of compounding periods
     * @return Final amount after compound interest
     */
    function compoundInterest(
        uint256 principal,
        uint256 rate,
        uint256 periods
    ) internal pure returns (uint256) {
        uint256 amount = principal;
        
        for (uint256 i = 0; i < periods; i++) {
            amount = safeAdd(amount, percentage(amount, rate));
        }
        
        return amount;
    }
    
    /**
     * @dev Calculate gas fees with custom ZSnail pricing
     * @param gasUsed Amount of gas consumed
     * @param baseFee Base fee per gas unit
     * @param priorityFee Priority fee for faster processing
     * @return Total fee in wei
     */
    function calculateGasFee(
        uint256 gasUsed,
        uint256 baseFee,
        uint256 priorityFee
    ) internal pure returns (uint256) {
        return safeMul(gasUsed, safeAdd(baseFee, priorityFee));
    }
}