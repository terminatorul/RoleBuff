local this = RoleBuffAddOn;

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

local function RoleBuff_CheckTankTalentsInvestedDeathKnight()
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
	local tabName, tabPoints = this:CountTalentsInTree(bloodTabIndex);

	if tabName ~= nil
	then
	    bloodTabPoints = tabPoints;
	end

	tabName, tabPoints = this:CountTalentsInTree(frostTabIndex);
	if tabName ~= nil
	then
	    frostTabPoints = tabPoints;
	end

	tabName, tabPoints = this:CountTalentsInTree(unholyTabIndex);
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

local function RoleBuff_InitialPlayerAliveDeathKnight(frame, event, ...)
    hasTankTalentsInvested = RoleBuff_CheckTankTalentsInvestedDeathKnight();
    hasFrostPresence = this:CheckPlayerHasAbility(this.frostPresenceSpellName);

    if hasTankTalentsInvested
    then
	print(this.displayName .. ": " .. this:FormatSpecialization(this.playerClassLocalized, this.playerRoleTank) .. ".");
    end

    local name, iconPath, tier, column, currentRank, maxRank = GetTalentInfo(frostTabIndex, threatOfThassarianTalentIndex);
    if name ~= nil and currentRank == maxRank
    then
	hasThreatOfThassarian = true;
	print(this.displayName .. ": " .. this:FormatSpecialization(this.playerClassLocalized, this.frostSpecName, this.abilityDualWielding) .. ".");
    else
	hasThreadOfThassarian = false;
    end

    local name, iconPath, tied, column, currentRank, maxRank = GetTalentInfo(unholyTabIndex, masterOfGhoulsTalentIndex);
    if name ~= nil and currentRank > 0
    then
	hasMasterOfGhouls = true;
    end
end

local function RoleBuff_UpdatePresenceDeathKnight(frame, even, ...)
    local newPresenceIndex = GetShapeshiftForm();
    if newPresenceIndex ~= 0 and newPresenceIndx ~= presenceIndex
    then
	local icon, name, active = GetShapeshiftFormInfo(newPresenceIndex)
	if name ~= nil
	then
	    this:DebugMessage(name);
	else
	    print("RoleBuff: presence " .. stanceIndex .. " active.");
	end
    else
	this:DebugMessage(this.warningNoDeathKnightPresence);
    end

    presenceIndex = newPresenceIndex;
end

local function RoleBuff_CombatCheckDeathKnight(chatOnly, frame, event, ...)
    if checkDeathKnightDualWielding and hasThreatOfThassarian
    then
	if IsEquippedItemType(this.itemTypeTwoHand)
	then
	    this:ReportMessage(this:ItemEquipMessage(this.itemOneHandWeapon), chatOnly);
	end
    end

    if checkDeathKnightPresence
    then
	if hasTankTalentsInvested
	then
	    if presenceIndex ~= frostPresenceIndex
	    then
		this:ReportMessage(this:SwitchFormMessage(this.frostPresenceSpellName), chatOnly) 
	    end
	else
	    if presenceIndex == frostPresenceIndex
	    then
		this:ReportMessage(this:AbilityActiveMessage(this.frostPresenceSpellName), chatOnly)
	    end
	end
    end
end

RoleBuffAddOn.EventHandlerTableDeathKnight = 
{
    [this.eventPlayerAlive] = function(frame, event, ...)
	--xpcall(RoleBuff_InitialPlayerAliveDeathKnight, RoleBuff_ErrorHandler, frame, event, ...)
	RoleBuff_InitialPlayerAliveDeathKnight(frame, event, ...);

	frame:RegisterEvent(this.eventActiveTalentGroupChanged);
	frame:RegisterEvent(this.eventUpdateShapeshiftForms);
	frame:RegisterEvent(this.eventUpdateShapeshiftForm);
	frame:RegisterEvent(this.eventPlayerRegenDisabled);
	frame:RegisterEvent(this.eventPlayerRegenEnabled);
	frame:RegisterEvent(this.eventPlayerEnterCombat);
	frame:RegisterEvent(this.eventPlayerLeaveCombat);
    end,

    [this.eventActiveTalentGroupChanged] = RoleBuff_InitialPlayerAliveDeathKnight,
    [this.eventUpdateShapeshiftForms] = RoleBuff_UpdatePresenceDeathKnight,
    [this.eventUpdateShapeshiftForm] = RoleBuff_UpdatePresenceDeathKnight,

    [this.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_DeathKnightAttacked and not RoleBuff_DeathKnightAttacking
	then
	    RoleBuff_CombatCheckDeathKnight(false, frame, event, ...);
	end
	RoleBuff_DeathKnightAttacked = true;
    end,

    [this.eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_DeathKnightAttacked = false;
    end,

    [this.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_DeathKnightAttacking and not RoleBuff_DeathKnightAttacked
	then
	    RoleBuff_CombatCheckDeathKnight(false, frame, event, ...);
	end
	RoleBuff_DeathKnightAttacking = true;
    end,

    [this.eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_DeathKnightAttacking = false;
    end
};

RoleBuffAddOn.SlashCommandHandlerDeathKnight =
{
    [this.slashCommandPlayerCheck] = function()
	RoleBuff_InitialPlayerAliveDeathKnight(nil, nil)
    end,

    [this.slashCommandCombatCheck] = function()
	RoleBuff_CombatCheckDeathKnight(true, nil, nil)
    end
};

function RoleBuffAddOn.GetDeathKnightRole()
    if hasTankTalentsInvested
    then
	return this.roleTank;
    else
	return this.roleDPS;
    end
end

function RoleBuffAddOn:DeathKnightOptionsFrameLoad(panel)
    panel.name = this.classNameDeathKnight;
    panel.parent = this.displayName;
    InterfaceOptions_AddCategory(panel)
end
