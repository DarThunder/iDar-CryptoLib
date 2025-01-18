# iDar-CryptoLib Functions Wiki
## Introduction
This wiki explains the functions available in iDar-CryptoLib, a cryptographic library designed for handling sensitive information.

## Functions
## AES
### aes.encrypt(message, secret)
Encrypts a message using the AES-128 algorithm.

- Params:
    - `message`: The message to encrypt (type: `string`).
    - `secret`: The symmetric key (type: `string`).
- Returns:
    - `encryptMessage`: The encrypted message (type: `string`).
### Example:
```lua
local encrypted = aes.encrypt("Hello world", "superduperultrasecretkey123")
print(encrypted) -- encrypted message
```

### aes.decrypt(encryptMessage, secret)
Decrypts a message that was encrypted using the AES-128 algorithm.

- Params:
    - `encryptMessage`: The encrypted message (type: `string`).
    - `secret`: The symmetric key (type: `string`).
- Returns:
    - `decryptMessage`: The original message (type: `string`).
### Example:
```lua
local decrypted = aes.decrypt(encrypted, "superduperultrasecretkey123")
print(decrypted) -- "Hello world"
```

## ChaCha20
### chacha.generateNonce()
Generates a unique 12-character/96-bit word

- Params: None

- Returns:
    - `nonce`: The unique 12-character/96-bit word (type: `string`)
### Example:
```lua
local nonce = chacha.generateNonce()
print(nonce) -- a 12-character word
```

### chacha.encrypt(message, secret, nonce)
Encrypts the message using the ChaCha20 algorithm

- Params:
    - `message`: The message to be encrypted (type: `string`)
    - `secret`: The symmetric key (type: `string`)
    - `nonce`: A unique 12-character word (type: `string`)

- Returns:
    - `encryptMessage`: The 64-character message already encrypted (type: `string`)
### Example:
```lua
local encryptMessage = chacha.encrypt("Hello world", "superduperultrasecretkey123", nonce)
print(encryptMessage) -- the 64-character encrypt message
```

### chacha.decrypt(encryptMessage, secret, nonce)
Decrypts the message using the ChaCha20 algorithm

- Params:
    - `encryptMessage`: It is the message to be decrypted (type: `string`)
    - `secret`: The symmetric key (type: `string`)
    - `nonce`: A unique 12-character word (type: `string`)
    - **Note**: the `nonce` parameter must be the same for both encryption and decryption

- Returns:
    - `decryptMessage`: The original message (type: `string`)
### Example:
```lua
local decryptMessage = chacha.decrypt(encryptMessage, "superduperultrasecretkey123", nonce)
print(decryptMessage) -- Hello world
```

## RSA
### rsa.generateKeys(bits)
Generates RSA asymmetric keys based on the number of bits you provide

- Params:
    - `bits`: The limit of bits that the key can generate, e.g. 2^32 (type: `number`)
- Returns:
    - `publicKey`: It is the public key, used to decrypt the message (type: `table`)
    - `privateKey`: It is the private key, used to encrypt the message (type: `table`)
### Example:
```lua
local publicKey, privateKey = rsa.generateKeys(32) -- 32 its the current limit (CC has limits)
print(publicKey) -- table containing 2 values, the public key (e) and n
print(privateKey) -- table containing 2 values, the private key (d) and n
```

### rsa.encrypt(message, publicKey)
Encrypt the message using the RSA algorithm

- Params:
    - `message`: It is the message to be encrypted (type: `number` or `bignum/string with numbers`)
    - `publicKey`: It is the key that will be used to encrypt (type: `table`)

- Returns:
    - `encryptMessage`: The message already encrypted (type: `bignum/string with numbers`)
### Example:
```lua
local encryptMessage = rsa.encrypt(2025, publicKey)
print(encryptMessage) -- the encrypt number
```

### rsa.decrypt(message, privateKey)
Decrypt the message using the RSA algorithm

- Params:
    - `message`: It is the message to be encrypted (type: `number` or `bignum/string with numbers`)
    - `privateKey`: It is the key that will be used to decrypt (type: `table`)

- Returns:
    - `decryptMessage`: The original message (type: `bignum/string with numbers`)
### Example:
```lua
local decryptMessage = rsa.decrypt(encryptMessage, privateKey)
print(decryptMessage) -- 2025
```

## SHA
### sha.sha256(prompt)
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
