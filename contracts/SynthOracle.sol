pragma solidity ^0.8.18;

import {IStdReference} from "./BandOracleInterfaces.sol";
import {PythStructs} from "./interfaces/PythStructs.sol";
import {AggregatorV2V3Interface} from "./interfaces/AggregatorV2V3Interface.sol";
import {IPyth} from "./interfaces/IPyth.sol";
import {Owned} from "./Owned.sol";

interface ISynthOracle is AggregatorV2V3Interface, IPyth {
    struct RateAtRound {
        int256 rate;
        uint256 round;
    }

    function updateFee() view external returns (uint256);

    function pullDataAndCache() external returns (RateAtRound memory);

    function withdraw() external;

    function setUpdateFee(uint256 _fee) external;
}

// abstract contract was introduced in solidity 0.6.0
// https://www.perplexity.ai/search/solidity-which-version-introdu-G4MjlroSR4.iU0CUUNSlKw
abstract contract SynthOracle is ISynthOracle, Owned {

    // only available after solidity v0.8.4
    error NotImplemented();

    mapping(uint256 => int256) internal roundData;

    uint256 public updateFee;

    constructor(address _owner) Owned(_owner) {

    }


    function getAnswer(
        uint256 /*roundId*/
    ) external view returns (int256) {
        revert(NotImplemented());
    }

    function getTimestamp(
        uint256 /*roundId*/
    ) external view returns (uint256) {
        revert(NotImplemented());
    }

    // Owner functions

    function withdraw() external onlyOwner {
        (bool success,) = owner.call.value(address(this).balance)("");
        require(success, "withdrawal failed");
    }

    function setUpdateFee(uint256 _fee) external onlyOwner {
        updateFee = _fee;
    }


    function getValidTimePeriod()
    external
    view
    returns (
        uint /*validTimePeriod*/
    )
    {
        revert(NotImplemented());
    }


    function getPriceNoOlderThan(
        bytes32, /*id*/
        uint /*age*/
    )
    external
    view
    returns (
        PythStructs.Price memory /*price*/
    )
    {
        revert(NotImplemented());
    }

    function getEmaPrice(
        bytes32 /*id*/
    )
    external
    view
    returns (
        PythStructs.Price memory /*price*/
    )
    {
        revert(NotImplemented());
    }

    function getEmaPriceUnsafe(
        bytes32 /*id*/
    )
    external
    view
    returns (
        PythStructs.Price memory /*price*/
    )
    {
        revert(NotImplemented());
    }

    function getEmaPriceNoOlderThan(
        bytes32, /*id*/
        uint /*age*/
    )
    external
    view
    returns (
        PythStructs.Price memory /*price*/
    )
    {
        revert(NotImplemented());
    }


    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    )
    external
    payable
    returns (
        PythStructs.PriceFeed[] memory /*priceFeeds*/
    )
    {
        revert(NotImplemented());
    }
}