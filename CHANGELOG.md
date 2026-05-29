# Changelog

## Beta

### v0.1.0

### Added

- AES block cipher implementation.
- SHA-256 hashing algorithm.
- Lightweight and optimized design for ComputerCraft: Tweaked.
- Modular and extensible internal architecture.

---

### v0.1.1

### Fixed

- Corrected minor issues in module loading (`require`) and usage of `bit32` functions.

---

### v0.2.0

### Added

- `ChaCha20` module and algorithm.
- `RSA` module and algorithm. (See Known Issues.)
- New dependency: [`iDar-BigNum`](https://github.com/DarThunder/iDar-BigNum), required for arbitrary-precision arithmetic.

### Fixed

- Corrected AES padding generation. Previously, an extra block was added when the input size was an exact multiple of 16 bytes.

### Improvements

- Internal cryptographic structure adjusted to support algorithms requiring large integer arithmetic.

### Known Issues

- RSA key generation is slow due to computationally expensive big-integer operations (mainly primality testing and modular arithmetic).
  A temporary limit restricts generated keys to a maximum of 32 bits.

### Notes

Work is ongoing to expand the library with elliptic-curve algorithms (targeting Curve25519) and HMAC support.

### v0.3.0

#### Critical Changes & Dependencies

- **Dependency Update: RSA Module:** The RSA module now requires **iDar-BigNum vBeta 2**. This is a mandatory update to incorporate a critical precision fix in the base arithmetic library.

#### New Features

- **Elliptic Curve Cryptography (ECC) `secp256k1`:**
  - Added the new `secp256k1` module, providing full support for the standard used in many cryptographic applications.
  - **Available Functions:**
    - `ecc.generatePrivateKey()`: Generates a valid random private key.
    - `ecc.getPublicKey(privKey)`: Computes the public key point from a private key.
    - `ecc.getSharedSecret(myPrivKey, theirPubKey)`: Implements Elliptic Curve Diffie-Hellman (ECDH) for secure shared secret calculation.

#### Improvements & Compliance

- **AES Module:**
  - **NIST Compliance (FIPS 197):** The AES implementation has been refactored to strictly adhere to the **NIST FIPS 197** standard for the **Mix Columns** transformation and the **Key Schedule** (Round Key generation). This ensures cryptographic correctness and robustness.
- **RSA Module:**
  - The module has been fully adapted to function seamlessly and reliably with the new architecture and corrected logic of the [`iDar-BigNum`](https://github.com/DarThunder/iDar-BigNum) Beta 2 library.

#### Bug Fixes

- **BigNum Core Fix:** Solved a fundamental arithmetic bug in the core [`iDar-BigNum`](https://github.com/DarThunder/iDar-BigNum) library concerning the incorrect propagation of the **borrow** in multi-byte subtraction, which previously led to flawed results in RSA's complex modular operations.
- Minor fixes applied to AES initialization and internal state handling.

### v0.4.0

#### New Features

- **Elliptic Curve Digital Signature Algorithm (ECDSA):**
  - Added full ECDSA support to the `secp256k1` module.
  - New functions available:
    - `ecc.sign(privKey, message)`: Generates a deterministic signature using **RFC 6979** compliant nonce generation (HMAC-SHA256).
    - `ecc.verify(pubKey, message, signature)`: Validates an ECDSA signature against a public key.

- **HMAC Support:**
  - Added the `hmac_sha256(key, message)` function to the `SHA-256` module, implementing the **keyed-hashing for message authentication** standard.

#### Improvements & Compliance

- **SHA-256 Module:**
  - Refactored the core `sha256` function to return both the **hexadecimal** and **binary (raw byte)** digest, improving integration flexibility.

- **AES Module:**
  - **Key Derivation Refinement:** The internal key derivation process was updated to use the full 32-byte binary output of SHA-256, ensuring true **AES-256** strength.
  - **External IV Generation:** Added the `generate_iv()` functionality to generate a cryptographically weak (due to Lua's `math.random` but, it's **lua in CC:T**, i can't work miracles) 16-byte Initialization Vector (IV) when one is not supplied, though providing an external.

#### Bug Fixes

- **ECC Critical Fix:** Corrected a critical bug in the `scalar_multiply` implementation's windowed method that caused the scalar value to be processed in a **nibble-reversed order**. This fix ensures correct mathematical results for point multiplication, resolving signature verification failures.
- **Dependency Install Fix:** Corrected the library installer/packaging logic to ensure the newly introduced `secp256k1` module is correctly included and installed alongside other components.

### v0.4.1

#### Added

- **Package Manager Support:** Added `manifest.lua` to enable direct installation and dependency resolution via **iDar-Pacman**.

### v0.4.2

#### Fixes

- **Manifest dependency:** Fixed incorrect dependency version for `iDar-BigNum`
- **Manifest files path:** Corrected the file paths for algorithm modules in the manifest.

### v0.4.3

#### Added

- New require paths compatible with iDar-Pacman package structure
- Support for absolute module paths: `require("iDar.CryptoLib.src.module")`

#### Changed

- Updated installation instructions to use iDar-Pacman as primary method
- Restructured internal file organization for better package management

#### Removed

- Automated installer script (`installer.lua`)
- Legacy installation method using `wget run`

### v0.4.4

#### Changed

- Manifest updated for compatibility with iDar-Pacman Alpha v2

### v0.4.5

#### Changed

- Manifest updated for compatibility with SATD V2.6

### v1.0.0

#### Critical Changes & Deprecations

- **Arch Re-structure & Deprecations:** Completely removed legacy cryptography modules (**AES** and **RSA**) along with the `iDar-BigNum` dependency for core operations. The library has been pivoted towards modern, high-performance stream ciphers and elliptic curve cryptography.
- **Module Namespaces:** Consolidated internal architecture into four clean modules under the `Crypto` package: `sha`, `encoding`, `secp256k1`, and `chacha20`.

#### New Features

- **ChaCha20-Poly1305 (AEAD) (`chacha20.lua`):**
  - Implemented the **ChaCha20** stream cipher combined with the **Poly1305** MAC for Authenticated Encryption with Associated Data (AEAD).
  - **Available Functions:**
    - `chacha.aead_encrypt(message, secret, nonce, aad)`: Encrypts a message and generates an authentication tag (Poly1305).
    - `chacha.aead_decrypt(ciphertext, secret, nonce, tag, aad)`: Decrypts and verifies message integrity, returning an explicit error if the data or key has been tampered with.
    - `chacha.generateNonce()`: Safely generates a cryptographically secure 12-byte nonce directly from `/dev/random`.

- **Advanced Key Derivation & Encoding (`encoding.lua`):**
  - **PBKDF2:** Added `encoding.pbkdf2(password, salt, dklen)` using HMAC-SHA256 with 10,000 iterations for secure password-based key derivation.
  - **HKDF:** Added `encoding.hkdf(ikm, salt, info, len)` for HMAC-based Extract-and-Expand key derivation.
  - **Hexadecimal Utilities:** Optimized `encoding.toHex(data)` and `encoding.fromHex(hex)` via native string patterns.
  - **Base64 Utilities:** Implemented robust `encoding.toBase64(data)` and `encoding.fromBase64(b64)` encoders/decoders with whitespace stripping and padding handling.

- **Elliptic Curve Cryptography (`secp256k1.lua`):**
  - Fully refactored the `secp256k1` module to operate with an independent big-integer baseline implementation.
  - Improved randomness in key generation by querying `/dev/random` natively.

#### Improvements & Optimizations

- **SHA-256 Module (`sha.lua`):**
  - Extracted and optimized the HMAC-SHA256 implementation (`sha.hmac_sha256`) to act as the structural backbone for HKDF, PBKDF2, and ECDSA nonce generation.

#### Known Issues / TODOs

- **ChaCha20 Internal Salt:** The internal implementation currently utilizes the `nonce` directly as a salt for PBKDF2 during encryption operations. A proper dedicated `salt` parameter is planned for a future patch to separate entropy concerns.
