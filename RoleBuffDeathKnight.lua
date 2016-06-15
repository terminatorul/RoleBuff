local mod = RoleBuffAddOn;

local checkDeathKnightPresence, checkDeathKnightDualWielding, checkDeathKnightGhoul = true, true, false;

local bloodPresenceIndex, frostPresenceIndex, UnholyPresenceIndex = 1, 2, 3;
local bloodTabIndex, frostTabIndex, unholyTabIndex = 1, 2, 3;

local bladeBarrierTalentIndex = 3;
local toughnessTalentIndex = 3;
local anticipationTalentIndex = 3;
local threatOfThassarianTalentIndex = 22;
local masterOfGhoulsTalentIndex = 20;

local bladeBarrierRank, anticipationRank, toughnessRank = 0, 0, 0;
local hasTankTalentsInvested = false;
local hasFrostPresence = false;
local hasThreatOfThassarian = false;
local hasMasterOfGhouls = false;

local presenceIndex = 0;
local RoleBuff_DeathKnightAttacked, RoleBuff_DeathKnightAttacking = false, false;

local function checkTankTalentsInvestedDeathKnight()
    local name, iconPath, tier, column, currentRank, maxRank = GetTalentInfo(bloodTabIndex, bladeBarrierTalentIndex);
    if name ~= nil
    then
	bladebarrierRank = currentRank;
    end

    name, iconPath, tier, column, currentRank, maxRank = GetTalentInfo(frostTabIndex, toughnessTalentIndex);
    if name ~= nil
    then
	toughnessRank = currentRank;
    end

    name, iconPath, tier, column, currentRank, maxRank = GetTalentInfo(unholyTabIndex, anticipationTalentIndex);
    if name ~= nil
    then
	anticipationRank = currentRank
    end

    if bladeBarrierRank + toughnessRank + anticipationRank > 5
    then
	return true;
    else
	local bloodTabPoints, frostTabPoints, unholyTabPoints = 0, 0, 0;
	local tabName, tabPoints = mod:CountTalentsInTree(bloodTabIndex);

	if tabName ~= nil
	then
	    bloodTabPoints = tabPoints;
	end

	tabName, tabPoints = mod:CountTalentsInTree(frostTabIndex);
	if tabName ~= nil
	then
	    frostTabPoints = tabPoints;
	end

	tabName, tabPoints = mod:CountTalentsInTree(unholyTabIndex);
	if tabName ~= nil
	then
	    unholyTabPoints = tabPoints;
	end

	if bladeBarrierRank + toughnessRank + anticipationRank >= (bloodTabPoints + frostTabPoints + unholyTabPoints) / 2
	then
	    return true;
	else
	    return false;
	end
    end
end

local function initialPlayerAliveDeathKnight(frame, event, ...)
    hasTankTalentsInvested = checkTankTalentsInvestedDeathKnight();
    hasFrostPresence = mod:CheckPlayerHasAbility(mod.frostPresenceSpellName);

    if hasTankTalentsInvested
    then
	print(mod.displayName .. ": " .. mod:FormatSpecialization(mod.playerClassLocalized, mod.playerRoleTank) .. ".");
    end

    local name, iconPath, tier, column, currentRank, maxRank = GetTalentInfo(frostTabIndex, threatOfThassarianTalentIndex);
    if name ~= nil and currentRank == maxRank
    then
	hasThreatOfThassarian = true;
	print(mod.displayName .. ": " .. mod:FormatSpecialization(mod.playerClassLocalized, mod.frostSpecName, mod.abilityDualWielding) .. ".");
    else
	hasThreadOfThassarian = false;
    end

    local name, iconPath, tied, column, currentRank, maxRank = GetTalentInfo(unholyTabIndex, masterOfGhoulsTalentIndex);
    if name ~= nil and currentRank > 0
    then
	hasMasterOfGhouls = true;
    end
end

local function updatePresenceDeathKnight(frame, even, ...)
    local newPresenceIndex = GetShapeshiftForm();
    if newPresenceIndex ~= 0 and newPresenceIndx ~= presenceIndex
    then
	local icon, name, active = GetShapeshiftFormInfo(newPresenceIndex)
	if name ~= nil
	then
	    mod:DebugMessage(name);
	else
	    print("RoleBuff: presence " .. stanceIndex .. " active.");
	end
    else
	mod:DebugMessage(mod.warningNoDeathKnightPresence);
    end

    presenceIndex = newPresenceIndex;
end

local function combatCheckDeathKnight(chatOnly, frame, event, ...)
    if checkDeathKnightDualWielding and hasThreatOfThassarian
    then
	if IsEquippedItemType(mod.itemTypeTwoHand)
	then
	    mod:ReportMessage(mod:ItemEquipMessage(mod.itemOneHandWeapon), chatOnly);
	end
    end

    if checkDeathKnightPresence
    then
	if hasTankTalentsInvested
	then
	    if presenceIndex ~= frostPresenceIndex
	    then
		mod:ReportMessage(mod:SwitchFormMessage(mod.frostPresenceSpellName), chatOnly) 
	    end
	else
	    if presenceIndex == frostPresenceIndex
	    then
		mod:ReportMessage(mod:AbilityActiveMessage(mod.frostPresenceSpellName), chatOnly)
	    end
	end
    end
end

mod.EventHandlerTableDeathKnight = 
{
    [mod.eventPlayerAlive] = function(frame, event, ...)
	--xpcall(initialPlayerAliveDeathKnight, RoleBuff_ErrorHandler, frame, event, ...)
	initialPlayerAliveDeathKnight(frame, event, ...);

	frame:RegisterEvent(mod.eventActiveTalentGroupChanged);
	frame:RegisterEvent(mod.eventUpdateShapeshiftForms);
	frame:RegisterEvent(mod.eventUpdateShapeshiftForm);
	frame:RegisterEvent(mod.eventPlayerRegenDisabled);
	frame:RegisterEvent(mod.eventPlayerRegenEnabled);
	frame:RegisterEvent(mod.eventPlayerEnterCombat);
	frame:RegisterEvent(mod.eventPlayerLeaveCombat);
    end,

    [mod.eventActiveTalentGroupChanged] = initialPlayerAliveDeathKnight,
    [mod.eventUpdateShapeshiftForms] = updatePresenceDeathKnight,
    [mod.eventUpdateShapeshiftForm] = updatePresenceDeathKnight,

    [mod.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_DeathKnightAttacked and not RoleBuff_DeathKnightAttacking
	then
	    combatCheckDeathKnight(false, frame, event, ...);
	end
	RoleBuff_DeathKnightAttacked = true;
    end,

    [mod.eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_DeathKnightAttacked = false;
    end,

    [mod.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_DeathKnightAttacking and not RoleBuff_DeathKnightAttacked
	then
	    combatCheckDeathKnight(false, frame, event, ...);
	end
	RoleBuff_DeathKnightAttacking = true;
    end,

    [mod.eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_DeathKnightAttacking = false;
    end
};

mod.SlashCommandHandlerDeathKnight =
{
    [mod.slashCommandPlayerCheck] = function()
	initialPlayerAliveDeathKnight(nil, nil)
    end,

    [mod.slashCommandCombatCheck] = function()
	combatCheckDeathKnight(true, nil, nil)
    end
};

function mod.GetDeathKnightRole()
    if hasTankTalentsInvested
    then
	return mod.roleTank;
    else
	return mod.roleDPS;
    end
end

function mod:DeathKnightOptionsFrameLoad(panel)
    panel.name = mod.classNameDeathKnight;
    panel.parent = mod.displayName;
    InterfaceOptions_AddCategory(panel)
end
