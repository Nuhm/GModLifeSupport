-- Configuration
local shieldRegenDelay = 10 -- Time in seconds before regeneration starts
local baseRegenRate = 1 -- Initial amount of shield regenerated per second
local maxRegenRate = 10 -- Maximum regeneration rate

-- Function to start shield regeneration for a player
local function startShieldRegeneration(ply)
    -- Get the player's maximum armor
    local  = ply:GetMaxArmor()

    -- Check if the player hasn't taken damage for the specified time
    if CurTime() - ply:GetNWFloat("LastDamageTime", 0) >= shieldRegenDelay then
        local currentArmor = ply:Armor()

        -- Calculate the new regeneration rate (incremental)
        local newRegenRate = baseRegenRate
        if baseRegenRate < maxRegenRate then
            newRegenRate = baseRegenRate + (CurTime() - ply:GetNWFloat("LastRegenTime", 0))
        end

        local newArmor = math.min(maxArmor, currentArmor + newRegenRate)

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
