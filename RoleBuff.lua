-- Wow 3.3.5a add-on to check for simple role-specific buffs when entering combat
-- Uses WowAPI.lua, RoleBuffWarrior.lua
-- Check any player for:
--	- fishing pole equipped
--	- missing gear items above some level

local mod = RoleBuffAddOn;

local RoleBuff_Enabled = true;

local opt =
{
    ["global"] = mod:ReadAddOnStorage(true, { "options", "global" }, "optMainHandOffHand", "optFishingPole", "optEmptyGear"),
    ["classes"] = mod:ReadAddOnStorage(true, { "options", "classes" },
	{
	    mod.playerClassEnDeathKnight, -- mod.playerClassEnDruid, mod.playerClassEnHunter, mod.playerClassEnMage, mod.playerClassEnMonk,
	    mod.playerClassEnPaladin, -- mod.playerClassEnPriest,
	    mod.playerClassEnRogue,
	    mod.playerClassEnShaman,
	    mod.playerClassEnWarlock,
	    mod.playerClassEnWarrior
	})
}

local RoleBuff_CheckEmptyGear = false;

local RoleBuff_PlayerAttacking, RoleBuff_PlayerAttacked = false, false;

local function combatCheckFishingPole(chatOnly)
    if opt.global.optFishingPole and
	(
	    tonumber(mod.clientBuildNumber) < 7561 and IsEquippedItemType(mod.itemTypeFishingPole)
		or
	    tonumber(mod.clientBuildNumber) >= 7561 and IsEquippedItemType(mod.itemTypeFishingPoles)	-- patch 2.3 The Gods of Zul'Aman
	)
    then
	mod:ReportMessage(mod:ItemEquippedMessage(mod.itemTypeFishingPole), chatOnly);
    end
end

local function combatCheckMainHandOffHand(chatOnly)
    if opt.global.optMainHandOffHand
    then
	local mainHandSlot, _ = GetInventorySlotInfo(mod.mainHandSlot);
	local offHandSlot, _ = GetInventorySlotInfo(mod.secondaryHandSlot);

	if GetInventoryItemID(mod.unitPlayer, mainHandSlot) == nil
	then
	    mod:ReportMessage(mod:ItemEquipMessage(mod.itemMainHandWeapon), chatOnly)
	end

	if GetInventoryItemID(mod.unitPlayer, offHandSlot) == nil and not IsEquippedItemType(mod.itemTypeTwoHand)
	then
	    mod:ReportMessage(mod:ItemEquipMessage(mod.itemOffHand), chatOnly)
	end
    end
end

local function combatCheckPlayer(chatOnly)
    combatCheckFishingPole(chatOnly);
    combatCheckMainHandOffHand(chatOnly);
    mod:CombatCheckGearSpec(chatOnly)
end

mod.trivialNpcCache, mod.trivialNpcIdCache = { }, { };

local function readUnitID(unitID)
    if UnitExists(unitID) and not UnitIsFriend(mod.unitPlayer, unitID) and UnitIsTrivial(unitID)
    then
	local unitGUID = UnitGUID(unitID);
	if unitGUID ~= nil
	then
	    local unitType, npcID, petID = mod:GetTypeAndID(unitGUID);

	    if unitType == mod.guidTypeNPC and mod.trivialNpcIdCache[npcID] == nil
	    then
		table.insert(mod.trivialNpcCache, 1, npcID);
		mod.trivialNpcIdCache[npcID] = true;

		if #mod.trivialNpcCache > 32
		then
		    mod.trivialNpcIdCache[mod.trivialNpcCache[#mod.trivialNpcCache]] = nil;
		    table.remove(mod.trivialNpcCache)
		end

		mod:DebugMessage("NPC " .. UnitName(unitID) .. " with ID " .. npcID .. " is trivial.")
	    end
	end
    end
end

local function combatEventHandler(frame, event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags)
    if UnitIsUnit(destName, mod.unitPlayer) and bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE)
    then
	-- A hostile unit does something to you in combat log
	local npcID = tonumber(sourceGUID:sub(9, 12), 16);
	local trivialString = "";
	if UnitIsTrivial(npcID)
	then
	    trivialString = "trivial "
	end
	print(eventType .. " from " .. trivialString .. " "  .. sourceName .. " (, NPC ID: " .. npcID .. ", GUID" .. sourceGUID .. ")")
    end
end

local RoleBuff_BaseEventHandlerTable =
{
    [mod.eventPlayerAlive] = function (frame, event, ...)
	mod:GearSpec_InitialPlayerAlive(frame, event, ...)
	frame:UnregisterEvent(mod.eventPlayerAlive);
    end,

    [mod.eventUpdateMouseoverUnit] = function(frame, event, ...) readUnitID(mod.unitMouseover) end,
    [mod.eventUnitTarget] = function(frame, event, unitId) readUnitID(unitId .. "-target") end,
    -- ["ADDON_LOADED"] = function(frame, even, addOnName)
    --     if addOnName == "RoleBuff"
    --     then
    --         -- mod:GetPlayerBuild()
    --         print("AddOn loaded: " .. mod.displayName)
    --     end
    -- end,
    --
    -- ["UNIT_THREAT_LIST_UPDATE"] = function(frame, event, unitId)
    --     print("Threat list update for " .. unitId)
    -- end,

    -- ["UNIT_THREAT_SITUATION_UPDATE"] = function(frame, event, unitId)
    --     print("Threat situation update for " .. unitId)
    -- end,

    -- ["COMBAT_LOG_EVENT_UNFILTERED"] = combatEventHandler,
    -- ["SWING_DAMAGE"] = combatEventHandler,
    -- ["SPELL_DAMAGE"] = combatEventHandler,
    -- ["RANGE_DAMAGE"] = combatEventHandler,

    [mod.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_PlayerAttacking and not RoleBuff_PlayerAttacked
	then
	    combatCheckPlayer(false);
	end

	RoleBuff_PlayerAttacked = true;
    end,

    [mod.eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_PlayerAttacked = false;
	mod:GearSetRoleAnnounce(frame, event, ...)
    end,

    [mod.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_PlayerAttacking and not RoleBuff_PlayerAttacked
	then
	    combatCheckPlayer(false);
	end

	RoleBuff_PlayerAttacking = true;
    end,

    [mod.eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_PlayerAttacking = false;
    end,

    [mod.eventReadyCheck] = function(frame, event, ...)
	mod:SlashCmdHandler(mod.slashCommandCombatCheck);
    end,

    [mod.eventUnitInventoryChanged] = function(frame, event, unitId, ...)
	mod:UnitInventoryChanged(unitId);
	return mod:OnGearSetEvent(frame, event, ...)
    end,
    [mod.eventEquipmentSetsChanged] = function(frame, event, ...) return mod:OnGearSetEvent(frame, event, ...) end,
    [mod.eventEquipmentSwapPending] = function(frame, event, ...) return mod:OnGearSetEvent(frame, event, ...) end,
    [mod.eventEquipmentSwapFinished] = function(frame, event, ...) return mod:OnGearSetEvent(frame, event, ...) end,
    [mod.eventWearEquipmentSet] = function(frame, event, ...) return mod:OnGearSetEvent(frame, event, ...) end,
    [mod.eventActiveTalentGroupChanged] = function(frame, event, ...) return mod:OnGearSetEvent(frame, event, ...) end
};

local classEventHandlerTable =
{
    [mod.playerClassEnWarrior] = mod.EventHandlerTableWarrior,
    [mod.playerClassEnDeathKnight] = mod.EventHandlerTableDeathKnight,
    [mod.playerClassEnPaladin] = mod.EventHandlerTablePaladin,
    [mod.playerClassEnWarlock] = mod.EventHandlerTableWarlock,
    [mod.playerClassEnShaman] = mod.EventHandlerTableShaman,
    [mod.playerClassEnRogue] = mod.EventHandlerTableRogue
};

mod.ClassGetRoleTable =
{
    [mod.playerClassEnWarrior] = mod.GetWarriorRole,
    [mod.playerClassEnDeathKnight] = mod.GetDeathKnightRole,
    [mod.playerClassEnPaladin] = mod.GetPaladinRole,
    [mod.playerClassEnWarlock] = mod.GetWarlockRole,
    [mod.playerClassEnShaman] = mod.GetShamanRole,
    [mod.playerClassEnRogue] = mod.GetRogueRole,
    [mod.playerClassEnPriest] = function()
	local specIndex, specName = mod:GetPlayerBuild()

	if specName == mod.holySpecName
	then
	    return mod.roleHealer;
	else
	    return mod.roleDPS;
	end
    end,
    [mod.playerClassEnDruid] = function() return nil; end
};

local slashCommandHandlerTable =
{
};

local classCommandHandlerTable =
{
    [mod.playerClassEnWarrior] = mod.SlashCommandHandlerWarrior,
    [mod.playerClassEnDeathKnight] = mod.SlashCommandHandlerDeathKnight,
    [mod.playerClassEnPaladin] = mod.SlashCommandHandlerPaladin,
    [mod.playerClassEnWarlock] = mod.SlashCommandHandlerWarlock,
    [mod.playerClassEnShaman] = mod.SlashCommandHandlerShaman,
    [mod.playerClassEnRogue] = mod.SlashCommandHandlerRogue
};

local baseCommandHandlerTable =
{
    [mod.slashCommandEnable] = function()
	RoleBuff_Enabled = true;
	print(mod.addonEnabledMessage);
    end,

    [mod.slashCommandDisable] = function()
	RoleBuff_Enabled = false;
	print(mod.addonDisabledMessage);
    end,

    [mod.slashCommandSpec] = function()
	if mod.playerClassEn ~= nil
	then
	    local specIndex, specName = mod:GetPlayerBuild();
	    print(mod:FormatSpecialization(mod.playerClassLocalized, specName));
	end

	if not RoleBuff_Enabled
	then
	    print(mod.addonDisabledMessage);
	end
    end,

    [mod.slashCommandPlayerCheck] = function()
	if classEventHandlerTable[mod.playerClassEn] == nil
	then
	    print(mod:NoClassSupportMessage(mod.playerClassLocalized));
	else
	    if opt.classes[mod.playerClassEn] ~= nil and not opt.classes[mod.playerClassEn]
	    then
		print(mod:ClassDisabledMessage(mod.playerClassLocalized));
	    end
	end
    end,

    [mod.slashCommandEquipmentSet] = function(cmdLine) return mod:SlashCommandEquipmentSet(cmdLine) end,

    [mod.slashCommandGearSpec] = function(cmdLine) return mod:GearSpecCheck() end,

    [mod.slashCommandSetDebug] = function(cmdLine)
	if cmdLine[2] ~= nil and cmdLine[2] == "on"
	then
	    mod.printDebugMessages = true
	end

	if cmdLine[2] ~= nil and cmdLine[2] == "off"
	then
	    mod.printDebugMessages = false
	end

	if not cmdLine[2]
	then
	    local verboseMode

	    if mod.printDebugMessages
	    then
		verboseMode = "on"
	    else
		verboseMode = "off"
	    end

	    print(mod.displayName .. ": " .. mod.slashCommandSetDebug .. " " .. verboseMode .. ".")
	end
    end,

    [mod.slashCommandInGroup] = function(cmdLine)
	if cmdLine[2] and cmdLine[2] == "on"
	then
	    mod.usePlayerInGroup = true
	end

	if cmdLine[2] and cmdLine[2] == "off"
	then
	    mod.usePlayerInGroup = false
	end

	if not cmdLine[2]
	then
	    local groupMode

	    if mod.usePlayerInGroup
	    then
		groupMode = "on"
	    else
		groupMode = "off"
	    end
	    print(mod.displayName .. ": " .. mod.slashCommandInGroup .. " " .. groupMode .. ".")
	end
    end
};

baseCommandHandlerTable[mod.slashCommandCombatCheck] = function()
    combatCheckPlayer(true);
    baseCommandHandlerTable[mod.slashCommandPlayerCheck]();
end;

-- called from XML
function mod:OnLoad(frame)
    if self.AddOnLocalized and self.UserStringsLocalized
    then
	frame:RegisterEvent(mod.eventAddOnLoaded);
    else
	print("RoleBuff: New add-on translation is needed for your World of Warcraft client language.");
	print("RoleBuff: Not loaded.");
    end
end

local function RoleBuff_ErrorHandler(errorMessage)
    print(mod.displayName .. ": " .. errorMessage);
    return errorMessage
end

local eventHandlerTable =
{
};

local function onAddOnLoaded(frame, event, ...)
    opt =
    {
	["global"] = mod:ReadAddOnStorage(true, { "options", "global" }, "optMainHandOffHand", "optFishingPole", "optEmptyGear"),
	["classes"] = mod:ReadAddOnStorage(true, { "options", "classes" },
	    {
		mod.playerClassEnDeathKnight, -- mod.playerClassEnDruid, mod.playerClassEnHunter, mod.playerClassEnMage, mod.playerClassEnMonk,
		mod.playerClassEnPaladin, -- mod.playerClassEnPriest,
		mod.playerClassEnRogue,
		mod.playerClassEnShaman,
		mod.playerClassEnWarlock,
		mod.playerClassEnWarrior
	    })
    };

    if mod.playerClassEn == nil
    then
	mod.playerClassLocalized, mod.playerClassEn, mod.playerClassIndex = UnitClass(mod.unitPlayer);

	frame:UnregisterEvent(mod.eventPlayerAlive);
	-- frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE");
	-- frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE");
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	frame:RegisterEvent(mod.eventPlayerAlive);
	frame:RegisterEvent(mod.eventPlayerRegenEnabled);
	frame:RegisterEvent(mod.eventPlayerRegenDisabled);
	frame:RegisterEvent(mod.eventPlayerEnterCombat);
	frame:RegisterEvent(mod.eventPlayerLeaveCombat);
	frame:RegisterEvent(mod.eventReadyCheck);
	frame:RegisterEvent(mod.eventUpdateMouseoverUnit);
	frame:RegisterEvent(mod.eventUnitTarget);

	if opt.classes[mod.playerClassEn] ~= nil
	then
	    if opt.classes[mod.playerClassEn]
	    then
		if classEventHandlerTable[mod.playerClassEn] ~= nil
		then
		    eventHandlerTable = classEventHandlerTable[mod.playerClassEn];
		    mod:OnEvent(frame, event, ...);

		    if eventHandlerTable[mod.eventPlayerAlive] ~= nil
		    then
			eventHandlerTable[mod.eventPlayerAlive](frame, event, ...)
		    end

		    print(mod.addonLoadedMessage)
		else
		    print(mod:NoClassSupportMessage(mod.playerClassLocalized))
		end
	    else
		print(mod:ClassDisabledMessage(mod.playerClassLocalized))
	    end
	else
	    print(mod:NoClassSupportMessage(mod.playerClassLocalized))
	end

	if classCommandHandlerTable[mod.playerClassEn] ~= nil
	then
	    slashCommandHandlerTable = classCommandHandlerTable[mod.playerClassEn]
	end

	mod:GearSpec_InitialPlayerAlive(frame, event, ...)
    end
end

eventHandlerTable[mod.eventAddOnLoaded] = onAddOnLoaded;

-- called from XML
function mod:OnEvent(frame, event, ...)
    if RoleBuff_Enabled
    then
	if eventHandlerTable[event]
	then
	    eventHandlerTable[event](frame, event, ...);
	end

	if RoleBuff_BaseEventHandlerTable[event]
	then
	    RoleBuff_BaseEventHandlerTable[event](frame, event, ...);
	end
    end
end

function mod:OnUpdate(frame, elapsedFrameTime)
    if self.UpdateHandlersSet
    then
	for _, handlerFn in pairs(self.UpdateHandlersSet)
	do
	    handlerFn(elapsedFrameTime)
	end
    end
end

function mod:SlashCmdHandler(msg)
    local cmdLine = { };

    if msg == nil
    then
	msg = "";
    end

    for arg in string.gmatch(msg, "[^ ]+")
    do
      tinsert(cmdLine, arg)
    end

    if #cmdLine == 0
    then
	msg = ""
    else
	msg = string.lower(cmdLine[1])
    end

    if slashCommandHandlerTable[msg] ~= nil or baseCommandHandlerTable[msg] ~= nil
    then
	if slashCommandHandlerTable[msg] ~= nil
	then
	    slashCommandHandlerTable[msg](cmdLine)
	end

	if baseCommandHandlerTable[msg] ~= nil
	then
	    baseCommandHandlerTable[msg](cmdLine)
	end
    else
	print(self.commandSyntaxIntroLine);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandSpec);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandEnable);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandDisable);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandPlayerCheck);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandCombatCheck);
	if tonumber(mod.clientBuildNumber) >= 9901	-- Path 3.1.2 needed for Equipment Manager
	then
	    print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandEquipmentSet .. " <EquipmentSet> <ExpectedRole>");
	    print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandEquipmentSet .. " <EquipmentSet> <ExpectedRole> [primary|secondary]");
	    print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandSwitchSpec);
	end
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandGearSpec);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandSetDebug .. " on|off");
    end
end

function mod:OptionValueChanged(panelName, optionName, optionValue)
    if self.optionsCache == nil
    then
	self.optionsCache = { }
    end

    if self.optionsCache[panelName] == nil
    then
	self.optionsCache[panelName] = { }
    end

    self.optionsCache[panelName][optionName] = optionValue
end

function mod:OptionsFrameLoad(panel)
    panel.name = self.displayName;
    panel.okay = function(self)
	-- print(displayName .. ": Interface options Okay.")
    end;
    panel.cancel = function(self)
	-- print(displayName .. ": Interface options Cancel.")
    end;
    panel.default = function(self)
	-- print(displayName .. ": Interface options defaults.")
    end;
    InterfaceOptions_AddCategory(panel);
end
