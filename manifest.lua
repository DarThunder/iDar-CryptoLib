return {
    directory = "Crypto",
    files = {
        ["chacha20.lua"] = "src/chacha20.lua",
        ["encoding.lua"] = "src/encoding.lua",
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