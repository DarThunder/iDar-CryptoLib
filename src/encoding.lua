local sha = require("Crypto.sha")

local encoding = {}

function encoding.toHex(data)
    return (data:gsub(".", function(c)
        return string.format("%02x", c:byte())
    end))
end

function encoding.fromHex(hex)
    if #hex % 2 ~= 0 then return nil, "Invalid hex length" end
    return (hex:gsub("%x%x", function(h)
        return string.char(tonumber(h, 16))
    end))
end

local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local B64_DECODE = {}
for i = 1, #B64_CHARS do
    B64_DECODE[B64_CHARS:sub(i, i)] = i - 1
end

function encoding.toBase64(data)
    local out = {}
    local len = #data

    for i = 1, len, 3 do
        local b1 = data:byte(i)
        local b2 = data:byte(i + 1) or 0
        local b3 = data:byte(i + 2) or 0

        local n = b1 * 65536 + b2 * 256 + b3

        out[#out + 1] = B64_CHARS:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
        out[#out + 1] = B64_CHARS:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
        out[#out + 1] = B64_CHARS:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
        out[#out + 1] = B64_CHARS:sub(n % 64 + 1, n % 64 + 1)
    end

    local rem = len % 3
    if rem == 1 then
        out[#out - 1] = "="
        out[#out]     = "="
    elseif rem == 2 then
        out[#out] = "="
    end

    return table.concat(out)
end

function encoding.fromBase64(b64)
    b64 = b64:gsub("%s", "")
    if #b64 % 4 ~= 0 then return nil, "Invalid base64 length" end

    local out = {}
    for i = 1, #b64, 4 do
        local c1 = B64_DECODE[b64:sub(i, i)]
        local c2 = B64_DECODE[b64:sub(i + 1, i + 1)]
        local c3 = B64_DECODE[b64:sub(i + 2, i + 2)]
        local c4 = B64_DECODE[b64:sub(i + 3, i + 3)]

        if not c1 or not c2 then return nil, "Invalid character base64" end

        local n = c1 * 262144 + c2 * 4096

        out[#out + 1] = string.char(math.floor(n / 65536) % 256)

        if b64:sub(i + 2, i + 2) ~= "=" then
            n = n + (c3 or 0) * 64
            out[#out + 1] = string.char(math.floor(n / 256) % 256)
        end

        if b64:sub(i + 3, i + 3) ~= "=" then
            n = n + (c4 or 0)
            out[#out + 1] = string.char(n % 256)
        end
    end

    return table.concat(out)
end

local PBKDF2_ITERATIONS = 10000

function encoding.pbkdf2(password, salt, dklen)
    dklen = dklen or 32
    local blocks_needed = math.ceil(dklen / 32)
    local dk = {}

    for block_idx = 1, blocks_needed do
        local u = sha.hmac_sha256(password, salt .. string.pack(">I4", block_idx), true)
        local f = u

        for _ = 2, PBKDF2_ITERATIONS do
            u = sha.hmac_sha256(password, u, true)
            local xored = {}
            for j = 1, 32 do
                xored[j] = string.char(bit32.bxor(f:byte(j), u:byte(j)))
            end
            f = table.concat(xored)
        end

        dk[#dk + 1] = f
    end

    return table.concat(dk):sub(1, dklen)
end

function encoding.hkdf(ikm, salt, info, len)
    salt = salt or string.rep("\0", 32)
    local prk = sha.hmac_sha256(salt, ikm, true)
    local okm, prev = "", ""
    local i = 0
    while #okm < len do
        i = i + 1
        prev = sha.hmac_sha256(prk, prev .. info .. string.char(i), true)
        okm = okm .. prev
    end
    return okm:sub(1, len)
end

return encoding