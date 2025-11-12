local sha = {}

local H = {
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
}
local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
}

local MOD32 = 0x100000000
local B = 64
local IPAD = string.rep("\x36", 64)
local OPAD = string.rep("\x5c", 64)

local function rotr32(value, bits)
    value = value % MOD32
    local r = (bit32.rshift(value, bits) + bit32.lshift(value, 32 - bits)) % MOD32
    return r
end

local function to32(x)
    return x % MOD32
end

local function sha256_compress(chunk, H_copy)
    local W = {}
    for i = 1, 16 do
        W[i] = to32(chunk[i] or 0)
    end
    for i = 17, 64 do
        local w15 = W[i-15]
        local w2  = W[i-2]
        local s0 = bit32.bxor(bit32.bxor(rotr32(w15, 7), rotr32(w15, 18)), bit32.rshift(w15, 3))
        local s1 = bit32.bxor(bit32.bxor(rotr32(w2, 17), rotr32(w2, 19)), bit32.rshift(w2, 10))
        W[i] = to32(W[i-16] + s0 + W[i-7] + s1)
    end

    local a, b, c, d, e, f, g, h = table.unpack(H_copy)

    for i = 1, 64 do
        local S1 = bit32.bxor(bit32.bxor(rotr32(e, 6), rotr32(e, 11)), rotr32(e, 25))
        local ch = bit32.bxor(bit32.band(e,f), bit32.band(bit32.bnot(e), g))
        local temp1 = to32(h + S1 + ch + K[i] + W[i])
        local S0 = bit32.bxor(bit32.bxor(rotr32(a, 2), rotr32(a, 13)), rotr32(a, 22))
        local maj = bit32.bxor(bit32.bxor(bit32.band(a, b), bit32.band(a, c)), bit32.band(b, c))
        local temp2 = to32(S0 + maj)

        h = g
        g = f
        f = e
        e = to32(d + temp1)
        d = c
        c = b
        b = a
        a = to32(temp1 + temp2)
    end

    local t = {a,b,c,d,e,f,g,h}
    for i = 1, 8 do
        H_copy[i] = to32(H_copy[i] + t[i])
    end
end

function sha.sha256(message)
    local message_len = #message
    local padded_message = message .. "\128"
    while (#padded_message % 64) ~= 56 do
        padded_message = padded_message .. "\0"
    end

    padded_message = padded_message .. string.pack(">I8", message_len * 8)

    local H_copy = {table.unpack(H)}
    for pos = 1, #padded_message, 64 do
        local block = padded_message:sub(pos, pos + 63)
        local a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p = string.unpack(">I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4", block)
        local chunk = {a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p}
        sha256_compress(chunk, H_copy)
    end

    local digest_hex = ""
    local digest_bin = ""
    for i = 1, 8 do
        digest_bin = digest_bin .. string.pack(">I4", H_copy[i]) 
        digest_hex = digest_hex .. string.format("%08x", H_copy[i])
    end
    return digest_hex, digest_bin
end

function sha.hmac_sha256(key, message, bin)
    local K_prime
    if #key > B then
        local _, K_hash_bin = sha.sha256(key)
        K_prime = K_hash_bin
    elseif #key < B then
        K_prime = key .. string.rep("\0", B - #key)
    else
        K_prime = key
    end

    local inner_key = {}
    for i = 1, B do
        inner_key[i] = string.char(bit32.bxor(K_prime:byte(i), IPAD:byte(i)))
    end

    local _, inner_hash_bin = sha.sha256(table.concat(inner_key) .. message)

    local outer_key = {}
    for i = 1, B do
        outer_key[i] = string.char(bit32.bxor(K_prime:byte(i), OPAD:byte(i)))
    end

    local result_hex, result_bin = sha.sha256(table.concat(outer_key) .. inner_hash_bin)
    return bin and result_bin or result_hex
end


return sha
