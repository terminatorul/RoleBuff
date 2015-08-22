
-- If you translate this file to your WoW client language, you can contribute
-- the translated file back to the add-on author at the e-mail address:
--	Timothy Madden <terminatorul@gmail.com>
--

if GetLocale() == enGB or GetLocale() == enUS
then

displayName = "RoleBuff";	-- this is usually not translated
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
commandSyntaxIntroLine = "Syntax: ";
addonLoadedMessage = displayName .. " loaded.";
addonEnabledMessage = displayName .. " enabled.";
addonDisabledMessage = displayName .. " disabled.";

setCommandArgsMessage = displayName .. ": <EquipmentSet> and <ExpectedRole> arguments expected.";
setCommandSingleRoleClass = displayName .. ": set command only used for classes with multiple roles.";
setCommandFirstArgMessage = displayName ..  ": First argument to set command should give the name of one of your existing equipment sets.";
setCommandSecondArgMessage = displayName .. ": Second argument to set command must be a player role name: DPS, Tank or Healer .";
setCommandUsageIntroLine = "Use:";
setCommandUsageClosingLine = "and set a role for each equipment set.";
equipmentMissmatchMessage = displayName .. ": Equipment set missmatch.";
equipmentMatchMessage = displayName .. ": Equipment set match.";
equipmentMatchNeededMessage = displayName ..": Multiple equipment sets with different player roles needed to check gear specialization.";
equipmentMatchSingleRoleClass = displayName .. ": Gear specialization check only used for classes with multiple roles.";
equipmentMatchDisabled = displayName .. ": Gear specialization check disabled.";

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

function RoleBuff_NoClassSupportMessage(className)
    return displayName .. ": No support for " .. className .. " class.";
end

function RoleBuff_ClassDisabledMessage(className)
    return displayName .. ": " .. className .. " " .. " class disabled.";
end

function RoleBuff_AbilityFoundMessage(abilityName)
    return "Found " .. abilityName .. " ability.";
end

-- Compose for example "Dual-wielding Frost Death Knight" from the base "Death Knight"
-- and the spcializations "Frost", "Dual-wielding"
function RoleBuff_FormatSpecialization(base, ...)
    local specList = { ... };
    local resultString = base;

    for specIndex = 1, #specList
    do
	resultString = specList[specIndex] .. " " .. resultString;
    end

    return resultString;
end

-- e.g. "Switch to Dire Bear"
function RoleBuff_SwitchFormMessage(classForm)
    return "Switch to " .. classForm
end

-- e.g. "Cast Warlock Armor"
function RoleBuff_AbilityToCastMessage(abilityName)
    return "Cast " .. abilityName
end

-- e.g. "Create Greater Healthstone"
function RoleBuff_CreateItemMessage(itemName)
    return "Create " .. itemName
end

-- e.g. "Equip shield"
function RoleBuff_ItemEquipMessage(itemName)
    return "Equip " .. itemName
end

-- e..g "Fishing Pole equipped"
function RoleBuff_ItemEquippedMessage(itemName)
    return itemName .. " equipped"
end

-- e.g. "Righteous Fury" (when active for non-tanks)
function RoleBuff_AbilityActiveMessage(abilityName)
    return abilityName
end

-- e.g. "Use Greater Soulstone"
function RoleBuff_UseItemMessage(itemName)
    return "Use " .. itemName
end

-- e.g. "Use Rogue Weapon Poison"
function RoleBuff_UseEnhancementMessage(enhancementName)
    return "Use " .. enhancementName
end

function RoleBuff_SummonUnitMessage(unitReference)
    return "Summon " .. unitReference
end

function RoleBuff_ApplyEnchantmentMessage(enchantmentReference)
    return "Apply " .. enchantmentReference
end

slashCommandSpec = "spec";
slashCommandPlayerCheck = "player-check";
slashCommandCombatCheck = "combat-check";
slashCommandEnable = "enable";
slashCommandDisable = "disable";
slashCommandEquipmentSet = "set";
slashCommandGearSpec = "gear-spec";
slashCommandSetDebug = "verbose";

RoleBuff_UserStringsLocalized = true

end
