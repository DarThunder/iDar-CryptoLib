# iDar-CryptoLib

iDar-CryptoLib is a comprehensive cryptography library that implements powerful and reliable algorithms (RSA, AES, ChaCha20, SHA-256, secp256k1) optimized for ComputerCraft: Tweaked. Whether you're protecting sensitive data, creating secure communication channels, or exploring cryptographic concepts, iDar-CryptoLib provides the tools you need.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [AES](#aes)
  - [ChaCha20](#chacha20)
  - [RSA](#rsa)
  - [SHA-256](#sha-256)
  - [secp256k1](#secp256k1)
- [Security Notes](#security-notes)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

## Features

- **AES-128-CBC**: Secure block cipher encryption with automatic padding
- **ChaCha20**: Modern stream cipher with parallel processing
- **RSA**: Asymmetric encryption with CRT optimization
- **SHA-256**: Cryptographic hashing algorithm
- **secp256k1**: Elliptic curve cryptography (ECDH key exchange & ECDSA)
- Lightweight and optimized for ComputerCraft: Tweaked
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

### AES

```lua
local aes = require("iDar.CryptoLib.src.aes")

-- AES-CBC encryption/decryption example
local key = "676767" -- don't matter the size of the key, it will be derived anyway lol
local data = "Sensitive information"
local iv = aes.generate_iv() -- 16 random bytes
local encrypted = aes.cbc_encrypt(data, key, iv)
local decrypted = aes.cbc_decrypt(encrypted, key)

print(decrypted) -- Output: Sensitive information
```

### ChaCha20

```lua
local chacha = require("iDar.CryptoLib.src.chacha20")

-- Generate nonce and encrypt
local nonce = chacha.generateNonce()
local key = "supersecretkey"
local encrypted = chacha.encrypt("Hello world", key, nonce)
local decrypted = chacha.decrypt(encrypted, key, nonce)

print(decrypted) -- Output: Hello world
```

### RSA

```lua
local rsa = require("iDar.CryptoLib.src.rsa")

-- Generate RSA keys (recommended: 32-128 bits for performance)
local publicKey, privateKey = rsa.generateKeys(64)

-- Encrypt and decrypt
local encrypted = rsa.encrypt("Secret message", publicKey)
local decrypted = rsa.decrypt(encrypted, privateKey)

print(decrypted) -- Output: Secret message
```

### SHA-256

```lua
local sha = require("iDar.CryptoLib.src.sha")

-- Hash a string
local message = "Hello, world!"
local hash_hex, hash_bin = sha.sha256(message)
print(hash_hex) -- Output: 315f5bdb76d078c43b8ac0064e4a0164612b1fce77c869345bfc94c75894edd3
print(hash_bin) -- Output: (binary data)

local secret = "mango"
local hmac_digest = sha.hmac_sha256(secret, message)

print("Message:", message) -- Output: Hello, world!
print("HMAC:", hmac_digest) -- Output: 1534f334fbe2c72667f632c7f77e1b8b627375dc9502b49f040d80794b2a67ab

local hmac_digest_bin = sha.hmac_sha256(secret, message, true)
print("HMAC BIN:", hmac_digest_bin) -- Output: (binary data)
```

### secp256k1

```lua
local ecc = require("iDar.CryptoLib.src.secp256k1")

-- Key exchange example
local privA = ecc.generatePrivateKey()
local pubA = ecc.getPublicKey(privA)

local privB = ecc.generatePrivateKey()
local pubB = ecc.getPublicKey(privB)

-- Both parties compute the same shared secret
local secretA = ecc.getSharedSecret(privA, pubB)
local secretB = ecc.getSharedSecret(privB, pubA)

print(secretA == secretB) -- Output: true
local message = "tung tung tung sahur ta ta ta sahur"
os.sleep(10) -- a very neccessary sleep if you don't want to burn your cpu lol

-- sign example
local sign = ecc.sign(privA, message)
print("R = " .. sign.r) -- R
print("S = " .. sign.s) -- S
os.sleep(10) -- another small pause to keep the CPU cool :)

-- verify example
local verify = ecc.verify(pubA, message, sign)
print("Result: ", verify.result, "\nMessage: ", verify.message) --Output true, Signature verification result
```

## Security Notes

**Important Security Considerations:**

- This library is designed for **educational purposes** and **ComputerCraft environments**
- For real-world security, use established cryptographic libraries
- **RSA key sizes are limited** due to ComputerCraft performance constraints
- **Never reuse IVs/nonces** with the same encryption key
- The randomness quality depends on `math.random()` - not suitable for high-security applications

## FAQ

**Q: What happens if I lose my private key?**  
A: Unfortunately, if you lose your private key, you won't be able to decrypt any data encrypted with the corresponding public key. Always back up your keys securely.

**Q: Can I use this with other mods?**  
A: Yes, as long as the other mods are compatible with ComputerCraft and Lua, iDar-CryptoLib should work seamlessly.

**Q: Why are RSA key sizes limited?**  
A: ComputerCraft has performance limitations. Generating large RSA keys (1024+ bits) would be extremely slow. We recommend 32-128 bits for practical use.

**Q: Is this library cryptographically secure?**  
A: While the algorithms are correctly implemented, the execution environment (ComputerCraft) and randomness sources may not provide enterprise-level security. (It's a library on pure Lua for a Minecraft mod for God's sake)

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a new branch for your feature or fix
3. Submit a pull request with a clear description
4. Ensure your code follows the existing style and includes proper documentation

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

```
Key changes made:
- Added all modules (AES, ChaCha20, RSA, SHA-256, secp256k1)
- Updated usage examples with correct function names and parameters
- Added security notes section with important warnings
- Expanded FAQ with practical questions
- Improved installation instructions
- Added proper module require paths
- Included performance considerations for RSA
- Made the tone consistent and professional while maintaining accessibility
```
