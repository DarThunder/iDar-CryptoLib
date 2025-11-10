# iDar-CryptoLib Functions Wiki

## Introduction

This wiki explains the functions available in iDar-CryptoLib, a cryptographic library designed for handling sensitive information **IN COMPUTERCRAFT ONLY** (at least you wanna get hacked).

## Algorithms

## AES

### aes.cbc_encrypt(message, secret, iv)

Encrypts a message using AES-128-CBC (Cipher Block Chaining) mode.

- **Params:**
  - `message`: The message to encrypt (type: `string`)
  - `secret`: The symmetric key (type: `string`). Will be hashed with SHA-256 and truncated to 16 bytes
  - `iv?`: Optional initialization vector (type: `string`, length: 16 bytes). If not provided or invalid, a random IV will be generated
- **Returns:**
  - `encryptedMessage`: The encrypted message with IV prepended (type: `string`)

#### Implementation Details:

- Uses PKCS#7 padding automatically
- Derives a 16-byte key from the secret using SHA-256 (bytes 17-32 of the hash)
- Generates random IV if not provided
- Output format: `IV (16 bytes) + encrypted data`

#### Example:

```lua
local encrypted = aes.cbc_encrypt("Hello world", "superduperultrasecretkey123")
print(encrypted) -- First 16 bytes are IV, rest is encrypted data

-- With custom IV
local iv = "1234567890123456" -- Must be exactly 16 bytes
local encrypted2 = aes.cbc_encrypt("Hello world", "superduperultrasecretkey123", iv)
```

### aes.cbc_decrypt(encryptedMessage, secret)

Decrypts a message that was encrypted using AES-128-CBC mode.

- **Params:**
  - `encryptedMessage`: The encrypted message with IV prepended (type: `string`)
  - `secret`: The symmetric key (type: `string`). Must be the same key used for encryption
- **Returns:**
  - `decryptedMessage`: The original message (type: `string`)

#### Implementation Details:

- Expects input format: `IV (16 bytes) + encrypted data`
- Automatically removes PKCS#7 padding
- Uses the same key derivation as encryption (SHA-256 bytes 17-32)

#### Example:

```lua
local decrypted = aes.cbc_decrypt(encrypted, "superduperultrasecretkey123")
print(decrypted) -- "Hello world"
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

## SHA

### sha.sha256(prompt)

Generates a SHA-256 hash from the provided input.

- **Params:**
  - `prompt`: The text to generate the hash (type: `string`).
- **Returns:**
  - `hash`: The resulting SHA-256 hash (type: `string`).

#### Example:

```lua
local hash = sha.sha256("Hello world")
print(hash) -- c8e284fe0b97a4bba8f65390ae0feb30d738c6d5bded85325b3bb1d70810a74
```

## secp256k1

The `secp256k1` module implements Elliptic Curve Cryptography (ECC) based on the secp256k1 curve, which is the standard used for secure key exchange and digital signatures in many modern applications like Bitcoin.

### ecc.generatePrivateKey()

Generates a valid, random private key for the secp256k1 curve.

- **Params:** None
- **Returns:**
  - `privateKey`: The private key (type: `bignum`)

#### Implementation Details:

- Generates 32 random bytes using `math.random()`
- Ensures the key is in the range `[1, N-1]` where N is the curve order
- **N** = `115792089237316195423570985008687907852837564279074904382605163141518161494337`

#### Example:

```lua
local ecc = require("idar-cl.secp256k1")
local privateKey = ecc.generatePrivateKey()
print(privateKey:toString()) -- a large integer (bignum)
```

### ecc.getPublicKey(privateKey)

Calculates the corresponding public key point (x, y) on the curve from a given private key.

- **Params:**
  - `privateKey`: The private key (type: `bignum`)
- **Returns:**
  - `publicKey`: A table containing the public key coordinates (type: `table` with `x` and `y` bignums)

#### Implementation Details:

- Performs scalar multiplication: `publicKey = privateKey × G`
- Where **G** is the generator point of the curve:
  - `x = 55066263022277343669578718895168534326250603453777594175500187360389116729240`
  - `y = 32670510020758816978083085130507043184471273380659243275938904335757337482424`
- Uses "double-and-add" algorithm for efficiency

#### Example:

```lua
local publicKey = ecc.getPublicKey(privateKey)
print(publicKey.x:toString()) -- x-coordinate of the public point
print(publicKey.y:toString()) -- y-coordinate of the public point
```

### ecc.getSharedSecret(myPrivKey, theirPubKey)

Performs the Elliptic Curve Diffie-Hellman (ECDH) key exchange to calculate a shared symmetric secret.

- **Params:**
  - `myPrivKey`: Your private key (type: `bignum`)
  - `theirPubKey`: The other party's public key (type: `table` with `x` and `y` bignums)
- **Returns:**
  - `sharedSecret`: The X-coordinate of the shared point (type: `bignum`)

#### Implementation Details:

- Calculates: `sharedPoint = myPrivKey × theirPubKey`
- Returns the x-coordinate of the resulting point as shared secret
- Both parties will get the same secret if: `myPrivKey × theirPubKey = theirPrivKey × myPubKey`

#### Example:

```lua
-- Alice generates her key pair
local privA = ecc.generatePrivateKey()
local pubA = ecc.getPublicKey(privA)

-- Bob generates his key pair
local privB = ecc.generatePrivateKey()
local pubB = ecc.getPublicKey(privB)

-- Both calculate the same shared secret
local secretA = ecc.getSharedSecret(privA, pubB)
local secretB = ecc.getSharedSecret(privB, pubA)

print(secretA:toString() == secretB:toString()) -- true
```

## SHA

### sha.sha256(message)

Generates a SHA-256 cryptographic hash from the provided input string.

- **Params:**
  - `message`: The input text to hash (type: `string`)
- **Returns:**
  - `hash`: The resulting SHA-256 hash as a hexadecimal string (type: `string`)

#### Implementation Details:

- Implements the full SHA-256 algorithm according to FIPS 180-4 standard (not really, but, works lmao)
- Uses 64 rounds of compression with pre-defined constants
- Applies proper padding with length encoding
- Processes 512-bit (64-byte) chunks
- Returns a fixed 64-character hexadecimal string (256 bits)

#### Technical Features:

- **Initial Hash Values:** Standard SHA-256 constants (H[0]-H[7])
- **Round Constants:** 64 pre-defined K values
- **Bit Operations:** Uses right rotation and logical functions
- **Message Schedule:** Expands 16 words to 64 words per chunk
- **Padding:** Appends '80' + zeros + message length in bits

#### Example:

```lua
local hash = sha.sha256("Hello world")
print(hash) -- "64ec88ca00b268e5ba1a35678a1b5316d212f4f366b2477232534a8aeca37f3c"

local hash2 = sha.sha256("")
print(hash2) -- "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
```

#### Algorithm Steps:

1. **Pre-processing:** Pad message to multiple of 512 bits
2. **Message Schedule:** Expand input to 64 words
3. **Compression:** 64 rounds of mixing with constants
4. **Finalization:** Combine intermediate hash values

The implementation produces standards-compliant SHA-256 hashes suitable for cryptographic verification and data integrity checks.

## Additional Notes

- Ensure that the key used for AES encryption is of the correct length (16 bytes for AES-128) or not, it is still truncated to 16 bytes. lol
- SHA-256 generates a fixed-length hash of 32 characters.
- I know RSA totally supports huge keys (1024+), but we're talking ComputerCraft here, fam. I seriously recommend not tryna generate keys bigger than 128 bits. Is that insecure? Duh, but I can't work miracles either, lol.
- Okay, so like, everyone knows secp256k1 is supposed to be way faster than RSA for key generation, and yeah, it totally is... if this was an actual computer, lmao. So, you gotta chill. I seriously recommend being patient, using RSA keys of 32 bits, or just using SHA256 as a janky HMAC (tbh).

## Security Considerations

- This library is designed for educational purposes and ComputerCraft environments
- For production security, consider using established cryptographic libraries
- Never reuse IVs/nonces with the same encryption key
- The quality of randomness depends on `math.random()` - use better entropy sources for critical applications
