local bignum = require("idar-bn.bigNum")

local ecc = {}

local ZERO = bignum("0")
local ONE = bignum("1")
local TWO = bignum("2")
local THREE = bignum("3")
local P = bignum("115792089237316195423570985008687907853269984665640564039457584007908834671663")
local G = {x = bignum("55066263022277343669578718895168534326250603453777594175500187360389116729240"), y = bignum("32670510020758816978083085130507043184471273380659243275938904335757337482424")}
local N = bignum("115792089237316195423570985008687907852837564279074904382605163141518161494337")

local function randomBigInt(nbytes)
    local buf = {}
    for i = 1, nbytes do
        buf[i] = string.char(math.random(0,255))
    end
    return ZERO.fromBytes(table.concat(buf))
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

    if g == -ONE then
        x = x * -1
    elseif g ~= ONE then
        return nil
    end

    if x < ZERO then
        x = x + m
    end

    local result = x % m
    return result
end

local function point_double(p)
    if p.y == ZERO then
        return nil
    end

    local s = (THREE * p.x^2) * modularInverse(TWO * p.y, P) % P
    local R = {x = (s^2 - TWO * p.x) % P}
    R.y = (s * (p.x - R.x) - p.y) % P
    return R
end

local function point_add(p, q)
    if not p then return q end
    if not q then return p end
    if p.x == q.x and p.y == q.y then
        return point_double(p)
    end

    if p.x == q.x then
        return nil
    end

    local s = (p.y - q.y) * modularInverse(p.x - q.x, P) % P
    local R = {x = (s^2 - p.x - q.x) % P}
    R.y = (s * (p.x - R.x) - p.y) % P

    return R
end

local function scalar_multiply(k, p)
    local R = nil
    local addend = p

    for i = 0, k:bitLength()-1 do
        os.sleep(0)
        if k:band(bignum(1):lshift(i)) ~= ZERO then
            R = point_add(R, addend)
        end
        addend = point_double(addend)
    end

    return R
end

function ecc.generatePrivateKey()
    local k = randomBigInt(32)
    return k % (N - ONE) + ONE
end

function ecc.getPublicKey(privKey)
    return scalar_multiply(privKey, G)
end

function ecc.getSharedSecret(myPrivKey, theirPubKey)
    local sharedPoint = scalar_multiply(myPrivKey, theirPubKey)
    if not sharedPoint then return nil end
    return sharedPoint.x
end

return ecc