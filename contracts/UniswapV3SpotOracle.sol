pragma solidity ^0.8.18;

import {SynthOracle} from "./SynthOracle.sol";
import {PythStructs} from "./interfaces/PythStructs.sol";
import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20Metadata} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract UniswapV3SpotOracle is SynthOracle {
    IUniswapV3Pool public pool;
    bool public inverse;
    uint8 public token0Decimals;
    uint8 public token1Decimals;

    /// by default, price is token1/token0, i.e. number of token1 needed to buy 1 unit of token0.
    /// e.g. For USDC/WETH pair, the default price is the number of WETH needed to buy 1 USDC
    /// when _inverse is set to true, the oracle will return price as token1/token0 instead
    /// the price returned by this oracle is in decimal format (e.g. 1234.567 means price is $1234.567 per WETH) multiplied by 1e18 for precision.
    constructor(
        IUniswapV3Pool _pool,
        bool _inverse,
        uint256 _updateFee,
        address _owner
    ) SynthOracle(_owner) {
        pool = _pool;
        inverse = _inverse;
        updateFee = _updateFee;
        address token0 = _pool.token0();
        address token1 = _pool.token1();
        token0Decimals = IERC20Metadata(token0).decimals();
        token1Decimals = IERC20Metadata(token1).decimals();
    }

    function _readUniswapPrice() view internal returns (uint256){
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint256 priceX128 = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96)) >> 64;
        priceX128 = priceX128 * 1e9;
        uint256 price = priceX128 >> 128;
        if (token0Decimals > token1Decimals) {
            price = price * (10 ** (token0Decimals - token1Decimals));
        } else if (token0Decimals < token1Decimals) {
            price = price / (10 ** (token1Decimals - token0Decimals));
        }
        if (inverse) {
            price = 1e18 / price;
        }
        return price;
    }

    function pullDataAndCache() public returns (RateAtRound memory) {
        uint256 price = _readUniswapPrice();
        uint256 round = block.timestamp;
        roundData[round] = int256(price);
        return RateAtRound(int256(price), round);
    }

    function latestRound() external view returns (uint256) {
        return block.timestamp;
    }

    function decimals() external view returns (uint8) {
        return 9;
    }

    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80, /*roundId*/
        int256, /*answer*/
        uint256, /*startedAt*/
        uint256, /*updatedAt*/
        uint80 /*answeredInRound*/
    )
    {
        if (uint256(_roundId) == block.timestamp) {
            return latestRoundData();
        }
        int256 data = roundData[uint256(_roundId)];
        if (data != 0) {
            return (_roundId, data, _roundId, _roundId, _roundId);
        }
        return (0, 0, 0, 0, 0);
    }

    function latestRoundData()
    public
    view
    returns (
        uint80, /*roundId*/
        int256, /*answer*/
        uint256, /*startedAt*/
        uint256, /*updatedAt*/
        uint80 /*answeredInRound*/
    )
    {
        uint256 rate = _readUniswapPrice();
        uint256 round = block.timestamp;
        return (uint80(round), int256(rate), round, round, uint80(round));
    }

    function latestAnswer() external view returns (int256) {
        return int256(_readUniswapPrice());
    }

    function _getPrice() internal
    view
    returns (
        PythStructs.Price memory p
    ){
        p.price = int64(uint64(_readUniswapPrice()));
        p.expo = 9;
        p.publishTime = block.timestamp;
        return p;
    }

    function getPrice(
        bytes32 /*id*/
    )
    external
    view
    returns (
        PythStructs.Price memory /*price*/
    )
    {
        return _getPrice();
    }


    function getPriceUnsafe(
        bytes32 /*id*/
    )
    external
    view
    returns (
        PythStructs.Price memory /*price*/
    )
    {
        return _getPrice();
    }

    function updatePriceFeeds(
        bytes[] calldata /*updateData*/
    ) external payable {
        // noop
    }


    function updatePriceFeedsIfNecessary(
        bytes[] calldata, /*updateData*/
        bytes32[] calldata, /*priceIds*/
        uint64[] calldata /*publishTimes*/
    ) external payable {
        // noop
    }

    function getUpdateFee(bytes[] calldata updateData) external view returns (uint feeAmount) {
        feeAmount = updateFee;
    }
}