// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FavorToken is ERC20Burnable, ERC20Votes, Ownable, Pausable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    uint256 public immutable cap;

    /**
     * @dev Initializes the contract minting the new tokens for the deployer.
     * deployer here is the owner of the FavorToken.
     */
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply, uint256 _cap) ERC20(_name, _symbol) ERC20Permit(_name) {
        require(_totalSupply <= _cap,"constructor: totalSupply cannot be more than cap");
        cap = _cap;
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
     * @dev Creates `amount` new tokens. Only the owner can call mint().
     *
     * See {ERC20-_mint}.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        ERC20Votes._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        ERC20Votes._burn(account, amount);
    }

    // Derives from multiple bases defining _afterTokenTransfer(), so the function overrides it
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        ERC20Votes._afterTokenTransfer(from, to, amount);
    }
}
