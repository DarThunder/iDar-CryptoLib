return {
    directory = "Crypto",
    files = {
        ["aes.lua"] = "src/aes.lua",
        ["chacha20.lua"] = "src/chacha20.lua",
        ["rsa.lua"] = "src/rsa.lua",
        ["secp256k1.lua"] = "src/secp256k1.lua",
        ["sha.lua"] = "src/sha.lua"
    },
    dependencies = {
        {
            name = "idar-bignum",
            version = "latest"
        }
    }
}