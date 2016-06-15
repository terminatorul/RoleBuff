local mod = RoleBuffAddOn;

local checkWarriorStance, checkWarriorShield, checkWarriorVigilance = true, true, true;

local battleStanceIndex = 1;
local defensiveStanceIndex = 2;
local bserkerStanceIndex = 3;

local isProtectionWarrior = false;
local hasBlock = false;
local hasDefensiveStance = false;
local hasVigilance = false;

local vigilanceTargetUnit = nil;
local vigilanceRank = nil;
local vigilanceExpireTime = 0;
local vigilanceIntervalReported = false;
local stanceIndex = 0;
local RoleBuff_WarriorAttacked, RoleBuff_WarriorAttacking = false, false;

local vigilanceSpellName, vigilanceBuffName = mod.vigilanceSpellName, mod.vigilanceBuffName;
local unitTarget, unitPlayer = mod.unitTarget, mod.unitPlayer;

local function checkProtectionWarrior()
    local specIndex, specName = mod:GetPlayerBuild();

    if specIndex ~= nil
    then
	print(mod:FormatSpecialization(mod.playerClassLocalized, specName));
	return specName == mod.protectionSpecName;
    else
	return nil;
    end
end

local function initialPlayerAliveWarrior(frame, event, ...)
    isProtectionWarrior = checkProtectionWarrior();
    hasDefensiveStance = mod:CheckPlayerHasAbility(mod.defensiveStanceSpellName);
    hasVigilance = mod:CheckPlayerHasAbility(vigilanceSpellName);
    hasBlock = mod:CheckPlayerHasAbility(mod.blockSpellName);
    stanceIndex = GetShapeshiftForm();
end

local function updateShapeshiftFormsWarrior(frame, event, ...)
    local newStanceIndex = GetShapeshiftForm();
    if newStanceIndex ~= 0 and newStanceIndex ~= stanceIndex
    then
	local icon, name, active = GetShapeshiftFormInfo(newStanceIndex)
	if name ~= nil
	then
	    print(name);
	else
	    print("RoleBuff: stance " .. newStanceIndex .. " active.");
	end
    else
	mod:DebugMessage(mod.warningNoWarriorStance);
    end

    stanceIndex = newStanceIndex
end

local function checkVigilanceTargetWarrior(chatOnly)
    if hasVigilance
    then
	if vigilanceExpireTime - 15 < GetTime()
	then
	    -- Vigilance has expired or is about to expire
	    vigilanceTargetUnit = nil;
	    vigilanceRank = nil;
	    vigilanceExpireTime = 0;
	end

	if mod:PlayerIsInGroup()
	then
	    if vigilanceTargetUnit == nil 
	    then
		-- warrior is in group and Vigilance expired
		mod:ReportMessage(mod:AbilityToCastMessage(vigilanceSpellName), chatOnly);
	    else
		-- check active vigilance
		-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, ..
		local vigilanceName, _, _, _, _, _, expirationTime, unitCaster = UnitBuff(vigilanceTargetUnit, vigilanceBuffName, vigilanceRank, mod.filterPlayer);

		if vigilanceName and UnitIsUnit(unitCaster, unitPlayer)
		then
		    local expirationInterval = expirationTime - GetTime();
		    local intervalSec = expirationInterval % 60;
		    local intervalMin = (expirationInterval - intervalSec) / 60;
		    mod:DebugMessage(vigilanceName .. " on " .. vigilanceTargetUnit .. " for the next " .. intervalMin .. " min " .. intervalSec .. " sec.")
		else
		    if UnitIsVisible(vigilanceTargetUnit) or not (UnitPlayerOrPetInParty(vigilanceTargetUnit) or UnitPlayerOrPetInRaid(vigilanceTargetUnit))
		    then
		    -- Last vigilance target no longer has the buff, or has it from some other warrior now 
			mod:ReportMessage(mod:AbilityToCastMessage(vigilanceSpellName), chatOnly);
		    end
		end
	    end
	end
    end
end

local function combatCheckWarrior(chatOnly)
    if isProtectionWarrior
    then
	if checkWarriorStance and hasDefensiveStance and (stanceIndex ~= defensiveStanceIndex)
	then
	    mod:ReportMessage(mod:SwitchFormMessage(mod.defensiveStanceSpellName), chatOnly);
	end

	if checkWarriorShield and hasBlock and not IsEquippedItemType(mod.itemTypeShields)
	then
	    mod:ReportMessage(mod:ItemEquipMessage(mod.itemShield), chatOnly);
	end

	if checkWarriorVigilance
	then
	    checkVigilanceTargetWarrior(chatOnly);
	end
    end
end

local function unitSpellCastSucceededWarrior(unit, spellName, spellRank, lineIDCounter)
    if spellName == vigilanceSpellName and UnitIsUnit(unit, unitPlayer)
    then
	vigilanceTargetUnit = UnitName(unitTarget);
	vigilanceRank = spellRank;
	vigilanceIntervalReported = false;
    end
end

local function onUnitAuraChange(unit)
    if unit and vigilanceTargetUnit and UnitIsUnit(unit, vigilanceTargetUnit) and UnitIsVisible(vigilanceTargetUnit)
    then
	local spellName = nil;

	-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable
	spellName, vigilanceRank, _, _, _, _, vigilanceExpireTime, unitCaster = UnitBuff(vigilanceTargetUnit, vigilanceBuffName, vigilanceRank);

	if spellName and UnitIsUnit(unitPlayer, unitCaster)
	then
	    if not vigilanceIntervalReported
	    then
		local expirationInterval = vigilanceExpireTime - GetTime();
		local intervalSec = expirationInterval % 60;
		local intervalMin = (expirationInterval - intervalSec) / 60;
		mod:DebugMessage(mod.displayName .. ": " .. spellName .. " cast on " .. vigilanceTargetUnit .. " for " .. intervalMin .. " min " .. intervalSec .. " sec.");
		vigilanceIntervalReported = true;
	    end
	else
	    -- Vigilance buff either lost or belongs to other warrior
	    mod:DebugMessage(mod.displayName .. ": " .. vigilanceBuffName .. " on " .. vigilanceTargetUnit .. " now off.");
	    vigilanceTargetUnit = nil;
	    vigilanceRank = nil;
	    vigilanceExpireTime = 0;
	end
    end
end

mod.EventHandlerTableWarrior = 
{
    [mod.eventPlayerAlive] = function(frame, event, ...)
	--xpcall(initialPlayerAliveWarrior, RoleBuff_ErrorHandler, frame, event, ...)
	initialPlayerAliveWarrior(frame, event, ...);

	frame:RegisterEvent(mod.eventActiveTalentGroupChanged);
	frame:RegisterEvent(mod.eventUpdateShapeshiftForms);
	frame:RegisterEvent(mod.eventUpdateShapeshiftForm);
	frame:RegisterEvent(mod.eventPlayerRegenDisabled);
	frame:RegisterEvent(mod.eventPlayerRegenEnabled);
	frame:RegisterEvent(mod.eventPlayerEnterCombat);
	frame:RegisterEvent(mod.eventPlayerLeaveCombat);
	frame:RegisterEvent(mod.eventUnitSpellCastSucceeded);
	frame:RegisterEvent(mod.eventUnitAura);
    end,

    [mod.eventActiveTalentGroupChanged] = function(frame, event, ...)
	initialPlayerAliveWarrior(frame, event, ...);
	vigilanceTargetUnit = nil;
	vigilanceExpireTime = 0;
    end,

    [mod.eventPlayerDead] = function(frame, event, ...)
	vigilanceTargetUnit = nil;
	vigilanceExpireTime = 0;
    end,

    [mod.eventUpdateShapeshiftForms] = function(frame, event, ...)
	updateShapeshiftFormsWarrior(frame, event, ...);
    end,

    [mod.eventUpdateShapeshiftForm] = function(frame, event, ...)
	updateShapeshiftFormsWarrior(frame, event, ...);
    end,

    [mod.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_WarriorAttacked and not RoleBuff_WarriorAttacking
	then
	    combatCheckWarrior(false);
	end
	RoleBuff_WarriorAttacked = true;
    end,

    [mod.eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_WarriorAttacked = false;
    end,

    [mod.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_WarriorAttacked and not RoleBuff_WarriorAttacking
	then
	    combatCheckWarrior(false);
	end
	RoleBuff_WarriorAttacking = true;
    end,

    [mod.eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_WarriorAttacking = false;
    end,

    [mod.eventUnitSpellCastSucceeded] = function(frame, event, ...)
	local unit, spellName, spellRank, lineIDCounterargsList = ...;
	unitSpellCastSucceededWarrior(unit, spellName, spellRank, lineIDCounter);
    end,

    [mod.eventUnitAura] = function(frame, event, ...)
	local args = { ... };
	onUnitAuraChange(args[1]);
    end
};

mod.SlashCommandHandlerWarrior =
{
    [mod.slashCommandPlayerCheck] = function()
	initialPlayerAliveWarrior(nil, nil)
    end,

    [mod.slashCommandCombatCheck] = function()
	combatCheckWarrior(true)
    end
};

function mod.GetWarriorRole()
    if isProtectionWarrior
    then
	return mod.roleTank;
    end

    return mod.roleDPS;
end

function mod:WarriorOptionsFrameLoad(panel)
    panel.name = self.classNameWarrior;
    panel.parent = self.displayName;
    InterfaceOptions_AddCategory(panel);
end
