local bignum = require("..iDar.Bignum.src.bigNum")

local rsa = {}

local ZERO   = bignum("0")
local ONE    = bignum("1")
local TWO    = bignum("2")
local THREE  = bignum("3")
local FIVE   = bignum("5")
local SEVEN  = bignum("7")
local ELEVEN = bignum("11")

local MILLER_RABIN_BASES = {TWO, THREE, FIVE, SEVEN, ELEVEN}

math.randomseed(os.time() + tonumber(tostring(os.clock()):reverse():sub(1, 5)))

local _small_primes_cache = nil

local function generate_small_primes(limit)
    limit = limit or 2000

    local sieve_limit = 17400

    local sieve = {}
    for i = 2, sieve_limit do
        sieve[i] = true
    end

    for p = 2, math.sqrt(sieve_limit) do
        if sieve[p] then
            os.sleep(0)

            for i = p * p, sieve_limit, p do
                sieve[i] = false
            end
        end
    end

    local native_primes = {}
    for p = 2, sieve_limit do
        if sieve[p] then
            table.insert(native_primes, p)
            if #native_primes >= limit then
                break
            end
        end
    end

    local bignum_primes = {}
    for _, p_num in ipairs(native_primes) do
        table.insert(bignum_primes, bignum(tostring(p_num)))
    end

    return bignum_primes
end

local function get_small_primes()
    if not _small_primes_cache then
        _small_primes_cache = generate_small_primes(2000)
    end
    return _small_primes_cache
end

local function is_sieved(n, sieve)
    for _, p in ipairs(sieve) do
        if n % p == ZERO then
            return true
        end
    end
    return false
end

local function generate_random_bits(n)
    if n < 2 then error("It needs at least 2 bits", 2) end
    local bits = {}

    bits[1] = 1
    bits[n] = 1

    for i = 2, n - 1 do
        bits[i] = math.random(0, 1)
    end

    return ZERO.fromBinary(table.concat(bits))
end

local function miller_rabin(n)
    if n == TWO or n == THREE or n == FIVE or n == SEVEN or n == ELEVEN then return true end
    if n < TWO or n % TWO == ZERO then return false end

    local n_minus_one = n - ONE

    local s = ZERO
    local d = n_minus_one
    while d % TWO == ZERO do
        d = d / TWO
        s = s + ONE
    end

    for _, a in ipairs(MILLER_RABIN_BASES) do
        if a < n_minus_one then
            local x = a:modExp(d, n)

            if x ~= ONE and x ~= n_minus_one then
                local is_composite = true
                local s_minus_one = s - ONE
                local i = ZERO

                while i < s_minus_one do
                    x = x:modExp(TWO, n)
                    if x == ONE then
                        return false
                    end
                    if x == n_minus_one then
                        is_composite = false
                        break
                    end
                    i = i + ONE
                end

                if is_composite then
                    return false
                end
            end
        end
    end

    return true
end

local function generate_prime(bits)
    local sieve = get_small_primes()
    local results = {}

    local function find_single_prime_task(pos)
        local candidate = generate_random_bits(bits)
        if candidate % TWO == ZERO then
            candidate = candidate + ONE
        end

        local bit_length = candidate:bitLength()

        while true do
            os.sleep(0)

            if not is_sieved(candidate, sieve) then

                if miller_rabin(candidate) then
                    results[pos] = candidate
                    return
                end

            end

            candidate = candidate + TWO

            if candidate:bitLength() > bit_length then
                candidate = generate_random_bits(bits)
                if candidate % TWO == ZERO then
                    candidate = candidate + ONE
                end
            end
        end
    end

    parallel.waitForAll(function ()
        find_single_prime_task(1) end, function ()
        find_single_prime_task(2) end)
        
    local p = results[1]
    local q = results[2]

    while p == q do
        q = find_single_prime_task()
    end

    return p, q
end

local function gcd(x, y)
    while y ~= ZERO do
        x, y = y, x % y
    end
    return x
end

local function gcd_extended(a, b)
    if b == ZERO then
        return a, ONE, ZERO
    end
    local g, x1, y1 = gcd_extended(b, a % b)
    local x = y1
    local y = x1 - (a / b) * y1

    return g, x, y
end

local function modular_inverse(a, m)
    local g, x, _ = gcd_extended(a, m)
    if g ~= ONE then
        return nil
    end

    if x < ZERO then
        x = x + m
    end

    return x % m
end

local function generate_public_key(phi_N)
    local e = bignum("65537")
    if gcd(phi_N, e) == ONE then
        return e
    end
    error("Failed to find public exponent")
end

function rsa.generate_keys(bits)
    get_small_primes()
    local p, q = generate_prime(bits)

    local n = p * q
    local phi_N = (p - ONE) * (q - ONE)

    local e = generate_public_key(phi_N)
    if not e then
        printError("Failed to create public key (e)")
        error("Key generation failed")
    end

    local d = modular_inverse(e, phi_N)
    if not d then
        printError("Failed to create private key (d)")
        error("Key generation failed")
    end

    local dP = d % (p - ONE)
    local dQ = d % (q - ONE)
    local qInv = modular_inverse(q, p)

    if not qInv then
        printError("Failed to calculate qInv for CRT")
        error("Key generation failed")
    end

    return {e, n}, {d, n, p, q, dP, dQ, qInv}
end

local function encrypt_internal(message, key)
    if #key < 2 then
        printError("Invalid parameters: message must be a number/string/bignum and key must contain 2 elements.")
        error("Invalid parameters")
    end

    local msg_num = bignum(message)
    local n = key[2]

    if msg_num < ZERO or msg_num > n then
        printError("Message too large to encrypt: must be between 0 and n.")
        error("Message overflow")
    end

    return msg_num:modExp(key[1], n)
end

function rsa.encrypt(message, public_key)
    local msg_num

    if type(message) == "string" then
        msg_num = ZERO.fromBytes(message)
    elseif type(message) == "table" or type(message) == "number" then
        msg_num = bignum(message)
    else
        printError("Tipo de mensaje no válido para cifrar.")
        error("Tipo de mensaje no válido")
    end

    return encrypt_internal(msg_num, public_key)
end

function rsa.decrypt(message, private_key)
    local c = bignum(message)

    local d = private_key[1]
    local n = private_key[2]

    if not private_key[7] then
        printError("WARNING: Private key does not contain CRT values. Using slow decryption.")
        local decrypted_num = c:modExp(d, n)

        return decrypted_num:toBytes()
    end

    local p = private_key[3]
    local q = private_key[4]
    local dP = private_key[5]
    local dQ = private_key[6]
    local qInv = private_key[7]

    local m1 = c:modExp(dP, p)

    local m2 = c:modExp(dQ, q)

    local h = (qInv * (m1 - m2)) % p
    if h < ZERO then
        h = h + p
    end

    local m_decrypted = m2 + h * q

    return m_decrypted:toBytes()
end

return rsa