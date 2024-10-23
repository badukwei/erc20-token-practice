// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is StdCheats, Test {
    // Constants
    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether;

    // Declare the Transfer and Approval events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    OurToken public ourToken;
    DeployOurToken public deployer;

    // Addresses for testing
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);
    address public charlie = address(0xCA71E);

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        // Label addresses for better test output readability
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
    }

    // ----- Initial Supply Tests -----

    function testInitialSupply() public {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    // ----- Transfer Tests -----

    function testTransfer() public {
        uint256 transferAmount = 100 ether; 

        // If there's no prank, foundry will use default address to do the transfer
        vm.prank(msg.sender);

        ourToken.transfer(alice, transferAmount);
        assertEq(ourToken.balanceOf(alice), transferAmount);
    }

    function testTransferEmitsEvent() public {
        uint256 transferAmount = 100 ether;

        vm.prank(msg.sender);

        vm.expectEmit(true, true, false, true);
        emit Transfer(msg.sender, alice, transferAmount);
        ourToken.transfer(alice, transferAmount);
    }

    function testTransferInsufficientBalance() public {
        uint256 excessiveAmount = deployer.INITIAL_SUPPLY() + 1;

        vm.prank(msg.sender);

        vm.expectRevert();
        ourToken.transfer(alice, excessiveAmount);
    }

    function testTransferToZeroAddress() public {
        uint256 transferAmount = 100 ether;

        vm.prank(msg.sender);

        vm.expectRevert();
        ourToken.transfer(address(0), transferAmount);
    }

    // ----- Approval and Allowance Tests -----

    function testApprove() public {
        uint256 approvalAmount = 100 ether;

        vm.prank(msg.sender);

        ourToken.approve(bob, approvalAmount);
        assertEq(ourToken.allowance(msg.sender, bob), approvalAmount);
    }

    function testApproveEmitsEvent() public {
        uint256 approvalAmount = 100 ether;

        vm.prank(msg.sender);

        vm.expectEmit(true, true, false, true);
        emit Approval(msg.sender, bob, approvalAmount);
        ourToken.approve(bob, approvalAmount);
    }

    // ----- TransferFrom Tests -----

    function testTransferFrom() public {
        uint256 bobStartingAmount = 200 ether;
        uint256 approvalAmount = 100 ether;
        uint256 transferAmount = 50 ether;

        vm.prank(msg.sender);
        ourToken.transfer(bob, bobStartingAmount);

        vm.prank(bob);
        ourToken.approve(charlie, approvalAmount);

        vm.prank(charlie);
        ourToken.transferFrom(bob, charlie, transferAmount);

        assertEq(ourToken.balanceOf(msg.sender), deployer.INITIAL_SUPPLY() - bobStartingAmount);
        assertEq(ourToken.balanceOf(bob), bobStartingAmount - transferAmount);
        assertEq(ourToken.balanceOf(charlie), transferAmount);
        assertEq(ourToken.allowance(bob, charlie), approvalAmount - transferAmount);
    }

    function testTransferFromInsufficientAllowance() public {
        uint256 bobStartingAmount = 200 ether;
        uint256 approvalAmount = 50 ether;
        uint256 transferAmount = 60 ether;

        vm.prank(msg.sender);
        ourToken.transfer(bob, bobStartingAmount);

        vm.prank(bob);
        ourToken.approve(charlie, approvalAmount);

        vm.prank(charlie);
        vm.expectRevert();
        ourToken.transferFrom(bob, charlie, transferAmount);
    }

    function testTransferFromInsufficientBalance() public {
        uint256 approvalAmount = deployer.INITIAL_SUPPLY() + 100 ether;
        uint256 transferAmount = deployer.INITIAL_SUPPLY() + 50 ether;

        vm.prank(msg.sender);
        ourToken.approve(bob, approvalAmount);

        vm.prank(bob);
        vm.expectRevert();
        ourToken.transferFrom(msg.sender, bob, transferAmount);
    }

    function testTransferFromEmitsEvent() public {
        uint256 bobStartingAmount = 200 ether;
        uint256 approvalAmount = 100 ether;
        uint256 transferAmount = 70 ether;

        vm.prank(msg.sender);
        ourToken.transfer(bob, bobStartingAmount);

        vm.prank(bob);
        ourToken.approve(charlie, approvalAmount);

        vm.expectEmit(true, true, false, true);
        emit Transfer(bob, charlie, transferAmount);

        vm.prank(charlie);
        ourToken.transferFrom(bob, charlie, transferAmount);
    }

    // ----- Edge Case Tests -----

    function testRevertsWhenSpenderIsZeroAddress() public {
        uint256 approvalAmount = 100 ether;
        
        vm.expectRevert();
        ourToken.approve(address(0), approvalAmount);
    }

    function testTransferMaxUint256() public {
        uint256 maxAmount = type(uint256).max;

        vm.prank(msg.sender);
        vm.expectRevert();
        ourToken.transfer(alice, maxAmount);
    }

    // ----- Metadata Tests -----

    function testTokenName() public {
        assertEq(ourToken.name(), "OurToken");
    }

    function testTokenSymbol() public {
        assertEq(ourToken.symbol(), "OT");
    }

    function testTokenDecimals() public {
        assertEq(ourToken.decimals(), 18);
    }

    // ----- Total Supply Tests -----

    function testTotalSupplyAfterTransfers() public {
        uint256 transferAmount = 100 ether;

        vm.prank(msg.sender);
        ourToken.transfer(alice, transferAmount);

        vm.prank(msg.sender);
        ourToken.transfer(bob, transferAmount);

        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    // ----- Balance Tests -----

    function testBalanceOfNonHolder() public {
        assertEq(ourToken.balanceOf(charlie), 0);
    }

    function testBalanceAfterMultipleTransfers() public {
        uint256 transferAmount1 = 50 ether;
        uint256 transferAmount2 = 30 ether;

        vm.prank(msg.sender);
        ourToken.transfer(alice, transferAmount1);
    
        vm.prank(msg.sender);
        ourToken.transfer(alice, transferAmount2);

        assertEq(ourToken.balanceOf(alice), transferAmount1 + transferAmount2);
    }
}
