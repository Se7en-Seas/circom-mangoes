pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/mimc.circom";
include "../node_modules/circomlib/circuits/comparators.circom";


template HashLeftRight() {
    signal input left;
    signal input right;
    signal output out;

    // Define a MiMC7 hash circuit with 2 inputs and 91 rounds
    component hasher = MultiMiMC7(2, 91);
    hasher.in[0] <== left;
    hasher.in[1] <== right;
    // Give hasher a fixed key of 1.
    hasher.k <== 1;
    out <== hasher.out;
}

template DualMux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    // Constrain s to 0 or 1
    s * (1 - s) === 0;
    // Order in[0] and in[1] based on s
    // s == 0 => out[0] == in[0] and out[1] == in[1]
    // s == 1 => out[0] == in[1] and out[1] == in[0]
    out[0] <== (in[1] - in[0]) * s + in[0];
    out[1] <== (in[0] - in[1]) * s + in[1];
}

// TODO change leafs to be split into 2 numbers, so that smart contracts can pass in keccak256 hashes of the leafs.
template SecretdMerkleTree(LEAF_COUNT) {
    signal input secret; // Secret value hashed with leafs before tree construction.
    signal input leafs[LEAF_COUNT];
    var arrayLength = 0;
    for (var i=0; 1 != LEAF_COUNT / (2 ** i); i++) {
        arrayLength += LEAF_COUNT / 2 ** (i + 1);
    }
    signal input pathIndices[arrayLength]; // Do not need pathIndices for the root.
    signal output secretRoot;

    // Components.
    component selectors[arrayLength];
    component hashers[LEAF_COUNT + arrayLength]; // Add LEAF_COUNT to pre-hash every leaf with the secret.

    // Hash leafs with secret.
    for (var i=0; i<LEAF_COUNT; i++) {
        hashers[i] = HashLeftRight();
        hashers[i].left <== leafs[i]; // Left is always the leaf.
        hashers[i].right <== secret; // Right is always the secret.
    }

    var hasherOffset = LEAF_COUNT;
    var selectorOffset = 0;
    var hasherIndex = 0;

    // Hash internal digests.
    for (var i=0; 1 != LEAF_COUNT / (2 ** i); i++) {
        var iterations = LEAF_COUNT / (2 ** (i + 1));
        for (var j=0; j<iterations; j++) {
            selectors[j + selectorOffset] = DualMux();
            selectors[j + selectorOffset].in[0] <== hashers[hasherIndex].out;
            selectors[j + selectorOffset].in[1] <== hashers[hasherIndex + 1].out;
            selectors[j + selectorOffset].s <== pathIndices[j + selectorOffset];

            hashers[j + hasherOffset] = HashLeftRight();
            hashers[j + hasherOffset].left <== selectors[j + selectorOffset].out[0];
            hashers[j + hasherOffset].right <== selectors[j + selectorOffset].out[1];

            hasherIndex += 2;
        }
        hasherOffset += iterations;
        selectorOffset += iterations;
    }

    secretRoot <== hashers[hasherOffset - 1].out;
}

component main {public [leafs]} = SecretdMerkleTree(4);