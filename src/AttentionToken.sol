// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// 导入 OpenZeppelin 的标准 ERC20 代币合约
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// 导入 OpenZeppelin 的所有权管理合约
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title AttentionToken (ATT 代币)
/// @notice AttentionLive 平台的原生代币，使用标准的 ERC20 实现，18 位小数
/// @dev 继承自 OpenZeppelin 的 ERC20 和 Ownable 合约
contract AttentionToken is ERC20, Ownable {
    
    // ============ 事件 ============
    
    /// @notice 当新代币被铸造时触发
    /// @param to 接收代币的地址
    /// @param amount 铸造的代币数量
    event Minted(address indexed to, uint256 amount);
    
    /// @notice 当代币被销毁时触发
    /// @param from 销毁代币的地址
    /// @param amount 销毁的代币数量
    event Burned(address indexed from, uint256 amount);

    // ============ 构造函数 ============
    
    /// @notice 部署合约并铸造初始供应量
    /// @dev 初始供应量为 1 亿 ATT，全部分配给部署者
    constructor() ERC20("Attention Token", "ATT") Ownable(msg.sender) {
        // 铸造初始供应量：100,000,000 ATT (带 18 位小数)
        // 10**18 是因为 ERC20 标准使用 18 位小数
        _mint(msg.sender, 100_000_000 * 10**18);
    }

    // ============ 外部函数 ============
    
    /// @notice 铸造新代币（仅限合约所有者）
    /// @dev 用于奖励分发或增加代币供应
    /// @param to 接收新代币的地址
    /// @param amount 要铸造的代币数量（带小数位）
    function mint(address to, uint256 amount) external onlyOwner {
        // 确保不向零地址铸造代币
        require(to != address(0), "ATT: mint to zero address");
        // 调用 ERC20 的内部铸造函数
        _mint(to, amount);
        // 触发铸造事件
        emit Minted(to, amount);
    }

    /// @notice 销毁调用者的代币
    /// @dev 任何人都可以销毁自己的代币，用于减少流通供应
    /// @param amount 要销毁的代币数量（带小数位）
    function burn(uint256 amount) external {
        // 调用 ERC20 的内部销毁函数
        // 会自动检查调用者是否有足够的余额
        _burn(msg.sender, amount);
        // 触发销毁事件
        emit Burned(msg.sender, amount);
    }
}
