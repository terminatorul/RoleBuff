-- Check Shaman for:
--	- totems
--	- elemental weapon enchant(s)
--	- elemental shield buffs
--
--
--  add plugin options UI
--  check attacked while mounted
--  check gray mobs attacking
--  check plugin loading after reloadui
--  check range for warrior vigilance
--  check RDF role versus player available specs

local mod = RoleBuffAddOn;

local checkElementalWeapon, checkShamanShield, checkEarthShield = true, true, true;

local checkShamanTotems, checkShamanWeapon = true, true;

local isRestorationShaman, hasWeaponEnchantment, hasEarthShield, hasShamanShield = nil, false, false, false;

local ShamanAttacked, ShamanAttacking = false, false;

local function onPlayerAlive(frame, event, ...)
    local specIndex, specName = mod:GetPlayerBuild();
    isRestorationShaman = (specName == mod.restaurationSpecName);
    hasWeaponEnchantment, hasEarthShield, hasShamanShield = false, false, false;

    if checkElementalWeapon
    then
	hasWeaponEnchantment = false;

	for idx, imbueWeaponAbility in pairs({ mod.flametongueWeapon, mod.earthlivingWeapon, mod.frostbrandWeapon, mod.rockbiterWeapon, mod.windfuryWeapon })
	do
	    if mod:CheckPlayerHasAbility(imbueWeaponAbility)
	    then
		hasWeaponEnchantment = true;
		break
	    end
	end
    end

    if checkShamanShield
    then
	hasShamanShield = false;

	for idx, shieldAbility in pairs({ mod.lightningShield, mod.waterShield })
	do
	    if mod:CheckPlayerHasAbility(shieldAbility)
	    then
		hasShamanShield = true;
		break
	    end
	end

	if checkEarthShield
	then
	    if mod:CheckPlayerHasAbility(mod.earthShield)
	    then
		hasEarthShield = true
	    end
	end
    end
end

local function checkShamanWeaponEnchant(chatOnly)
    if checkElementalWeapon and hasWeaponEnchantment
    then
	local hasMainHandEnchant, hasOffHandEnchant = mod:HasWeaponEnchants();

	if hasMainHandEnchant ~= nil and (hasOffHandEnchant ~= nil or not OffhandHasWeapon())
	then
	else
	    mod:ReportMessage(mod:AbilityToCastMessage(mod.shamanElementalWeapon), chatOnly);
	end
    end
end

mod.earthShieldTarget, mod.earthShieldExpiration = nil, nil;

local shamanShieldList = { [mod.waterShield] = true, [mod.lightningShield] = true, [mod.earthShield] = true };

local function unitSpellCastSucceededShaman(unitCaster, spellName, spellRank, lineIDCounter)
    if spellName == mod.earthShield and unitCaster and UnitIsUnit(unitCaster, mod.unitPlayer)
    then
	mod.earthShieldTarget = (UnitName(mod.unitTarget) or UnitName(mod.unitPlayer))
    end
end

local function unitAuraChange(unit)
    if unit and mod.earthShieldTarget and UnitIsUnit(unit, mod.earthShieldTarget) and UnitIsVisible(unit)
    then
	-- Check remaining time for Earth Shield buff on target
	local spellName, unitCaster, prevExpireTime = nil, nil, mod.earthShieldExpiration;
	spellName, _, _, _, _, _, mod.earthShieldExpiration, unitCaster = UnitBuff(mod.earthShieldTarget, mod.earthShield);

	if spellName and unitCaster and UnitIsUnit(unitCaster, mod.unitPlayer)
	then
	    if not prevExpireTime
	    then
		local expireInterval = math.floor(mod.earthShieldExpiration - GetTime() + 0.5);
		mod:DebugMessage(mod.displayName .. ": " .. spellName .. " cast on " .. UnitName(unit) .. " for " .. math.floor(expireInterval / 60) .. " min " .. (expireInterval % 60) .. " sec.")
	    else
	    end
	else
	    -- Earth Shield buff now expired or replaced by other shaman
	    mod.earthShieldTarget = nil;
	    mod.earthShieldExpiration = nil;
	    mod:DebugMessage(mod.displayName .. ": " .. mod.earthShield .. " now removed.")
	end
    end
end


local function checkShamanElementalShield(chatOnly)
    if checkShamanShield and hasShamanShield
    then
	local i, buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster = 1, nil, nil, nil, nil, nil, nil, nil, nil;

	repeat
	    buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster = UnitBuff(mod.unitPlayer, i);
	    i = i + 1;

	    if buffName
	    then
		if shamanShieldList[buffName] and unitCaster and UnitIsUnit(unitCaster, mod.unitPlayer)
		then
		    return buffName
		end
	    end
	until buffName == nil

	mod:ReportMessage(mod:AbilityToCastMessage(mod.shamanElementalShield), chatOnly)
    end
end

local function checkEarthShieldInParty(chatOnly, shamanElementalShield)
    if checkEarthShield and hasEarthShield and shamanElementalShield ~= mod.earthShield and mod:PlayerIsInGroup()
    then
	if mod.earthShieldTarget and mod.earthShieldExpiration
	then
	    if mod.earthShieldExpiration > GetTime() + 5 and UnitExists(mod.earthShieldTarget)
	    then
		local buffName, _, _, _, _, _, _, unitCaster = UnitBuff(mod.earthShieldTarget, mod.earthShield);
		if buffName and unitCaster and UnitIsUnit(unitCaster, mod.unitPlayer)
		then
		    -- mod.earthShieldTarget still has Earth Shield buff from player
		    return
		end
	    end

	    mod.earthShieldTarget = nil;
	    mod.earthShieldExpiration = nil
	end

	mod:ReportMessage(mod:AbilityToCastMessage(mod.earthShield), chatOnly)
    end
end

function mod.GetShamanRole()
    if isRestorationShaman
    then
	return mod.roleHealer;
    else
	return mod.roleDPS;
    end
end

local function combatCheckShaman(chatOnly, frame, event, ...)
    checkShamanWeaponEnchant(chatOnly);
    checkEarthShieldInParty(chatOnly, checkShamanElementalShield(chatOnly))
end

mod.EventHandlerTableShaman =
{
    [mod.eventPlayerAlive] = function(frame, event, ...)
	onPlayerAlive(frame, event, ...);

	frame:RegisterEvent(mod.eventUnitSpellCastSucceeded);
	frame:RegisterEvent(mod.eventUnitAura);
	frame:RegisterEvent(mod.eventActiveTalentGroupChanged)
    end,

    [mod.eventActiveTalentGroupChanged] = onPlayerAlive,

    [mod.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not ShamanAttacked and not ShamanAttacking
	then
	    combatCheckShaman(false, frame, event, ...);
	end
	ShamanAttacked = true
    end,

    [mod.eventPlayerRegenEnabled] = function(frame, event, ...)
	ShamanAttacked = false
    end,

    [mod.eventPlayerEnterCombat] = function(frame, event, ...)
	if not ShamanAttacking and not ShamanAttacked
	then
	    combatCheckShaman(false, frame, event, ...);
	end
	ShamanAttacking = true
    end,

    [mod.eventPlayerLeaveCombat] = function(frame, event, ...)
	ShamanAttacking = false
    end,

    [mod.eventUnitSpellCastSucceeded] = function(frame, event, ...)
	local unitCaster, spellName, spellRank, lineIDCounter = ...;
	unitSpellCastSucceededShaman(unitCaster, spellName, spellRank, lineIDCounter);
    end,

    [mod.eventUnitAura] = function(frame, event, ...)
	local args = { ... };
	unitAuraChange(args[1])
    end
};

mod.SlashCommandHandlerShaman =
{
    [mod.slashCommandPlayerCheck] = function()
	onPlayerAlive(nil, nil)
    end,

    [mod.slashCommandCombatCheck] = function()
	combatCheckShaman(true, nil, nil)
    end
};

function mod:ShamanOptionsFrameLoad(panel)
    panel.name = mod.classNameShaman;
    panel.parent = mod.displayName;
    InterfaceOptions_AddCategory(panel)
end
