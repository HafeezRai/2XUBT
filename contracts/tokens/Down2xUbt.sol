pragma solidity ^0.5.16;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";

/**
 * @notice Down3xUbt erc20 mock
 */
contract Down2xUbt is ERC20Detailed, ERC20Mintable, ERC20Burnable {
    uint256 public version;

    constructor(uint256 _version)
        public
        ERC20Detailed("Down 2xUbt", "DOWN2XUBT", 18)
    {
        version = _version;
    }
}
