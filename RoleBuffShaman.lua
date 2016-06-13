-- Check Shaman for:
--	- totems
--	- flametongue weapon
--	- water shield
--
--
--  add plugin options UI
--  check attacked while mounted
--  check gray mobs attacking
--  check plugin loading after reloadui
--  check range for warrior vigilance
--  check RDF role versus player available specs

local mod = RoleBuffAddOn;

local checkShamanWeaponEnchant, checkShamanShield, checkElementalShield = true, true, true;

local checkShamanTotems, checkShamanWeapon, cheackShamanShielding = true, true, true;

local isRestaurationShaman, hasWeaponEnchantment, hasElementalShield, hasShamanShield = nil, false, false, false;

local ShamanAttacked, ShamanAttacking = false, false;

local function OnPlayerAlive(frame, event, ...)
    local specIndex, specName = mod:GetPlayerBuild();
    isRestaurationShaman = (specName == mod.restaurationSpecName);

    if checkShamanWeaponEnchant
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

	if checkElementalShield
	then
	    for idx, shieldAbility in pairs({ mod.earthShield })
	    do
		if mod:CheckPlayerHasAbility(shieldAbility)
		then
		    hasElementalShield = true;
		    break
		end
	    end
	end
    end
end

local function CheckShamanWeaponEnchant(chatOnly)
    if checkShamanWeaponEnchant and hasWeaponEnchantment
    then
	local hasMainHandEnchant, hasOffHandEnchant = mod:HasWeaponEnchants();

	if hasMainHandEnchant ~= nil and (hasOffhandEnchant ~= nil or not OffhandHasWeapon())
	then
	else
	    mod:ReportMessage(mod.shamanWeaponEnchantment, chatOnly);
	end
    end
end

local shamanShieldList = { [mod.waterShield] = true, [mod.lightningShield] = true, [mod.earthShield] = true };

local function CheckShamanShield(chatOnly)
    if checkShamanShield and hasShamanShield
    then
	local i, buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster = 1, nil, nil, nil, nil, nil, nil, nil, nil;

	repeat
	    buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster = UnitBuff(mod.unitPlayer, i);
	    i = i + 1;

	    if buffName ~= nil
	    then
		if shamanShieldList[buffName] ~= nil and UnitIsUnit(unitCaster)
		then
		    return
		end
	    end
	until buffName == nil

	mod:ReportMessage(mod:AbilityToCastMessage(mod.shamanElementalShield), chatOnly);
    end
end

function RoleBuffAddOn.GetShamanRole()
    if isRestaurationShaman 
    then
	return mod.roleHealer;
    else
	return mod.roleDPS;
    end
end

local function CombatCheckShaman(chatOnly, frame, event, ...)
    CheckShamanWeaponEnchant(chatOnly);
    CheckShamanShield(chatOnly)
end

mod.EventHandlerTableShaman =
{
    [mod.eventPlayerAlive] = OnPlayerAlive,
    [mod.eventActiveTalentGroupChanged] = OnPlayerAlive,

    [mod.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not ShamanAttacked and not ShamanAttacking
	then
	    CombatCheckShaman(false, frame, event, ...);
	end
	ShamanAttacked = true;
    end,

    [mod.eventPlayerRegenEnabled] = function(frame, event, ...)
	ShamanAttacked = false;
    end,

    [mod.eventPlayerEnterCombat] = function(frame, event, ...)
	if not ShamanAttacking and not ShamanAttacked
	then
	    CombatCheckShaman(false, frame, event, ...);
	end
	ShamanAttacking = true;
    end,

    [mod.eventPlayerLeaveCombat] = function(frame, event, ...)
	ShamanAttacking = false;
    end
};

mod.SlashCommandHandlerShaman =
{
    [mod.slashCommandPlayerCheck] = function()
	OnPlayerAlive(nil, nil)
    end,

    [mod.slashCommandCombatCheck] = function()
	CombatCheckShaman(true, nil, nil)
    end
};

function mod:ShamanOptionsFrameLoad(panel)
    panel.name = mod.classNameShaman;
    panel.parent = mod.displayName;
    InterfaceOptions_AddCategory(panel)
end
