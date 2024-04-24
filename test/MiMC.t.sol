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

    function testSecretMerkleTree() external {
        uint256 secret = 10;

        uint256 a = hasher.hashMulti(1, 2);
        uint256 leafA = hasher.hashMulti(a, secret);
        uint256 b = hasher.hashMulti(3, 4);
        uint256 leafB = hasher.hashMulti(b, secret);
        uint256 root = hasher.hashMulti(leafA, leafB);

        uint256 expectedRoot = 12496568937140143640907443226343187050369326205835973023618878027235704289017;
        assertEq(root, expectedRoot, "Root does not match expected output");
    }

    function testShuffledMerkleTree() external {
        uint256 leafA = hasher.hashMulti(1, 2);
        uint256 leafB = hasher.hashMulti(3, 4);
        uint256 root = hasher.hashMulti(leafB, leafA);

        console.log("Root: %d", root);
        uint256 expectedRoot = 12496568937140143640907443226343187050369326205835973023618878027235704289017;
        // assertEq(root, expectedRoot, "Root does not match expected output");
    }

    function testVedaMerkleTree() external {
        uint256 leafA = hasher.hashMulti(1, 2);
        uint256 leafB = hasher.hashMulti(3, 4);
        uint256 leafC = hasher.hashMulti(5, 6);
        uint256 secret = 100;

        uint256 AS = hasher.hashMulti(leafA, secret);
        uint256 ANull = hasher.hashMulti(leafA, 0);
        uint256 BC = hasher.hashMulti(leafB, leafC);

        uint256 rootWithNull = hasher.hashMulti(ANull, BC);
        uint256 rootWithSecret = hasher.hashMulti(AS, BC);
        uint256 secretHash = hasher.hash(secret);

        uint256 expectedSecretHash = 13280099886815029221288666002737874468148381556221134405564391793586496323681;
        assertEq(secretHash, expectedSecretHash, "Secret hash does not match expected output");

        console.log("Root with secret: %d", rootWithSecret);
        console.log("Root with null: %d", rootWithNull);
        console.log("Secret hash: %d", secretHash);
        console.log("Leaf BC: %d", BC);
        console.log("Leaf hash A: %d", hasher.hash(leafA));
    }
}
