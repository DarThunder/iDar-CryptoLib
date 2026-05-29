# iDar-CryptoLib

iDar-CryptoLib is a comprehensive cryptography library that implements powerful and reliable algorithms (RSA, AES, ChaCha20, SHA-256, secp256k1) optimized for ComputerCraft: Tweaked. Whether you're protecting sensitive data, creating secure communication channels, or exploring cryptographic concepts, iDar-CryptoLib provides the tools you need.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [ChaCha20](#chacha20)
  - [SHA-256](#sha-256)
  - [secp256k1](#secp256k1)
- [Security Notes](#security-notes)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

## Features

- **ChaCha20-Poly1305**: Authenticated encryption (AEAD) with integrity verification
- **SHA-256**: Cryptographic hashing algorithm with HMAC support
- **secp256k1**: Elliptic curve cryptography (ECDH key exchange & ECDSA signing)
- Lightweight and optimized for ComputerCraft: Tweaked
- **RSA**: Asymmetric encryption with CRT optimization
- Modular and extensible design

## Requirements

- Minecraft with ComputerCraft: Tweaked mod installed (at least version 1.116.1)
- Minecraft 1.20.1 or above (compatibility with older versions not guaranteed)
- Basic knowledge of Lua programming

## Installation

### Recommended Installation (via [`iDar-Pacman`](https://github.com/DarThunder/iDar-Pacman)):

```lua
pacman -S idar-cryptolib
```

### Manual Installation:

1. Download the library files from the repository
2. Place them in your ComputerCraft computer's directory (e.g directory/)
3. Use `require("directory.module")` to load specific modules

## Usage

### ChaCha20

ChaCha20 uses **authenticated encryption (AEAD)** — encryption and integrity verification happen together. `aead_encrypt` returns both the ciphertext and a tag, and `aead_decrypt` requires the tag to verify the message wasn't tampered with.

```lua
local chacha = require("Crypto.chacha20")

local key = "supersecretkey"
local nonce = chacha.generateNonce() -- 12 random bytes from /dev/random

-- Encrypt: returns ciphertext and authentication tag
local ciphertext, tag = chacha.aead_encrypt("Hello world", key, nonce)

-- Decrypt: tag is required to verify integrity
local decrypted, err = chacha.aead_decrypt(ciphertext, key, nonce, tag)

if decrypted then
    print(decrypted) -- Output: Hello world
else
    print("Decryption failed: " .. err) -- Integrity check failed
end

-- Optional: additional authenticated data (AAD)
local ciphertext2, tag2 = chacha.aead_encrypt("Hello world", key, nonce, "extra context")
local decrypted2 = chacha.aead_decrypt(ciphertext2, key, nonce, tag2, "extra context")
```

> **Never reuse the same nonce with the same key.** Always generate a fresh nonce for each message.

### SHA-256

```lua
local sha = require("Crypto.sha")

-- Hash a string
local message = "Hello, world!"
local hash_hex, hash_bin = sha.sha256(message)
print(hash_hex) -- Output: 315f5bdb76d078c43b8ac0064e4a0164612b1fce77c869345bfc94c75894edd3
print(hash_bin) -- Output: (binary data)

-- HMAC-SHA256
local secret = "mango"
local hmac_hex = sha.hmac_sha256(secret, message)
print("HMAC:", hmac_hex) -- Output: 1534f334fbe2c72667f632c7f77e1b8b627375dc9502b49f040d80794b2a67ab

-- Binary output (for use in other crypto functions)
local hmac_bin = sha.hmac_sha256(secret, message, true)
print("HMAC BIN:", hmac_bin) -- Output: (binary data)
```

### secp256k1

```lua
local ecc = require("Crypto.secp256k1")

-- Key generation
local privA = ecc.generatePrivateKey()
local pubA = ecc.getPublicKey(privA)

local privB = ecc.generatePrivateKey()
local pubB = ecc.getPublicKey(privB)

-- ECDH: both parties compute the same shared secret
local secretA = ecc.getSharedSecret(privA, pubB)
local secretB = ecc.getSharedSecret(privB, pubA)

print(secretA == secretB) -- Output: true

-- ECDSA signing (this is slow — secp256k1 is heavy in pure Lua)
local message = "tung tung tung sahur"
os.sleep(10) -- give your CPU a moment before signing

local signature = ecc.sign(privA, message)
print("R = " .. signature.r)
print("S = " .. signature.s)

os.sleep(10) -- and another one before verifying

-- Verify signature
local result = ecc.verify(pubA, message, signature)
print("Valid:", result.result)   -- Output: true
print("Message:", result.message) -- Output: Signature verification result
```

## Security Notes

**Important Security Considerations:**

- This library is designed for **educational purposes** and **ComputerCraft environments**
- For real-world security, use established cryptographic libraries.
- **Never reuse nonces** with the same encryption key, especially with ChaCha20.
- Randomness is sourced from `/dev/random` via the `sys` API — quality depends on your activity.
- ChaCha20 key derivation currently uses PBKDF2 with the nonce as salt — functional for a beta, but a dedicated salt parameter is planned.

## FAQ

**Q: What happens if I lose my private key?**  
A: If you lose your private key, you won't be able to decrypt any data encrypted with the corresponding public key. Always back up your keys securely.

**Q: Can I use this with other mods?**  
A: Yes, as long as the other mods are compatible with ComputerCraft and Lua, iDar-CryptoLib should work seamlessly.

**Q: Is this library cryptographically secure?**  
A: The algorithms are correctly implemented, but this is a pure Lua library running inside a Minecraft mod — don't use it to protect anything that actually matters in the real world.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a new branch for your feature or fix
3. Submit a pull request with a clear description
4. Ensure your code follows the existing style and includes proper documentation

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
