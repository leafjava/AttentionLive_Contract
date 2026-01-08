// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title AttentionToken
/// @notice Platform native token for AttentionLive - ATT token with 18 decimals
contract AttentionToken is ERC20, Ownable {
    
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    constructor() ERC20("Attention Token", "ATT") Ownable(msg.sender) {
        // Mint initial supply to deployer (100 million ATT)
        _mint(msg.sender, 100_000_000 * 10**18);
    }

    /// @notice Mint new tokens (only owner - for reward distribution)
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "ATT: mint to zero address");
        _mint(to, amount);
        emit Minted(to, amount);
    }

    /// @notice Burn tokens from caller
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit Burned(msg.sender, amount);
    }
}
