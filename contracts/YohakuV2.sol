// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AttestationERC721} from "./AttestationERC721.sol";

/// @custom:oz-upgrades-from Yohaku
contract AttestationERC721V2 is AttestationERC721 {
    function revokeMinter(address minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
    }
}
