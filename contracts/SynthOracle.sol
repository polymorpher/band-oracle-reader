pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

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

abstract contract SynthOracle is ISynthOracle, Owned {

    // only available after solidity v0.8.4
    // error NotImplemented();
    string constant NOT_IMPLEMENTED = "NOT_IMPLEMENTED";

    mapping(uint256 => int256) internal roundData;

    uint256 public updateFee;


    function getAnswer(
        uint256 /*roundId*/
    ) external view returns (int256) {
        revert(NOT_IMPLEMENTED);
    }

    function getTimestamp(
        uint256 /*roundId*/
    ) external view returns (uint256) {
        revert(NOT_IMPLEMENTED);
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
        revert(NOT_IMPLEMENTED);
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
        revert(NOT_IMPLEMENTED);
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
        revert(NOT_IMPLEMENTED);
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
        revert(NOT_IMPLEMENTED);
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
        revert(NOT_IMPLEMENTED);
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
        revert(NOT_IMPLEMENTED);
    }
}