local bignum = require("idar-bn.bigNum")

local rsa = {}

math.randomseed(math.randomseed(os.time() + tonumber(tostring(os.clock()):reverse():sub(1, 5))))

local function generateRandomBits(n)
    local bits = {}

    bits[1] = 1
    --bits[n] = 1

    for i = 2, n do
        bits[i] = math.random(0, 1)
    end

    local bitString = table.concat(bits)
    return bignum.fromBinary(bitString)
end

local function millerRabin(n, valid)
    local one = "1"
    local two = "2"
    local nMinusOne = bignum.sub(n, one)
    local s = "0"
    local d = nMinusOne
    local a = two

    while bignum.and_bitwise(d, one) == "0" do
        d = bignum.div(d, two)
        s = bignum.add(s, one)
    end

    local x = bignum.modExp(a, d, n)

    if x ~= one or x ~= nMinusOne then
        local isComposite = true
        for _ = 1, bignum.sub(s, "1") do
            x = bignum.modExp(x, two, n)
            if x == nMinusOne or x == one then
                isComposite = false
                break
            end
        end

        if isComposite then
            table.insert(valid, false)
            return
        end
    end

    table.insert(valid, n)
end

local function generatePrime(bits)
    local sample = {}
    local valid = {}
    while #sample < 50 do
        local candidate = generateRandomBits(bits)
        if bignum.mod(candidate, "3") ~= "0" then
            table.insert(sample, function ()
                millerRabin(candidate, valid)
            end)
        end
    end

    parallel.waitForAll(table.unpack(sample))
    local primes = {}
    for _, value in ipairs(valid) do
        if value then
            table.insert(primes, value)
            if #primes >= 2 then return primes[1], primes[2] end
        end
    end

    return generatePrime(bits)
end

local function gcd(x, y)
    if y == "0" then
        return x
    end
    return gcd(y, bignum.mod(x, y))
end

local function gcdExtended(a, b)
    if b == "0" then
        return a, "1", "0"
    end
    local g, x1, y1 = gcdExtended(b, bignum.mod(a, b))
    local x = y1
    local y = bignum.sub(x1, bignum.mul(bignum.div(a, b), y1))

    return g, x, y
end

local function modularInverse(a, m)
    local g, x, _ = gcdExtended(a, m)
    if g ~= "1" then
        return nil
    end

    if x:sub(1, 1) == "-" then
        if bignum.compare(x:sub(2), m) >= 0 then
            x = bignum.mod(bignum.add(m, bignum.mod(x, m)), m)
        else
            x = bignum.sub(m, x:sub(2))
        end
    end

    return bignum.mod(x, m)
end

local function generatePublicKey(phiN, e)
    if bignum.compare(phiN,e) == -1 then
        return nil
    end
    if gcd(phiN, e) == "1" then
        return e
    end
    return generatePublicKey(phiN, bignum.add(e, "2"))
end

function rsa.generateKeys(bits)
    if bits > 32 then bits = 32 end

    local p, q = generatePrime(bits)

    while p == q do
        q = generatePrime(bits)
    end

    local n = bignum.mul(p, q)
    local phiN = bignum.mul(bignum.sub(p, "1"), bignum.sub(q, "1"))

    local e = generatePublicKey(phiN, "3")
    if not e then
        printError("Failed to create public key (e)")
        error("Key generation failed")
    end

    local d = modularInverse(e, phiN)
    if not d then
        printError("Failed to create private key (d)")
        error("Key generation failed")
    end

    return {e, n}, {d, n}
end

local function operate(message, key)
    if (type(message) ~= "number" and type(message) ~= "string") or #key < 2 then
        printError("Invalid parameters: message must be a number or bigNum and key must contain at least 2 elements.")
        error("Invalid parameters")
    end

    message = tostring(message)

    if bignum.compare(message, "0") == -1 or bignum.compare(message, key[2]) == 1 then
        printError("Message too large to encrypt: must be between 0 and n.")
        error("Message overflow")
    end

    local encryptedMessage = bignum.modExp(message, key[1], key[2])
    return encryptedMessage
end

function rsa.encrypt(message, publicKey)
    return operate(message, publicKey)
end

function rsa.decrypt(message, privateKey)
    return operate(message, privateKey)
end

return rsa
