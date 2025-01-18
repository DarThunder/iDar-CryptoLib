# Changelog

## Beta
### v0.1.0
- AES block cipher implementation
- SHA-256 hashing algorithm
- Lightweight and optimized for ComputerCraft: Tweaked
- Modular and extensible design

### v0.1.1
- Minor fixes in the use of "requires" and use of bit32 library functions

### v0.2.0
#### Changes
- Added the `ChaCha20` module and algorithm.
- Added the `RSA` module and algorithm (Note: `RSA` has some instability, see details in known issues below).
- A new requirement has been added: [iDar-BigNum](https://github.com/DarThunder/iDar-BigNum) library is now required.
#### Fixes/Improvements
- Fixed the padding generation in the `AES` module, which was adding an extra block when the input was an exact multiple of 16.
#### Known Issues
- The `RSA` algorithm has a slow key generation process. Currently, a limit has been imposed to generate keys of up to 32 bits. Solutions to reduce key generation time are being considered.
#### Notes
RSA was a real headache, mainly due to the large numbers it uses. I had to create a arbitrary-precision arithmetic to generate keys larger than 12 bits, but it's working fine now. I am also thinking of adding elliptic curve-based algorithms, specifically curve 25519, and including some HMAC algorithms. So, stay tuned for new updates in the coming weeks!
