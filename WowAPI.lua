-- strings here must match the WoW AddOn API (no translations)

clientVersionString, clientBuildNumber, clientDate = GetBuildInfo();

-- localization files can set these variables to true after translated strings have been declared --
RoleBuff_AddOnLocalized, RoleBuff_UserStringsLocalized = false, false;

enUS = "enUS";
enGB = "enGB";
frFR = "frFR";
deDE = "deDE";
itIT = "itIT";
koKR = "koKR";
zhCN = "zhCN";
zhTW = "zhTW";
ruRU = "ruRU";
esES = "esES";
esMX = "esMX";
ptBR = "ptBR";

eventAddOnLoaded = "ADDON_LOADED";
eventPlayerAlive = "PLAYER_ALIVE";				-- talents information is now available
eventPlayerRegenDisabled = "PLAYER_REGEN_DISABLED";             -- used as "enter combat" indicator
eventPlayerRegenEnabled = "PLAYER_REGEN_ENABLED";
eventPlayerEnterCombat = "PLAYER_ENTER_COMBAT";
eventPlayerLeaveCombat = "PLAYER_LEAVE_COMBAT";
eventPlayerDead = "PLAYER_DEAD";
eventUnitSpellCastSucceeded = "UNIT_SPELLCAST_SUCCEEDED";       -- succeeded or resisted, actually
eventPartyMembersChanged = "PARTY_MEMBERS_CHANGED";
eventRaidRoosterUpdate = "RAID_ROSTER_UPDATE";
eventActiveTalentGroupChanged = "ACTIVE_TALENT_GROUP_CHANGED";
eventUpdateShapeshiftForms = "UPDATE_SHAPESHIFT_FORMS";
eventUpdateShapeshiftForm = "UPDATE_SHAPESHIFT_FORM";
eventUnitSpellCastSucceeded = "UNIT_SPELLCAST_SUCCEEDED";
eventUnitAura = "UNIT_AURA";
eventUnitInventoryChanged = "UNIT_INVENTORY_CHANGED";
eventEquipmentSetsChanged = "EQUIPMENT_SETS_CHANGED";
eventEquipmentSwapPending = "EQUIPMENT_SWAP_PENDING";
eventEquipmentSwapFinished = "EQUIPMENT_SWAP_FINISHED";
eventWearEquipmentSet = "WEAR_EQUIPMENT_SET";
eventCompanionUpdate = "COMPANION_UPDATE";			-- companion or mount

playerClassLocalized = "";
playerClassEn = nil;
playerClassIndex = 0;

-- WoW 3.3.5a has 10 classes ("Mists of Pandaria" expansion added the "Monk" class)
playerClassEnWarrior = "WARRIOR";
playerClassEnPaladin = "PALADIN";
playerClassEnDeathKnight = "DEATHKNIGHT";   -- Introduced in Wrath of the Lich King expansion
playerClassEnWarlock = "WARLOCK";
playerClassEnShaman = "SHAMAN";
playerClassEnRogue = "ROGUE";
playerClassEnMage = "MAGE";
playerClassEnPriest = "PRIEST";
playerClassEnDruid = "DRUID";
playerClassEnHunter = "HUNTER";
playerClassEnMonk = "MONK";		    -- Introduced in Mists of Pandaria expansion

roleDPS = "DAMAGER";
roleTank = "TANK";
roleHealer = "HEALER";

classRoles = 
{
    [playerClassEnWarrior] = { roleDPS, roleTank }, [playerClassEnPaladin] = { roleDPS, roleTank, roleHealer },
    [playerClassEnDeathKnight] = { roleDPS, roleTank }, [playerClassEnWarlock] = { roleDPS },
    [playerClassEnShaman] = { roleDPS, roleHealer }, [playerClassEnRogue] = { roleDPS },
    [playerClassEnMage] = { roleDPS }, [playerClassEnPriest] = { roleDPS, roleHealer },
    [playerClassEnDruid] = { roleDPS, roleTank, roleHealer }, [playerClassEnHunter] = { roleDPS },
    [playerClassEnMonk] = { roleDPS, roleTank, roleHealer }
};

classRolesCount =
{
    [playerClassEnWarrior] =	    #classRoles[playerClassEnWarrior],
    [playerClassEnPaladin] =	    #classRoles[playerClassEnPaladin],
    [playerClassEnDeathKnight] =    #classRoles[playerClassEnDeathKnight],
    [playerClassEnWarlock] =	    #classRoles[playerClassEnWarlock],
    [playerClassEnShaman] =	    #classRoles[playerClassEnShaman],
    [playerClassEnRogue] =	    #classRoles[playerClassEnRogue],
    [playerClassEnMage] =	    #classRoles[playerClassEnMage],
    [playerClassEnPriest] =	    #classRoles[playerClassEnPriest],
    [playerClassEnDruid] =	    #classRoles[playerClassEnDruid],
    [playerClassEnHunter] =	    #classRoles[playerClassEnHunter],
    [playerClassEnMonk] =	    #classRoles[playerClassEnMonk]
};

unitPlayer = "player";
unitTarget = "target";
unitPet = "pet";

filterPlayer = "PLAYER";

defaultVigilanceDurationSec = 30 * 60;

-- Gear slots
headSlot = "HeadSlot";
neckSlot = "NeckSlot";
shoulderSlot = "ShoulderSlot";
backSlot = "BackSlot";
chestSlot = "ChestSlot";
shirtSlot = "ShirtSlot";
tabardSlot = "TabardSlot";
wristSlot = "WristSlot";
handsSlot = "HandsSlot";
waistSlot = "WaistSlot";
legsSlot = "LegsSlot";
feetSlot = "FeetSlot";
fingerSlot0 = "Finger0Slot";
fingerSlot1 = "Finger1Slot";
trinketSlot0 = "Trinket0Slot";
trinketSlot1 = "Trinket1Slot";
mainHandSlot = "MainHandSlot";
offHandSlot = "SecondaryHandSlot";
rangedSlot = "RangedSlot";		-- removed in Cataclysm
ammoSlot = "AmmoSlot";			-- removed in Cataclysm
