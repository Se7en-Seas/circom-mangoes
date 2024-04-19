// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MiMC} from "src/MiMC.sol";

contract MiMCTest is Test {
    MiMC public hasher;

    function setUp() public {
        hasher = new MiMC();
    }

    function testHash() external {
        uint256 hash = hasher.hash(1);

        uint256 expectedOut = 21785673157876902334464013887733890681254725954471966448540240124574108155811;
        assertEq(hash, expectedOut, "Hash does not match expected output");
    }

    function testHashMulti() external {
        uint256 x = 8904385298540932584375984375983427598475;
        uint256 y = 11432532454949349845858585855555985734985743987592843759;
        uint256 hash = hasher.hashMulti(x, y);

        uint256 expectedOut = 190464376388688072797252877547784713098038893007072289640332979678670439217;
        assertEq(hash, expectedOut, "Hash does not match expected output");
    }

    function testGasUsage() external {
        uint256 x = 8904385298540932584375984375983427598475;
        // uint256 y = 11432532454949349845858585855555985734985743987592843759;
        uint256 gas = gasleft();
        hasher.hash(x);
        console.log("Gas used: %d", gas - gasleft());
    }
}
