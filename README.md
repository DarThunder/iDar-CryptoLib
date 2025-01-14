# iDar-CryptoLib

iDar CryptoLib is a cryptography-focused library that implements powerful and reliable algorithms (RSA, AES, SHA-256, etc.). It's optimized and ready to enhance your Minecraft world with the ComputerCraft: Tweaked mod. Whether you're protecting sensitive data, creating secure communication channels, or exploring cryptographic concepts, iDar CryptoLib has you covered.

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [AES](#aes)
  - [RSA](#rsa)
  - [SHA256](#sha256)
- [Contributing](#contributing)
- [License](#license)

## Features
- RSA encryption and decryption
- AES block cipher implementation
- SHA-256 hashing algorithm
- Lightweight and optimized for ComputerCraft: Tweaked
- Modular and extensible design

## Requirements
- Minecraft with the ComputerCraft: Tweaked mod installed
- Minecraft 1.20.1 or above (Below 1.20.1, only God knows if it is compatible).
- Basic knowledge of Lua programming

## Getting Started
### Install in ComputerCraft:
  1. use this command in the terminal of the computer/pocket computer to use.
```lua
wget run https://raw.githubusercontent.com/DarThunder/iDar-CryptoLib/refs/heads/main/installer.lua
```
  2. wait of the installation process.

### Load the library:
  1. Use require("idar-cl") to load the library into your ComputerCraft programs.

## Usage
### AES
```lua
local aes = require("idar-cl.aes")

-- Encrypt and decrypt
local key = "securepassword123"
local data = "Sensitive information"
local encrypted = aes.encrypt(data, key)
local decrypted = aes.decrypt(encrypted, key)

print(decrypted) -- Output: Sensitive information
```
### RSA
```lua
local rsa = require("idar-cl.rsa")

-- Generate RSA keys
local publicKey, privateKey = rsa.generateKeys(2048)

-- Encrypt and decrypt
local encrypted = rsa.encrypt("Hello, world!", publicKey)
local decrypted = rsa.decrypt(encrypted, privateKey)

print(decrypted) -- Output: Hello, world!
```
### SHA256
```lua
local sha = require("idar-cl.sha")

-- Hash a string
local hash = sha.sha256("Hello, world!")
print(hash) -- Output: a SHA-256 hash of the input
```
## FAQ

- Q: What happens if I lose my private key?
- A: Unfortunately, if you lose your private key, you won't be able to decrypt any data encrypted with the corresponding public key. Make sure to back up your keys securely.

- Q: Can I use this library with other mods?
- A: Yes, as long as the other mods are compatible with ComputerCraft and Lua, iDar CryptoLib should work seamlessly.

- Q: Is there a way to extend the library with new algorithms?
- A: Absolutely! The library is designed to be modular, so you can add your own cryptographic functions by following the structure of the existing modules.

## Contributing
Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Submit a pull request with a clear description.

## License
This project is licensed under the GPL License. See the [LICENSE](LICENSE) file for details.
