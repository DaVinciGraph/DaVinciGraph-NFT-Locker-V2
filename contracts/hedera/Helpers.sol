// SPDX-License-Identifier: MIT
// Developed by the DaVinciGraph Team
// Website: davincigraph.io

pragma solidity ^0.8.9;

import "./SafeHTS.sol";
import "../libraries/SafeCast.sol";

/**
 * @title HederaHelpers Library
 * @notice This library provides helper functions for interacting with the Hedera Token Service (HTS).
 *         These functions abstract common, complex operations into reusable methods to simplify the main
 *         contract code and improve readability.
 * @dev The functions in this library ensure secure and efficient interactions with HTS, including token
 *      associations, transfers, and validation checks.
 */
library HederaHelpers {

    /**
     * @notice Associates a non-fungible token with the contract.
     * @param token The address of the non-fungible token to be associated.
     * @dev This function verifies that the non-fungible token is valid before associating it with the
     *      contract. It uses the `SafeHTS` library to ensure the association is securely processed.
     *      Emits a `TokenAssociated` event upon successful association. It also prevents the association
     *      of tokens with custom fees.
     */
    function associateNonFungibleToken(address token) internal {
        require(token != address(0), "Token address must be provided");
        require( SafeHTS.safeGetTokenType(token) == 1, "Only non-fungible tokens are allowed" );
        revertOnTokensWithCustomFees(token);
        SafeHTS.safeAssociateToken(token, address(this));
    }

    /**
     * @notice Reverts if the specified token has any custom fee structures.
     * @param token The address of the token to check for custom fees.
     * @dev This function performs a safeguard check to ensure that tokens with custom fees (fixed, fractional, or royalty fees)
     *      are not supported by the contract. Allowing such tokens could unintentionally drain the contract's balance or
     *      complicate fee management. By reverting on tokens with custom fees, this function builds trust between contract
     *      owners and users, ensuring that only tokens without additional fees are allowed, even if associated by mistake.
     */
    function revertOnTokensWithCustomFees(address token) internal {
        // Retrieve the custom fee schedules for the token
        (IHederaTokenService.FixedFee[] memory fixedFees, IHederaTokenService.FractionalFee[] memory fractionalFees, IHederaTokenService.RoyaltyFee[] memory royaltyFees) = SafeHTS.safeGetTokenCustomFees(token);

        // Revert if the token has any type of custom fees
        require(fixedFees.length == 0 && fractionalFees.length == 0 && royaltyFees.length == 0, "Tokens with custom fees are not supported");
    }
}