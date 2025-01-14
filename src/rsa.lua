local rsa = {}

local function binaryToDecimal(binaryString)
    local decimal = 0
    local length = #binaryString

    for i = 1, length do
        local currentBit = tonumber(binaryString:sub(i, i))

        local power = length - i

        decimal = decimal + currentBit * (2 ^ power)
    end
    return decimal
end

local function generateRandomBits(n)
    local bits = {}

    bits[1] = 1
    bits[n] = 1

    for i = 2, n - 1 do
        bits[i] = math.random(0, 1)
    end

    local bitString = table.concat(bits)
    return binaryToDecimal(bitString)
end

local function millerRabin(n, k, valid)
    local s = 0
    local d = n - 1
    while bit.band(d, 1) == 0 do
        d = bit.rshift(d, 1)
        s = s + 1
    end

    for _ = 1, k do
        local a = math.random(2, n - 2)
        local x = cipher.modExp(a, d, n)
        local isComposite = true
        if x ~= 1 and x ~= n - 1 then
            for _ = 1, s - 1 do
                x = cipher.modExp(x, 2, n)
                if x == n - 1 then
                    isComposite = false
                    break
                end
            end

            if isComposite then
                table.insert(valid, false)
                return
            end
        end
    end

    table.insert(valid, n)
end

local function isDivisibleBy3(n)
    --n = decimalToBinary(n)
    local oddCount, evenCount = 0, 0
    local position = 0

    while n > 0 do
        local currentbit = n % 2
        if bit.band(position, 1) == 0 then
            evenCount = evenCount + currentbit
        else
            oddCount = oddCount + currentbit
        end
        n = bit.rshift(n, 1)
        position = position + 1
    end

    return math.abs(oddCount - evenCount) % 3 == 0
end

local function generatePrime(bits)
    local sample = {}
    local valid = {}
    while #sample < 50 do
        local candidate = generateRandomBits(bits)
        if not isDivisibleBy3(candidate) then
            table.insert(sample, function ()
                --millerRabin(candidate, 60, valid)
            end)
        end
    end
    parallel.waitForAll(table.unpack(sample))
    for _, value in ipairs(valid) do
        if value then
            return value
        end
    end
    return generatePrime(bits)
end

local function gmd(x, y)
    if y == 0 then
        return x
    end
    return gmd(y, x % y)
end
