pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;
import {SynthOracle} from "./SynthOracle.sol";

contract BandOracleReader is SynthOracle {

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
}