local DMW = DMW
DMW.Enemies, DMW.Units, DMW.Friends = {}, {}, {}
DMW.Friends.Units = {}
DMW.Friends.Tanks = {}
local Enemies, Units, Friends = DMW.Enemies, DMW.Units, DMW.Friends.Units
local Unit, LocalPlayer = DMW.Classes.Unit, DMW.Classes.LocalPlayer

local function RemoveUnit(Pointer)
    if Units[Pointer] ~= nil then
        Units[Pointer] = nil
    end
    if DMW.Tables.TTD[Pointer] ~= nil then
        DMW.Tables.TTD[Pointer] = nil
    end
    if DMW.Tables.AuraCache[Pointer] ~= nil then
        DMW.Tables.AuraCache[Pointer] = nil
    end
end

local function SortEnemies()
    local LowestHealth, HighestHealth, HealthNorm, EnemyScore, RaidTarget
    for _, v in pairs(Enemies) do
        if not LowestHealth or v.Health < LowestHealth then
            LowestHealth = v.Health
        end
        if not HighestHealth or v.Health > HighestHealth then
            HighestHealth = v.Health
        end
    end
    for _, v in pairs(Enemies) do
        HealthNorm = (10 - 1) / (HighestHealth - LowestHealth) * (v.Health - HighestHealth) + 10
        if HealthNorm ~= HealthNorm or tostring(HealthNorm) == tostring(0 / 0) then
            HealthNorm = 0
        end
        EnemyScore = HealthNorm
        if v.TTD > 1.5 then
            EnemyScore = EnemyScore + 5
        end
        RaidTarget = GetRaidTargetIndex(v.Pointer)
        if RaidTarget ~= nil then
            EnemyScore = EnemyScore + RaidTarget * 3
            if RaidTarget == 8 then
                EnemyScore = EnemyScore + 5
            end
        end
        v.EnemyScore = EnemyScore
    end
    if #Enemies > 1 then
        table.sort(
            Enemies,
            function(x, y)
                return x.EnemyScore > y.EnemyScore
            end
        )
        table.sort(
            Enemies,
            function(x)
                if UnitIsUnit(x.Pointer, "target") then
                    return true
                else
                    return false
                end
            end
        )
    end
end

local function HandleFriends()
    table.wipe(DMW.Friends.Tanks)
    if #Friends > 1 then
        table.sort(
            Friends,
            function(x, y)
                return x.HP < y.HP
            end
        )
    end
    for _, Unit in pairs(Friends) do
        Unit.Role = UnitGroupRolesAssigned(Unit.Pointer)
        if Unit.Role == "TANK" then
            table.insert(DMW.Friends.Tanks, Unit)
        end
    end
end

local function UpdateUnits()
    table.wipe(Enemies)
    table.wipe(Friends)
    DMW.Player.Target = nil
    DMW.Player.Mouseover = nil
    DMW.Player.Pet = nil

    for Pointer, Unit in pairs(Units) do
        if not Unit.NextUpdate or Unit.NextUpdate < DMW.Time then
            Unit:Update()
        end
        if not DMW.Player.Target and UnitIsUnit(Pointer, "target") then
            DMW.Player.Target = Unit
        elseif not DMW.Player.Mouseover and UnitIsUnit(Pointer, "mouseover") then
            DMW.Player.Mouseover = Unit
        elseif DMW.Player.PetActive and not DMW.Player.Pet and UnitIsUnit(Pointer, "pet") then
            DMW.Player.Pet = Unit
        end
        if Unit.ValidEnemy then
            table.insert(Enemies, Unit)
        end
        if Unit.Player and UnitIsUnit(Pointer, "player") then
            table.insert(Friends, Unit)
        elseif DMW.Player.InGroup and Unit.Player and Unit.LoS and (UnitInRaid(Pointer) or UnitInParty(Pointer)) then
            table.insert(Friends, Unit)
        end
    end
    SortEnemies()
    HandleFriends()
end

function DMW.UpdateOM()
    local _, updated, added, removed = GetObjectCount(true)
    if updated and #removed > 0 then
        for _, v in pairs(removed) do
            RemoveUnit(v)
        end
    end
    if updated and #added > 0 then
        for _, v in pairs(added) do
            if ObjectIsUnit(v) then
                Units[v] = Unit(v)
            end
        end
    end
    DMW.Player:Update()
    UpdateUnits()
end
