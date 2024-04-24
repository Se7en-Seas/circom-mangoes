pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/switcher.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/mimc.circom";

// Hash left and right inputs using Poseidon.
// template HashLR() {
//     signal input L;
//     signal input R;
//     signal output out;

//     component hasher = Poseidon(2);
//     hasher.inputs[0] <== L;
//     hasher.inputs[1] <== R;

//     hasher.out ==> out;
// }

// template HashSingle() {
//     signal input single;
//     signal output out;

//     component hasher = Poseidon(1);
//     hasher.inputs[0] <== single;

//     hasher.out ==> out;
// }

// Hash using MiMC7.
template HashLR() {
    signal input L;
    signal input R;
    signal output out;

    // Define a MiMC7 hash circuit with 2 inputs and 91 rounds
    component hasher = MultiMiMC7(2, 91);
    hasher.in[0] <== L;
    hasher.in[1] <== R;
    // Give hasher a fixed key of 1.
    hasher.k <== 1;
    out <== hasher.out;
}

template HashSingle() {
    signal input single;
    signal output out;

    // Define a MiMC7 hash circuit with 2 inputs and 91 rounds
    component hasher = MiMC7(91);
    hasher.x_in <== single;
    // Give hasher a fixed key of 1.
    hasher.k <== 1;
    out <== hasher.out;
}

template VedaMerkleProof(LEVELS) {
    
    // Public signals
    signal input leafInTwo[2];
    signal input secretLeafHash; // Used to constrain leafInTwo to NOT be the secret leaf.
    signal input rootWithSecret;

    // Private signals
    signal input pathElements[LEVELS];
    signal input pathIndices[LEVELS];

    // Internal signals.
    signal leaf;

    component hashers[LEVELS + 1];
    component switchers[LEVELS];
    component secretCheckHasher = HashSingle();
    component eqs = IsEqual();

    // Hash leafInTwo to leaf.
    hashers[0] = HashLR();
    hashers[0].L <== leafInTwo[0];
    hashers[0].R <== leafInTwo[1];

    leaf <== hashers[0].out;

    // Constrain leaf to not be the secret leaf.
    secretCheckHasher.single <== leaf;
    eqs.in[0] <== secretCheckHasher.out;
    eqs.in[1] <== secretLeafHash;
    // Constrain leaf to not equal secret leaf.
    eqs.out === 0;

    for (var i=0; i<LEVELS; i++) {
        // Setup switchers.
        switchers[i] = Switcher();
        switchers[i].L <== hashers[i].out;
        switchers[i].R <== pathElements[i];
        switchers[i].sel <== pathIndices[i];

        // Setup hashers.
        hashers[i+1] = HashLR();
        hashers[i+1].L <== switchers[i].outL;
        hashers[i+1].R <== switchers[i].outR;
    }

    // Check that the root is correct.
    rootWithSecret === hashers[LEVELS].out;
}

component main {public [leafInTwo, secretLeafHash, rootWithSecret]} = VedaMerkleProof(2);