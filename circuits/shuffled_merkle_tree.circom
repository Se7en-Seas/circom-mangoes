pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/mimc.circom";


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

template ShuffledMerkleTree(LEAF_COUNT, LEVELS) {
    signal input leafs[LEAF_COUNT];
    signal input shuffledRoot;
    signal input hashOrder[LEVELS];
    signal input pathIndices[LEVELS];

    // Hash first layer of leafs.
    signal internal_0[4];
    component selectors_0[4];
    component hashers_0[4];

    for (var i=0; i<4; i++) {
        selectors_0[i] = DualMux();
        // Could the leaves be passed in in an as hidden leafs? Then we just need a verification to show that every public leaf is used.
        selectors_0[i].in[0] <== leafs[hashOrder[i]];
        selectors_0[i].in[1] <== leafs[hashOrder[i+1]];
        selectors_0[i].s <== pathIndices[i];

        hashers_0[i] = HashLeftRight();
        hashers_0[i].left <== selectors_0[i].out[0];
        hashers_0[i].right <== selectors_0[i].out[1];
        internal_0[i] <== hashers_0[i].out;
    }
}

component main {public [leafs, shuffledRoot]} = ShuffledMerkleTree(8, 3);