-- Configuration
local shieldRegenDelay = 10 -- Time in seconds before regeneration starts
local regenRate = 1 -- Initial amount of shield regenerated per second
local maxRegenRate = 10 -- Maximum regeneration rate
local regenRateIncrement = 1 -- Rate at which the regeneration rate increases
local regenRateIncreaseInterval = 5 -- Time in seconds between rate increases
local prevRegenRate = 0;

-- Function to start shield regeneration for a player
local function startShieldRegeneration(ply)
    -- Get the player's maximum armor
    local maxArmor = ply:GetMaxArmor()

    -- Check if the player hasn't taken damage for the specified time
    if CurTime() - ply:GetNWFloat("LastDamageTime", 0) >= shieldRegenDelay then
        local currentArmor = ply:Armor()

        -- Calculate the time since the last regeneration increase
        local timeSinceLastIncrease = CurTime() - ply:GetNWFloat("LastRegenIncreaseTime", 0)

        -- If it's time to increase the regeneration rate
        if timeSinceLastIncrease >= regenRateIncreaseInterval then
            -- Increase the regeneration rate
            regenRate = math.min(maxRegenRate, prevRegenRate + regenRateIncrement)
            prevRegenRate = regenRate

            -- Store the current time for the next increase
            ply:SetNWFloat("LastRegenIncreaseTime", CurTime())
        end

        local newArmor = math.min(maxArmor, currentArmor + regenRate)

        -- Log a message in the console when a player is being healed
        if newArmor > currentArmor then
            print(ply:Nick() .. " is being healed. Armor increased from " .. currentArmor .. " to " .. newArmor .. " / " .. maxArmor)
            ply:SetArmor(newArmor)
        end

        -- Store the current regeneration time for incremental increase
        ply:SetNWFloat("LastRegenTime", CurTime())
    end
end

-- Hook to track player damage
hook.Add("PlayerHurt", "TrackLastDamageTime", function(ply)
    ply:SetNWFloat("LastDamageTime", CurTime())
end)

-- Hook to start regeneration on player spawn
hook.Add("PlayerSpawn", "InitializeShieldRegenTimer", function(ply)
    timer.Create("ShieldRegenTimer_" .. ply:EntIndex(), 1, 0, function()
        startShieldRegeneration(ply)
    end)
end)

-- Create a function to restore all players' armor
local function RegenAllArmor(ply)
    for _, player in pairs(player.GetAll()) do
        local maxArmor = player:GetMaxArmor()
        player:SetArmor(maxArmor)
        player:PrintMessage(HUD_PRINTTALK, "Your armor has been fully restored by an administrator.")
    end
end

-- Register the chat command
hook.Add("PlayerSay", "RestoreAllArmorCommand", function(ply, text, team)
    if text:lower() == "/regenall" then
        if ply:IsSuperAdmin() then
            RegenAllArmor(ply) -- Call the function to restore armor
            return ""
        end
    end
end)