return {
    directory = "CryptoLib",
    files = {
        "aes.lua",
        "chacha20.lua",
        "rsa.lua",
        "secp256k1.lua",
        "sha.lua"
    },
    dependencies = {
        {
            name = "idar-bignum",
            version = "v2.0.0"
        }
    }
}