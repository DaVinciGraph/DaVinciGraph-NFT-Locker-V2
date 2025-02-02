// SPDX-License-Identifier: MIT
// Developed by the DaVinciGraph Team
// Website: davincigraph.io

pragma solidity ^0.8.9;

import "./SafeCast.sol";

/**
 * @title Validate Library
 * @notice This library enforces rules around creating and managing token locks to maintain integrity within 
 *         the DaVinciGraph Token Locker contract.
 * @dev The validation functions in this library provide reusable conditions that check the validity of 
 *      operations like creating locks, increasing amounts, extending durations, and withdrawing unlocked amounts.
 */
library Validate {

   
    function newLock(
        address token,
        int64 serialNumber,
        address beneficiary, 
        uint256 duration,
        bool doesLockExist
    ) internal pure {
        require(token != address(0), "Token address must be provided");
        require(beneficiary != address(0), "Beneficiary address must be provided");
        require(duration > 0, "Lock duration should be greater than 0" );
        require(serialNumber > 0, "Serial number must be provided");
        require(doesLockExist == false, "NFT is already locked" );
    }
    
    function extendingDuration(
        address token,
        int64 serialNumber,
        uint256 extraDuration,
        bool doesLockExist
    ) internal pure {
        require(token != address(0), "Token address cannot be zero");
        require(serialNumber > 0, "Serial number must be provided");
        require(extraDuration > 0, "Extra Duration should be greater than 0");
        require(doesLockExist == true, "Lock not found");
    }
    
    function withdrawUnlockedNFT(
        address token,
        int64 serialNumber,
        int64 lockStartTimestamp,
        int64 duration
    ) internal view {
        require(token != address(0), "Token address cannot be zero");
        require(serialNumber > 0, "Serial number must be provided");
        require(duration > 0, "Account have not locked this NFT" );
        require(SafeCast.toInt64(block.timestamp) >= lockStartTimestamp  + duration, "Lock duration is not over" );
    }
}
