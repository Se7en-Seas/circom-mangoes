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

// TODO use template parameters to make this more flexible
// TODO change leafs to be split into 2 numbers, so that smart contracts can pass in keccak256 hashes of the leafs.
template SecretdMerkleTree() {
    signal input secret; // Secret value hashed with leafs before tree construction.
    signal input leafs[8];
    signal input pathIndices_0[4];
    signal input pathIndices_1[2];
    signal input pathIndices_2;
    signal output secretRoot;

    // Hash first layer of leafs.
    signal internal_0[4];
    component selectors_0[4];
    component hashers_0[4];
    component secret_hashers[8];

    for (var i=0; i<4; i++) {
        // Hash leafs with secret.
        secret_hashers[2 * i] = HashLeftRight();
        secret_hashers[2 * i].left <== leafs[2 * i]; // Left is always the leaf.
        secret_hashers[2 * i].right <== secret; // Right is always the secret.
        secret_hashers[2 * i + 1] = HashLeftRight();
        secret_hashers[2 * i + 1].left <== leafs[2 * i + 1];
        secret_hashers[2 * i + 1].right <== secret;

        selectors_0[i] = DualMux();
        selectors_0[i].in[0] <== secret_hashers[2 * i].out;
        selectors_0[i].in[1] <== secret_hashers[2 * i + 1].out;
        selectors_0[i].s <== pathIndices_0[i];

        hashers_0[i] = HashLeftRight();
        hashers_0[i].left <== selectors_0[i].out[0];
        hashers_0[i].right <== selectors_0[i].out[1];
        internal_0[i] <== hashers_0[i].out;
    }

    // Hash the next layer
    signal internal_1[2];
    component selectors_1[2];
    component hashers_1[2];

    for (var i=0; i<2; i++) {
        selectors_1[i] = DualMux();
        selectors_1[i].in[0] <== internal_0[2 * i];
        selectors_1[i].in[1] <== internal_0[2 * i + 1];
        selectors_1[i].s <== pathIndices_1[i];

        hashers_1[i] = HashLeftRight();
        hashers_1[i].left <== selectors_1[i].out[0];
        hashers_1[i].right <== selectors_1[i].out[1];
        internal_1[i] <== hashers_1[i].out;
    }

    // Hash the final layer
    signal internal_2;
    component selector_2 = DualMux();
    selector_2.in[0] <== internal_1[0];
    selector_2.in[1] <== internal_1[1];
    selector_2.s <== pathIndices_2;

    component hasher_2 = HashLeftRight();
    hasher_2.left <== selector_2.out[0];
    hasher_2.right <== selector_2.out[1];

    secretRoot <== hasher_2.out;
}

component main {public [leafs]} = SecretdMerkleTree();