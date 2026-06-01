-- StudioAgentPlugin.lua
-- Plugin Roblox Studio: menerima perintah dari ArchitectAI dan mengeksekusi di Studio
-- Install: taruh di ~/Documents/Roblox/Plugins/ atau drag ke Plugin folder di Studio

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- =====================================================================
-- KONFIGURASI - Ubah URL ini sesuai domain Replit Anda
-- =====================================================================
local CONFIG = {
    API_BASE_URL = "https://d7f17005-f514-48b2-9845-0a4627afbfa2-00-24gpl3i4vgjeh.pike.replit.dev/api",
    POLL_INTERVAL = 3,   -- detik antar polling
    SESSION_ID = "",     -- akan diisi otomatis
    ENABLED = true,
}

-- =====================================================================
-- PLUGIN TOOLBAR
-- =====================================================================
local toolbar = plugin:CreateToolbar("Roblox AI Agent")

local connectButton = toolbar:CreateButton(
    "Connect",
    "Hubungkan ke ArchitectAI",
    "rbxassetid://0"
)

local pollButton = toolbar:CreateButton(
    "Poll Commands",
    "Ambil perintah dari ArchitectAI",
    "rbxassetid://0"
)

local statusButton = toolbar:CreateButton(
    "Status",
    "Lihat status koneksi",
    "rbxassetid://0"
)

-- =====================================================================
-- HELPER FUNCTIONS
-- =====================================================================
local function log(msg)
    print("[StudioAgent] " .. tostring(msg))
end

local function getService(targetName)
    local serviceMap = {
        ["ServerScriptService"] = ServerScriptService,
        ["ReplicatedStorage"] = ReplicatedStorage,
        ["StarterPlayer"] = StarterPlayer,
        ["Workspace"] = workspace,
    }
    return serviceMap[targetName] or ServerScriptService
end

local function httpGet(endpoint)
    local url = CONFIG.API_BASE_URL .. endpoint
    local ok, result = pcall(function()
        return HttpService:GetAsync(url, true)
    end)
    if ok then
        return HttpService:JSONDecode(result)
    else
        log("ERROR GET " .. endpoint .. ": " .. tostring(result))
        return nil
    end
end

local function httpPost(endpoint, data)
    local url = CONFIG.API_BASE_URL .. endpoint
    local body = HttpService:JSONEncode(data)
    local ok, result = pcall(function()
        return HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false)
    end)
    if ok then
        return HttpService:JSONDecode(result)
    else
        log("ERROR POST " .. endpoint .. ": " .. tostring(result))
        return nil
    end
end

-- =====================================================================
-- COMMAND EXECUTORS
-- =====================================================================
local CommandExecutors = {}

function CommandExecutors.create_script(cmd)
    local service = getService(cmd.target or "ServerScriptService")
    local name = cmd.name or "NewScript"
    local content = cmd.content or "-- Script dibuat oleh ArchitectAI\n"

    -- Cek apakah sudah ada
    local existing = service:FindFirstChild(name)
    if existing then
        if existing:IsA("Script") or existing:IsA("ModuleScript") or existing:IsA("LocalScript") then
            existing.Source = content
            log("Updated script: " .. name)
            return { success = true, action = "updated", file = name }
        end
    end

    -- Tentukan tipe script
    local scriptInstance
    local isLocal = string.find(name:lower(), "client") or
                    string.find(name:lower(), "local") or
                    cmd.target == "StarterPlayer"

    if isLocal then
        scriptInstance = Instance.new("LocalScript")
    elseif string.find(name:lower(), "module") then
        scriptInstance = Instance.new("ModuleScript")
    else
        scriptInstance = Instance.new("Script")
    end

    scriptInstance.Name = name:gsub("%.lua$", "")
    scriptInstance.Source = content
    scriptInstance.Parent = service

    log("Created script: " .. name .. " in " .. (cmd.target or "ServerScriptService"))
    return { success = true, action = "created", file = name }
end

function CommandExecutors.modify_script(cmd)
    local service = getService(cmd.target or "ServerScriptService")
    local name = (cmd.name or ""):gsub("%.lua$", "")

    local target = service:FindFirstChild(name, true)
    if not target then
        log("Script tidak ditemukan: " .. name .. ", membuat baru...")
        return CommandExecutors.create_script(cmd)
    end

    if target:IsA("Script") or target:IsA("ModuleScript") or target:IsA("LocalScript") then
        target.Source = cmd.content or target.Source
        log("Modified script: " .. name)
        return { success = true, action = "modified", file = name }
    end

    return { success = false, error = "Target bukan script instance" }
end

function CommandExecutors.create_part(cmd)
    local props = cmd.properties or {}
    local part = Instance.new("Part")
    part.Name = cmd.name or "Part"
    part.Size = Vector3.new(
        props.SizeX or 4,
        props.SizeY or 1,
        props.SizeZ or 4
    )
    part.Position = Vector3.new(
        props.X or 0,
        props.Y or 5,
        props.Z or 0
    )
    if props.Anchored ~= nil then
        part.Anchored = props.Anchored
    else
        part.Anchored = true
    end
    if props.Color then
        part.BrickColor = BrickColor.new(props.Color)
    end
    if props.Material then
        part.Material = Enum.Material[props.Material] or Enum.Material.Plastic
    end
    part.Parent = workspace

    log("Created part: " .. part.Name)
    return { success = true, action = "created_part", name = part.Name }
end

function CommandExecutors.create_model(cmd)
    local model = Instance.new("Model")
    model.Name = cmd.name or "Model"
    model.Parent = workspace

    if cmd.content then
        local ok, err = pcall(function()
            local scriptInstance = Instance.new("Script")
            scriptInstance.Name = "ModelSetup"
            scriptInstance.Source = cmd.content
            scriptInstance.Parent = model
        end)
        if not ok then
            log("Warning: Gagal attach script ke model: " .. tostring(err))
        end
    end

    log("Created model: " .. model.Name)
    return { success = true, action = "created_model", name = model.Name }
end

function CommandExecutors.test_game(cmd)
    log("Test game dipanggil - " .. (cmd.message or ""))
    return {
        success = true,
        action = "test_requested",
        note = "Gunakan Play button di Studio untuk test. Plugin tidak bisa auto-play."
    }
end

function CommandExecutors.report_status(_cmd)
    local scriptCount = #ServerScriptService:GetChildren()
    local repCount = #ReplicatedStorage:GetChildren()
    return {
        success = true,
        action = "status_reported",
        server_scripts = scriptCount,
        replicated_storage = repCount,
    }
end

-- =====================================================================
-- EXECUTE COMMANDS
-- =====================================================================
local function executeCommand(cmd)
    local action = cmd.action or "report_status"
    local executor = CommandExecutors[action]

    if not executor then
        log("Unknown action: " .. action)
        return {
            success = false,
            error = "Action tidak dikenal: " .. action,
        }
    end

    local ok, result = pcall(executor, cmd)
    if not ok then
        log("ERROR executing " .. action .. ": " .. tostring(result))
        return { success = false, error = tostring(result) }
    end
    return result
end

local function executeAllCommands(commands)
    local results = {}
    local filesCreated = {}
    local filesModified = {}
    local errors = {}

    for _, cmd in ipairs(commands) do
        log("Executing: " .. (cmd.action or "?") .. " - " .. (cmd.message or ""))
        local result = executeCommand(cmd)
        table.insert(results, result)

        if result.success then
            if result.action == "created" or result.action == "created_part" or result.action == "created_model" then
                table.insert(filesCreated, result.file or result.name or cmd.name or "unknown")
            elseif result.action == "modified" or result.action == "updated" then
                table.insert(filesModified, result.file or cmd.name or "unknown")
            end
        else
            table.insert(errors, (cmd.name or cmd.action or "?") .. ": " .. (result.error or "unknown error"))
        end
    end

    return {
        files_created = filesCreated,
        files_modified = filesModified,
        errors = errors,
        result_count = #results,
    }
end

-- =====================================================================
-- MAIN POLL LOOP
-- =====================================================================
local function pollAndExecute()
    if CONFIG.SESSION_ID == "" then
        log("SESSION_ID belum diset. Klik Connect dulu.")
        return
    end

    local data = httpGet("/studio/pending-commands?session_id=" .. CONFIG.SESSION_ID)
    if not data then return end

    local commands = data.commands or {}
    if #commands == 0 then
        log("Tidak ada perintah baru.")
        return
    end

    log("Menerima " .. #commands .. " perintah dari ArchitectAI")

    local execResult = executeAllCommands(commands)

    local reportStatus = #execResult.errors == 0 and "success" or "error"
    local actionTaken = "Dieksekusi " .. execResult.result_count .. " perintah"

    local reportPayload = {
        session_id = CONFIG.SESSION_ID,
        status = reportStatus,
        action_taken = actionTaken,
        files_created = execResult.files_created,
        files_modified = execResult.files_modified,
        errors = execResult.errors,
        questions = {},
        next_suggested_action = "Lanjutkan pembangunan game",
    }

    local reportResult = httpPost("/studio/report", reportPayload)
    if reportResult then
        log("Laporan terkirim ke ArchitectAI. Status: " .. reportStatus)
    end
end

-- =====================================================================
-- BUTTON HANDLERS
-- =====================================================================
connectButton.Click:Connect(function()
    local sessionList = httpGet("/agent/sessions")
    if not sessionList or #sessionList == 0 then
        log("Tidak ada sesi aktif. Buat sesi dulu via CMD atau API.")
        return
    end

    local latest = sessionList[1]
    CONFIG.SESSION_ID = latest.id
    log("Terhubung ke sesi: " .. CONFIG.SESSION_ID)
    log("Goal: " .. (latest.goal or ""))
    log("Status: " .. (latest.status or ""))
end)

pollButton.Click:Connect(function()
    log("Polling perintah...")
    pollAndExecute()
end)

statusButton.Click:Connect(function()
    local status = httpGet("/studio/status")
    if status then
        log("=== STATUS ===")
        log("Total sessions: " .. tostring(status.total_sessions))
        log("Running: " .. tostring(status.running))
        log("Waiting Studio: " .. tostring(status.waiting_studio))
        log("Completed: " .. tostring(status.completed))
        log("Session aktif: " .. (CONFIG.SESSION_ID ~= "" and CONFIG.SESSION_ID or "Belum terhubung"))
    end
end)

-- Auto-poll setiap POLL_INTERVAL detik jika sudah terhubung
local pollConnection
local function startAutoPoller()
    if pollConnection then pollConnection:Disconnect() end
    pollConnection = game:GetService("RunService").Heartbeat:Connect(function()
        -- tidak digunakan untuk heartbeat, hanya sebagai timer
    end)

    task.spawn(function()
        while CONFIG.ENABLED do
            task.wait(CONFIG.POLL_INTERVAL)
            if CONFIG.SESSION_ID ~= "" then
                pollAndExecute()
            end
        end
    end)
end

log("StudioAgent Plugin loaded! Klik 'Connect' untuk terhubung ke ArchitectAI.")
log("Pastikan HTTP Requests diaktifkan di Game Settings > Security")
startAutoPoller()
