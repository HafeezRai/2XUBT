pragma solidity ^0.5.16;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";

/**
 * @notice UpDai erc20 token
 */
contract Up2xUbt is ERC20Detailed, ERC20Mintable, ERC20Burnable {
    uint256 public version;

    constructor(uint256 _version) public ERC20Detailed("Up 2xUbt", "UP2XUBT", 18) {
        version = _version;
    }
}
