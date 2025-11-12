# iDar-CryptoLib Functions Wiki

## Introduction

This wiki explains the functions available in iDar-CryptoLib, a cryptographic library designed to handle sensitive information **ONLY IN COMPUTER CRAFT** (unless you want to get hacked lol).

## Algorithms

## AES

### aes.cbc_encrypt(message, secret, iv)

Encrypts a message using the AES-128-CBC (Cipher Block Chaining) mode.

- **Parameters:**
  - `message`: The message to encrypt (`string`)
  - `secret`: The symmetric key (`string`). This will be hashed with SHA-256, and the **full 32-byte binary hash** will be used as the AES-256 key.
  - `iv?`: Optional Initialization Vector (`string`, length: 16 bytes).
- **Returns:**
  - `encryptedMessage`: The encrypted message with the IV prepended (`string`)

#### Implementation Details:

- Uses automatic PKCS#7 padding.
- Derives a **32-byte (AES-256)** key from the secret using the full SHA-256 binary hash.
- If a valid IV is not provided, one is generated using `math.random()`. **Warning:** This IV is cryptographically weak.
- Output format: `IV (16 bytes) + encrypted data`

#### Example:

```lua
local encrypted = aes.cbc_encrypt("Hello world", "superduperultrasecretkey123")
print(encrypted) -- The first 16 bytes are the IV, the rest is ciphertext

-- With custom IV
local iv = "1234567890123456" -- Must be exactly 16 bytes
local encrypted2 = aes.cbc_encrypt("Hello world", "superduperultrasecretkey123", iv)
```

### aes.cbc_decrypt(message, secret)

Decrypts a message previously encrypted with `aes.cbc_encrypt`.

- **Parameters:**
  - `message`: The encrypted message (must include the 16-byte IV at the start).
  - `secret`: The symmetric key used for encryption.
- **Returns:**
  - `decryptedMessage`: The original message (`string`)

#### Example:

```lua
local encrypted = aes.cbc_encrypt("Hello world", "superduperultrasecretkey123")
print(encrypted)

local decrypted = aes.cbc_decrypt(encrypted, "superduperultrasecretkey123")
print(decrypted) -- Output: Hello world
```

### aes.generate_iv()

Generate a Initialization Vector for `AES-CBC`

- **Parameters:**
  - `none`
- **Returns:**
  - `iv`: A random 16 bytes value

#### Example:

```lua
local aes = require("idar-cl.aes")

-- AES-CBC encryption/decryption example
local key = "676767"
local data = "Sensitive information"
local iv = aes.generate_iv() -- 16 random bytes
local encrypted = aes.cbc_encrypt(data, key, iv)
local decrypted = aes.cbc_decrypt(encrypted, key)

print(decrypted) -- Output: Sensitive information
```

## ChaCha20

### chacha.generateNonce()

Generates a cryptographically secure 12-byte (96-bit) nonce for ChaCha20 encryption.

- **Params:** None
- **Returns:**
  - `nonce`: A unique 12-byte nonce (type: `string`)

#### Implementation Details:

- Uses Lua's `math.random()` to generate random bytes
- Each byte ranges from 0-255
- Result is exactly 12 bytes long

#### Example:

```lua
local nonce = chacha.generateNonce()
print(#nonce) -- 12
```

### chacha.encrypt(message, secret, nonce)

Encrypts a message using the ChaCha20 stream cipher.

- **Params:**
  - `message`: The message to encrypt (type: `string`)
  - `secret`: The symmetric key (type: `string`). Will be hashed with SHA-256
  - `nonce`: A unique 12-byte nonce (type: `string`)
- **Returns:**
  - `encryptedMessage`: The encrypted message (type: `string`)

#### Implementation Details:

- Derives encryption key using SHA-256 of the secret
- Uses 20 rounds of ChaCha20 algorithm
- Automatically applies PKCS#7-style padding to 64-byte blocks
- Processes blocks in parallel using `parallel.waitForAll()`
- Each block uses a 64-byte counter (position) combined with nonce

#### Example:

```lua
local nonce = chacha.generateNonce()
local encrypted = chacha.encrypt("Hello world", "superduperultrasecretkey123", nonce)
print(#encrypted) -- Length will be padded to multiple of 64 bytes
```

### chacha.decrypt(encryptedMessage, secret, nonce)

Decrypts a message that was encrypted using ChaCha20.

- **Params:**
  - `encryptedMessage`: The encrypted message (type: `string`)
  - `secret`: The symmetric key (type: `string`). Must be the same as used for encryption
  - `nonce`: The same 12-byte nonce used for encryption (type: `string`)
- **Returns:**
  - `decryptedMessage`: The original message (type: `string`)

#### Implementation Details:

- Uses the same operation as encryption (XOR with keystream)
- Automatically removes padding after decryption
- **Crucial:** The nonce must be identical to the one used for encryption

#### Example:

```lua
local decrypted = chacha.decrypt(encrypted, "superduperultrasecretkey123", nonce)
print(decrypted) -- "Hello world"
```

## RSA

### rsa.generateKeys(bits)

Generates RSA asymmetric key pairs using parallel prime generation and Chinese Remainder Theorem (CRT) for optimization.

- **Params:**
  - `bits`: The bit length for prime generation (type: `number`)
- **Returns:**
  - `publicKey`: Table containing public exponent `e` and modulus `n` (type: `table`)
  - `privateKey`: Table containing private key components for CRT optimization (type: `table`)

#### Implementation Details:

- Uses parallel generation of two primes `p` and `q` using `parallel.waitForAll()`
- Implements Miller-Rabin primality test with bases {2, 3, 5, 7, 11}
- Pre-computes small primes up to 2000 for efficient sieving
- Uses public exponent `e = 65537` by default
- Implements CRT parameters for faster decryption: `dP, dQ, qInv`

#### Key Structure:

```lua
-- Public Key: {e, n}
-- Private Key: {d, n, p, q, dP, dQ, qInv}
```

#### Example:

```lua
local publicKey, privateKey = rsa.generateKeys(32)
print(publicKey[1])  -- e (public exponent)
print(publicKey[2])  -- n (modulus)
print(privateKey[1]) -- d (private exponent)
```

### rsa.encrypt(message, publicKey)

Encrypts a message using RSA public key encryption.

- **Params:**
  - `message`: The message to encrypt (type: `number`, `string`, or `bignum`)
  - `publicKey`: The public key table `{e, n}` (type: `table`)
- **Returns:**
  - `encryptedMessage`: The encrypted message as bignum (type: `bignum`)

#### Implementation Details:

- Automatically converts strings to bignum using byte representation
- Validates that message is within range `[0, n]`
- Uses modular exponentiation: `message^e mod n`

#### Example:

```lua
-- Encrypt a number
local encrypted = rsa.encrypt(2025, publicKey)
print(encrypted:toString())

-- Encrypt a string (converted to bytes)
local encryptedText = rsa.encrypt("Hello", publicKey)
```

### rsa.decrypt(encryptedMessage, privateKey)

Decrypts a message using RSA private key with CRT optimization.

- **Params:**
  - `encryptedMessage`: The encrypted message (type: `bignum` or `string`)
  - `privateKey`: The private key table with CRT parameters (type: `table`)
- **Returns:**
  - `decryptedMessage`: The original message as string (type: `string`)

#### Implementation Details:

- Uses Chinese Remainder Theorem for faster decryption:
  - `m1 = c^dP mod p`
  - `m2 = c^dQ mod q`
  - `h = qInv × (m1 - m2) mod p`
  - `m = m2 + h × q`
- Falls back to standard decryption if CRT parameters are missing
- Automatically converts bignum result back to string

#### Example:

```lua
local decrypted = rsa.decrypt(encrypted, privateKey)
print(decrypted) -- Original message
```

## SHA-256

The SHA-256 module provides secure hashing and Message Authentication Code (HMAC) functionality.

### sha.sha256(message)

Computes the SHA-256 hash of a given message.

- **Parameters:**
  - `message`: The message to hash (`string`)
- **Returns:**
  - `hexDigest`: The hash in hexadecimal format (64 characters)
  - `binDigest`: The hash in binary format (32 bytes)

#### Example:

```lua
local hex, bin = sha.sha256("Hello world")
print("Hex:", hex) -- Output: b94d27b9934d3e08a52e52d7da7debac...
print("Bin Length:", #bin) -- Output: 32
```

### sha.hmac_sha256(key, message)

Computes the Hash-based Message Authentication Code (HMAC) using SHA-256.

- **Parameters:**
  - `key`: The secret key for the HMAC (`string`)
  - `message`: The message to authenticate (`string`)
- **Returns:**
  - `hmacDigest`: The HMAC digest in hexadecimal format.

#### Example:

```lua
local hmac = sha.hmac_sha256("secretkey", "data to authenticate")
print("HMAC:", hmac)
```

## secp256k1 (ECC)

Full implementation of the **secp256k1** elliptic curve with Key Exchange (ECDH) and Digital Signature (ECDSA).

### ecc.generatePrivateKey()

Generates a valid random private key for the curve.

- **Returns:**
  - `privateKey`: A `bignum` representing the private key.

### ecc.getPublicKey(privKey)

Calculates the public key point from the private key.

- **Parameters:**
  - `privKey`: The private key (`bignum`)
- **Returns:**
  - `publicKey`: A table with affine coordinates `{x = bignum, y = bignum}`.

### ecc.getSharedSecret(myPrivKey, theirPubKey)

Performs Elliptic Curve Diffie-Hellman (ECDH) to compute a symmetric shared secret.

- **Parameters:**
  - `myPrivKey`: Your private key (`bignum`)
  - `theirPubKey`: The other participant's public key (`{x, y}` table of `bignum`)
- **Returns:**
  - `sharedSecret`: A `bignum` (X-coordinate of the resulting point) which is the shared secret.

### ecc.sign(privKey, message)

Generates an ECDSA digital signature for a message. Uses **RFC 6979** deterministic nonce generation (HMAC-SHA256).

- **Parameters:**
  - `privKey`: The signer's private key (`bignum`)
  - `message`: The message to be signed (`string`)
- **Returns:**
  - `signature`: A table `{r = bignum, s = bignum}`.

### ecc.verify(pubKey, message, signature)

Verifies an ECDSA digital signature against a message and a public key.

- **Parameters:**
  - `pubKey`: The signer's public key (`{x, y}` table of `bignum`)
  - `message`: The original message that was signed (`string`)
  - `signature`: The `{r, s}` signature generated previously.
- **Returns:**
  - `verificationResult`: A table with `{result = boolean, message = string}`.

#### Example of ECDSA and ECDH:

```lua
local ecc = require("idar-cl.secp256k1")
local message = "The shared secret is vital."
local sleep_time = 5 -- Use a short sleep time for the example

-- 1. ECDH Demo
local privA = ecc.generatePrivateKey()
local pubA = ecc.getPublicKey(privA)
local privB = ecc.generatePrivateKey()
local pubB = ecc.getPublicKey(privB)

local secretA = ecc.getSharedSecret(privA, pubB)
local secretB = ecc.getSharedSecret(privB, pubA)

print("ECDH Secret Match:", secretA:toString() == secretB:toString())
-- Output: ECDH Secret Match: true

-- 2. ECDSA Demo
os.sleep(sleep_time) -- Yielding is necessary for CPU-intensive ops

local signature = ecc.sign(privA, message)
print("Signature R:", signature.r:toString():sub(1, 20) .. "...")

os.sleep(sleep_time) -- Yielding is necessary for CPU-intensive ops

local verification = ecc.verify(pubA, message, signature)
print("ECDSA Verification Succeeded:", verification.result)
-- Output: ECDSA Verification Succeeded: true
```

## Additional Notes

- **AES Key Length:** The `aes.cbc_encrypt` function now uses the full **32 bytes** (256 bits) of the SHA-256 hash as the key, ensuring true **AES-256** strength.
- **SHA-256 Return:** The `sha.sha256` function now returns both the **hexadecimal** and **binary** digests for greater flexibility.
- I know RSA totally supports huge keys (1024+), but we're talking ComputerCraft here, fam. I seriously recommend not tryna generate keys bigger than 128 bits. Is that insecure? Duh, but I can't work miracles either, lol.
- **secp256k1 Performance:** Elliptic Curve operations, while generally faster than RSA in standard environments, are still computationally intensive in Lua/CC:T. Please be patient with key generation and signature operations.
- **IV Generation:** If the IV is not provided to AES, a default IV is generated using `math.random()`. **This is not cryptographically secure.**

## Security Considerations

- This library is designed for educational purposes and ComputerCraft environments.
- For production security in real world, consider using established cryptographic libraries.
- Never reuse IVs/nonces with the same encryption key.
- The quality of randomness depends on `math.random()` - use better entropy sources for critical applications.
