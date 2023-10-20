/* Creating a UserVerifier */
import { UserVerifier } from "@multiversx/sdk-wallet";

const aliceVerifier = UserVerifier.fromAddress(addressOfAlice);
const bobVerifier = UserVerifier.fromAddress(addressOfBob);

/* Suppose we have the following transaction */
const tx = Transaction.fromPlainObject({
        nonce: 42,
        value: "12345",
        sender: addressOfAlice.bech32(),
        receiver: addressOfBob.bech32(),
        gasPrice: 1000000000,
        gasLimit: 50000,
        chainID: "D",
        version: 1,
        signature: "3c5eb2d1c9b3ab2f578541e62dcfa5008976d11f85644a48884a8a6c4d2980fa14954ab2924d6e67c051562488096d2e79cd3c0378edf234a52e648e672d1b0a"
});

const serializedTx = tx.serializeForSigning();
const txSignature = tx.getSignature();

/* And / or the following message and signature */
message = new SignableMessage({ message: Buffer.from("hello") });
serializedMessage = message.serializeForSigning();
messageSignature = Buffer.from("561bc58f1dc6b10de208b2d2c22c9a474ea5e8cabb59c3d3ce06bbda21cc46454aa71a85d5a60442bd7784effa2e062fcb8fb421c521f898abf7f5ec165e5d0f", "hex");

/* We can verify their signatures as follows */
console.log("Is signature of Alice?", aliceVerifier.verify(serializedTx, txSignature));
console.log("Is signature of Alice?", aliceVerifier.verify(serializedMessage, messageSignature));
console.log("Is signature of Bob?", bobVerifier.verify(serializedTx, txSignature));
console.log("Is signature of Bob?", bobVerifier.verify(serializedMessage, messageSignature));