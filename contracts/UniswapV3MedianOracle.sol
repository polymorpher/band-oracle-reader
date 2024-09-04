pragma solidity ^0.8.18;

import {SynthOracle} from "./SynthOracle.sol";
import {PythStructs} from "./interfaces/PythStructs.sol";
import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20Metadata} from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract UniswapV3MedianOracle is SynthOracle {
    error InvalidTick();
    int24 internal constant MAX_V3POOL_TICK = 887272;

    IUniswapV3Pool public pool;
    bool public inverse;
    uint8 public token0Decimals;
    uint8 public token1Decimals;
    uint32 public medianWindow;

    /// by default, price is token1/token0, i.e. number of token1 needed to buy 1 unit of token0.
    /// e.g. For USDC/WETH pair, the default price is the number of WETH needed to buy 1 USDC
    /// when _inverse is set to true, the oracle will return price as token1/token0 instead
    /// the price returned by this oracle is in decimal format (e.g. 1234.567 means price is $1234.567 per WETH) multiplied by 1e18 for precision.
    constructor(
        IUniswapV3Pool _pool,
        bool _inverse,
        uint32 _medianWindow,
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
        medianWindow = _medianWindow;
    }

    // copied from Panoptic Math library
    // https://github.com/polymorpher/panoptic-v1-core/blob/02cd20d23698f9ae62d6d51262f7043be4146b6c/contracts/libraries/Math.sol#L659
    function quickSort(int24[] memory arr, int256 left, int256 right) internal pure {
        unchecked {
            int256 i = left;
            int256 j = right;
            if (i == j) return;
            int24 pivot = arr[uint256(left + (right - left) / 2)];
            while (i < j) {
                while (arr[uint256(i)] < pivot) i++;
                while (pivot < arr[uint256(j)]) j--;
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    i++;
                    j--;
                }
            }
            if (left < j) quickSort(arr, left, j);
            if (i < right) quickSort(arr, i, right);
        }
    }

    // copied from Panoptic Math library
    function sort(int24[] memory data) internal pure returns (int24[] memory) {
        unchecked {
            quickSort(data, int256(0), int256(data.length - 1));
        }
        return data;
    }

    // https://github.com/polymorpher/panoptic-v1-core/blob/1432f9152e3e16c9c692b14bd7160bff7ce20737/contracts/libraries/PanopticMath.sol#L111
    function medianTickFilter(
        IUniswapV3Pool univ3pool,
        uint32 window
    ) internal view returns (int24 medianTick) {
        uint32[] memory secondsAgos = new uint32[](20);

        int24[] memory measurements = new int24[](19);

        unchecked {
        // construct the time stots
            for (uint32 i = 0; i < 20; ++i) {
                secondsAgos[i] = ((i + 1) * window) / uint32(20);
            }

        // observe the tickCumulative at the 20 pre-defined time slots
            (int56[] memory tickCumulatives, ) = univ3pool.observe(secondsAgos);

        // compute the average tick per 30s window
            for (uint32 i = 0; i < 19; ++i) {
                measurements[i] = int24(
                    (tickCumulatives[i] - tickCumulatives[i + 1]) / int56(uint56(window / 20))
                );
            }

        // sort the tick measurements
            int24[] memory sortedTicks = sort(measurements);

        // Get the median value
            medianTick = sortedTicks[10];
        }
    }

    // same as Uniswap's TickMath implementation, but Uniswap's code doesn't compile due to more strict type check in later versions of Solidity
    // https://github.com/polymorpher/panoptic-v1-core/blob/02cd20d23698f9ae62d6d51262f7043be4146b6c/contracts/libraries/Math.sol#L113
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_V3POOL_TICK))) revert InvalidTick();

            uint256 sqrtR = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
        // RealV: 0xfffcb933bd6fad37aa2d162d1a594001
            if (absTick & 0x2 != 0) sqrtR = (sqrtR * 0xfff97272373d413259a46990580e213a) >> 128;
        // RealV: 0xfff97272373d413259a46990580e2139
            if (absTick & 0x4 != 0) sqrtR = (sqrtR * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        // RealV: 0xfff2e50f5f656932ef12357cf3c7fdca
            if (absTick & 0x8 != 0) sqrtR = (sqrtR * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        // RealV: 0xffe5caca7e10e4e61c3624eaa0941ccd
            if (absTick & 0x10 != 0) sqrtR = (sqrtR * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        // RealV: 0xffcb9843d60f6159c9db58835c92663e
            if (absTick & 0x20 != 0) sqrtR = (sqrtR * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        // RealV: 0xff973b41fa98c081472e6896dfb254b6
            if (absTick & 0x40 != 0) sqrtR = (sqrtR * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        // RealV: 0xff2ea16466c96a3843ec78b326b5284f
            if (absTick & 0x80 != 0) sqrtR = (sqrtR * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        // RealV: 0xfe5dee046a99a2a811c461f1969c3032
            if (absTick & 0x100 != 0) sqrtR = (sqrtR * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        // RealV: 0xfcbe86c7900a88aedcffc83b479aa363
            if (absTick & 0x200 != 0) sqrtR = (sqrtR * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        // RealV: 0xf987a7253ac413176f2b074cf7815dd0
            if (absTick & 0x400 != 0) sqrtR = (sqrtR * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        // RealV: 0xf3392b0822b70005940c7a398e4b6ff1
            if (absTick & 0x800 != 0) sqrtR = (sqrtR * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        // RealV: 0xe7159475a2c29b7443b29c7fa6e887f2
            if (absTick & 0x1000 != 0) sqrtR = (sqrtR * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        // RealV: 0xd097f3bdfd2022b8845ad8f792aa548c
            if (absTick & 0x2000 != 0) sqrtR = (sqrtR * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        // RealV: 0xa9f746462d870fdf8a65dc1f90e05b52
            if (absTick & 0x4000 != 0) sqrtR = (sqrtR * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        // RealV: 0x70d869a156d2a1b890bb3df62baf27ff
            if (absTick & 0x8000 != 0) sqrtR = (sqrtR * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        // RealV: 0x31be135f97d08fd981231505542fbfe8
            if (absTick & 0x10000 != 0) sqrtR = (sqrtR * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        // RealV: 0x9aa508b5b7a84e1c677de54f3e988fe
            if (absTick & 0x20000 != 0) sqrtR = (sqrtR * 0x5d6af8dedb81196699c329225ee604) >> 128;
        // RealV: 0x5d6af8dedb81196699c329225ed28d
            if (absTick & 0x40000 != 0) sqrtR = (sqrtR * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        // RealV: 0x2216e584f5fa1ea926041bedeaf4
            if (absTick & 0x80000 != 0) sqrtR = (sqrtR * 0x48a170391f7dc42444e8fa2) >> 128;
        // RealV: 0x48a170391f7dc42444e7be7

            if (tick > 0) sqrtR = type(uint256).max / sqrtR;

        // Downcast + rounding up to keep is consistent with Uniswap's
            sqrtPriceX96 = uint160((sqrtR >> 32) + (sqrtR % (1 << 32) == 0 ? 0 : 1));
        }
    }

    function _readUniswapPrice() view internal returns (uint256){
        int24 medianTick = medianTickFilter(pool, medianWindow);
        uint160 sqrtPriceX96 = getSqrtRatioAtTick(medianTick);
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