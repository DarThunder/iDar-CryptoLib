local bignum = require("bigNum")

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

local _smallPrimesCache = nil

local function generateSmallPrimes(limit)
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

local function getSmallPrimes()
    if not _smallPrimesCache then
        _smallPrimesCache = generateSmallPrimes(2000)
    end
    return _smallPrimesCache
end

local function isSieved(n, sieve)
    for _, p in ipairs(sieve) do
        if n % p == ZERO then
            return true
        end
    end
    return false
end

local function generateRandomBits(n)
    if n < 2 then error("It needs at least 2 bits", 2) end
    local bits = {}

    bits[1] = 1
    bits[n] = 1

    for i = 2, n - 1 do
        bits[i] = math.random(0, 1)
    end

    return ZERO.fromBinary(table.concat(bits))
end

local function millerRabin(n)
    if n == TWO or n == THREE or n == FIVE or n == SEVEN or n == ELEVEN then return true end
    if n < TWO or n % TWO == ZERO then return false end

    local nMinusOne = n - ONE

    local s = ZERO
    local d = nMinusOne
    while d % TWO == ZERO do
        d = d / TWO
        s = s + ONE
    end

    for _, a in ipairs(MILLER_RABIN_BASES) do
        if a < nMinusOne then 
            local x = a:modExp(d, n)

            if x ~= ONE and x ~= nMinusOne then
                local isComposite = true
                local sMinusOne = s - ONE
                local i = ZERO

                while i < sMinusOne do
                    x = x:modExp(TWO, n)
                    if x == ONE then
                        return false
                    end
                    if x == nMinusOne then
                        isComposite = false
                        break
                    end
                    i = i + ONE
                end

                if isComposite then
                    return false
                end
            end
        end
    end

    return true
end

local function generatePrime(bits)
    local sieve = getSmallPrimes()
    local results = {}

    local function findSinglePrimeTask(pos)
        local candidate = generateRandomBits(bits)
        if candidate % TWO == ZERO then
            candidate = candidate + ONE
        end

        local bitLength = candidate:bitLength()

        while true do
            os.sleep(0)

            if not isSieved(candidate, sieve) then

                if millerRabin(candidate) then
                    results[pos] = candidate
                    return
                end

            end

            candidate = candidate + TWO

            if candidate:bitLength() > bitLength then
                candidate = generateRandomBits(bits)
                if candidate % TWO == ZERO then
                    candidate = candidate + ONE
                end
            end
        end
    end

    parallel.waitForAll(function ()
        findSinglePrimeTask(1) end, function ()
        findSinglePrimeTask(2) end)
        
    local p = results[1]
    local q = results[2]

    while p == q do
        q = findSinglePrimeTask()
    end

    return p, q
end

local function gcd(x, y)
    while y ~= ZERO do
        x, y = y, x % y
    end
    return x
end

local function gcdExtended(a, b)
    if b == ZERO then
        return a, ONE, ZERO
    end
    local g, x1, y1 = gcdExtended(b, a % b)
    local x = y1
    local y = x1 - (a / b) * y1

    return g, x, y
end

local function modularInverse(a, m)
    local g, x, _ = gcdExtended(a, m)
    if g ~= ONE then
        return nil
    end

    if x < ZERO then
        x = x + m
    end

    return x % m
end

local function generatePublicKey(phiN)
    local e = bignum("65537")
    if gcd(phiN, e) == ONE then
        return e
    end
    error("Failed to find public exponent")
end

function rsa.generateKeys(bits)
    getSmallPrimes()
    local p, q = generatePrime(bits)

    local n = p * q
    local phiN = (p - ONE) * (q - ONE)

    local e = generatePublicKey(phiN)
    if not e then
        printError("Failed to create public key (e)")
        error("Key generation failed")
    end

    local d = modularInverse(e, phiN)
    if not d then
        printError("Failed to create private key (d)")
        error("Key generation failed")
    end

    local dP = d % (p - ONE)
    local dQ = d % (q - ONE)
    local qInv = modularInverse(q, p)

    if not qInv then
        printError("Failed to calculate qInv for CRT")
        error("Key generation failed")
    end

    return {e, n}, {d, n, p, q, dP, dQ, qInv}
end

local function encryptInternal(message, key)
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

function rsa.encrypt(message, publicKey)
    local msg_num

    if type(message) == "string" then
        msg_num = ZERO.fromBytes(message)
    elseif type(message) == "table" or type(message) == "number" then
        msg_num = bignum(message)
    else
        printError("Tipo de mensaje no válido para cifrar.")
        error("Tipo de mensaje no válido")
    end

    return encryptInternal(msg_num, publicKey)
end

function rsa.decrypt(message, privateKey)
    local c = bignum(message)

    local d = privateKey[1]
    local n = privateKey[2]

    if not privateKey[7] then
        printError("WARNING: Private key does not contain CRT values. Using slow decryption.")
        local decrypted_num = c:modExp(d, n)

        return decrypted_num:toBytes()
    end

    local p = privateKey[3]
    local q = privateKey[4]
    local dP = privateKey[5]
    local dQ = privateKey[6]
    local qInv = privateKey[7]

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