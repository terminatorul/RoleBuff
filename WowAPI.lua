-- strings here must match the WoW AddOn API (no translations)

local mod = RoleBuffAddOn;

mod.clientVersionString, mod.clientBuildNumber, mod.clientDate = GetBuildInfo();

-- localization files can set these variables to true after translated strings have been declared --
mod.AddOnLocalized, mod.UserStringsLocalized = false, false;

local apiStringsTable = 
{
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
    eventReadyCheck = "READY_CHECK";

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
};

for key, val in pairs(apiStringsTable)
do
    mod[key] = val;
end

mod.classRoles = 
{
    [mod.playerClassEnWarrior] = { mod.roleDPS, mod.roleTank }, [mod.playerClassEnPaladin] = { mod.roleDPS, mod.roleTank, mod.roleHealer },
    [mod.playerClassEnDeathKnight] = { mod.roleDPS, mod.roleTank }, [mod.playerClassEnWarlock] = { mod.roleDPS },
    [mod.playerClassEnShaman] = { mod.roleDPS, mod.roleHealer }, [mod.playerClassEnRogue] = { mod.roleDPS },
    [mod.playerClassEnMage] = { mod.roleDPS }, [mod.playerClassEnPriest] = { mod.roleDPS, mod.roleHealer },
    [mod.playerClassEnDruid] = { mod.roleDPS, mod.roleTank, mod.roleHealer }, [mod.playerClassEnHunter] = { mod.roleDPS },
    [mod.playerClassEnMonk] = { mod.roleDPS, mod.roleTank, mod.roleHealer }
};

mod.classRolesCount =
{
    [mod.playerClassEnWarrior] =	#mod.classRoles[mod.playerClassEnWarrior],
    [mod.playerClassEnPaladin] =	#mod.classRoles[mod.playerClassEnPaladin],
    [mod.playerClassEnDeathKnight] =    #mod.classRoles[mod.playerClassEnDeathKnight],
    [mod.playerClassEnWarlock] =	#mod.classRoles[mod.playerClassEnWarlock],
    [mod.playerClassEnShaman] =		#mod.classRoles[mod.playerClassEnShaman],
    [mod.playerClassEnRogue] =		#mod.classRoles[mod.playerClassEnRogue],
    [mod.playerClassEnMage] =		#mod.classRoles[mod.playerClassEnMage],
    [mod.playerClassEnPriest] =		#mod.classRoles[mod.playerClassEnPriest],
    [mod.playerClassEnDruid] =		#mod.classRoles[mod.playerClassEnDruid],
    [mod.playerClassEnHunter] =		#mod.classRoles[mod.playerClassEnHunter],
    [mod.playerClassEnMonk] =		#mod.classRoles[mod.playerClassEnMonk]
};
