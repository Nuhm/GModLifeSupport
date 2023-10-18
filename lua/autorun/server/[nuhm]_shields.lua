-- Configuration
local debugMode = false;

-- Delays
local armorRegenDelay = 10 -- Time in seconds before regeneration starts

-- Regen Rate
local defaultRegenRate = 1
local playerArmorRegenRate = {} -- Initial amount of armor regenerated per second
local maxArmorRegenRate = 10    -- Maximum regeneration rate

-- Regen Increments
local regenRateIncrement = 1             -- Rate at which the regeneration rate increases
local armorRegenRateIncreaseInterval = 5 -- Time in seconds between rate increases

-- Data Stores
local playerArmorData = {}
local prevPlayerArmorRegenRate = {};

if debugMode then
    print("[nuhm] Shields has been loaded!")
end

-- Function to start armor regeneration for a player
local function startArmorRegeneration(ply)
    -- Check if the player hasn't taken damage for the specified time
    if CurTime() - ply:GetNWFloat("LastDamageTime", 0) >= armorRegenDelay then
        local currentArmor = ply:Armor()
        local maxArmor = playerArmorData[ply] or 100 -- Use the stored max armor value or a default (e.g., 100)

        -- Calculate the time since the last regeneration increase
        local timeSinceLastArmorRegen = CurTime() - ply:GetNWFloat("LastRegenIncreaseTime", 0)

        -- If it's time to increase the regeneration rate
        if timeSinceLastArmorRegen >= armorRegenRateIncreaseInterval then
            -- Increase the regeneration rate
            playerArmorRegenRate[ply] = math.min(maxArmorRegenRate, prevPlayerArmorRegenRate[ply] + regenRateIncrement)
            prevPlayerRegenRate[ply] = playerArmorRegenRate[ply]

            -- Store the current time for the next increase
            ply:SetNWFloat("LastRegenIncreaseTime", CurTime())
        end

        local newArmor = math.min(maxArmor, currentArmor + playerArmorRegenRate[ply])

        -- Log a message in the console when a player is being healed
        if newArmor > currentArmor then
            if debugMode then
                print(ply:Nick() ..
                    " is being regenerated. Armor increased from " ..
                    currentArmor .. " to " .. newArmor .. " / " .. maxArmor)
            end
            ply:SetArmor(newArmor)
        end


        -- Store the current regeneration time for incremental increase
        ply:SetNWFloat("LastRegenTime", CurTime())
    end
end

-- Create a function to restore all players' armor
local function RegenAllArmor(ply)
    for _, player in pairs(player.GetAll()) do
        local maxArmor = playerArmorData[player] or 100 -- Use the stored max armor value or a default (e.g., 100)
        player:SetArmor(maxArmor)
        player:PrintMessage(HUD_PRINTTALK, "Your armor has been fully restored by an administrator.")
    end
end

if debugMode then
    print("[nuhm] Shields commands have been loaded!")
end

-- Function to set up hooks
local function SetupHooks()
    -- Hook to call the custom function when a player spawns
    hook.Add("PlayerSpawn", "StorePlayerArmorOnSpawn", function(ply)
        -- Added timer to avoid getting armor values before they're set
        timer.Simple(1, function()
            if IsValid(ply) then
                local armorLevel = ply:Armor()
                if armorLevel < 100 then
                    armorLevel = 100 -- Set it to 100 if it's less than 100
                end
                playerArmorData[ply] = armorLevel
            end
        end)
    end)

    -- Hook to track player damage
    hook.Add("PlayerHurt", "TrackLastDamageTime", function(ply)
        ply:SetNWFloat("LastDamageTime", CurTime())
        prevPlayerRegenRate[ply] = defaultRegenRate
    end)

    -- Hook to start regeneration on player spawn
    hook.Add("PlayerSpawn", "InitializeArmorRegenTimer", function(ply)
        timer.Create("ArmorRegenTimer_" .. ply:EntIndex(), 1, 0, function()
            startArmorRegeneration(ply)
        end)
    end)

    -- Register the chat command
    hook.Add("PlayerSay", "RestoreAllArmorCommand", function(ply, text, team)
        if text:lower() == "/regenall" then
            if ply:IsSuperAdmin() then
                RegenAllArmor(ply) -- Call the function to restore armor
                return ""
            else
                return ""
            end
        end
    end)

    if debugMode then
        print("[nuhm] Shields hooks have been added!")
    end
end

-- Call the function to set up hooks
SetupHooks()
