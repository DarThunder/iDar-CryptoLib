return {
    directory = "CryptoLib",
    files = {
        "src/aes.lua",
        "src/chacha20.lua",
        "src/rsa.lua",
        "src/secp256k1.lua",
        "src/sha.lua"
    },
    dependencies = {
        {
            name = "idar-bignum",
            version = "v2.0.1"
        }
    }
}