-- LocalizationSystem.lua
-- Bilingual support: English (default) and Indonesian (auto-detected by locale)

local LocalizationSystem = {}

local Strings = {
    EN = {
        -- HUD
        HUD_HEALTH = "Health",
        HUD_MANA = "Mana",
        HUD_NO_MANA = "No Mana Core Equipped",
        HUD_LIMB_HEALTHY = "Healthy",
        HUD_LIMB_INJURED = "Injured",
        HUD_LIMB_DESTROYED = "Destroyed",

        -- Inventory
        INV_TITLE = "Storage & Gear",
        INV_WEIGHT = "Weight",
        INV_CAPACITY = "Capacity",
        INV_FULL = "Inventory Full!",
        INV_CLOSE = "Close",

        -- Map
        MAP_TITLE_LOBBY = "Tactical Map: O'Neill Spaceship Lobby",
        MAP_TITLE_KALIMANTAN = "Tactical Map: Kalimantan Combat Zone",
        MAP_SAFE_ZONE = "LOCATION: Safe Zone — Century-Class Orbital Habitat",
        MAP_COMBAT_ZONE = "LOCATION: Combat Zone — Kalimantan Grid (1330km × 960km)",
        MAP_EXTRACT_ALPHA = "Alpha Extraction Zone: Central Grid (0, 0)",
        MAP_WEATHER_ADVISORY = "WEATHER ADVISORY: Monitoring for Seasonal Shifts and Meteor Strikes.",
        MAP_GEAR_WARNING = "WARNING: Ensure gear loadout does not exceed 70kg before entering portal.",
        MAP_POI_QM = "Quartermaster Riggs (Weapons/Armor) — East Wing",
        MAP_POI_APATH = "Apothecary Vael (Magic/Consumables) — West Wing",
        MAP_POI_PORTAL = "Fantasy Portal Domain — North Hangar",
        MAP_POI_STASH = "Player Stash / Extraction Deposit — South Hangar",
        MAP_TOPOGRAPHY = "TOPOGRAPHY: Proceed with extreme caution. Hostile ecosystem detected.",
        MAP_LOADING = "Loading topographical data...",
        MAP_STATUS = "Status",

        -- Market
        MARKET_TITLE = "Flea Market (Player-to-Player)",
        MARKET_SEARCH = "Search items...",
        MARKET_BUY = "Buy",
        MARKET_SELL = "Sell",
        MARKET_PRICE = "Price",
        MARKET_CATEGORIES = {"All", "Weapons", "Armor", "Loot", "Consumables"},
        MARKET_PURCHASE_SUCCESS = "Item purchased!",
        MARKET_PURCHASE_FAIL = "Purchase failed.",

        -- Combat
        COMBAT_KILLED = "Eliminated",
        COMBAT_REVIVE = "Revive",
        COMBAT_EXTRACT = "Extraction Successful!",

        -- Interaction
        ACT_PICKUP = "Pick Up",
        ACT_OPEN = "Open",
        ACT_EXAMINE = "Examine",
        ACT_EXTRACT = "Extract",

        -- Seasons
        SEASON_SPRING = "Spring",
        SEASON_DRY = "Dry Season",
        SEASON_RAIN = "Rainy Season",
        SEASON_WINTER = "Winter",
        SEASON_CHANGED = "Season has changed:",

        -- Meteor
        METEOR_WARNING = "METEOR INCOMING!",
        METEOR_DANGER = "Seek cover immediately!",

        -- Menus
        MENU_SETTINGS = "Settings",
        MENU_QUIT = "Quit Game",

        -- Mobile buttons
        MOBILE_BAG = "Bag",
        MOBILE_MARKET = "Market",
        MOBILE_MAP = "Map",
        MOBILE_SHOP = "Shop",
        MOBILE_SET = "Set",

        -- Biome labels
        BIOME_LOBBY = "Spaceship Lobby",
        BIOME_TROPICAL = "Tropical Forest",
        BIOME_MOUNTAIN = "Mountain Range",
        BIOME_SWAMP = "Swamp",
        BIOME_COAST = "Coastline",
    },

    ID = {
        -- HUD
        HUD_HEALTH = "Kesehatan",
        HUD_MANA = "Mana",
        HUD_NO_MANA = "Tidak Ada Inti Mana Terpasang",
        HUD_LIMB_HEALTHY = "Sehat",
        HUD_LIMB_INJURED = "Terluka",
        HUD_LIMB_DESTROYED = "Hancur",

        -- Inventory
        INV_TITLE = "Penyimpanan & Perlengkapan",
        INV_WEIGHT = "Berat",
        INV_CAPACITY = "Kapasitas",
        INV_FULL = "Inventori Penuh!",
        INV_CLOSE = "Tutup",

        -- Map
        MAP_TITLE_LOBBY = "Peta Taktis: Lobby Pesawat Luar Angkasa",
        MAP_TITLE_KALIMANTAN = "Peta Taktis: Zona Tempur Kalimantan",
        MAP_SAFE_ZONE = "LOKASI: Zona Aman — Habitat Orbital Kelas Abad",
        MAP_COMBAT_ZONE = "LOKASI: Zona Tempur — Grid Kalimantan (1330km × 960km)",
        MAP_EXTRACT_ALPHA = "Zona Ekstraksi Alpha: Pusat Grid (0, 0)",
        MAP_WEATHER_ADVISORY = "PERINGATAN CUACA: Memantau Perubahan Musim dan Hujan Meteor.",
        MAP_GEAR_WARNING = "PERINGATAN: Pastikan beban perlengkapan tidak melebihi 70kg sebelum masuk portal.",
        MAP_POI_QM = "Quartermaster Riggs (Senjata/Baju Besi) — Sayap Timur",
        MAP_POI_APATH = "Apoteker Vael (Sihir/Konsumabel) — Sayap Barat",
        MAP_POI_PORTAL = "Domain Portal Fantasi — Hangar Utara",
        MAP_POI_STASH = "Penyimpanan Pemain / Deposit Ekstraksi — Hangar Selatan",
        MAP_TOPOGRAPHY = "TOPOGRAFI: Lanjutkan dengan sangat hati-hati. Ekosistem berbahaya terdeteksi.",
        MAP_LOADING = "Memuat data topografi...",
        MAP_STATUS = "Status",

        -- Market
        MARKET_TITLE = "Pasar Loak (Antar Pemain)",
        MARKET_SEARCH = "Cari item...",
        MARKET_BUY = "Beli",
        MARKET_SELL = "Jual",
        MARKET_PRICE = "Harga",
        MARKET_CATEGORIES = {"Semua", "Senjata", "Baju Besi", "Barang Rampasan", "Konsumabel"},
        MARKET_PURCHASE_SUCCESS = "Item berhasil dibeli!",
        MARKET_PURCHASE_FAIL = "Pembelian gagal.",

        -- Combat
        COMBAT_KILLED = "Dieliminasi",
        COMBAT_REVIVE = "Hidupkan Kembali",
        COMBAT_EXTRACT = "Ekstraksi Berhasil!",

        -- Interaction
        ACT_PICKUP = "Ambil",
        ACT_OPEN = "Buka",
        ACT_EXAMINE = "Periksa",
        ACT_EXTRACT = "Ekstrak",

        -- Seasons
        SEASON_SPRING = "Musim Semi",
        SEASON_DRY = "Musim Kemarau",
        SEASON_RAIN = "Musim Hujan",
        SEASON_WINTER = "Musim Dingin",
        SEASON_CHANGED = "Musim telah berganti:",

        -- Meteor
        METEOR_WARNING = "METEOR DATANG!",
        METEOR_DANGER = "Segera cari perlindungan!",

        -- Menus
        MENU_SETTINGS = "Pengaturan",
        MENU_QUIT = "Keluar Game",

        -- Mobile buttons
        MOBILE_BAG = "Tas",
        MOBILE_MARKET = "Pasar",
        MOBILE_MAP = "Peta",
        MOBILE_SHOP = "Toko",
        MOBILE_SET = "Set",

        -- Biome labels
        BIOME_LOBBY = "Lobby Pesawat",
        BIOME_TROPICAL = "Hutan Tropis",
        BIOME_MOUNTAIN = "Pegunungan",
        BIOME_SWAMP = "Rawa",
        BIOME_COAST = "Pantai",
    }
}

local currentLang = "EN"

-- Detect language from Roblox locale
local function DetectLanguage()
    local success, locale = pcall(function()
        return game:GetService("LocalizationService").RobloxLocaleId
    end)
    if success and locale then
        if locale:sub(1, 2):lower() == "id" then
            return "ID"
        end
    end
    return "EN"
end

function LocalizationSystem.Init()
    currentLang = DetectLanguage()
end

function LocalizationSystem.SetLanguage(lang)
    if Strings[lang] then
        currentLang = lang
    end
end

function LocalizationSystem.GetLanguage()
    return currentLang
end

function LocalizationSystem.Get(key)
    local langTable = Strings[currentLang] or Strings["EN"]
    local fallback = Strings["EN"]
    return langTable[key] or fallback[key] or ("[" .. tostring(key) .. "]")
end

-- Shortcut
LocalizationSystem.T = LocalizationSystem.Get

return LocalizationSystem
