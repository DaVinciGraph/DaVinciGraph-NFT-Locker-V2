// SPDX-License-Identifier: MIT
// Developed by the DaVinciGraph Team
// Website: davincigraph.io

pragma solidity ^0.8.9;

import "./hedera/SafeHTS.sol";
import "./hedera/Helpers.sol";

import "./libraries/SafeCast.sol";

import "./davincigraph/DavinciFeeChargable.sol";

import "./openzeppelin/Pausable.sol";

/**
 * @title DaVinciGraph NFT Locker
 * @notice This contract allows users to securely lock non-fungible tokens (NFTs) on the Hedera network. Users can set 
 *         lock durations, designate beneficiaries, extend lock durations, and withdraw NFTs once the lock duration 
 *         has expired. The contract utilizes DAVINCI tokens for operation fees.
 * @dev The contract securely manages NFT transfers through Hedera Token Service (HTS) and prevents reentrancy attacks.
 */
contract DaVinciGraphNFTLocker is DavinciFeeChargable, Pausable {
    using SafeCast for uint256;

    /**
     * @dev Structure representing a lock.
     * - `creator`: The address of the account that created the lock.
     * - `beneficiary`: The address of the account that will receive the NFT upon lock expiration.
     * - `start`: The timestamp when the lock was created.
     * - `duration`: The lock duration in seconds.
     */
    struct Lock {
        address creator;
        address beneficiary;
        int64 start;
        int64 duration;
    }

    /**
     * @dev Mapping structure to store locks:
     *      - token => serialNumber => Lock
     */
    mapping(address => mapping(int64 => Lock)) public locks;

    /**
     * @notice Initializes the NFT locker with a specified fee.
     * @param _fee The fee (in DAVINCI tokens) to charge for each lock operation.
     */
    constructor(int64 _fee) DavinciFeeChargable(_fee) {}

    /**
     * @notice Allows the contract to associate a new non-fungible token to the itself.
     * @param token The address of the NFT token to be associated.
     * @dev This function is restricted to non-fungible tokens (NFTs) and enables the locker to securely manage 
     *      specified NFTs through Hedera Token Service.
     */
    function associateToken(address token) external whenNotPaused {
        HederaHelpers.associateNonFungibleToken(token);

        emit TokenAssociated(token);
    }

    /**
     * @notice Allows a user to create a new lock for an NFT with a specific beneficiary and duration.
     * @param token The address of the Non-Fungible Token.
     * @param serialNumber The serial number of the NFT to be locked.
     * @param beneficiary The address of the account that will receive the NFT upon lock expiration.
     * @param duration The lock duration in seconds.
     * @dev Transfers the NFT from the sender to the locker contract and charges a fee in DAVINCI tokens.
     *      Ensures the NFT is not already locked and validates all inputs.
     */
    function createLock(
        address token,
        int64 serialNumber,
        address beneficiary,
        uint256 duration
    ) external nonReentrant whenNotPaused {
        require(token != address(0), "Token address must be provided");
        require(beneficiary != address(0), "Beneficiary address must be provided");
        require(duration > 1 minutes, "Lock duration should be greater than 1 minute");
        require(serialNumber > 0, "Serial number must be provided");
        require(locks[token][serialNumber].duration == 0, "NFT is already locked");

        SafeHTS.safeTransferNFT(token, msg.sender, address(this), serialNumber);
        chargeFee(fee);
        locks[token][serialNumber] = Lock(msg.sender, beneficiary, block.timestamp.toInt64(), duration.toInt64());
        emit LockCreated(token, serialNumber, msg.sender, beneficiary, duration);
    }

    /**
     * @notice Extends the duration of an existing NFT lock.
     * @param token The address of the Non-Fungible Token.
     * @param serialNumber The serial number of the NFT.
     * @param extraDuration The additional time (in seconds) to add to the lock duration.
     * @dev Only the beneficiary of the lock can extend the duration. A fee in DAVINCI tokens is charged for this operation.
     */
    function extendLockDuration(
        address token,
        int64 serialNumber,
        uint256 extraDuration
    ) external nonReentrant {
        require(token != address(0), "Token address cannot be zero");
        require(serialNumber > 0, "Serial number must be provided");
        require(extraDuration > 0, "Extra Duration should be greater than 0");

        Lock memory lock = locks[token][serialNumber];

        require(lock.duration > 0, "Lock does not exist");
        require(lock.beneficiary == msg.sender, "Only beneficiary can extend the lock duration");

        chargeFee(fee);
        locks[token][serialNumber].duration += extraDuration.toInt64();
        emit LockDurationExtended(token, serialNumber, extraDuration);
    }

    /**
     * @notice Allows the beneficiary or any other account on behalf of the beneficiary to withdraw an NFT 
     *         after the lock duration has expired.
     * @param token The address of the Non-Fungible Token.
     * @param serialNumber The serial number of the NFT to withdraw.
     * @dev Ensures the lock duration has expired before allowing withdrawal. Deletes the lock entry upon successful transfer.
     */
    function withdrawUnlockedNFT(
        address token,
        int64 serialNumber
    ) external nonReentrant {
        require(token != address(0), "Token address cannot be zero");
        require(serialNumber > 0, "Serial number must be provided");

        Lock memory lock = locks[token][serialNumber];

        require(lock.duration > 0, "Lock does not exist");
        require(block.timestamp.toInt64() >= lock.start + lock.duration, "Lock duration is not over");

        HederaHelpers.revertOnTokensWithCustomFees(token);
        delete locks[token][serialNumber];
        SafeHTS.safeTransferNFT(token, address(this), lock.beneficiary, serialNumber);
        emit UnlockedNFTWithdrawn(token, serialNumber, msg.sender);
    }

    /**
     * @notice Retrieves the lock details for a specific NFT.
     * @param token The address of the Non-Fungible Token.
     * @param serialNumber The serial number of the NFT.
     * @return The lock details including creator, beneficiary, start time, and duration.
     */
    function getLockedNFT(
        address token,
        int64 serialNumber
    ) public view returns (Lock memory) {
        return locks[token][serialNumber];
    }

    /**
     * @notice Pauses the contract, preventing association and lock creation operations.
     * @dev Only callable by the contract owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract, resuming association and lock creation operations.
     * @dev Only callable by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // Events

    /**
     * @notice Emitted when a new Non-Fungible Token is successfully associated with the locker.
     * @param token The address of the associated Non-Fungible Token.
     */
    event TokenAssociated(address indexed token);

    /**
     * @notice Emitted when a new NFT lock is created.
     * @param token The address of the Non-Fungible Token.
     * @param serialNumber The serial number of the locked NFT.
     * @param creator The address of the creator of the lock.
     * @param beneficiary The address of the beneficiary.
     * @param duration The lock duration in seconds.
     */
    event LockCreated(
        address indexed token,
        int64 indexed serialNumber,
        address creator,
        address beneficiary,
        uint256 duration
    );

    /**
     * @notice Emitted when the lock duration for an NFT is extended.
     * @param token The address of the Non-Fungible Token.
     * @param serialNumber The serial number of the locked NFT.
     * @param extraDuration The additional time (in seconds) added to the lock duration.
     */
    event LockDurationExtended(
        address indexed token,
        int64 indexed serialNumber,
        uint256 extraDuration
    );

    /**
     * @notice Emitted when an NFT is withdrawn after the lock duration expires.
     * @param token The address of the Non-Fungible Token.
     * @param serialNumber The serial number of the NFT.
     * @param actor The account performing the withdrawal.
     */
    event UnlockedNFTWithdrawn(
        address indexed token,
        int64 indexed serialNumber,
        address actor
    );
}
