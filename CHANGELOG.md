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
