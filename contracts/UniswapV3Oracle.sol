pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {SynthOracle} from "./SynthOracle.sol";
import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract BandOracleReader is SynthOracle {
    IUniswapV3Pool public pool;
    bool public inverse;
    uint256 token0Decimals;
    uint256 token1Decimals;

    constructor(
        IUniswapV3Pool _pool,
        bool _inverse,
        uint256 _updateFee,
        address _owner
    ) public Owned(_owner) {
        pool = _pool;
        inverse = _inverse;
        updateFee = _updateFee;
        address token0 = _pool.token0();
        token0Decimals = IERC20Minimal(token0)
    }

    function _readUniswapPrice() internal returns (uint256){
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();
        uint256 price = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96) * 1e18) >> 192;
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
        return 18;
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
        p.price = uint64(_readUniswapPrice() / 1e9);
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