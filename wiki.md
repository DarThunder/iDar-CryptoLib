# iDar-CryptoLib Functions Wiki
## Introduction
This wiki explains the functions available in iDar-CryptoLib, a cryptographic library designed for handling sensitive information.

## Functions
`aes.encrypt(message, secret)`
Encrypts a message using the AES-128 algorithm.

- Params:
    - `message`: The message to encrypt (type: `string`).
    - `secret`: The key to encrypt the message (type: `string`).
- Returns:
    - `encryptMessage`: The encrypted message (type: `string`).
### Example:
```lua
local encrypted = aes.encrypt("Hello world", "superduperultrasecretkey123")
print(encrypted) -- encrypted message
```

`aes.decrypt(encryptMessage, secret)`
Decrypts a message that was encrypted using the AES-128 algorithm.

- Params:
    - `encryptMessage`: The encrypted message (type: `string`).
    - `secret`: The key to decrypt the message (type: `string`).
- Returns:
    - `decryptMessage`: The original message (type: `string`).
### Example:
```lua
local decrypted = aes.decrypt(encrypted, "superduperultrasecretkey123")
print(decrypted) -- "Hello world"
```

`sha.sha256(prompt)`
Generates a SHA-256 hash from the provided input.

- Params:
    - `prompt`: The text to generate the hash (type: `string`).
- Returns:
    - `hash`: The resulting SHA-256 hash (type: `string`).
### Example:
```lua
local hash = sha.sha256("Hello world")
print(hash) --c8e284fe0b97a4bba8f65390ae0feb30d738c6d5bded85325b3bb1d70810a74
```

## Additional Notes
- Ensure that the key used for AES encryption is of the correct length (16 bytes for AES-128) or not, it is still truncated to 16 bytes. lol
- SHA-256 generates a fixed-length hash of 32 characters.
