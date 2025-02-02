// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "./IHederaTokenService.sol";
import "./HederaResponseCodes.sol";

library SafeHTS {
    address constant precompileAddress = address(0x167);

    error SingleAssociationFailed();
    error NFTTransferFailed();
    error TokenTransferFailed();
    error GetTokenCustomFeesFailed();
    error GetTokenTypeFailed();

    function safeAssociateToken(address token, address account) internal {
        (bool success, bytes memory result) = precompileAddress.call(
            abi.encodeWithSelector(IHederaTokenService.associateToken.selector,
            account, token));
        if (!tryDecodeSuccessResponseCode(success, result)) revert SingleAssociationFailed();
    }

    function safeTransferNFT(address token, address sender, address receiver, int64 serialNumber) internal {
        (bool success, bytes memory result) = precompileAddress.call(
            abi.encodeWithSelector(IHederaTokenService.transferNFT.selector,
            token, sender, receiver, serialNumber));
        if (!tryDecodeSuccessResponseCode(success, result)) revert NFTTransferFailed();
    }

    function safeTransferToken(address token, address sender, address receiver, int64 amount) internal {
        (bool success, bytes memory result) = precompileAddress.call(
            abi.encodeWithSelector(IHederaTokenService.transferToken.selector,
            token, sender, receiver, amount));
        if (!tryDecodeSuccessResponseCode(success, result)) revert TokenTransferFailed();
    }

    function safeGetTokenCustomFees(address token) internal
    returns (IHederaTokenService.FixedFee[] memory fixedFees, IHederaTokenService.FractionalFee[] memory fractionalFees, IHederaTokenService.RoyaltyFee[] memory royaltyFees)
    {
        int32 responseCode;
        (bool success, bytes memory result) = precompileAddress.call(
            abi.encodeWithSelector(IHederaTokenService.getTokenCustomFees.selector, token));
        (responseCode, fixedFees, fractionalFees, royaltyFees) =
        success
        ? abi.decode(result, (int32, IHederaTokenService.FixedFee[], IHederaTokenService.FractionalFee[], IHederaTokenService.RoyaltyFee[]))
        : (HederaResponseCodes.UNKNOWN, fixedFees, fractionalFees, royaltyFees);
        if (responseCode != HederaResponseCodes.SUCCESS) revert GetTokenCustomFeesFailed();
    }

    function safeGetTokenType(address token) internal
    returns (int32 tokenType)
    {
        int32 responseCode;
        (bool success, bytes memory result) = precompileAddress.call(
            abi.encodeWithSelector(IHederaTokenService.getTokenType.selector, token));
        (responseCode, tokenType) = success ? abi.decode(result, (int32, int32)) : (HederaResponseCodes.UNKNOWN, int32(0));
        if (responseCode != HederaResponseCodes.SUCCESS) revert GetTokenTypeFailed();
    }

    function tryDecodeSuccessResponseCode(bool success, bytes memory result) private pure returns (bool) {
       return (success ? abi.decode(result, (int32)) : HederaResponseCodes.UNKNOWN) == HederaResponseCodes.SUCCESS;
    }
}
