local sha = require("..iDar.CryptoLib.src.sha")

local chacha = {}

local function to_u32(x) return x % 2^32 end

local function word_to_bytes_le(w)
    w = to_u32(w)
    local b1 = w % 256
    local b2 = math.floor(w / 256) % 256
    local b3 = math.floor(w / 65536) % 256
    local b4 = math.floor(w / 16777216) % 256
    return string.char(b1, b2, b3, b4)
end

local function bytes_to_word_le(s, i)
    i = i or 1
    local b1, b2, b3, b4 = string.byte(s, i, i+3)
    return to_u32(b1 + b2*256 + b3*65536 + b4*16777216)
end

local function rotl32(x, n)
    x = to_u32(x)
    n = n % 32
    return to_u32(bit32.lshift(x, n) + bit32.rshift(x, 32 - n))
end

local function quarter_round(state, a, b, c, d)
    state[a] = to_u32(state[a] + state[b]); state[d] = bit32.bxor(state[d], state[a]); state[d] = rotl32(state[d], 16)
    state[c] = to_u32(state[c] + state[d]); state[b] = bit32.bxor(state[b], state[c]); state[b] = rotl32(state[b], 12)
    state[a] = to_u32(state[a] + state[b]); state[d] = bit32.bxor(state[d], state[a]); state[d] = rotl32(state[d], 8)
    state[c] = to_u32(state[c] + state[d]); state[b] = bit32.bxor(state[b], state[c]); state[b] = rotl32(state[b], 7)
end

local function chacha20_block(key32, counter, nonce12)
    local constants = {
        bytes_to_word_le("expa"),
        bytes_to_word_le("nd 3"),
        bytes_to_word_le("2-by"),
        bytes_to_word_le("te k"),
    }

    local state = {}
    for i = 1,4 do state[i] = constants[i] end
    for i = 1,8 do
        local offset = (i-1)*4 + 1
        state[4 + i] = bytes_to_word_le(key32, offset)
    end
    state[13] = to_u32(counter)
    state[14] = bytes_to_word_le(nonce12, 1)
    state[15] = bytes_to_word_le(nonce12, 5)
    state[16] = bytes_to_word_le(nonce12, 9)

    local working = {}
    for i = 1, 16 do working[i] = state[i] end

    for _ = 1, 10 do
        quarter_round(working, 1, 5, 9, 13)
        quarter_round(working, 2, 6, 10, 14)
        quarter_round(working, 3, 7, 11, 15)
        quarter_round(working, 4, 8, 12, 16)
        quarter_round(working, 1, 6, 11, 16)
        quarter_round(working, 2, 7, 12, 13)
        quarter_round(working, 3, 8, 9, 14)
        quarter_round(working, 4, 5, 10, 15)
    end

    local out = {}
    for i = 1, 16 do
        local w = to_u32(working[i] + state[i])
        out[#out + 1] = word_to_bytes_le(w)
    end

    return table.concat(out)
end

local function xor_strings(a, b)
    local res = {}
    local n = math.min(#a, #b)
    for i = 1, n do
        res[i] = string.char(bit32.bxor(string.byte(a, i), string.byte(b, i)))
    end
    return table.concat(res)
end

local function derive_key(secret)
    local _, bin = sha.sha256(secret)
    return bin
end

local function operate(message, secret, nonce)
    if not message or not secret or not nonce then return nil end
    if #nonce ~= 12 then error("nonce must be 12 bytes") end

    local key = derive_key(secret)
    local out = {}
    local counter = 0
    local pos = 1

    while pos <= #message do
        local keystream = chacha20_block(key, counter, nonce)
        local block = message:sub(pos, pos + 63)
        local x = xor_strings(block, keystream)
        out[#out + 1] = x
        pos = pos + #block
        counter = (counter + 1) % 2^32
    end

    return table.concat(out)
end

function chacha.encrypt(message, secret, nonce)
    return operate(message, secret, nonce)
end

function chacha.decrypt(message, secret, nonce)
    return operate(message, secret, nonce)
end

function chacha.generateNonce()
    local t = {}
    for i = 1, 12 do t[i] = string.char(math.random(0,255)) end
    return table.concat(t)
end

return chacha
