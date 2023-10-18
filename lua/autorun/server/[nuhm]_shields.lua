-- Configuration
local debugMode = false;
local shieldRegenDelay = 10         -- Time in seconds before regeneration starts
local defaultRegenRate = 1
local playerRegenRate = {}          -- Initial amount of shield regenerated per second
local maxRegenRate = 10             -- Maximum regeneration rate
local regenRateIncrement = 1        -- Rate at which the regeneration rate increases
local regenRateIncreaseInterval = 5 -- Time in seconds between rate increases
local prevPlayerRegenRate = {};
local playerArmorData = {}

if debugMode then
    print("[nuhm] Shields has been loaded!")
end

-- Function to start shield regeneration for a player
local function startShieldRegeneration(ply)
    -- Check if the player hasn't taken damage for the specified time
    if CurTime() - ply:GetNWFloat("LastDamageTime", 0) >= shieldRegenDelay then
        local currentArmor = ply:Armor()
        local maxArmor = playerArmorData[ply] or 100 -- Use the stored max armor value or a default (e.g., 100)

        -- Calculate the time since the last regeneration increase
        local timeSinceLastIncrease = CurTime() - ply:GetNWFloat("LastRegenIncreaseTime", 0)

        -- If it's time to increase the regeneration rate
        if timeSinceLastIncrease >= regenRateIncreaseInterval then
            -- Increase the regeneration rate
            playerRegenRate[ply] = math.min(maxRegenRate, prevPlayerRegenRate[ply] + regenRateIncrement)
            prevPlayerRegenRate[ply] = playerRegenRate[ply]

            -- Store the current time for the next increase
            ply:SetNWFloat("LastRegenIncreaseTime", CurTime())
        end

        local newArmor = math.min(maxArmor, currentArmor + playerRegenRate[ply])


        -- Log a message in the console when a player is being healed
        if newArmor > currentArmor then
            if debugMode then
                print(ply:Nick() ..
                    " is being healed. Armor increased from " .. currentArmor .. " to " .. newArmor .. " / " .. maxArmor)
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
    hook.Add("PlayerSpawn", "InitializeShieldRegenTimer", function(ply)
        timer.Create("ShieldRegenTimer_" .. ply:EntIndex(), 1, 0, function()
            startShieldRegeneration(ply)
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
