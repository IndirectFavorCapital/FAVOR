// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Favor is ERC20, ERC20Capped, ERC20Burnable, ERC20Votes, Ownable, Pausable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    /**
     * @dev Initializes the contract minting the new tokens for the deployer.
     * deployer here is the owner of the Favor.
     */
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, uint256 _cap) ERC20(_name, _symbol) ERC20Capped(_cap) {
        _mint(msg.sender, _totalSupply);
    }

    /**
     * @dev Pauses all token transfers. Only the owner can call pause().
     *
     * See {Pausable-_pause}.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers. Only the owner can call unpause().
     *
     * See {Pausable-_unpause}.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Creates `_amount` new tokens. Only the owner can call mint().
     *
     * See {ERC20-_mint}.
     */
    function mint(uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }

    /**
     * @dev Destroys `_amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }

    // Derives from multiple bases defining _afterTokenTransfer(), so the function overrides it
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    // Derives from multiple bases defining _mint(), so the function overrides it
    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Capped, ERC20Votes) {
        super._mint(to, amount);
    }

    // Derives from multiple bases defining _burn(), so the function overrides it
    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

}