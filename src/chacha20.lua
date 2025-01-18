local sha = require("idar-cl.sha")

local chacha = {}

local constFields = {"a", "b", "c", "d"}
local oMatrix = nil

local function add(block1, block2)
    local result = {}
    for i = 1, #block1 do
        result[i] = string.char((string.byte(block1, i) + string.byte(block2, i)) % 0xFF)
    end
    return table.concat(result)
end

local function rotate(block, bits)
    local result = {}
    for i = 1, #block do
        result[i] = string.char(bit.blshift(string.byte(block, i), bits) % 0xFF)
    end
    return table.concat(result)
end

local function xor(block1, block2)
    local result = {}
    for i = 1, #block1 do
        result[i] = string.char(bit.bxor(string.byte(block1, i), string.byte(block2, i)))
    end
    return table.concat(result)
end

local function split(input, row, startCol, endCol, stream)
    stream[row] = stream[row] or {}

    for c = startCol, endCol do
        stream[row][c] = input:sub(1, 4)
        input = input:sub(5)
    end

    return input
end

local function fromMatrix(matrix)
    local block = {}
    for i = 1, 4 do
        for j = 1, 4 do
            block[#block + 1] = matrix[i][j]
        end
    end

    return table.concat(block)
end

local function sortCols(stream)
    local sortStream = {}
    for _, chara in ipairs(constFields) do
        sortStream[chara] = {}
        for j = 1, 4 do
            sortStream[chara][j] = stream[chara][j]
        end
    end

    return sortStream
end

local function sortDiagonal(stream)
    local sortStream = {}

    for i, chara in ipairs(constFields) do
        sortStream[chara] = {}
        for j = 1, 4 do
            sortStream[chara][j] = stream[chara][((j + i - 2) % 4) + 1]
        end
    end

    return sortStream
end

local function generateStream(key, position, nonce)
    local stream = {a = {"expa", "nd 3", "2-by", "te k"}}
    key = split(key, "b", 1, 4, stream)
    split(key, "c", 1, 4, stream)
    split(position, "d", 1, 1, stream)
    split(nonce, "d", 2, 4, stream)

    return stream
end

local function sortMatrix(stream, mode)
    if mode == 1 then
        stream = sortCols(stream)
    else
        stream = sortDiagonal(stream)
    end

    return stream
end

local function quarterRound(stream)
    stream.b = add(stream.a, stream.b)
    stream.a = xor(stream.a, stream.d)
    stream.d = rotate(stream.d, 16)
    stream.d = add(stream.d, stream.c)
    stream.c = xor(stream.c, stream.b)
    stream.b = rotate(stream.b, 12)
    stream.b = add(stream.b, stream.a)
    stream.a = xor(stream.a, stream.d)
    stream.d = rotate(stream.d, 8)
    stream.d = add(stream.d, stream.c)
    stream.c = xor(stream.c, stream.b)
    stream.b = rotate(stream.b, 7)
end

local function generateKeySequence(stream)
    if not oMatrix then return end

    for currentRound = 1, 20 do
        stream = sortMatrix(stream, currentRound % 2)
        local round = {}
        for quarter = 1, 4 do
            table.insert(round, function ()
                local quarterTable = {a = stream["a"][quarter], b = stream["b"][quarter], c = stream["c"][quarter], d = stream["d"][quarter]}
                quarterRound(quarterTable)

                for key, value in pairs(quarterTable) do
                    stream[key][quarter] = value
                end
            end)
        end

        parallel.waitForAll(table.unpack(round))
    end

    local keySequence = {}

    for i = 1, 4 do
        keySequence[i] = {}
        for j = 1, 4 do
            keySequence[i][j] = add(stream[constFields[i]][j], oMatrix[constFields[i]][j])
        end
    end

    return fromMatrix(keySequence)
end

local function operate(message, secret, nonce)
    if not nonce or not secret or not message then return end
    if #nonce < 12 then return end

    secret = sha.sha256(secret)

    local fillLength = (64 - (#message % 64)) % 64
    message = message .. string.rep(string.char(fillLength), fillLength)

    local blocks = {}
    for i = 1, #message, 64 do
        table.insert(blocks, message:sub(i, i + 63))
    end

    local encryptMessage = ""

    for position, block in ipairs(blocks) do
        local stream = generateStream(secret, string.rep("\0", 3) .. string.char(position), nonce)
        oMatrix = stream

        local secuenceKey = generateKeySequence(stream)

        encryptMessage = encryptMessage .. xor(block, secuenceKey)
    end

    return encryptMessage
end

function chacha.encrypt(message, secret, nonce)
    return operate(message, secret, nonce)
end

function chacha.decrypt(message, secret, nonce)
    local rawMessage = operate(message, secret, nonce)
    if not rawMessage then return end

    local padValue = string.byte(rawMessage:sub(-1))
    return rawMessage:sub(1, -padValue - 1)
end

function chacha.generateNonce()
    local nonce = {}
    for i = 1, 12 do
        nonce[i] = string.char(math.random(0, 255))
    end
    return table.concat(nonce)
end

return chacha
