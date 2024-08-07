// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "contracts/Lock.sol";

contract LockTest is Test {
    Lock public lock;
    Lock public lock2;

    uint256 public constant ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    uint256 public ONE_GWEI = 1_000_000_000;

    uint256 public lockedAmount = ONE_GWEI;
    uint256 public unlockTime = block.timestamp + ONE_YEAR_IN_SECS;

    address owner = vm.addr(1);
    address another = vm.addr(2);

    event Withdrawal(uint256 amount, uint256 when);

    //Deployment
    function setUp() public {
        hoax(owner, 1 ether);
        lock = new Lock{value: lockedAmount}(unlockTime);
        // console.log("Called setUp");
    }

    //Should set the right unlockTime
    function testUnlockTime() public {
        assertEq(lock.unlockTime(), unlockTime);
    }

    //Should set the right owner
    function testRightOwner() public {
        assertEq(lock.owner(), owner);
    }

    //Should receive and store the funds to lock
    function testStoreFunds() public {
        assertEq(address(lock).balance, lockedAmount);
    }

    //Should fail if the unlockTime is not in the future
    function testFailDeployNotFutureUnlockTime() public {
        lock = new Lock{value: lockedAmount}(1);
    }

    function testDeployNotFutureUnlockTime() public {
        vm.expectRevert();
        lock = new Lock{value: lockedAmount}(1);
    }

    //Should revert with the right error if called too soon
    function testNotWithdraws() public {
        vm.expectRevert(bytes("You can't withdraw yet"));
        lock.withdraw();
    }

    //Should revert with the right error if called from another account
    function testNotHandleAnotherAccount() public {
        vm.startPrank(another);
        vm.expectRevert(bytes("You aren't the owner"));

        //increase the time
        skip(unlockTime);
        lock.withdraw();

        vm.stopPrank();
    }

    //Shouldn't fail if the unlockTime has arrived and the owner calls it
    function testFailWithdrawsAtUnlockTime() public {
        vm.expectRevert();
        vm.prank(owner);
        skip(unlockTime);
        lock.withdraw();
    }

    //Should emit an event on withdrawals
    function testEmitWithdrawal() public {
        vm.startPrank(another);
        vm.deal(another, 1 ether);
        lock2 = new Lock{value: lockedAmount}(unlockTime);

        skip(unlockTime);

        //Lock.sol event Withdrawal(uint amount, uint when);
        vm.expectEmit(false, false, false, true);
        emit Withdrawal(address(lock2).balance, block.timestamp);
        lock2.withdraw();

        vm.stopPrank();
    }

    //Should transfer the funds to the owner
    function testOwnerWithdraws() public {
        skip(unlockTime);

        vm.startPrank(owner);

        lock.withdraw();
        assertEq(address(lock).balance, 0);
        assertEq(address(owner).balance, 1 ether);

        vm.stopPrank();
    }
}
