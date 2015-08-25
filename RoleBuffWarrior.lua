local checkWarriorStance, checkWarriorShield, checkWarriorVigilance = true, true, true;

local battleStanceIndex = 1;
local defensiveStanceIndex = 2;
local bserkerStanceIndex = 3;

isProtectionWarrior = false;
hasBlock = false;
hasDefensiveStance = false;
hasVigilance = false;

playerIsInGroup = false;
vigilanceTargetUnit = nil;
vigilanceRank = nil;
vigilanceExpireTime = 0;
vigilanceIntervalReported = false;
stanceIndex = 0;
RoleBuff_WarriorAttacked, RoleBuff_WarriorAttacking = false, false;

function RoleBuff_CheckProtectionWarrior()
    local specIndex, specName = RoleBuff_GetPlayerBuild();

    if specIndex ~= nil
    then
	print(RoleBuff_FormatSpecialization(playerClassLocalized, specName));
	return specName == protectionSpecName;
    else
	return nil;
    end
end

function RoleBuff_InitialPlayerAliveWarrior(frame, event, ...)
    isProtectionWarrior = RoleBuff_CheckProtectionWarrior();
    hasDefensiveStance = RoleBuff_CheckPlayerHasAbility(defensiveStanceSpellName);
    hasVigilance = RoleBuff_CheckPlayerHasAbility(vigilanceSpellName);
    hasBlock = RoleBuff_CheckPlayerHasAbility(blockSpellName);
    stanceIndex = GetShapeshiftForm();
end

function RoleBuff_UpdateShapeshiftFormsWarrior(frame, event, ...)
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
	RoleBuff_DebugMessage(warningNoWarriorStance);
    end

    stanceIndex = newStanceIndex
end

function RoleBuff_CheckVigilanceTargetWarrior(chatOnly)
    if hasVigilance
    then
	if vigilanceExpireTime - 15 < GetTime()
	then
	    -- Vigilance has expired or is about to expire
	    vigilanceTargetUnit = nil;
	    vigilanceRank = nil;
	    vigilanceExpireTime = 0;
	end

	if RoleBuff_PlayerIsInGroup()
	then
	    if vigilanceTargetUnit == nil 
	    then
		-- warrior is in group and Vigilance expired
		RoleBuff_ReportMessage(RoleBuff_AbilityToCastMessage(vigilanceSpellName), chatOnly);
	    else
		-- check active vigilance
		-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, ..
		local vigilanceName, _, _, _, _, _, expirationTime, unitCaster = UnitBuff(vigilanceTargetUnit, vigilanceBuffName, vigilanceRank, filterPlayer);

		if vigilanceName and UnitIsUnit(unitCaster, unitPlayer)
		then
		    local expirationInterval = expirationTime - GetTime();
		    local intervalSec = expirationInterval % 60;
		    local intervalMin = (expirationInterval - intervalSec) / 60;
		    RoleBuff_DebugMessage(vigilanceName .. " on " .. vigilanceTargetUnit .. " for the next " .. intervalMin .. " min " .. intervalSec .. " sec.")
		else
		    if UnitIsVisible(vigilanceTargetUnit) or not (UnitPlayerOrPetInParty(vigilanceTargetUnit) or UnitPlayerOrPetInRaid(vigilanceTargetUnit))
		    then
		    -- Last vigilance target no longer has the buff, or has it from some other warrior now 
			RoleBuff_ReportMessage(RoleBuff_AbilityToCastMessage(vigilanceSpellName), chatOnly);
		    end
		end
	    end
	end
    end
end

function RoleBuff_CombatCheckWarrior(chatOnly)
    if isProtectionWarrior
    then
	if checkWarriorStance and hasDefensiveStance and (stanceIndex ~= defensiveStanceIndex)
	then
	    RoleBuff_ReportMessage(RoleBuff_SwitchFormMessage(defensiveStanceSpellName), chatOnly);
	end

	if checkWarriorShield and hasBlock and not IsEquippedItemType(itemTypeShields)
	then
	    RoleBuff_ReportMessage(RoleBuff_ItemEquipMessage(itemShield), chatOnly);
	end

	if checkWarriorVigilance
	then
	    RoleBuff_CheckVigilanceTargetWarrior(chatOnly);
	end
    end
end

function RoleBuff_UnitSpellCastSucceededWarrior(unit, spellName, spellRank, lineIDCounter)
    if spellName == vigilanceSpellName and UnitIsUnit(unit, unitPlayer)
    then
	vigilanceTargetUnit = (UnitName(unitTarget));
	vigilanceRank = spellRank;
	vigilanceIntervalReported = false;
    end
end

function RoleBuff_UnitAuraChange(unit)
    if unit and vigilanceTargetUnit and UnitIsUnit(unit, vigilanceTargetUnit)
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
		RoleBuff_DebugMessage(displayName .. ": " .. spellName .. " cast on " .. vigilanceTargetUnit .. " for " .. intervalMin .. " min " .. intervalSec .. " sec.");
		vigilanceIntervalReported = true;
	    end
	else
	    -- Vigilance buff either lost or belongs to other warrior
	    RoleBuff_DebugMessage(displayName .. ": " .. vigilanceBuffName .. " on " .. vigilanceTargetUnit .. " now off.");
	    vigilanceTargetUnit = nil;
	    vigilanceRank = nil;
	    vigilanceExpireTime = 0;
	end
    end
end

RoleBuff_EventHandlerTableWarrior = 
{
    [eventPlayerAlive] = function(frame, event, ...)
	--xpcall(RoleBuff_InitialPlayerAliveWarrior, RoleBuff_ErrorHandler, frame, event, ...)
	RoleBuff_InitialPlayerAliveWarrior(frame, event, ...);

	frame:RegisterEvent(eventActiveTalentGroupChanged);
	frame:RegisterEvent(eventUpdateShapeshiftForms);
	frame:RegisterEvent(eventUpdateShapeshiftForm);
	frame:RegisterEvent(eventPlayerRegenDisabled);
	frame:RegisterEvent(eventPlayerRegenEnabled);
	frame:RegisterEvent(eventPlayerEnterCombat);
	frame:RegisterEvent(eventPlayerLeaveCombat);
	frame:RegisterEvent(eventUnitSpellCastSucceeded);
	frame:RegisterEvent(eventUnitAura);
    end,

    [eventActiveTalentGroupChanged] = function(frame, event, ...)
	RoleBuff_InitialPlayerAliveWarrior(frame, event, ...);
	vigilanceTargetUnit = nil;
	vigilanceExpireTime = 0;
    end,

    [eventPlayerDead] = function(frame, event, ...)
	vigilanceTargetUnit = nil;
	vigilanceExpireTime = 0;
    end,

    [eventUpdateShapeshiftForms] = function(frame, event, ...)
	RoleBuff_UpdateShapeshiftFormsWarrior(frame, event, ...);
    end,

    [eventUpdateShapeshiftForm] = function(frame, event, ...)
	RoleBuff_UpdateShapeshiftFormsWarrior(frame, event, ...);
    end,

    [eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_WarriorAttacked and not RoleBuff_WarriorAttacking
	then
	    RoleBuff_CombatCheckWarrior(false);
	end
	RoleBuff_WarriorAttacked = true;
    end,

    [eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_WarriorAttacked = false;
    end,

    [eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_WarriorAttacked and not RoleBuff_WarriorAttacking
	then
	    RoleBuff_CombatCheckWarrior(false);
	end
	RoleBuff_WarriorAttacking = true;
    end,

    [eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_WarriorAttacking = false;
    end,

    [eventUnitSpellCastSucceeded] = function(frame, event, ...)
	local unit, spellName, spellRank, lineIDCounterargsList = ...;
	RoleBuff_UnitSpellCastSucceededWarrior(unit, spellName, spellRank, lineIDCounter);
    end,

    [eventUnitAura] = function(frame, event, ...)
	local args = { ... };
	RoleBuff_UnitAuraChange(args[1]);
    end
};

RoleBuff_SlashCommandHandlerWarrior =
{
    [slashCommandPlayerCheck] = function()
	RoleBuff_InitialPlayerAliveWarrior(nil, nil)
    end,

    [slashCommandCombatCheck] = function()
	RoleBuff_CombatCheckWarrior(true)
    end
};

function RoleBuff_GetWarriorRole()
    if isProtectionWarrior
    then
	return roleTank;
    end

    return roleDPS;
end

function RoleBuff_WarriorOptionsFrame_Load(panel)
    panel.name = classNameWarrior;
    panel.parent = displayName;
    InterfaceOptions_AddCategory(panel);
end
