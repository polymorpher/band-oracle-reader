
// File: contracts/interfaces/AggregatorV2V3Interface.sol

pragma solidity ^0.5.16;

//import "@chainlink/contracts-0.0.10/src/v0.5/interfaces/AggregatorV2V3Interface.sol";

interface AggregatorV2V3Interface {
    function latestRound() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File: contracts/interfaces/PythStructs.sol

pragma solidity ^0.5.16;

// import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// File: contracts/interfaces/IPyth.sol

pragma solidity ^0.5.16;



// import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(bytes32 indexed id, uint64 publishTime, int64 price, uint64 conf);

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);

    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// File: contracts/BandOracleInterfaces.sol

pragma solidity ^0.5.16;


interface IStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string calldata _base, string calldata _quote) external view returns (ReferenceData memory);

    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(string[] calldata _bases, string[] calldata _quotes)
        external
        view
        returns (ReferenceData[] memory);
}

// File: contracts/Owned.sol

pragma solidity ^0.5.16;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// File: contracts/BandOracleReader.sol

pragma solidity ^0.5.16;







contract BandOracleReader is AggregatorV2V3Interface, IPyth, Owned {
    // only available after solidity v0.8.4
    // error NotImplemented();
    string constant NOT_IMPLEMENTED = "NOT_IMPLEMENTED";

    IStdReference public bandOracle;
    string public base;
    string public quote;

    mapping(uint256 => int256) internal roundData;

    uint256 public updateFee;

    struct RateAtRound {
        int256 rate;
        uint256 round;
    }

    constructor(
        IStdReference _bandOracle,
        string memory _base,
        string memory _quote,
        uint256 _updateFee
    ) public {
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

    // Owner functions

    function withdraw() external onlyOwner {
        (bool success, ) = owner.call.value(address(this).balance)("");
        require(success, "withdrawal failed");
    }

    function setUpdateFee(uint256 _fee) external onlyOwner {
        updateFee = _fee;
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
        (, int256 rate, uint256 time, , ) = _latestRoundData();

        return int64(rate / 1e9);
    }

    // =============================================

    // ========= Pyth Interface =========
    function _getPrice() internal view returns (PythStructs.Price memory price) {
        (, int256 rate, uint256 time, , ) = _latestRoundData();
        price.publishTime = time;
        price.conf = 0;
        price.expo = 9;
        price.price = int64(rate / 1e9);
        return price;
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
    // =============================================
}
