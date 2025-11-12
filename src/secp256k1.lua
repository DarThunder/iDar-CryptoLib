local sha = require("idar-cl.sha")
local bignum = require("idar-bn.bigNum")

local ecc = {}

local ZERO = bignum("0")
local ONE = bignum("1")
local TWO = bignum("2")
local THREE = bignum("3")
local FOUR = bignum("4")
local SEVEN = bignum("7")
local EIGHT = bignum("8")
local P = bignum("115792089237316195423570985008687907853269984665640564039457584007908834671663")
local G = {x = bignum("55066263022277343669578718895168534326250603453777594175500187360389116729240"), y = bignum("32670510020758816978083085130507043184471273380659243275938904335757337482424")}
local N = bignum("115792089237316195423570985008687907852837564279074904382605163141518161494337")

local function random_big_int(nbytes)
    local seed = os.epoch("utc") + os.getComputerID()
    math.randomseed(seed)
    local bytes = {}
    for i = 1, nbytes do
        bytes[i] = string.char(math.random(0, 255))
    end
    return ZERO.fromBytes(table.concat(bytes))
end

local function hash_message(message)
    local _, bin_digest = sha.sha256(message)
    local z = ZERO.fromBytes(bin_digest)
    return z % N
end

local function generate_k(priv, z)
    local key = priv:toBytes()
    local h1 = z:toBytes()

    local K = string.rep("\x00", 32)
    local V = string.rep("\x01", 32)

    K = sha.hmac_sha256(K, V .. "\x00" .. key .. h1, true)
    V = sha.hmac_sha256(K, V, true)

    while true do
        V = sha.hmac_sha256(K, V, true)
        local k = ZERO.fromBytes(V)
        if k > ZERO and k < N then
            return k
        end
        K = sha.hmac_sha256(K, V .. "\x00", true)
        V = sha.hmac_sha256(K, V, true)
    end
end

local function modular_inverse(a, m)
    local x, y, u, v = ZERO, ONE, ONE, ZERO
    local b = m
    a = a % m
    while a ~= ZERO do
        local q = b / a
        local r = b % a
        local m_ = x - u * q
        local n = y - v * q
        b, a, x, y, u, v = a, r, u, v, m_, n
    end
    if b ~= ONE then return nil end
    return x % m
end

local function to_affine(p)
    if p.z == ONE or not p.z then return {x = p.x, y = p.y} end

    local zinv = modular_inverse(p.z, P)
    local zinv2 = (zinv * zinv) % P
    local zinv3 = (zinv2 * zinv) % P

    os.sleep(0)
    return {
        x = (p.x * zinv2) % P,
        y = (p.y * zinv3) % P
    }
end

local function is_on_curve(pt)
    if not pt then return false end
    if not pt.z or pt.z == ONE then
        local lhs = (pt.y * pt.y) % P
        local rhs = (pt.x * pt.x * pt.x + SEVEN) % P
        return lhs == rhs
    else
        local a = to_affine(pt)
        return is_on_curve(a)
    end
end

local function point_double(p)
    if p.y == ZERO then return nil end

    local y2 = (p.y * p.y) % P
    local s = (FOUR * p.x * y2) % P
    local m = (THREE * p.x * p.x) % P

    local nx = (m * m - TWO * s) % P
    local ny = (m * (s - nx) - EIGHT * y2 * y2) % P
    local nz = (TWO * p.y * p.z) % P

    return {x = nx, y = ny, z = nz}
end

local function point_add(p, q)
    if not p then return q end
    if not q then return p end

    if not q.z then q = {x = q.x, y = q.y, z = ONE} end
    if not p.z then p = {x = p.x, y = p.y, z = ONE} end

    local z1z1 = (p.z * p.z) % P
    local z2z2 = (q.z * q.z) % P
    local u1 = (p.x * z2z2) % P
    local u2 = (q.x * z1z1) % P
    local s1 = (p.y * q.z * z2z2) % P
    local s2 = (q.y * p.z * z1z1) % P

    if u1 == u2 then
        if s1 == s2 then
            return point_double(p)
        else
            return nil
        end
    end

    local h = (u2 - u1) % P
    local i = (FOUR * h * h) % P
    local j = (h * i) % P
    local r = (TWO * (s2 - s1)) % P
    local v = (u1 * i) % P

    local nx = (r * r - j - TWO * v) % P
    local ny = (r * (v - nx) - TWO * s1 * j) % P
    local nz = ((p.z + q.z) * (p.z + q.z) - z1z1 - z2z2) % P
    nz = (nz * h) % P

    return {x = nx, y = ny, z = nz}
end

local function scalar_multiply(k, p)
    local precomputed = { nil }
    precomputed[1] = p
    for i = 2, 16 do
        precomputed[i] = point_add(precomputed[i-1], p)
    end

    local R = nil
    for i = 63, 0, -1 do
        if R then
            R = point_double(R)
            R = point_double(R)
            R = point_double(R)
            R = point_double(R)
        end

        local window = k:rshift(i*4):band(15)
        if window ~= ZERO then
            R = point_add(R, precomputed[window.digits[1]])
        end
    end
    return R
end

function ecc.generatePrivateKey()
    local k = random_big_int(32)
    return k % (N - ONE) + ONE
end

function ecc.getPublicKey(priv_key)
    local Pj = scalar_multiply(priv_key, G)
    return to_affine(Pj)
end

function ecc.getSharedSecret(my_priv_key, their_pub_key)
    if not is_on_curve(their_pub_key) then return nil end
    local shared_point = scalar_multiply(my_priv_key, their_pub_key)
    if not shared_point then return nil end
    local affine = to_affine(shared_point)
    return affine.x
end

function ecc.sign(priv_key, message)
    local z = hash_message(message)

    local k = generate_k(priv_key, z)
    local R_proj = scalar_multiply(k, G)
    R_affine = to_affine(R_proj)
    local r = R_affine.x % N
    local k_inv = modular_inverse(k, N)
    local term1 = (r * priv_key) % N
    local term2 = (z + term1) % N
    local s = (k_inv * term2) % N

    return {r = r, s = s}
end

function ecc.verify(pub_key, message, sign)
    if not is_on_curve(pub_key) then
        return {result = false, message = "Invalid public key"}
    end
    local z = hash_message(message)

    if sign.r < ONE or sign.r > N - ONE or sign.s < ONE or sign.s > N - ONE then
        return {result = false, message = "Invalid r or s range"}
    end

    local w = modular_inverse(sign.s, N)
    if not w then return {result = false, message = "Cannot calculate s inverse"} end
    local u1 = (z * w) % N
    local u2 = (sign.r * w) % N
    local P1 = scalar_multiply(u1, G)
    os.sleep(0)
    local P_pub_proj = {x = pub_key.x, y = pub_key.y, z = ONE}
    local P2 = scalar_multiply(u2, P_pub_proj)
    os.sleep(0)
    local R_prime_proj = point_add(P1, P2)

    if not R_prime_proj then
        return {result = false, message = "Point addition resulted in infinity"}
    end

    local R_prime_affine = to_affine(R_prime_proj)

    local r_prime = R_prime_affine.x % N
    print("R de verifiacion: ", r_prime)

    return {result = sign.r == r_prime, message = "Signature verification result"}
end

return ecc