local this = RoleBuffAddOn;

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

local vigilanceSpellName, vigilanceBuffName = this.vigilanceSpellName, this.vigilanceBuffName;
local unitTarget, unitPlayer = this.unitTarget, this.unitPlayer;

local function RoleBuff_CheckProtectionWarrior()
    local specIndex, specName = this:GetPlayerBuild();

    if specIndex ~= nil
    then
	print(this:FormatSpecialization(this.playerClassLocalized, specName));
	return specName == this.protectionSpecName;
    else
	return nil;
    end
end

local function RoleBuff_InitialPlayerAliveWarrior(frame, event, ...)
    isProtectionWarrior = RoleBuff_CheckProtectionWarrior();
    hasDefensiveStance = this:CheckPlayerHasAbility(this.defensiveStanceSpellName);
    hasVigilance = this:CheckPlayerHasAbility(vigilanceSpellName);
    hasBlock = this:CheckPlayerHasAbility(this.blockSpellName);
    stanceIndex = GetShapeshiftForm();
end

local function RoleBuff_UpdateShapeshiftFormsWarrior(frame, event, ...)
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
	this:DebugMessage(this.warningNoWarriorStance);
    end

    stanceIndex = newStanceIndex
end

local function RoleBuff_CheckVigilanceTargetWarrior(chatOnly)
    if hasVigilance
    then
	if vigilanceExpireTime - 15 < GetTime()
	then
	    -- Vigilance has expired or is about to expire
	    vigilanceTargetUnit = nil;
	    vigilanceRank = nil;
	    vigilanceExpireTime = 0;
	end

	if this:PlayerIsInGroup()
	then
	    if vigilanceTargetUnit == nil 
	    then
		-- warrior is in group and Vigilance expired
		this:ReportMessage(this:AbilityToCastMessage(vigilanceSpellName), chatOnly);
	    else
		-- check active vigilance
		-- name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, ..
		local vigilanceName, _, _, _, _, _, expirationTime, unitCaster = UnitBuff(vigilanceTargetUnit, vigilanceBuffName, vigilanceRank, this.filterPlayer);

		if vigilanceName and UnitIsUnit(unitCaster, unitPlayer)
		then
		    local expirationInterval = expirationTime - GetTime();
		    local intervalSec = expirationInterval % 60;
		    local intervalMin = (expirationInterval - intervalSec) / 60;
		    this:DebugMessage(vigilanceName .. " on " .. vigilanceTargetUnit .. " for the next " .. intervalMin .. " min " .. intervalSec .. " sec.")
		else
		    if UnitIsVisible(vigilanceTargetUnit) or not (UnitPlayerOrPetInParty(vigilanceTargetUnit) or UnitPlayerOrPetInRaid(vigilanceTargetUnit))
		    then
		    -- Last vigilance target no longer has the buff, or has it from some other warrior now 
			this:ReportMessage(this:AbilityToCastMessage(vigilanceSpellName), chatOnly);
		    end
		end
	    end
	end
    end
end

local function RoleBuff_CombatCheckWarrior(chatOnly)
    if isProtectionWarrior
    then
	if checkWarriorStance and hasDefensiveStance and (stanceIndex ~= defensiveStanceIndex)
	then
	    this:ReportMessage(this:SwitchFormMessage(this.defensiveStanceSpellName), chatOnly);
	end

	if checkWarriorShield and hasBlock and not IsEquippedItemType(this.itemTypeShields)
	then
	    this:ReportMessage(this:ItemEquipMessage(this.itemShield), chatOnly);
	end

	if checkWarriorVigilance
	then
	    RoleBuff_CheckVigilanceTargetWarrior(chatOnly);
	end
    end
end

local function RoleBuff_UnitSpellCastSucceededWarrior(unit, spellName, spellRank, lineIDCounter)
    if spellName == vigilanceSpellName and UnitIsUnit(unit, unitPlayer)
    then
	vigilanceTargetUnit = UnitName(unitTarget);
	vigilanceRank = spellRank;
	vigilanceIntervalReported = false;
    end
end

local function RoleBuff_UnitAuraChange(unit)
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
		this:DebugMessage(this.displayName .. ": " .. spellName .. " cast on " .. vigilanceTargetUnit .. " for " .. intervalMin .. " min " .. intervalSec .. " sec.");
		vigilanceIntervalReported = true;
	    end
	else
	    -- Vigilance buff either lost or belongs to other warrior
	    this:DebugMessage(this.displayName .. ": " .. vigilanceBuffName .. " on " .. vigilanceTargetUnit .. " now off.");
	    vigilanceTargetUnit = nil;
	    vigilanceRank = nil;
	    vigilanceExpireTime = 0;
	end
    end
end

RoleBuffAddOn.EventHandlerTableWarrior = 
{
    [this.eventPlayerAlive] = function(frame, event, ...)
	--xpcall(RoleBuff_InitialPlayerAliveWarrior, RoleBuff_ErrorHandler, frame, event, ...)
	RoleBuff_InitialPlayerAliveWarrior(frame, event, ...);

	frame:RegisterEvent(this.eventActiveTalentGroupChanged);
	frame:RegisterEvent(this.eventUpdateShapeshiftForms);
	frame:RegisterEvent(this.eventUpdateShapeshiftForm);
	frame:RegisterEvent(this.eventPlayerRegenDisabled);
	frame:RegisterEvent(this.eventPlayerRegenEnabled);
	frame:RegisterEvent(this.eventPlayerEnterCombat);
	frame:RegisterEvent(this.eventPlayerLeaveCombat);
	frame:RegisterEvent(this.eventUnitSpellCastSucceeded);
	frame:RegisterEvent(this.eventUnitAura);
    end,

    [this.eventActiveTalentGroupChanged] = function(frame, event, ...)
	RoleBuff_InitialPlayerAliveWarrior(frame, event, ...);
	vigilanceTargetUnit = nil;
	vigilanceExpireTime = 0;
    end,

    [this.eventPlayerDead] = function(frame, event, ...)
	vigilanceTargetUnit = nil;
	vigilanceExpireTime = 0;
    end,

    [this.eventUpdateShapeshiftForms] = function(frame, event, ...)
	RoleBuff_UpdateShapeshiftFormsWarrior(frame, event, ...);
    end,

    [this.eventUpdateShapeshiftForm] = function(frame, event, ...)
	RoleBuff_UpdateShapeshiftFormsWarrior(frame, event, ...);
    end,

    [this.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_WarriorAttacked and not RoleBuff_WarriorAttacking
	then
	    RoleBuff_CombatCheckWarrior(false);
	end
	RoleBuff_WarriorAttacked = true;
    end,

    [this.eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_WarriorAttacked = false;
    end,

    [this.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_WarriorAttacked and not RoleBuff_WarriorAttacking
	then
	    RoleBuff_CombatCheckWarrior(false);
	end
	RoleBuff_WarriorAttacking = true;
    end,

    [this.eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_WarriorAttacking = false;
    end,

    [this.eventUnitSpellCastSucceeded] = function(frame, event, ...)
	local unit, spellName, spellRank, lineIDCounterargsList = ...;
	RoleBuff_UnitSpellCastSucceededWarrior(unit, spellName, spellRank, lineIDCounter);
    end,

    [this.eventUnitAura] = function(frame, event, ...)
	local args = { ... };
	RoleBuff_UnitAuraChange(args[1]);
    end
};

RoleBuffAddOn.SlashCommandHandlerWarrior =
{
    [this.slashCommandPlayerCheck] = function()
	RoleBuff_InitialPlayerAliveWarrior(nil, nil)
    end,

    [this.slashCommandCombatCheck] = function()
	RoleBuff_CombatCheckWarrior(true)
    end
};

function RoleBuffAddOn.GetWarriorRole()
    if isProtectionWarrior
    then
	return this.roleTank;
    end

    return this.roleDPS;
end

function RoleBuffAddOn:WarriorOptionsFrameLoad(panel)
    panel.name = self.classNameWarrior;
    panel.parent = self.displayName;
    InterfaceOptions_AddCategory(panel);
end
