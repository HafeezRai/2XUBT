pragma solidity ^0.5.16;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./StableMath.sol";
import "./CFD.sol";

/**
 * @notice UpSideDai contract
 * @dev Just a CFD factory
 */
contract UpDown2xUbt is Ownable {
    using StableMath for uint256;

    mapping(uint256 => address) public deployedCFD;

    event CFDeployed(
        address indexed CFD,
        uint256 creationDate,
        uint256 indexed settlementDate,
        uint256 indexed version
    );

    /**
     * @notice deploy a new CFD
     * @param _makerMedianizer maker medianizer address
     * @param _uniswapFactory uniswap factory address
     * @param _daiToken dai token addr
     * @param _leverage leverage where 1x == 1e18
     * @param _fee payout fee where 100% fee == 1e18
     * @param _settlementLength time in seconds for settlement
     * @param _version tranche number, or version
     */
    function newCFD(
        address _makerMedianizer,
        address _uniswapFactory,
        address _daiToken,
        uint256 _leverage,
        uint256 _fee,
        uint256 _settlementLength,
        uint256 _version
    ) public onlyOwner {
        require(
            _makerMedianizer != address(0),
            "DaiHard::invalid maker medianizer address"
        );
        require(
            _uniswapFactory != address(0),
            "DaiHard::invalid uniswap factory address"
        );
        require(_daiToken != address(0), "DaiHard::invalid DAI token address");
        require(_leverage > 0, "DaiHard::invalid leverage");

        require(_settlementLength > 0, "DaiHard::invalid settlement timestamp");

        uint256 settlementDate = now.add(_settlementLength);

        deployedCFD[_version] = address(
            new CFD(
                _makerMedianizer,
                _uniswapFactory,
                _daiToken,
                _leverage,
                _fee,
                settlementDate,
                _version
            )
        );

        emit CFDeployed(deployedCFD[_version], now, settlementDate, _version);
    }

}
