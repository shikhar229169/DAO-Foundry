// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {Box} from "../src/Box.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {GovToken} from "../src/GovToken.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/Governor.sol"; 

contract MyGovernorTest is Test {
    MyGovernor governor;
    Box box;
    TimeLock timeLock;
    GovToken govToken;

    address user = makeAddr("user");

    uint256 MIN_DELAY = 1 hours;
    uint256 INIT_SUPPLY = 100 ether;
    uint256 VOTING_DELAY = 1;
    uint256 VOTING_PERIOD = 1 weeks;


    address[] proposers;
    address[] executors;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;

    function setUp() external {
        vm.startPrank(user);

        govToken = new GovToken();  

        govToken.mint(user, INIT_SUPPLY);   // mints gov token
        govToken.delegate(user);

        timeLock = new TimeLock(MIN_DELAY, proposers, executors);

        governor = new MyGovernor(govToken, timeLock);

        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.TIMELOCK_ADMIN_ROLE();

        timeLock.grantRole(proposerRole, address(governor));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(adminRole, user);

        box = new Box();

        box.transferOwnership(address(timeLock));

        vm.stopPrank();
    }

    function test_CantUpdateBox_WithoutGovernance() public {
        vm.expectRevert();

        box.setNumber(777);
    }

    function test_Governance_UpdatesBox() public {
        uint256 newNumber = 777;
        bytes memory data = abi.encodeWithSelector(
            box.setNumber.selector, newNumber
        );

        string memory description = "Hey I want to change the number to 777 because it's my favourite.";
        targets.push(address(box));
        values.push(0);
        calldatas.push(data);

        // Creates a proposal to change the number
        uint256 proposalId = governor.propose(targets, values, calldatas, description);
        console.log("----Proposal Created-----");
        console.log("Current State:", uint256(governor.state(proposalId)));

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("----Voting Starts-----");
        console.log("Current State:", uint256(governor.state(proposalId)));

        // Vote in favour for the proposal
        uint8 support = 1;
        string memory reason = "Because I am a CAT-HAWK-FROF";

        vm.prank(user);
        governor.castVoteWithReason(proposalId, support, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("----Voting Period Over----");
        console.log("Current State:", uint256(governor.state(proposalId)));

        // We did the voting, as there is only 1 vote which is in favour
        // so the state changes to Succeeded
        // but if the vote was against or no votes, the state would be Defeated

        // Now we need to queue to txn to be executed
        // Queue the Proposal

        bytes32 descriptionHash = keccak256(abi.encodePacked(description));

        governor.queue(targets, values, calldatas, descriptionHash);

        console.log("----Proposal is in Queued State----");
        console.log("Current State:", uint256(governor.state(proposalId)));

        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        // The time lock delay has passed
        // Time to execute the proposl

        governor.execute(targets, values, calldatas, descriptionHash);

        console.log("----Proposal Executed----");
        console.log("Current State:", uint256(governor.state(proposalId)));


        assert(governor.state(proposalId) == IGovernor.ProposalState.Executed);
        assertEq(box.getNumber(), newNumber);
    }
}

// in IGovernor
enum ProposalState {
    Pending,    // 0
    Active,     // 1
    Canceled,   // 2
    Defeated,   // 3
    Succeeded,  // 4
    Queued,     // 5
    Expired,    // 6
    Executed    // 7
}

// in GovernorCountingSimple
// signifies uint8 support
enum VoteType {
    Against,  // 0
    For,      // 1
    Abstain   // 2
}