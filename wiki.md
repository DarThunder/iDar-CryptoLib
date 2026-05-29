# iDar-CryptoLib Functions Wiki

## Introduction

This wiki explains the functions available in iDar-CryptoLib, a cryptographic library designed to handle sensitive information **ONLY IN COMPUTER CRAFT** (unless you want to get hacked lol).

## Algorithms

## Encoding

Utility module for encoding, decoding, and key derivation. Used internally by other modules, but fully available for your own use.

### encoding.toHex(data)

Converts binary data to a hexadecimal string.

- **Parameters:**
  - `data`: Binary string to convert (`string`)
- **Returns:**
  - `hex`: Lowercase hexadecimal representation (`string`)

#### Example:

```lua
local encoding = require("Crypto.encoding")

local hex = encoding.toHex("Hi")
print(hex) -- Output: 4869
```

---

### encoding.fromHex(hex)

Converts a hexadecimal string back to binary data.

- **Parameters:**
  - `hex`: Hexadecimal string — must have even length (`string`)
- **Returns:**
  - `data`: Binary string (`string`)
  - `err`: Error message if the hex length is invalid (`string`, or `nil`)

#### Example:

```lua
local data = encoding.fromHex("4869")
print(data) -- Output: Hi
```

---

### encoding.toBase64(data)

Encodes binary data to a Base64 string.

- **Parameters:**
  - `data`: Binary string to encode (`string`)
- **Returns:**
  - `b64`: Base64 encoded string (`string`)

#### Example:

```lua
local b64 = encoding.toBase64("Hello world")
print(b64) -- Output: SGVsbG8gd29ybGQ=
```

---

### encoding.fromBase64(b64)

Decodes a Base64 string back to binary data.

- **Parameters:**
  - `b64`: Base64 encoded string — whitespace is stripped automatically (`string`)
- **Returns:**
  - `data`: Decoded binary string (`string`)
  - `err`: Error message if the input is invalid (`string`, or `nil`)

#### Example:

```lua
local data = encoding.fromBase64("SGVsbG8gd29ybGQ=")
print(data) -- Output: Hello world
```

---

### encoding.pbkdf2(password, salt, dklen)

Derives a cryptographic key from a password using PBKDF2-HMAC-SHA256.

- **Parameters:**
  - `password`: The password to derive from (`string`)
  - `salt`: A unique salt value (`string`)
  - `dklen?`: Desired key length in bytes (`number`, default: `32`)
- **Returns:**
  - `derivedKey`: The derived key as a binary string (`string`)

#### Implementation Details:

- Uses HMAC-SHA256 as the pseudorandom function
- Runs **10,000 iterations** — intentionally slow to resist brute-force attacks
- Default output is 32 bytes (256 bits)

#### Example:

```lua
local key = encoding.pbkdf2("my password", "random salt", 32)
print(#key) -- Output: 32
```

---

### encoding.hkdf(ikm, salt, info, len)

Derives a key using HKDF (HMAC-based Key Derivation Function) with SHA-256.

- **Parameters:**
  - `ikm`: Input keying material (`string`)
  - `salt?`: Optional salt — defaults to 32 zero bytes if not provided (`string`)
  - `info`: Context and application-specific information (`string`)
  - `len`: Length of the output key in bytes (`number`)
- **Returns:**
  - `okm`: Output keying material as a binary string (`string`)

#### Implementation Details:

- Implements RFC 5869 (Extract-and-Expand)
- Suitable for deriving multiple keys from a single shared secret (e.g. after ECDH)
- Faster than PBKDF2 — not designed for password hashing

#### Example:

```lua
local shared_secret = ecc.getSharedSecret(privA, pubB)
local key = encoding.hkdf(shared_secret:toBytes(), nil, "encryption key", 32)
print(#key) -- Output: 32
```

---

## ChaCha20

ChaCha20-Poly1305 is an **authenticated encryption** cipher (AEAD). Every encryption produces both a ciphertext and a 16-byte authentication tag. Decryption will fail if the message or tag has been tampered with.

### chacha.generateNonce()

Generates a cryptographically secure 12-byte (96-bit) nonce for ChaCha20 encryption.

- **Parameters:** None
- **Returns:**
  - `nonce`: A unique 12-byte nonce (`string`)

#### Implementation Details:

- Reads from `/dev/random` via the `sys` API
- Result is exactly 12 bytes long

#### Example:

```lua
local nonce = chacha.generateNonce()
print(#nonce) -- Output: 12
```

---

### chacha.aead_encrypt(message, secret, nonce, aad)

Encrypts a message and produces an authentication tag using ChaCha20-Poly1305.

- **Parameters:**
  - `message`: The message to encrypt (`string`)
  - `secret`: The symmetric key (`string`) — derived internally using PBKDF2
  - `nonce`: A unique 12-byte nonce (`string`)
  - `aad?`: Optional additional authenticated data — authenticated but not encrypted (`string`)
- **Returns:**
  - `ciphertext`: The encrypted message (`string`)
  - `tag`: 16-byte Poly1305 authentication tag (`string`)

#### Implementation Details:

- Key is derived from `secret` using PBKDF2-HMAC-SHA256 with the nonce as salt
- Poly1305 key is generated from the first ChaCha20 block (counter = 0)
- Message encryption starts at counter = 1
- AAD and ciphertext lengths are included in the MAC input per the AEAD spec

#### Example:

```lua
local chacha = require("Crypto.chacha20")

local key = "supersecretkey"
local nonce = chacha.generateNonce()

local ciphertext, tag = chacha.aead_encrypt("Hello world", key, nonce)

-- With optional AAD
local ciphertext2, tag2 = chacha.aead_encrypt("Hello world", key, nonce, "extra context")
```

> **Never reuse the same nonce with the same key.** Always generate a fresh nonce per message.

---

### chacha.aead_decrypt(ciphertext, secret, nonce, tag, aad)

Decrypts a message and verifies its authentication tag using ChaCha20-Poly1305.

- **Parameters:**
  - `ciphertext`: The encrypted message (`string`)
  - `secret`: The symmetric key used for encryption (`string`)
  - `nonce`: The same 12-byte nonce used during encryption (`string`)
  - `tag`: The 16-byte authentication tag returned by `aead_encrypt` (`string`)
  - `aad?`: The same additional authenticated data used during encryption, if any (`string`)
- **Returns:**
  - `message`: The decrypted message (`string`), or `nil` if verification fails
  - `err`: Error message if the tag doesn't match (`string`, or `nil`)

#### Implementation Details:

- Recomputes the Poly1305 tag before decrypting
- If the computed tag doesn't match, returns `nil` and an error — **the ciphertext is never decrypted if integrity fails**

#### Example:

```lua
local decrypted, err = chacha.aead_decrypt(ciphertext, key, nonce, tag)

if decrypted then
    print(decrypted) -- Output: Hello world
else
    print("Decryption failed: " .. err)
end

-- With AAD
local decrypted2 = chacha.aead_decrypt(ciphertext2, key, nonce, tag2, "extra context")
```

---

## SHA-256

The SHA-256 module provides secure hashing and Message Authentication Code (HMAC) functionality.

### sha.sha256(message)

Computes the SHA-256 hash of a given message.

- **Parameters:**
  - `message`: The message to hash (`string`)
- **Returns:**
  - `hexDigest`: The hash in hexadecimal format (64 characters) (`string`)
  - `binDigest`: The hash in binary format (32 bytes) (`string`)

#### Example:

```lua
local sha = require("Crypto.sha")

local hex, bin = sha.sha256("Hello world")
print("Hex:", hex)
print("Bin length:", #bin) -- Output: 32
```

---

### sha.hmac_sha256(key, message, bin)

Computes the HMAC-SHA256 of a message using a secret key.

- **Parameters:**
  - `key`: The secret key (`string`)
  - `message`: The message to authenticate (`string`)
  - `bin?`: If `true`, returns binary output instead of hex (`boolean`, default: `false`)
- **Returns:**
  - `hmacDigest`: The HMAC digest — hex string by default, binary if `bin` is `true` (`string`)

#### Example:

```lua
local hmac_hex = sha.hmac_sha256("secretkey", "data to authenticate")
print("HMAC:", hmac_hex)

-- Binary output (useful as input to other crypto functions)
local hmac_bin = sha.hmac_sha256("secretkey", "data to authenticate", true)
print("HMAC bin length:", #hmac_bin) -- Output: 32
```

---

## secp256k1 (ECC)

Full implementation of the **secp256k1** elliptic curve with Key Exchange (ECDH) and Digital Signature (ECDSA).

### ecc.generatePrivateKey()

Generates a valid random private key for the curve.

- **Parameters:** None
- **Returns:**
  - `privateKey`: A `bignum` in the range `[1, N-1]` where N is the curve order

#### Implementation Details:

- Reads random bytes from `/dev/random` via the `sys` API
- Result is guaranteed to be a valid scalar for secp256k1

---

### ecc.getPublicKey(privKey)

Calculates the public key point from a private key.

- **Parameters:**
  - `privKey`: The private key (`bignum`)
- **Returns:**
  - `publicKey`: Affine point `{x = bignum, y = bignum}` on the curve

---

### ecc.getSharedSecret(myPrivKey, theirPubKey)

Performs ECDH to compute a shared secret between two parties.

- **Parameters:**
  - `myPrivKey`: Your private key (`bignum`)
  - `theirPubKey`: The other party's public key (`{x, y}` table of `bignum`)
- **Returns:**
  - `sharedSecret`: The X-coordinate of the resulting point (`bignum`), or `nil` if the public key is invalid

#### Implementation Details:

- Validates that `theirPubKey` lies on the curve before computing
- The shared secret is the X-coordinate of `myPrivKey × theirPubKey`

---

### ecc.sign(privKey, message)

Generates a deterministic ECDSA signature for a message.

- **Parameters:**
  - `privKey`: The signer's private key (`bignum`)
  - `message`: The message to sign (`string`)
- **Returns:**
  - `signature`: A table `{r = bignum, s = bignum}`

#### Implementation Details:

- Hashes the message with SHA-256 before signing
- Uses **RFC 6979** deterministic nonce generation via HMAC-SHA256 — no randomness needed
- `s` is always normalized to the lower half of N to prevent signature malleability

---

### ecc.verify(pubKey, message, signature)

Verifies an ECDSA signature against a message and public key.

- **Parameters:**
  - `pubKey`: The signer's public key (`{x, y}` table of `bignum`)
  - `message`: The original signed message (`string`)
  - `signature`: The `{r, s}` signature to verify (`table`)
- **Returns:**
  - `result`: A table `{result = boolean, message = string}`

#### Example:

```lua
local ecc = require("Crypto.secp256k1")

-- ECDH
local privA = ecc.generatePrivateKey()
local pubA  = ecc.getPublicKey(privA)
local privB = ecc.generatePrivateKey()
local pubB  = ecc.getPublicKey(privB)

local secretA = ecc.getSharedSecret(privA, pubB)
local secretB = ecc.getSharedSecret(privB, pubA)
print("Shared secret match:", secretA:toString() == secretB:toString()) -- true

-- ECDSA
local message = "The shared secret is vital."

local signature = ecc.sign(privA, message)

local verification = ecc.verify(pubA, message, signature)
print("Valid:", verification.result)   -- Output: true
print("Info:", verification.message)  -- Output: Signature verification result
```

---

## Additional Notes

- **SHA-256 returns two values:** `sha.sha256` returns both hex and binary — use the binary one when passing to other crypto functions.
- **PBKDF2 vs HKDF:** Use `pbkdf2` for password-based key derivation (slow by design). Use `hkdf` to expand an already-strong secret like a shared ECDH result (fast).
- **RSA and AES** are not part of this library anymore. Good riddance.

## Security Considerations

- This library is designed for educational purposes and ComputerCraft environments.
- For production security in the real world, use established cryptographic libraries.
- Never reuse nonces with the same encryption key, especially with ChaCha20.
- Randomness is sourced from `/dev/random` via the `sys` API — quality depends on your ComputerCraft environment.
