
-- If you translate this file to your WoW client language, you can contribute
-- the translated file back to the add-on author at the e-mail address:
--	Timothy Madden <terminatorul@gmail.com>
--

local mod = RoleBuffAddOn;

if GetLocale() == mod.enGB or GetLocale() == mod.enUS
then
    mod.displayName = "RoleBuff";	-- this is usually not translated

    local translationTableEn = 
    {
	playerRoleTank = "Tank";
	playerRoleHealer = "Healer";
	playerRoleDPS = "DPS";
	hybridPlayerBuildIntroLine = "Hybrid player build:";
	paladinAura = "Paladin Aura";
	paladinSeal = "Paladin Seal";
	paladinBlessing = "Paladin Blessing";
	warlockMinion = "Warlock Minion";
	warlockArmor = "Warlock Armor";
	warlockWeaponEnchantment = "Warlock Weapon Enchantment";
	rogueWeaponPoison = "Rogue Weapon Posion";
	shamanElementalWeapon = "Elemental Weapon";
	shamanElementalShield = "Elemental Shield";
	commandSyntaxIntroLine = "Syntax: ";
	addonLoadedMessage = mod.displayName .. " loaded.";
	addonEnabledMessage = mod.displayName .. " enabled.";
	addonDisabledMessage = mod.displayName .. " disabled.";

	setCommandArgsMessage = mod.displayName .. ": <EquipmentSet> and <ExpectedRole> arguments expected.";
	setCommandSingleRoleClass = mod.displayName .. ": set command only used for classes with multiple roles.";
	setCommandFirstArgMessage = mod.displayName ..  ": First argument to set command should give the name of one of your existing equipment sets.";
	setCommandSecondArgMessage = mod.displayName .. ": Second argument to set command must be a player role name: DPS, Tank or Healer .";
	setCommandUsageIntroLine = "Use:";
	setCommandUsageClosingLine = "and set a role for each equipment set.";
	equipmentMissmatchMessage = mod.displayName .. ": Equipment set missmatch.";
	equipmentMatchMessage = mod.displayName .. ": Equipment set match.";
	equipmentMatchNeededMessage = mod.displayName ..": Multiple equipment sets with different player roles needed to check gear specialization.";
	equipmentMatchSingleRoleClass = mod.displayName .. ": Gear specialization check only used for classes with multiple roles.";
	equipmentMatchDisabled = mod.displayName .. ": Gear specialization check disabled.";

	itemMainHandWeapon = "Main Hand Weapon";
	itemOffHand = "Off Hand";

	-- warrior
	itemShield = "Shield";
	warningNoWarriorStance = "No Warrior stance!";

	-- Death Knight
	itemOneHandWeapon = "One-Hand weapon";
	abilityDualWielding = "Dual-wielding";
	warningNoDeathKnightPresence = "No Death Knight presence!";
	warningSwitchGear = "Switch gear";

	slashCommandSpec = "spec";
	slashCommandPlayerCheck = "player-check";
	slashCommandCombatCheck = "combat-check";
	slashCommandEnable = "enable";
	slashCommandDisable = "disable";
	slashCommandEquipmentSet = "set";
	slashCommandGearSpec = "gear-spec";
	slashCommandSetDebug = "verbose";
	slashCommandInGroup = "always-in-group";
    };

    for key, val in pairs(translationTableEn)
    do
	RoleBuffAddOn[key] = val
    end

    function RoleBuffAddOn:NoClassSupportMessage(className)
	return self.displayName .. ": No support for " .. className .. " class.";
    end

    function RoleBuffAddOn:ClassDisabledMessage(className)
	return self.displayName .. ": " .. className .. " " .. " class disabled.";
    end

    function RoleBuffAddOn:AbilityFoundMessage(abilityName)
	return "Found " .. abilityName .. " ability.";
    end

    -- Compose for example "Dual-wielding Frost Death Knight" from the base "Death Knight"
    -- and the spcializations "Frost", "Dual-wielding"
    function RoleBuffAddOn:FormatSpecialization(base, ...)
	local specList = { ... };
	local resultString = base;

	for specIndex = 1, #specList
	do
	    resultString = specList[specIndex] .. " " .. resultString;
	end

	return resultString;
    end

    -- e.g. "Switch to Dire Bear"
    function RoleBuffAddOn:SwitchFormMessage(classForm)
	return "Switch to " .. classForm
    end

    -- e.g. "Cast Warlock Armor"
    function RoleBuffAddOn:AbilityToCastMessage(abilityName)
	return "Cast " .. abilityName
    end

    -- e.g. "Create Greater Healthstone"
    function RoleBuffAddOn:CreateItemMessage(itemName)
	return "Create " .. itemName
    end

    -- e.g. "Equip shield"
    function RoleBuffAddOn:ItemEquipMessage(itemName)
	return "Equip " .. itemName
    end

    -- e..g "Fishing Pole equipped"
    function RoleBuffAddOn:ItemEquippedMessage(itemName)
	return itemName .. " equipped"
    end

    -- e.g. "Righteous Fury" (when active for non-tanks)
    function RoleBuffAddOn:AbilityActiveMessage(abilityName)
	return abilityName
    end

    -- e.g. "Use Greater Soulstone"
    function RoleBuffAddOn:UseItemMessage(itemName)
	return "Use " .. itemName
    end

    -- e.g. "Use Rogue Weapon Poison"
    function RoleBuffAddOn:UseEnhancementMessage(enhancementName)
	return "Use " .. enhancementName
    end

    function RoleBuffAddOn:SummonUnitMessage(unitReference)
	return "Summon " .. unitReference
    end

    function RoleBuffAddOn:ApplyEnchantmentMessage(enchantmentReference)
	return "Apply " .. enchantmentReference
    end

    function RoleBuffAddOn:MissingItemMessage(itemName)
	return "Missing " .. itemName
    end

    RoleBuffAddOn.UserStringsLocalized = true
end
