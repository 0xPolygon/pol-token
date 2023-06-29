// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract PolygonMigration is Ownable2Step {
    using SafeERC20 for IERC20;

    IERC20 public immutable polygon;
    IERC20 public immutable matic;

    event Migrated(address indexed account, uint256 amount);

    constructor(IERC20 polygon_, IERC20 matic_) {
        polygon = polygon_;
        matic = matic_;
    }

    function migrate(uint256 amount) external {
        emit Migrated(msg.sender, amount);

        matic.safeTransferFrom(msg.sender, address(this), amount);
        polygon.safeTransfer(msg.sender, amount);
        matic.safeTransfer(0x000000000000000000000000000000000000dEaD, amount);
    }
}
