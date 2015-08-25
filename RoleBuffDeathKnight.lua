local checkDeathKnightPresence, checkDeathKnightDualWielding, checkDeathKnightGhoul = true, true, false;

local bloodPresenceIndex, frostPresenceIndex, UnholyPresenceIndex = 1, 2, 3;
local bloodTabIndex, frostTabIndex, unholyTabIndex = 1, 2, 3;

local bladeBarrierTalentIndex = 3;
local toughnessTalentIndex = 3;
local anticipationTalentIndex = 3;
local threatOfThassarianTalentIndex = 22;
local masterOfGhoulsTalentIndex = 20;

bladeBarrierRank, anticipationRank, toughnessRank = 0, 0, 0;
hasTankTalentsInvested = false;
hasFrostPresence = false;
hasThreatOfThassarian = false;
hasMasterOfGhouls = false;

presenceIndex = 0;
RoleBuff_DeathKnightAttacked, RoleBuff_DeathKnightAttacking = false, false;

function RoleBuff_CheckTankTalentsInvestedDeathKnight()
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
	local tabName, tabPoints = RoleBuff_CountTalentsInTree(bloodTabIndex);

	if tabName ~= nil
	then
	    bloodTabPoints = tabPoints;
	end

	tabName, tabPoints = RoleBuff_CountTalentsInTree(frostTabIndex);
	if tabName ~= nil
	then
	    frostTabPoints = tabPoints;
	end

	tabName, tabPoints = RoleBuff_CountTalentsInTree(unholyTabIndex);
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

function RoleBuff_InitialPlayerAliveDeathKnight(frame, event, ...)
    hasTankTalentsInvested = RoleBuff_CheckTankTalentsInvestedDeathKnight();
    hasFrostPresence = RoleBuff_CheckPlayerHasAbility(frostPresenceSpellName);

    if hasTankTalentsInvested
    then
	print(displayName .. ": " .. RoleBuff_FormatSpecialization(playerClassLocalized, playerRoleTank) .. ".");
    end

    local name, iconPath, tier, column, currentRank, maxRank = GetTalentInfo(frostTabIndex, threatOfThassarianTalentIndex);
    if name ~= nil and currentRank == maxRank
    then
	hasThreatOfThassarian = true;
	print(displayName .. ": " .. RoleBuff_FormatSpecialization(playerClassLocalized, frostSpecName, abilityDualWielding) .. ".");
    else
	hasThreadOfThassarian = false;
    end

    local name, iconPath, tied, column, currentRank, maxRank = GetTalentInfo(unholyTabIndex, masterOfGhoulsTalentIndex);
    if name ~= nil and currentRank > 0
    then
	hasMasterOfGhouls = true;
    end
end

function RoleBuff_UpdatePresenceDeathKnight(frame, even, ...)
    local newPresenceIndex = GetShapeshiftForm();
    if newPresenceIndex ~= 0 and newPresenceIndx ~= presenceIndex
    then
	local icon, name, active = GetShapeshiftFormInfo(newPresenceIndex)
	if name ~= nil
	then
	    RoleBuff_DebugMessage(name);
	else
	    print("RoleBuff: presence " .. stanceIndex .. " active.");
	end
    else
	RoleBuff_DebugMessage(warningNoDeathKnightPresence);
    end

    presenceIndex = newPresenceIndex;
end

function RoleBuff_CombatCheckDeathKnight(chatOnly, frame, event, ...)
    if checkDeathKnightDualWielding and hasThreatOfThassarian
    then
	if IsEquippedItemType(itemTypeTwoHand)
	then
	    RoleBuff_ReportMessage(RoleBuff_ItemEquipMessage(itemOneHandWeapon), chatOnly);
	end
    end

    if checkDeathKnightPresence
    then
	if hasTankTalentsInvested
	then
	    if presenceIndex ~= frostPresenceIndex
	    then
		RoleBuff_ReportMessage(RoleBuff_SwitchFormMessage(frostPresenceSpellName), chatOnly) 
	    end
	else
	    if presenceIndex == frostPresenceIndex
	    then
		RoleBuff_ReportMessage(RoleBuff_AbilityActiveMessage(frostPresenceSpellName), chatOnly)
	    end
	end
    end
end

RoleBuff_EventHandlerTableDeathKnight = 
{
    [eventPlayerAlive] = function(frame, event, ...)
	--xpcall(RoleBuff_InitialPlayerAliveDeathKnight, RoleBuff_ErrorHandler, frame, event, ...)
	RoleBuff_InitialPlayerAliveDeathKnight(frame, event, ...);

	frame:RegisterEvent(eventActiveTalentGroupChanged);
	frame:RegisterEvent(eventUpdateShapeshiftForms);
	frame:RegisterEvent(eventUpdateShapeshiftForm);
	frame:RegisterEvent(eventPlayerRegenDisabled);
	frame:RegisterEvent(eventPlayerRegenEnabled);
	frame:RegisterEvent(eventPlayerEnterCombat);
	frame:RegisterEvent(eventPlayerLeaveCombat);
    end,

    [eventActiveTalentGroupChanged] = RoleBuff_InitialPlayerAliveDeathKnight,
    [eventUpdateShapeshiftForms] = RoleBuff_UpdatePresenceDeathKnight,
    [eventUpdateShapeshiftForm] = RoleBuff_UpdatePresenceDeathKnight,

    [eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_DeathKnightAttacked and not RoleBuff_DeathKnightAttacking
	then
	    RoleBuff_CombatCheckDeathKnight(false, frame, event, ...);
	end
	RoleBuff_DeathKnightAttacked = true;
    end,

    [eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_DeathKnightAttacked = false;
    end,

    [eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_DeathKnightAttacking and not RoleBuff_DeathKnightAttacked
	then
	    RoleBuff_CombatCheckDeathKnight(false, frame, event, ...);
	end
	RoleBuff_DeathKnightAttacking = true;
    end,

    [eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_DeathKnightAttacking = false;
    end
};

RoleBuff_SlashCommandHandlerDeathKnight =
{
    [slashCommandPlayerCheck] = function()
	RoleBuff_InitialPlayerAliveDeathKnight(nil, nil)
    end,

    [slashCommandCombatCheck] = function()
	RoleBuff_CombatCheckDeathKnight(true, nil, nil)
    end
};

function RoleBuff_GetDeathKnightRole()
    if hasTankTalentsInvested
    then
	return roleTank;
    else
	return roleDPS;
    end
end

function RoleBuff_DeathKnightOptionsFrame_Load(panel)
    panel.name = classNameDeathKnight;
    panel.parent = displayName;
    InterfaceOptions_AddCategory(panel)
end
