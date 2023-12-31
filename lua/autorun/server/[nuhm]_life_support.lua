-- Configuration
local debugMode = false;

-- Delays
local storePlayerArmorOnSpawnDelay = 3
local armorRegenDelay = 10  -- Time in seconds before armor regeneration starts
local healthRegenDelay = 15 -- Time in seconds before health regeneration starts

-- Regen Rate
local defaultArmorRegenRate = 1
local defaultHealthRegenRate = 1
local playerArmorRegenRate = {}  -- Initial amount of armor regenerated per second
local playerHealthRegenRate = {} -- Initial amount of health regenerated per second
local maxArmorRegenRate = 10     -- Maximum armor regeneration rate
local maxHealthRegenRate = 10    -- Maximum health regeneration rate

-- Regen Increments
local regenRateIncrement = 1              -- Rate at which the regeneration rate increases
local armorRegenRateIncreaseInterval = 1  -- Time in seconds between armor rate increases
local healthRegenRateIncreaseInterval = 1 -- Time in seconds between health rate increases

-- Data Stores
local playerArmorData = {}
local playerHealthData = {}
local prevPlayerArmorRegenRate = {}
local prevPlayerHealthRegenRate = {}

if debugMode then
    print("[nuhm] Life System has been loaded!")
end

-- Function to start armor regeneration for a player
local function startArmorRegeneration(ply)
    -- Check if the player entity is valid
    if not IsValid(ply) then
        print("[Error] Invalid player entity in startArmorRegeneration function")
        return
    end
    -- Check if the player hasn't taken damage for the specified time
    if CurTime() - ply:GetNWFloat("LastArmorDamageTime", 0) >= armorRegenDelay then
        local currentArmor = ply:Armor()
        local maxArmor = playerArmorData[ply] or 100 -- Use the stored max armor value or a default (e.g., 100)

        -- Calculate the time since the last regeneration increase
        local timeSinceLastArmorRegen = CurTime() - ply:GetNWFloat("LastArmorRegenIncreaseTime", 0)

        -- If it's time to increase the regeneration rate
        if timeSinceLastArmorRegen >= armorRegenRateIncreaseInterval then
            -- Increase the regeneration rate
            if prevPlayerArmorRegenRate[ply] == nil then
                prevPlayerArmorRegenRate[ply] = 0
            end

            playerArmorRegenRate[ply] = math.min(maxArmorRegenRate, prevPlayerArmorRegenRate[ply] + regenRateIncrement)
            prevPlayerArmorRegenRate[ply] = playerArmorRegenRate[ply]

            -- Store the current time for the next increase
            ply:SetNWFloat("LastArmorRegenIncreaseTime", CurTime())

            local newArmor = math.min(maxArmor, currentArmor + playerArmorRegenRate[ply])

            -- Log a message in the console when a player is being healed
            if newArmor > currentArmor then
                if debugMode then
                    print(ply:Nick() ..
                        " is having their armor regenerated. Armor increased from " ..
                        currentArmor .. " to " .. newArmor .. " / " .. maxArmor)
                end
                ply:SetArmor(newArmor)
            end


            -- Store the current regeneration time for incremental increase
            ply:SetNWFloat("LastArmorRegenTime", CurTime())
        end
    end
end

-- Function to start health regeneration for a player
local function startHealthRegeneration(ply)
    -- Check if the player entity is valid
    if not IsValid(ply) then
        print("[Error] Invalid player entity in startHealthRegeneration function")
        return
    end

    -- Check if the player hasn't taken damage to their health for the specified time
    if CurTime() - ply:GetNWFloat("LastHealthDamageTime", 0) >= healthRegenDelay then
        local currentHealth = ply:Health()
        local maxHealth = playerHealthData[ply] or 100 -- Use the stored max health value or a default (e.g., 100)

        -- Calculate the time since the last health regeneration increase
        local timeSinceLastHealthRegen = CurTime() - ply:GetNWFloat("LastHealthRegenIncreaseTime", 0)

        -- If it's time to increase the health regeneration rate
        if timeSinceLastHealthRegen >= healthRegenRateIncreaseInterval then
            if prevPlayerHealthRegenRate[ply] == nil then
                prevPlayerHealthRegenRate[ply] = 0
            end

            -- Increase the health regeneration rate
            playerHealthRegenRate[ply] = math.min(maxHealthRegenRate, prevPlayerHealthRegenRate[ply] + regenRateIncrement)
            prevPlayerHealthRegenRate[ply] = playerHealthRegenRate[ply]

            -- Store the current time for the next increase
            ply:SetNWFloat("LastHealthRegenIncreaseTime", CurTime())

            local newHealth = math.min(maxHealth, currentHealth + playerHealthRegenRate[ply])

            -- Log a message in the console when a player's health is being regenerated
            if newHealth > currentHealth then
                if debugMode then
                    print(ply:Nick() ..
                        " is having their health regenerated. Health increased from " ..
                        currentHealth .. " to " .. newHealth .. " / " .. maxHealth)
                end
                ply:SetHealth(newHealth)
            end

            -- Store the current health regeneration time for incremental increase
            ply:SetNWFloat("LastHealthRegenTime", CurTime())
        end
    end
end

-- Create a function to restore all players' armor
local function RegenAllArmor()
    for _, player in pairs(player.GetAll()) do
        local maxArmor = playerArmorData[player] or 100 -- Use the stored max armor value or a default (e.g., 100)
        player:SetArmor(maxArmor)
        player:PrintMessage(HUD_PRINTTALK, "Your armor has been fully restored by an administrator.")
    end
end

-- Create a function to restore all players' health
local function RegenAllHealth()
    for _, player in pairs(player.GetAll()) do
        local maxHealth = playerHealthData[player] or 100 -- Use the stored max health value or a default (e.g., 100)
        player:SetHealth(maxHealth)
        player:PrintMessage(HUD_PRINTTALK, "Your health has been fully restored by an administrator.")
    end
end

-- Function to remove player data when they disconnect, time out, or crash
local function RemovePlayerData(ply)
    playerArmorData[ply] = nil
    playerHealthData[ply] = nil
    prevPlayerArmorRegenRate[ply] = nil
    prevPlayerHealthRegenRate[ply] = nil
    playerArmorRegenRate[ply] = nil
    playerHealthRegenRate[ply] = nil

    -- Stop the regeneration timers upon player disconnect
    timer.Remove("ArmorRegenTimer_" .. ply:EntIndex())
    timer.Remove("HealthRegenTimer_" .. ply:EntIndex())
end

if debugMode then
    print("[nuhm] Life System commands have been loaded!")
end

-- Function to set up hooks
local function SetupHooks()
    -- Hook to call the function when a player disconnects
    hook.Add("PlayerDisconnected", "RemovePlayerDataOnDisconnect", function(ply)
        RemovePlayerData(ply)
    end)

    -- Hook to call the function when a player initial spawns
    hook.Add("PlayerInitialSpawn", "RemovePlayerDataOnSpawn", function(ply)
        RemovePlayerData(ply)
    end)

    -- Hook to call the custom function when a player spawns
    hook.Add("PlayerSpawn", "StorePlayerArmorOnSpawn", function(ply)
        -- Added timer to avoid getting armor values before they're set
        timer.Simple(storePlayerArmorOnSpawnDelay, function()
            if IsValid(ply) then
                local armorLevel = ply:Armor()
                if armorLevel < 100 then
                    armorLevel = 100 -- Set it to 100 if it's less than 100
                end
                playerArmorData[ply] = armorLevel

                local healthLevel = ply:Health()
                if healthLevel < 100 then
                    healthLevel = 100 -- Set it to 100 if it's less than 100
                end
                playerHealthData[ply] = healthLevel
            else
                print("[Error] Invalid player entity in StorePlayerArmorOnSpawn hook")
            end
        end)
    end)

    -- Hook to track player damage
    hook.Add("PlayerHurt", "TrackLastDamageTime", function(ply)
        -- Check if the damage is to their health
        if ply:Health() < ply:GetMaxHealth() then
            ply:SetNWFloat("LastHealthDamageTime", CurTime())
            prevPlayerHealthRegenRate[ply] = defaultHealthRegenRate
        end
        -- Check if the damage is to their armor
        if ply:Armor() < 100 then
            ply:SetNWFloat("LastArmorDamageTime", CurTime())
            prevPlayerArmorRegenRate[ply] = defaultArmorRegenRate
        end
    end, 0)

    -- Hook to start regeneration on player spawn
    hook.Add("PlayerSpawn", "InitializeRegenTimers", function(ply)
        timer.Create("ArmorRegenTimer_" .. ply:EntIndex(), 1, 0, function()
            startArmorRegeneration(ply)
        end)

        timer.Create("HealthRegenTimer_" .. ply:EntIndex(), 1, 0, function()
            startHealthRegeneration(ply)
        end)
    end)

    -- Register the chat command to restore armor
    hook.Add("PlayerSay", "RestoreAllArmorCommand", function(ply, text, team)
        if text:lower() == "/regenallarmor" then
            if ply:IsSuperAdmin() then
                RegenAllArmor(ply) -- Call the function to restore armor
                return ""
            else
                return ""
            end
        end
    end)

    -- Register the chat command to restore health
    hook.Add("PlayerSay", "RestoreAllHealthCommand", function(ply, text, team)
        if text:lower() == "/regenallhealth" then
            if ply:IsSuperAdmin() then
                RegenAllHealth(ply) -- Call the function to restore health
                return ""
            else
                return ""
            end
        end
    end)

    if debugMode then
        print("[nuhm] Life System hooks have been added!")
    end
end

-- Call the function to set up hooks
SetupHooks()
