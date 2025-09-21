#!/usr/bin/env python3
"""
ZSnail L2 Gas Pricing Calculator
Mathematical implementation of gas pricing algorithms
Author: ZSnail Blockchain Framework
Date: September 19, 2025
"""

import math
from datetime import datetime, timezone
from typing import Dict, List, Any

class ZSnailGasPricingCalculator:
    """
    Mathematical gas pricing calculator for ZSnail L2 blockchain
    Implements all algorithms defined in the framework
    """
    
    def __init__(self):
        # Constants
        self.ZSNAIL_DECIMALS = 18
        self.MIN_GAS_PRICE = 0.1  # ZSNAIL
        self.MAX_GAS_PRICE = 10.0  # ZSNAIL
        self.BLOCK_TIME = 2.0  # seconds
        self.MAX_BLOCK_SIZE = 30_000_000  # gas limit
        self.TARGET_UTILIZATION = 0.5  # 50%
        self.MAX_TPS = 25_000
        
        # Economic parameters
        self.infrastructure_cost_per_day = 100.0  # USD
        self.usd_to_zsnail_rate = 12_500  # 1 USD = 12,500 ZSNAIL
        self.profit_margin = 1.2  # 20% profit
        self.l2_discount = 0.01  # 99% cheaper than L1
        
        # Network state
        self.current_tps = 0
        self.current_utilization = 0.0  # 0-1
        self.active_validators = 50
        self.max_validators = 100
        self.current_block = 0
        
        # Price history - properly typed lists
        self.price_history: List[float] = []
        self.utilization_history: List[float] = []
        self.max_history_length = 1000
        
        # Time weights for peak/off-peak pricing
        self.time_weights = self._initialize_time_weights()
        
        # Calculate initial base fee
        self.base_fee = self._calculate_base_fee()
    
    def _initialize_time_weights(self) -> Dict[int, float]:
        """Initialize time weights for 24-hour cycle"""
        weights: Dict[int, float] = {}
        
        # Default weight: 1.0
        for hour in range(24):
            weights[hour] = 1.0
        
        # Peak hours (UTC 12-16, 20-24): 1.5x weight
        for hour in range(12, 16):
            weights[hour] = 1.5
        for hour in range(20, 24):
            weights[hour] = 1.5
        
        # Low hours (UTC 4-8): 0.7x weight
        for hour in range(4, 8):
            weights[hour] = 0.7
        
        return weights
    
    def _calculate_base_fee(self) -> float:
        """
        Calculate base fee using economic formula:
        B = (IC / BPD) * PM * LD
        """
        blocks_per_day = 86400 / self.BLOCK_TIME  # 43,200 blocks
        cost_per_block_usd = self.infrastructure_cost_per_day / blocks_per_day
        
        # Apply profit margin and L2 discount
        base_cost_usd = cost_per_block_usd * self.profit_margin * self.l2_discount
        
        # Convert to ZSNAIL
        base_fee_zsnail = base_cost_usd * self.usd_to_zsnail_rate
        
        return base_fee_zsnail
    
    def calculate_priority_fee(self) -> float:
        """
        Calculate priority fee based on demand:
        F(d) = Fmin * (1 + (TPS_current / TPS_max)^2)
        """
        min_priority = 0.1  # ZSNAIL
        
        if self.current_tps == 0:
            return min_priority
        
        demand_factor = self.current_tps / self.MAX_TPS
        demand_factor_squared = demand_factor ** 2
        
        priority_fee = min_priority * (1 + demand_factor_squared)
        
        return priority_fee
    
    def calculate_congestion_multiplier(self) -> float:
        """
        Calculate congestion multiplier:
        C(u,t) = 1 + (u^3 * w(t))
        """
        if self.current_utilization == 0:
            return 0.0
        
        # Get current hour for time weight
        current_hour = datetime.now(timezone.utc).hour
        time_weight = self.time_weights[current_hour]
        
        # Calculate u^3 (utilization cubed)
        u_cubed = self.current_utilization ** 3
        
        # C = base_fee * (u^3 * w(t))
        congestion_factor = u_cubed * time_weight
        congestion_cost = self.base_fee * congestion_factor
        
        return congestion_cost
    
    def calculate_operational_cost(self) -> float:
        """
        Calculate operational cost:
        O(s) = V(n) + S(d) + N(b)
        """
        # Validator cost: (ActiveValidators / MaxValidators) * 0.05 ZSNAIL
        validator_cost = (self.active_validators / self.max_validators) * 0.05
        
        # Storage cost: Minimal for gas calculation
        storage_cost = 0.001
        
        # Network cost: Based on current TPS
        network_cost = (self.current_tps / 100) * 0.002
        
        return validator_cost + storage_cost + network_cost
    
    def calculate_gas_price(self) -> float:
        """
        Main gas price calculation:
        P = BaseFee + PriorityFee + CongestionMultiplier + OperationalCost
        """
        priority_fee = self.calculate_priority_fee()
        congestion_multiplier = self.calculate_congestion_multiplier()
        operational_cost = self.calculate_operational_cost()
        
        total_price = (self.base_fee + priority_fee + 
                      congestion_multiplier + operational_cost)
        
        # Ensure price is within bounds
        total_price = max(self.MIN_GAS_PRICE, min(self.MAX_GAS_PRICE, total_price))
        
        return total_price
    
    def estimate_transaction_cost(self, gas_used: int) -> float:
        """Estimate transaction cost for given gas usage"""
        gas_price = self.calculate_gas_price()
        # Return cost in ZSNAIL (not wei-style division)
        return gas_used * gas_price / 1_000_000  # More reasonable scaling
    
    def calculate_batch_discount(self, tx_count: int) -> float:
        """Calculate batch transaction discount"""
        if tx_count <= 1:
            return 1.0  # No discount for single transactions
        
        discount_txs = min(tx_count, 100)
        discount_rate = discount_txs * 0.005  # 0.5% per transaction
        
        return 1.0 - discount_rate
    
    def update_network_state(self, tps: int, utilization: float, validators: int):
        """Update current network state"""
        self.current_tps = tps
        self.current_utilization = max(0.0, min(1.0, utilization))
        self.active_validators = validators
        self.current_block += 1
        
        # Update history
        current_price = self.calculate_gas_price()
        self.price_history.append(current_price)
        self.utilization_history.append(self.current_utilization)
        
        # Maintain history length
        if len(self.price_history) > self.max_history_length:
            self.price_history.pop(0)
            self.utilization_history.pop(0)
    
    def update_base_fee(self):
        """Update base fee based on historical utilization"""
        if len(self.utilization_history) < 100:
            return
        
        # Calculate average utilization over last 100 blocks
        avg_utilization = sum(self.utilization_history[-100:]) / 100
        
        old_base_fee = self.base_fee
        
        # Adaptive base fee adjustment
        if avg_utilization > 0.8:  # > 80%
            self.base_fee *= 1.125  # Increase by 12.5%
        elif avg_utilization < 0.2:  # < 20%
            self.base_fee *= 0.875  # Decrease by 12.5%
        
        # Ensure base fee is within bounds
        min_base = self.MIN_GAS_PRICE / 4
        max_base = self.MAX_GAS_PRICE / 4
        self.base_fee = max(min_base, min(max_base, self.base_fee))
        
        print(f"Base fee adjusted: {old_base_fee:.6f} -> {self.base_fee:.6f} ZSNAIL")
    
    def get_competitive_analysis(self) -> Dict[str, Any]:
        """Get competitive analysis data"""
        current_price = self.calculate_gas_price()
        
        # Calculate metrics
        avg_price_week = self._get_average_price(5040)  # 1 week of blocks
        price_volatility = self._calculate_volatility(168)  # 24 hour volatility
        
        return {
            "zsnail_price": current_price,
            "target_l1_advantage": 0.95,  # 95% cheaper target
            "avg_price_week": avg_price_week,
            "price_volatility": price_volatility,
            "cost_per_transaction_types": {
                "simple_transfer": self.estimate_transaction_cost(21_000),
                "erc20_transfer": self.estimate_transaction_cost(65_000),
                "smart_contract": self.estimate_transaction_cost(100_000),
                "complex_defi": self.estimate_transaction_cost(500_000)
            }
        }
    
    def _get_average_price(self, blocks: int) -> float:
        """Calculate average price over last N blocks"""
        if not self.price_history:
            return self.base_fee
        
        recent_prices = self.price_history[-blocks:] if len(self.price_history) >= blocks else self.price_history
        return sum(recent_prices) / len(recent_prices) if recent_prices else self.base_fee
    
    def _calculate_volatility(self, blocks: int) -> float:
        """Calculate price volatility (standard deviation)"""
        if len(self.price_history) < blocks or blocks < 2:
            return 0.0
        
        recent_prices = self.price_history[-blocks:]
        avg_price = sum(recent_prices) / len(recent_prices)
        
        variance = sum((price - avg_price) ** 2 for price in recent_prices) / (len(recent_prices) - 1)
        
        return math.sqrt(variance)
    
    def get_pricing_components(self) -> Dict[str, Any]:
        """Get breakdown of pricing components"""
        return {
            "base_fee": self.base_fee,
            "priority_fee": self.calculate_priority_fee(),
            "congestion_multiplier": self.calculate_congestion_multiplier(),
            "operational_cost": self.calculate_operational_cost(),
            "total_price": self.calculate_gas_price(),
            "network_state": {
                "current_tps": self.current_tps,
                "current_utilization": self.current_utilization,
                "active_validators": self.active_validators,
                "current_block": self.current_block
            }
        }
    
    def simulate_network_conditions(self, scenarios: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Simulate gas pricing under different network conditions"""
        results: List[Dict[str, Any]] = []
        
        for scenario in scenarios:
            # Save current state
            original_state: Dict[str, Any] = {
                "tps": self.current_tps,
                "utilization": self.current_utilization,
                "validators": self.active_validators
            }
            
            # Apply scenario
            self.update_network_state(
                int(scenario.get("tps", self.current_tps)),
                float(scenario.get("utilization", self.current_utilization)),
                int(scenario.get("validators", self.active_validators))
            )
            
            # Calculate results
            result: Dict[str, Any] = {
                "scenario": scenario,
                "gas_price": self.calculate_gas_price(),
                "components": self.get_pricing_components(),
                "transaction_costs": {
                    "simple_transfer": self.estimate_transaction_cost(21_000),
                    "erc20_transfer": self.estimate_transaction_cost(65_000),
                    "defi_operation": self.estimate_transaction_cost(300_000)
                }
            }
            results.append(result)
            
            # Restore original state
            self.update_network_state(
                original_state["tps"],
                original_state["utilization"],
                original_state["validators"]
            )
        
        return results


def main() -> None:
    """Test the gas pricing calculator"""
    calculator = ZSnailGasPricingCalculator()
    
    print("ZSnail L2 Gas Pricing Calculator")
    print("=" * 50)
    
    # Initial state
    print(f"Initial base fee: {calculator.base_fee:.6f} ZSNAIL")
    print(f"Initial gas price: {calculator.calculate_gas_price():.6f} ZSNAIL")
    print()
    
    # Test scenarios
    scenarios: List[Dict[str, Any]] = [
        {"name": "Low Activity", "tps": 100, "utilization": 0.1, "validators": 30},
        {"name": "Normal Activity", "tps": 5000, "utilization": 0.5, "validators": 60},
        {"name": "High Activity", "tps": 15000, "utilization": 0.8, "validators": 90},
        {"name": "Peak Congestion", "tps": 24000, "utilization": 0.95, "validators": 100},
    ]
    
    print("Gas Pricing Scenarios:")
    print("-" * 80)
    print(f"{'Scenario':<15} {'TPS':<8} {'Util%':<6} {'Gas Price':<12} {'Transfer Cost':<12}")
    print("-" * 80)
    
    for scenario in scenarios:
        calculator.update_network_state(
            int(scenario["tps"]),
            float(scenario["utilization"]),
            int(scenario["validators"])
        )
        
        gas_price = calculator.calculate_gas_price()
        transfer_cost = calculator.estimate_transaction_cost(21_000)
        
        print(f"{scenario['name']:<15} {scenario['tps']:<8} "
              f"{float(scenario['utilization'])*100:<5.1f}% {gas_price:<12.6f} "
              f"{transfer_cost:<12.8f}")
    
    print("\nDetailed Analysis for Peak Congestion:")
    print("-" * 50)
    
    # Set peak conditions
    calculator.update_network_state(24000, 0.95, 100)
    components = calculator.get_pricing_components()
    
    for key, value in components.items():
        if isinstance(value, dict):
            print(f"{key}:")
            for k, v in value.items():  # type: ignore
                # Professional display of nested dictionary values
                key_str = str(k)  # type: ignore
                if isinstance(v, (int, float)):
                    print(f"  {key_str}: {v}")
                else:
                    print(f"  {key_str}: {str(v)}")  # type: ignore
        else:
            print(f"{key}: {value:.6f}")
    
    print("\nCompetitive Analysis:")
    print("-" * 30)
    analysis = calculator.get_competitive_analysis()
    
    for key, value in analysis.items():
        if isinstance(value, dict):
            print(f"{key}:")
            for k, v in value.items():  # type: ignore
                # Professional display of analysis results
                key_str = str(k)  # type: ignore
                if isinstance(v, (int, float)):
                    print(f"  {key_str}: {v:.8f} ZSNAIL")
                else:
                    print(f"  {key_str}: {str(v)}")  # type: ignore
        else:
            print(f"{key}: {value}")


if __name__ == "__main__":
    main()