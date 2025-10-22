// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MinimalERC20.sol";

/// @title BondingCurveTokenExponential
/// @notice Exponential-like bonding curve implemented with fixed-point approximation.
contract BondingCurveTokenExponential is MinimalERC20 {
    uint256 public k; // coefficient
    uint8 public precision = 4; // low precision for example
    address public owner;
    event Bought(address indexed buyer, uint256 tokens, uint256 cost);

    constructor(uint256 _k) MinimalERC20("BondingExp", "BCE") {
        k = _k;
        owner = msg.sender;
    }

    // approximate price function: price per token = k * (1 + supply / 10^precision) ^ precision
    function pricePerTokenAtSupply(uint256 S) public view returns (uint256) {
        // naive polynomial approximation: (1 + x)^n approx 1 + n*x for small x, to keep gas down
        uint256 x = S / (10 ** precision);
        return k * (1 + uint256(precision) * x);
    }

    function priceToMint(uint256 n) public view returns (uint256) {
        uint256 cost = 0;
        for(uint256 i = 0; i < n; i++) {
            cost += pricePerTokenAtSupply(totalSupply + i);
        }
        return cost;
    }

    function buyExact(uint256 n) external payable {
        require(n > 0, "zero");
        uint256 cost = priceToMint(n);
        require(msg.value >= cost, "insufficient value");
        _mint(msg.sender, n * (10 ** decimals));
        if(msg.value > cost) payable(msg.sender).transfer(msg.value - cost);
        emit Bought(msg.sender, n, cost);
    }

    receive() external payable {}
}
