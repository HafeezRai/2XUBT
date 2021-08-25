pragma solidity ^0.5.16;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapFactory.sol";
import "./interfaces/IUniswapExchange.sol";
import "./interfaces/IMakerMedianizer.sol";
import "./tokens/Up2xUbt.sol";
import "./tokens/Down2xUbt.sol";
import "./StableMath.sol";

/**
  * @title CFD - take a 20x leveraged position on the future price of DAI.. or provide
  * liquidity to the market and earn staking rewards. Liquidation prices at 20x are 0.95<>1.05
  * @author Daichotomy team
  * @dev Check out all this sweet code!
  */
contract CFD {
    using StableMath for uint256;

    /***************************************
                  CONNECTIONS
    ****************************************/

    address public makerMedianizer;
    address public uniswapFactory;
    address public daiToken;

    /***************************************
                    CONFIG
    ****************************************/

    Up2xUbt public up2xUbt;
    Down2xUbt public down2xUbt;
    IUniswapExchange public uniswapUp2xUbtExchange;
    IUniswapExchange public uniswapDown2xUbtExchange;

    uint256 public leverage; // 1x leverage == 1e18
    uint256 public feeRate; // 100% fee == 1e18, 0.3% fee == 3e15
    uint256 public settlementDate; // In seconds

    /***************************************
              STAKING & SETTLEMENT
    ****************************************/

    bool public inSettlementPeriod = false;
    uint256 public daiPriceAtSettlement; // $1 == 1e18
    uint256 public up2xUbtRateAtSettlement; // 1:1 == 1e18
    uint256 public down2xUbtRateAtSettlement; // 1:1 == 1e18

    uint256 public totalMintVolumeInDai;

    struct Stake {
        uint256 upLP; // Total LP for the UP2XUBT pool
        uint256 downLP; // Total LP for the UP2XUBT pool
        uint256 mintVolume; // Total mint volume in DA units
        bool liquidated; // Has this staker withdrawn his funds?
    }

    mapping(address => Stake) public stakes;

    event UpDown2xUbtRates(
        uint256 up2xUbtRate,
        uint256 down2xUbtRate
    );

    event NeededEthCollateral(
        address indexed depositor,
        address indexed cfd,
        uint256 indexed amount,
        uint256 up2xUbtPoolEth,
        uint256 down2xUbtPoolEth,
        uint256 totalEthCollateral
    );

    /**
     * @notice constructor
     * @param _makerMedianizer maker medianizer address
     * @param _uniswapFactory uniswap factory address
     * @param _daiToken maker medianizer address
     * @param _leverage leverage (1000000000000000x) (1x == 1e18)
     * @param _fee payout fee (1% == 1e16)
     * @param _settlementDate maker medianizer address
     * @param _version which tranche are we on?
     */
    constructor(
        address _makerMedianizer,
        address _uniswapFactory,
        address _daiToken,
        uint256 _leverage,
        uint256 _fee,
        uint256 _settlementDate,
        uint256 _version
    ) public {
        makerMedianizer = _makerMedianizer;
        uniswapFactory = _uniswapFactory;
        daiToken = _daiToken;

        leverage = _leverage;
        feeRate = _fee;
        settlementDate = _settlementDate;

        up2xUbt = new Up2xUbt(_version);
        down2xUbt = new Down2xUbt(_version);

        uniswapUp2xUbtExchange = IUniswapExchange(
            IUniswapFactory(uniswapFactory).createExchange(address(up2xUbt))
        );
        uniswapDown2xUbtExchange = IUniswapExchange(
            IUniswapFactory(uniswapFactory).createExchange(address(down2xUbt))
        );

        require(
            up2xUbt.approve(address(uniswapUp2xUbtExchange), uint256(-1)),
            "Approval of up2xUbt failed"
        );
        require(
            down2xUbt.approve(address(uniswapDown2xUbtExchange), uint256(-1)),
            "Approval of down2xUbt failed"
        );
    }

    /***************************************
                    MODIFIERS
    ****************************************/


    // veiw later

    modifier notInSettlementPeriod() {
        if (now > settlementDate) {
            inSettlementPeriod = true;
            daiPriceAtSettlement = GetDaiPriceUSD();
            (
                up2xUbtRateAtSettlement,
                down2xUbtRateAtSettlement
            ) = getCurrentDaiRates(daiPriceAtSettlement);
        }
        require(!inSettlementPeriod, "Must not be in settlement period");
        _;
    }

    modifier onlyInSettlementPeriod() {
        require(inSettlementPeriod, "Must be in settlement period");
        _;
    }

    /***************************************
              LIQUIDITY PROVIDERS
    ****************************************/

    /**
     * @notice mint UP and DOWN 2xUbt tokens
     * @param _daiDeposit amount of DAI to deposit
     */
    function mint(uint256 _daiDeposit) external payable notInSettlementPeriod {
        // Step 1. Take the DAI
        require(
            IERC20(daiToken).transferFrom(
                msg.sender,
                address(this),
                _daiDeposit
            ),
            "CFD::error transfering underlying asset"
        );

        // Step 2. Calculate the value of these tokens, and how much ETH that is
        (uint256 up2xUbtEthUnits, uint256 down2xUbtEthUnits) = getETHCollateralRequirements(
            _daiDeposit
        );
        uint256 totalETHCollateral = up2xUbtEthUnits.add(down2xUbtEthUnits);
        require(msg.value >= totalETHCollateral, "CFD::error transfering ETH");
        if (msg.value > totalETHCollateral) {
            msg.sender.transfer(msg.value - totalETHCollateral);
        }

        // Step 3. Mint the up/down 2xUbt tokens
        up2xUbt.mint(address(this), _daiDeposit.div(2));
        down2xUbt.mint(address(this), _daiDeposit.div(2));

        // Step 4. Contribute to Uniswap
        uint256 upLP = uniswapUp2xUbtExchange.addLiquidity.value(up2xUbtEthUnits)(
            1,
            _daiDeposit.div(2),
            now.add(3600)
        );
        uint256 downLP = uniswapDown2xUbtExchange.addLiquidity.value(
            down2xUbtEthUnits
        )(1, _daiDeposit.div(2), now + 3600);

        // Step 5. Store the LP and log the mint volume
        totalMintVolumeInDai = totalMintVolumeInDai.add(_daiDeposit);
        stakes[msg.sender] = Stake({
            upLP: stakes[msg.sender].upLP.add(upLP),
            downLP: stakes[msg.sender].downLP.add(downLP),
            mintVolume: stakes[msg.sender].mintVolume.add(_daiDeposit),
            liquidated: false
        });

        // TODO - add a time element here to incentivise early stakers to provide liquidity
        // This will affect the proportionate amount of rewards they receive at the end

    }

    /**
     * @notice get the amount of ETH required to create a uniswap exchange
     * @param _daiDeposit the total amount of underlying to deposit (UP/DOWN 2xUbt = _daiDeposit/2)
     * @return the amount of ETH needed for UP2XUBT pool and DOWN2XUBT pool
     */
    function getETHCollateralRequirements(uint256 _daiDeposit)
        public
        returns (uint256, uint256)
    {
        uint256 individualDeposits = _daiDeposit.div(2);
        // get ETH price, where $200 == 200e18
        uint256 ethUsdPrice = GetETHUSDPriceFromMedianizer();
        // get DAI price, where $1 == 1e18
        uint256 daiPriceUsd = GetDaiPriceUSD();

        // Rate 1:1 == 1e18, 1.2:1 == 12e17
        (uint256 up2xUbtRate, uint256 down2xUbtRate) = getCurrentDaiRates(
            daiPriceUsd
        );
        // e.g. (11e17 * 1e18) / 1e18 = 11e17
        uint256 totalUp2xUbtValue = up2xUbtRate.mulTruncate(individualDeposits);
        uint256 totalDown2xUbtValue = down2xUbtRate.mulTruncate(individualDeposits);

        // ETH amount needed for the UP2XUBT pool
        // e.g. (11e17 * 1e18) / 287e18 = 11e35 / 287e18 = 3e15 ETH
        uint256 up2xUbtPoolEth = totalUp2xUbtValue.divPrecisely(ethUsdPrice);
        uint256 down2xUbtPoolEth = totalDown2xUbtValue.divPrecisely(ethUsdPrice);

        emit NeededEthCollateral(
            msg.sender,
            address(this),
            _daiDeposit,
            up2xUbtPoolEth,
            down2xUbtPoolEth,
            up2xUbtPoolEth.add(down2xUbtPoolEth)
        );

        return (up2xUbtPoolEth, down2xUbtPoolEth);
    }

    /**
     * @notice Claims all rewards that a staker is eligable for
     */
    function claimRewards() external onlyInSettlementPeriod {
        Stake memory stake = stakes[msg.sender];
        require(
            stake.mintVolume > 0 && !stake.liquidated,
            "Must be a valid staker"
        );
        stakes[msg.sender].liquidated = true;

        // 1. Claim Redemption Fees (proportionate to LP)
        // e.g. (1e27 * 3e15)/1e18 = 3e42/1e18 = 3e24
        uint256 totalRedemptionFees = totalMintVolumeInDai.mulTruncate(feeRate);
        require(
            IERC20(daiToken).transfer(msg.sender, totalRedemptionFees),
            "Must receive the fees"
        );

        // 2. Redeem or withdraw LP
        // 2.1. Get everything from Uniswap
        (uint256 ethRedeemedUp, uint256 up2xUbtRedeemed) = uniswapUp2xUbtExchange
            .removeLiquidity(stake.upLP, 1, 1, now + 3600);
        (uint256 ethRedeemedDown, uint256 down2xUbtRedeemed) = uniswapDown2xUbtExchange
            .removeLiquidity(stake.downLP, 1, 1, now + 3600);
        // 2.2. Redeem all the tokens
        _payout(
            msg.sender,
            up2xUbtRedeemed,
            down2xUbtRedeemed,
            up2xUbtRateAtSettlement,
            down2xUbtRateAtSettlement
        );
        // 2.3. Transfer the eth to the user
        msg.sender.transfer(ethRedeemedUp.add(ethRedeemedDown));
    }

    /***************************************
                PUBLIC REDEPTION
    ****************************************/

    /**
     * @notice redeem a pair of UP2XUBT and DOWN2XUBT
     * @dev this function can be called before the settlement date, an equal amount of UPDAI and DOWNDAI should be deposited
     * @param _redeemAmount Pair count where 1 real token == 1e18 base units
     */
    function redeem(uint256 _redeemAmount) public notInSettlementPeriod {
        // burn UPDAI & DOWNDAI from redeemer
        up2xUbt.burnFrom(msg.sender, _redeemAmount);
        down2xUbt.burnFrom(msg.sender, _redeemAmount);

        uint256 daiPriceUsd = GetDaiPriceUSD();
        // Rate 1:1 == 1e18, 1.2:1 == 12e17
        (uint256 up2xUbtRate, uint256 down2xUbtRate) = getCurrentDaiRates(
            daiPriceUsd
        );

        // spread MONEY bitches
        _payout(
            msg.sender,
            _redeemAmount,
            _redeemAmount,
            up2xUbtRate,
            down2xUbtRate
        );
    }

    /**
     * @notice redeem UP2xUbt or DOWN2xUbt token
     * @dev this function can only be called after contract settlement
     */
    function redeemFinal() public onlyInSettlementPeriod {
        // get up2xUbt balance
        uint256 up2xUbtRedeemAmount = up2xUbt.balanceOf(msg.sender);
        // get down2xUbt balance
        uint256 down2xUbtRedeemAmount = down2xUbt.balanceOf(msg.sender);

        // burn up2xUbt
        up2xUbt.burnFrom(msg.sender, up2xUbtRedeemAmount);
        // burn down2xUbt
        down2xUbt.burnFrom(msg.sender, down2xUbtRedeemAmount);

        // spread MONEY bitches
        _payout(
            msg.sender,
            up2xUbtRedeemAmount,
            down2xUbtRedeemAmount,
            up2xUbtRateAtSettlement,
            down2xUbtRateAtSettlement
        );
    }

    /***************************************
              INTERNAL - PAYOUT
    ****************************************/

    /**
     * @notice $ payout function $
     * @dev can only be called internally
     * @param redeemer redeemer address
     * @param up2xUbtUnits units of Up2xUbt
     * @param down2xUbtUnits units of Down2xUbt
     * @param up2xUbtRate Rate of 2xUbt<>DAI
     * @param down2xUbtRate units of 2xUbt<>DAI
     */
    function _payout(
        address redeemer,
        uint256 up2xUbtUnits,
        uint256 down2xUbtUnits,
        uint256 up2xUbtRate,
        uint256 down2xUbtRate
    ) internal {
        // e.g. (12e17 * 100e18) / 1e18 = 12e37 / 1e18 = 120e18
        uint256 convertedUp2xUbt = up2xUbtRate.mulTruncate(up2xUbtUnits);
        // e.g. (8e17 * 100e18) / 1e18 = 8e37 / 1e18 = 80e18
        uint256 convertedDown2xUbt = down2xUbtRate.mulTruncate(down2xUbtUnits);
        // if feeRate = 3e15, (2e20*3e15)/1e18 = 6e17
        uint256 totalDaiPayout = convertedUp2xUbt.add(convertedDown2xUbt);
        uint256 fee = totalDaiPayout.mulTruncate(feeRate);
        // Pay the moola
        IERC20(daiToken).transfer(redeemer, totalDaiPayout.sub(fee));
    }

    /***************************************
              INTERNAL - SETTLE CONTRACT
    ****************************************/

    /**
     * @notice settle CFD
     * @param daiUsdPrice Dai price in USD where $1 == 1e18
     */
    function _settleContract(uint256 daiUsdPrice, bool priceIsPositive) internal {
        inSettlementPeriod = true;
        daiPriceAtSettlement = daiUsdPrice;

        // If Price is positive, Up wins and is worth 2:1, where Down is worth 0:1
        (uint256 finalUp2xUbtRate, uint256 finalDown2xUbtRate) = priceIsPositive
            ? (uint256(2e18), uint256(0))
            : (uint256(0), uint256(2e18));
        up2xUbtRateAtSettlement = finalUp2xUbtRate;
        down2xUbtRateAtSettlement = finalDown2xUbtRate;
    }

    /***************************************
                  PRICE HELPERS
    ****************************************/

    /**
     * @notice Based on the price of DAI, what are the current exchange rates for up2xUbt and down2xUbt?
     * @param daiUsdPrice Dai price in USD where $1 == 1e18
     * @return up2xUbtRate where 1:1 == 1e18
     * @return down2xUbtRate where 1:1 == 1e18
     */
    function getCurrentDaiRates(uint256 daiUsdPrice)
        public
        returns (uint256, uint256)
    {
        // (1 + ((DaiPriceFeed-1) *  Leverage))
        // Given that price is reflected absolutely on both sides.. then
        // (1 + (delta * leverage)), to find the up multiplier
        uint256 one = 1e18;
        bool priceIsPositive = daiUsdPrice > one;
        // Get price delta, e.g. if daiUsdPrice == 1007e15, delta == 7e15
        uint256 delta = priceIsPositive
            ? daiUsdPrice.sub(one)
            : one.sub(daiUsdPrice);
        // Consider 20x leverage == 20e18 == 2e19, then
        // e.g. 7e15 * 2e19 == 14e34, then truncate to 4e16
        uint256 deltaWithLeverage = delta.mulTruncate(leverage);
        // e.g. 1e18 + 4e16 = 104e16
        uint256 winRate = one.add(deltaWithLeverage);
        // If the price has hit the roof, settle the contract
        if (winRate >= uint256(2e18)) {
            _settleContract(daiUsdPrice, priceIsPositive);

            emit UpDown2xUbtRates(up2xUbtRateAtSettlement, down2xUbtRateAtSettlement);

            return (up2xUbtRateAtSettlement, down2xUbtRateAtSettlement);
        }
        else {
            // e.g. 1e18 - 2e17 = 8e17
            uint256 loseRate = (uint256(2e18)).sub(deltaWithLeverage);
            // If price is positive, up2xUbtRate should be better :)
            if(priceIsPositive) {
                emit UpDown2xUbtRates(winRate, loseRate);

                return (winRate, loseRate);
            }
            else {
                emit UpDown2xUbtRates(loseRate, winRate);

                return (loseRate, winRate);
            }
        }
    }

    /**
     * @notice get DAI price in USD
     * @dev this function get the DAI/USD price by getting the price of ETH/USD from Maker medianizer and dividing it by the price of ETH/DAI from Uniswap.
     * @return relativePrice of DAI with regards to USD peg, where 1:1 == 1e18
     */
    function GetDaiPriceUSD() public view returns (uint256 relativePrice) {
        address uniswapExchangeAddress = IUniswapFactory(uniswapFactory)
            .getExchange(daiToken);

        // ethUsdPrice, where $1 == 1e18
        uint256 ethUsdPrice = GetETHUSDPriceFromMedianizer();
        // ethDaiPrice, where 1:1 == 1e8. Using a single wei here means 0 slippage and allows pricing from low liq pool
        // extrapolate to base 1e18 in order to do calcs
        uint256 ethDaiPriceSimple = IUniswapExchange(uniswapExchangeAddress)
            .getEthToTokenInputPrice(1 * 10**6);
        uint256 ethDaiPriceExact = ethDaiPriceSimple.mul(10**12);

        return ethUsdPrice.divPrecisely(ethDaiPriceExact);
    }

    /**
     * @notice Parses the bytes32 price from Makers Medianizer into uint
     * @return uint256 Medianised price where $1 == 1e18
     */
    function GetETHUSDPriceFromMedianizer() public view returns (uint256) {
        return uint256(IMakerMedianizer(makerMedianizer).read());
    }
}