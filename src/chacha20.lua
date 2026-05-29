local encoding = require("Crypto.encoding")

local chacha = {}

local bxor = bit32.bxor
local lshift = bit32.lshift
local rshift = bit32.rshift
local spack = string.pack
local sunpack = string.unpack
local MOD32 = 4294967296

local function operate(message, secret, nonce, initial_counter)
    if not message or not secret or not nonce then return nil end

    local key = encoding.pbkdf2(secret, nonce) -- nonce is not a good option for a salt, TODO: be a better person and add a salt parameter
    local k1, k2, k3, k4, k5, k6, k7, k8 = sunpack("<I4I4I4I4I4I4I4I4", key)
    local n1, n2, n3 = sunpack("<I4I4I4", nonce)

    local out = {}
    local counter = initial_counter or 1
    local pos = 1
    local msg_len = #message
    local s1, s2, s3, s4 = 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574

    while pos <= msg_len do
        local x1, x2, x3, x4 = s1, s2, s3, s4
        local x5, x6, x7, x8 = k1, k2, k3, k4
        local x9, x10, x11, x12 = k5, k6, k7, k8
        local x13, x14, x15, x16 = counter, n1, n2, n3

        for _ = 1, 10 do
            x1 = (x1 + x5) % MOD32; x13 = bxor(x13, x1); x13 = bxor(lshift(x13, 16), rshift(x13, 16))
            x9 = (x9 + x13) % MOD32; x5 = bxor(x5, x9); x5 = bxor(lshift(x5, 12), rshift(x5, 20))
            x1 = (x1 + x5) % MOD32; x13 = bxor(x13, x1); x13 = bxor(lshift(x13, 8), rshift(x13, 24))
            x9 = (x9 + x13) % MOD32; x5 = bxor(x5, x9); x5 = bxor(lshift(x5, 7), rshift(x5, 25))

            x2 = (x2 + x6) % MOD32; x14 = bxor(x14, x2); x14 = bxor(lshift(x14, 16), rshift(x14, 16))
            x10 = (x10 + x14) % MOD32; x6 = bxor(x6, x10); x6 = bxor(lshift(x6, 12), rshift(x6, 20))
            x2 = (x2 + x6) % MOD32; x14 = bxor(x14, x2); x14 = bxor(lshift(x14, 8), rshift(x14, 24))
            x10 = (x10 + x14) % MOD32; x6 = bxor(x6, x10); x6 = bxor(lshift(x6, 7), rshift(x6, 25))

            x3 = (x3 + x7) % MOD32; x15 = bxor(x15, x3); x15 = bxor(lshift(x15, 16), rshift(x15, 16))
            x11 = (x11 + x15) % MOD32; x7 = bxor(x7, x11); x7 = bxor(lshift(x7, 12), rshift(x7, 20))
            x3 = (x3 + x7) % MOD32; x15 = bxor(x15, x3); x15 = bxor(lshift(x15, 8), rshift(x15, 24))
            x11 = (x11 + x15) % MOD32; x7 = bxor(x7, x11); x7 = bxor(lshift(x7, 7), rshift(x7, 25))

            x4 = (x4 + x8) % MOD32; x16 = bxor(x16, x4); x16 = bxor(lshift(x16, 16), rshift(x16, 16))
            x12 = (x12 + x16) % MOD32; x8 = bxor(x8, x12); x8 = bxor(lshift(x8, 12), rshift(x8, 20))
            x4 = (x4 + x8) % MOD32; x16 = bxor(x16, x4); x16 = bxor(lshift(x16, 8), rshift(x16, 24))
            x12 = (x12 + x16) % MOD32; x8 = bxor(x8, x12); x8 = bxor(lshift(x8, 7), rshift(x8, 25))

            x1 = (x1 + x6) % MOD32; x16 = bxor(x16, x1); x16 = bxor(lshift(x16, 16), rshift(x16, 16))
            x11 = (x11 + x16) % MOD32; x6 = bxor(x6, x11); x6 = bxor(lshift(x6, 12), rshift(x6, 20))
            x1 = (x1 + x6) % MOD32; x16 = bxor(x16, x1); x16 = bxor(lshift(x16, 8), rshift(x16, 24))
            x11 = (x11 + x16) % MOD32; x6 = bxor(x6, x11); x6 = bxor(lshift(x6, 7), rshift(x6, 25))

            x2 = (x2 + x7) % MOD32; x13 = bxor(x13, x2); x13 = bxor(lshift(x13, 16), rshift(x13, 16))
            x12 = (x12 + x13) % MOD32; x7 = bxor(x7, x12); x7 = bxor(lshift(x7, 12), rshift(x7, 20))
            x2 = (x2 + x7) % MOD32; x13 = bxor(x13, x2); x13 = bxor(lshift(x13, 8), rshift(x13, 24))
            x12 = (x12 + x13) % MOD32; x7 = bxor(x7, x12); x7 = bxor(lshift(x7, 7), rshift(x7, 25))

            x3 = (x3 + x8) % MOD32; x14 = bxor(x14, x3); x14 = bxor(lshift(x14, 16), rshift(x14, 16))
            x9 = (x9 + x14) % MOD32; x8 = bxor(x8, x9); x8 = bxor(lshift(x8, 12), rshift(x8, 20))
            x3 = (x3 + x8) % MOD32; x14 = bxor(x14, x3); x14 = bxor(lshift(x14, 8), rshift(x14, 24))
            x9 = (x9 + x14) % MOD32; x8 = bxor(x8, x9); x8 = bxor(lshift(x8, 7), rshift(x8, 25))

            x4 = (x4 + x5) % MOD32; x15 = bxor(x15, x4); x15 = bxor(lshift(x15, 16), rshift(x15, 16))
            x10 = (x10 + x15) % MOD32; x5 = bxor(x5, x10); x5 = bxor(lshift(x5, 12), rshift(x5, 20))
            x4 = (x4 + x5) % MOD32; x15 = bxor(x15, x4); x15 = bxor(lshift(x15, 8), rshift(x15, 24))
            x10 = (x10 + x15) % MOD32; x5 = bxor(x5, x10); x5 = bxor(lshift(x5, 7), rshift(x5, 25))
        end

        x1 = (x1 + s1) % MOD32; x2 = (x2 + s2) % MOD32; x3 = (x3 + s3) % MOD32; x4 = (x4 + s4) % MOD32
        x5 = (x5 + k1) % MOD32; x6 = (x6 + k2) % MOD32; x7 = (x7 + k3) % MOD32; x8 = (x8 + k4) % MOD32
        x9 = (x9 + k5) % MOD32; x10 = (x10 + k6) % MOD32; x11 = (x11 + k7) % MOD32; x12 = (x12 + k8) % MOD32
        x13 = (x13 + counter) % MOD32; x14 = (x14 + n1) % MOD32; x15 = (x15 + n2) % MOD32; x16 = (x16 + n3) % MOD32

        if msg_len - pos >= 63 then
            local m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16 = sunpack("<I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4", message, pos)
            out[#out + 1] = spack("<I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4", 
                bxor(x1, m1), bxor(x2, m2), bxor(x3, m3), bxor(x4, m4),
                bxor(x5, m5), bxor(x6, m6), bxor(x7, m7), bxor(x8, m8),
                bxor(x9, m9), bxor(x10, m10), bxor(x11, m11), bxor(x12, m12),
                bxor(x13, m13), bxor(x14, m14), bxor(x15, m15), bxor(x16, m16)
            )
            pos = pos + 64
        else
            local keystream = spack("<I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4", x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, x16)
            local rem = msg_len - pos + 1
            for i = 1, rem do
                out[#out + 1] = string.char(bxor(string.byte(message, pos + i - 1), string.byte(keystream, i)))
            end
            pos = pos + rem
        end

        counter = (counter + 1) % MOD32
    end

    return table.concat(out)
end

local function poly1305_mac(msg, key)
    local n0, n1, n2, n3 = sunpack("<I4I4I4I4", key)

    n0 = n0 % 268435456
    n1 = (n1 % 268435456) - (n1 % 4)
    n2 = (n2 % 268435456) - (n2 % 4)
    n3 = (n3 % 268435456) - (n3 % 4)

    local r0 = n0 % 67108864
    local r1 = math.floor(n0 / 67108864) + (n1 % 1048576) * 64
    local r2 = math.floor(n1 / 1048576) + (n2 % 16384) * 4096
    local r3 = math.floor(n2 / 16384) + (n3 % 256) * 262144
    local r4 = math.floor(n3 / 256)

    local rr1, rr2, rr3, rr4 = r1 * 5, r2 * 5, r3 * 5, r4 * 5
    local h0, h1, h2, h3, h4 = 0, 0, 0, 0, 0

    local pos = 1
    local len = #msg
    while pos <= len do
        local b_len = math.min(16, len - pos + 1)
        local block = msg:sub(pos, pos + b_len - 1)

        block = block .. "\1" .. string.rep("\0", 16 - b_len)
        local m0, m1, m2, m3 = sunpack("<I4I4I4I4", block)

        local c0 = m0 % 67108864
        local c1 = math.floor(m0 / 67108864) + (m1 % 1048576) * 64
        local c2 = math.floor(m1 / 1048576) + (m2 % 16384) * 4096
        local c3 = math.floor(m2 / 16384) + (m3 % 256) * 262144
        local c4 = math.floor(m3 / 256)

        if b_len == 16 then
            c4 = c4 + 16777216
        end

        h0 = h0 + c0; h1 = h1 + c1; h2 = h2 + c2; h3 = h3 + c3; h4 = h4 + c4

        local d0 = h0*r0 + h1*rr4 + h2*rr3 + h3*rr2 + h4*rr1
        local d1 = h0*r1 + h1*r0  + h2*rr4 + h3*rr3 + h4*rr2
        local d2 = h0*r2 + h1*r1  + h2*r0  + h3*rr4 + h4*rr3
        local d3 = h0*r3 + h1*r2  + h2*r1  + h3*r0  + h4*rr4
        local d4 = h0*r4 + h1*r3  + h2*r2  + h3*r1  + h4*r0

        local c = math.floor(d0 / 67108864); h0 = d0 % 67108864; d1 = d1 + c
        c = math.floor(d1 / 67108864); h1 = d1 % 67108864; d2 = d2 + c
        c = math.floor(d2 / 67108864); h2 = d2 % 67108864; d3 = d3 + c
        c = math.floor(d3 / 67108864); h3 = d3 % 67108864; d4 = d4 + c
        c = math.floor(d4 / 67108864); h4 = d4 % 67108864; h0 = h0 + c * 5
        c = math.floor(h0 / 67108864); h0 = h0 % 67108864; h1 = h1 + c

        pos = pos + 16
    end

    local g0 = h0 + 5
    local c = math.floor(g0 / 67108864); g0 = g0 % 67108864
    local g1 = h1 + c
    c = math.floor(g1 / 67108864); g1 = g1 % 67108864
    local g2 = h2 + c
    c = math.floor(g2 / 67108864); g2 = g2 % 67108864
    local g3 = h3 + c
    c = math.floor(g3 / 67108864); g3 = g3 % 67108864
    local g4 = h4 + c - 67108864

    if g4 >= 0 then h0, h1, h2, h3, h4 = g0, g1, g2, g3, g4 end

    local f0 = (h0 + (h1 % 64) * 67108864) % MOD32
    local f1 = (math.floor(h1 / 64) + (h2 % 4096) * 1048576) % MOD32
    local f2 = (math.floor(h2 / 4096) + (h3 % 262144) * 16384) % MOD32
    local f3 = (math.floor(h3 / 262144) + h4 * 256) % MOD32

    local s0, s1, s2, s3 = sunpack("<I4I4I4I4", key, 17)
    local t0 = f0 + s0; f0 = t0 % MOD32
    local t1 = f1 + s1 + math.floor(t0 / MOD32); f1 = t1 % MOD32
    local t2 = f2 + s2 + math.floor(t1 / MOD32); f2 = t2 % MOD32
    local t3 = f3 + s3 + math.floor(t2 / MOD32); f3 = t3 % MOD32

    return spack("<I4I4I4I4", f0, f1, f2, f3)
end

local function pad16(str)
    local rem = #str % 16
    if rem == 0 then return str end
    return str .. string.rep("\0", 16 - rem)
end

function chacha.aead_encrypt(message, secret, nonce, aad)
    aad = aad or ""
    local poly_key = operate(string.rep("\0", 32), secret, nonce, 0)

    local ciphertext = operate(message, secret, nonce, 1)

    local mac_data = pad16(aad) .. pad16(ciphertext) .. spack("<I8I8", #aad, #ciphertext)
    local tag = poly1305_mac(mac_data, poly_key)

    return ciphertext, tag
end

function chacha.aead_decrypt(ciphertext, secret, nonce, tag, aad)
    aad = aad or ""
    local poly_key = operate(string.rep("\0", 32), secret, nonce, 0)

    local mac_data = pad16(aad) .. pad16(ciphertext) .. spack("<I8I8", #aad, #ciphertext)
    local computed_tag = poly1305_mac(mac_data, poly_key)

    if computed_tag ~= tag then
        return nil, "Error de Integridad: Mensaje alterado o clave incorrecta"
    end

    return operate(ciphertext, secret, nonce, 1)
end

function chacha.generateNonce()
    local rand_fd = sys.open("/dev/random", "r")

    if not rand_fd then return nil end

    local nonce = sys.read(rand_fd)
    sys.close(rand_fd)

    return nonce:sub(1,12)
end

return chacha