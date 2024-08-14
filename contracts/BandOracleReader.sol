pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {SynthOracle} from "./SynthOracle.sol";

contract BandOracleReader is SynthOracle {

    IStdReference public bandOracle;
    string public base;
    string public quote;

    constructor(
        IStdReference _bandOracle,
        string memory _base,
        string memory _quote,
        uint256 _updateFee,
        address _owner
    ) public Owned(_owner) {
        bandOracle = _bandOracle;
        base = _base;
        quote = _quote;
        updateFee = _updateFee;
    }

    function pullDataAndCache() public returns (RateAtRound memory) {
        IStdReference.ReferenceData memory data = bandOracle.getReferenceData(base, quote);
        uint256 round = block.timestamp;
        if (data.lastUpdatedBase != 0) {
            round = data.lastUpdatedBase;
        }
        roundData[round] = int256(data.rate);
        return RateAtRound(int256(data.rate), round);
    }



    // ========= Chainlink interface ======
    function latestRound() external view returns (uint256) {
        // note that Band oracle sometimes return empty value for lastUpdatedBase and lastUpdatedQuote, even though they should contain the timestamp for the last update
        IStdReference.ReferenceData memory data = bandOracle.getReferenceData(base, quote);
        if (data.lastUpdatedBase != 0) {
            return data.lastUpdatedBase;
        }
        return block.timestamp;
    }

    function decimals() external view returns (uint8) {
        // Band oracle uses 18 decimals, see https://docs.bandchain.org/products/band-standard-dataset/using-band-standard-dataset/contract
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
        // There is no interface from Band oracle to retrieve previous round data
        // return previous round data if we have it, otherwise return empty data, unless round id equals block.timestamp, in which case we return the latest data
        if (uint256(_roundId) == block.timestamp) {
            return _latestRoundData();
        }
        int256 data = roundData[uint256(_roundId)];
        if (data != 0) {
            return (_roundId, data, _roundId, _roundId, _roundId);
        }
        return (0, 0, 0, 0, 0);
    }

    function latestRoundData()
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
        return _latestRoundData();
    }

    function _latestRoundData()
    internal
    view
    returns (
        uint80, /*roundId*/
        int256, /*answer*/
        uint256, /*startedAt*/
        uint256, /*updatedAt*/
        uint80 /*answeredInRound*/
    )
    {
        IStdReference.ReferenceData memory data = bandOracle.getReferenceData(base, quote);
        uint256 round = block.timestamp;
        if (data.lastUpdatedBase != 0) {
            round = data.lastUpdatedBase;
        }
        return (uint80(round), int256(data.rate), round, round, uint80(round));
    }

    // ========= GMX VaultPriceFeed integration =========
    function latestAnswer() external view returns (int256) {
        (, int256 rate, uint256 time, ,) = _latestRoundData();

        return int64(rate / 1e9);
    }

    // =============================================

    // ========= Pyth Interface =========
    function _getPrice() internal view returns (PythStructs.Price memory price) {
        (, int256 rate, uint256 time, ,) = _latestRoundData();
        price.publishTime = time;
        price.conf = 0;
        price.expo = 9;
        price.price = int64(rate / 1e9);
        return price;
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

    // =============================================
}