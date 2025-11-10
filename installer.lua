local BN_DIR = "idar-bn/"
local CL_DIR = "idar-cl/"
local DEPENDENCE_URL = "https://raw.githubusercontent.com/DarThunder/iDar-BigNum/refs/heads/main/installer.lua"
local BASE_URL = "https://raw.githubusercontent.com/DarThunder/iDar-CryptoLib/refs/heads/main/src/"

local MODULES = {
    "aes",
    "rsa",
    "sha",
    "chacha20"
}

if not fs.exists(BN_DIR) then
    print("Resolving dependencies...")
    local ok = shell.run("wget", "run", DEPENDENCE_URL)
    if not ok then
        print("Failed to download BigNum installer.")
        return
    end
end

local function checkInternet()
    local test = http.get(BASE_URL .. "aes.lua")
    if test then
        test.close()
        print("Internet OK.")
        return true
    else
        print("No internet connection detected.")
        return false
    end
end

local function ensureDir(path)
    if not fs.exists(path) then
        fs.makeDir(path)
        print("Directory '" .. path .. "' created.")
    end
end

if not checkInternet() then return end

ensureDir(CL_DIR)

local success = true

print("Downloading modules...")
for _, name in ipairs(MODULES) do
    local url = BASE_URL .. name .. ".lua"
    local dest = CL_DIR .. name .. ".lua"

    print("Installing '" .. name .. ".lua'...")

    local response = http.get(url)
    if not response then
        print("Failed to download: " .. name .. ".lua")
        success = false
    else
        local content = response.readAll()
        response.close()

        local file = fs.open(dest, "w")
        if not file then
            print("Failed to write: " .. dest)
            success = false
        else
            file.write(content)
            file.close()
            print("Installed: " .. name .. ".lua")
        end
    end
end

if success then
    if fs.exists("installer.lua") then
        fs.delete("installer.lua")
    end
    print("iDar CryptoLib installed successfully.")
else
    print("One or more modules failed to install. Existing files were kept for safety.")
end
