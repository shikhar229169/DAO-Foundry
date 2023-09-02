// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
    constructor(uint256 minDelay, address[] memory proposors, address[] memory executors) TimelockController(minDelay, proposors, executors, msg.sender) {

    }
}