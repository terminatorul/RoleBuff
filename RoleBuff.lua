-- Wow 3.3.5a add-on to check for simple role-specific buffs when entering combat
-- Uses WowAPI.lua, RoleBuffWarrior.lua
-- Check any player for:
--	- fishing pole equipped
--	- missing gear items above some level

local this, mod = RoleBuffAddOn, RoleBuffAddOn;

local RoleBuff_Enabled = true;

local opt =
{
    ["global"] = this:ReadAddOnStorage(true, { "options", "global" }, "optMainHandOffHand", "optFishingPole", "optEmptyGear"),
    ["classes"] = this:ReadAddOnStorage(true, { "options", "classes" },
	{
	    this.playerClassEnDeathKnight, -- this.playerClassEnDruid, this.playerClassEnHunter, this.playerClassEnMage, this.playerClassEnMonk, 
	    this.playerClassEnPaladin, -- this.playerClassEnPriest, 
	    this.playerClassEnRogue, -- this.playerClassEnShaman, 
	    this.playerClassEnWarlock, this.playerClassEnWarrior
	})
}

local RoleBuff_CheckEmptyGear = false;

local RoleBuff_PlayerAttacking, RoleBuff_PlayerAttacked = false, false;

local RoleBuff_Debug = false;

function RoleBuffAddOn:DebugMessage(msg)
    if RoleBuff_Debug
    then
	print(msg);
    end
end

local function RoleBuff_CombatCheckFishingPole(chatOnly)
    if opt.global.optFishingPole and
	(
	    tonumber(this.clientBuildNumber) < 7561 and IsEquippedItemType(this.itemTypeFishingPole)
		or
	    tonumber(this.clientBuildNumber) >= 7561 and IsEquippedItemType(this.itemTypeFishingPoles)	-- patch 2.3 The Gods of Zul'Aman
	)
    then
	this:ReportMessage(this:ItemEquippedMessage(this.itemTypeFishingPole), chatOnly);
    end
end

local function RoleBuff_CombatCheckMainHandOffHand(chatOnly)
    if opt.global.optMainHandOffHand
    then
	local mainHandSlot, _ = GetInventorySlotInfo(this.mainHandSlot);
	local offHandSlot, _ = GetInventorySlotInfo(this.secondaryHandSlot);

	if GetInventoryItemID(this.unitPlayer, mainHandSlot) == nil
	then
	    this:ReportMessage(this:ItemEquipMessage(this.itemMainHandWeapon), chatOnly)
	end

	if GetInventoryItemID(this.unitPlayer, offHandSlot) == nil and not IsEquippedItemType(this.itemTypeTwoHand)
	then
	    this:ReportMessage(this:ItemEquipMessage(this.itemOffHand), chatOnly)
	end
    end
end

local function RoleBuff_CombatCheckPlayer(chatOnly)
    RoleBuff_CombatCheckFishingPole(chatOnly);
    RoleBuff_CombatCheckMainHandOffHand(chatOnly);
    this:CombatCheckGearSpec(chatOnly)
end

mod.trivialNpcCache, mod.trivialNpcIdCache = { }, { };

local function ReadUnitID(unitID)
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

		print("NPC " .. UnitName(unitID) .. " with ID " .. npcID .. " is trivial.")
	    end
	end
    end
end

local RoleBuff_BaseEventHandlerTable = 
{
    [this.eventUpdateMouseoverUnit] = function(frame, event, ...) ReadUnitID(mod.unitMouseover) end,
    [this.eventUnitTarget] = function(frame, event, unitId) ReadUnitID(unitId .. "-target") end,
    [this.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_PlayerAttacking and not RoleBuff_PlayerAttacked
	then
	    RoleBuff_CombatCheckPlayer(false);
	end

	RoleBuff_PlayerAttacked = true;
    end,

    [this.eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_PlayerAttacked = false;
	this:GearSetRoleAnnounce(frame, event, ...)
    end,

    [this.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_PlayerAttacking and not RoleBuff_PlayerAttacked
	then
	    RoleBuff_CombatCheckPlayer(false);
	end

	RoleBuff_PlayerAttacking = true;
    end,

    [this.eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_PlayerAttacking = false;
    end,

    [this.eventReadyCheck] = function(frame, event, ...)
	RoleBuffAddOn:SlashCmdHandler(this.slashCommandCombatCheck);
    end,

    [this.eventUnitInventoryChanged] = function(frame, event, unitId, ...)
	this:UnitInventoryChanged(unitId);
	return this:OnGearSetEvent(frame, event, ...)
    end,
    [this.eventEquipmentSetsChanged] = function(frame, event, ...) return this:OnGearSetEvent(frame, event, ...) end,
    [this.eventEquipmentSwapPending] = function(frame, event, ...) return this:OnGearSetEvent(frame, event, ...) end,
    [this.eventEquipmentSwapFinished] = function(frame, event, ...) return this:OnGearSetEvent(frame, event, ...) end,
    [this.eventWearEquipmentSet] = function(frame, event, ...) return this:OnGearSetEvent(frame, event, ...) end,
    [this.eventActiveTalentGroupChanged] = function(frame, event, ...) return this:OnGearSetEvent(frame, event, ...) end
};

local RoleBuff_ClassEventHandlerTable =
{
    [this.playerClassEnWarrior] = this.EventHandlerTableWarrior,
    [this.playerClassEnDeathKnight] = this.EventHandlerTableDeathKnight,
    [this.playerClassEnPaladin] = this.EventHandlerTablePaladin,
    [this.playerClassEnWarlock] = this.EventHandlerTableWarlock,
    [this.playerClassEnShaman] = nil,
    [this.playerClassEnRogue] = this.EventHandlerTableRogue
};

RoleBuffAddOn.ClassGetRoleTable =
{
    [this.playerClassEnWarrior] = this.GetWarriorRole,
    [this.playerClassEnDeathKnight] = this.GetDeathKnightRole,
    [this.playerClassEnPaladin] = this.GetPaladinRole,
    [this.playerClassEnWarlock] = this.GetWarlockRole,
    [this.playerClassEnShaman] = this.GetShamanRole,
    [this.playerClassEnRogue] = this.GetRogueRole,
    [this.playerClassEnPriest] = function()
	local specIndex, specName = this:GetPlayerBuild()

	if specName == this.holySpecName
	then
	    return this.roleHealer;
	else
	    return this.roleDPS;
	end
    end,
    [this.playerClassEnDruid] = function() return nil; end
};

local RoleBuff_SlashCommandHandlerTable = 
{
};

local RoleBuff_ClassCommandHandlerTable = 
{
    [this.playerClassEnWarrior] = this.SlashCommandHandlerWarrior,
    [this.playerClassEnDeathKnight] = this.SlashCommandHandlerDeathKnight,
    [this.playerClassEnPaladin] = this.SlashCommandHandlerPaladin,
    [this.playerClassEnWarlock] = this.SlashCommandHandlerWarlock,
    [this.playerClassEnShaman] = nil,
    [this.playerClassEnRogue] = this.SlashCommandHandlerRogue
};

local RoleBuff_BaseCommandHandlerTable =
{
    [this.slashCommandEnable] = function()
	RoleBuff_Enabled = true;
	print(this.addonEnabledMessage);
    end,

    [this.slashCommandDisable] = function()
	RoleBuff_Enabled = false;
	print(this.addonDisabledMessage);
    end,

    [this.slashCommandSpec] = function()
	if this.playerClassEn ~= nil
	then
	    local specIndex, specName = this:GetPlayerBuild();
	    print(this:FormatSpecialization(this.playerClassLocalized, specName));
	end

	if not RoleBuff_Enabled
	then
	    print(this.addonDisabledMessage);
	end
    end,

    [this.slashCommandPlayerCheck] = function()
	if RoleBuff_ClassEventHandlerTable[this.playerClassEn] == nil
	then
	    print(this:NoClassSupportMessage(this.playerClassLocalized));
	else
	    if opt.classes[this.playerClassEn] ~= nil and not opt.classes[this.playerClassEn]
	    then
		print(this:ClassDisabledMessage(this.playerClassLocalized));
	    end
	end
    end,

    [this.slashCommandEquipmentSet] = function(cmdLine) return this:SlashCommandEquipmentSet(cmdLine) end,

    [this.slashCommandGearSpec] = function(cmdLine) return this:GearSpecCheck() end,

    [this.slashCommandSetDebug] = function(cmdLine)
	if cmdLine[2] ~= nil and cmdLine[2] == "on"
	then
	    RoleBuff_Debug = true
	end

	if cmdLine[2] ~= nil and cmdLine[2] == "off"
	then
	    RoleBuff_Debug = false
	end
    end
};

RoleBuff_BaseCommandHandlerTable[this.slashCommandCombatCheck] = function()
    RoleBuff_CombatCheckPlayer(true);
    RoleBuff_BaseCommandHandlerTable[this.slashCommandPlayerCheck]();
end;

-- called from XML
function RoleBuffAddOn:OnLoad(frame)
    if self.AddOnLocalized and self.UserStringsLocalized
    then
	frame:RegisterEvent(self.eventPlayerAlive);
    else
	print("RoleBuff: New add-on translation is needed for your World of Warcraft client language.");
	print("RoleBuff: Not loaded.");
    end
end

local function RoleBuff_ErrorHandler(errorMessage)
    print(this.displayName .. ": " .. errorMessage);
    return errorMessage;
end

local RoleBuff_EventHandlerTable =
{
    [this.eventPlayerAlive] = 'RoleBuff_OnInitialPlayerAlive'
};

local function RoleBuff_OnInitialPlayerAlive(frame, event, ...)
    if this.playerClassEn == nil
    then
	if event == this.eventPlayerAlive
	then
	    this.playerClassLocalized, this.playerClassEn, this.playerClassIndex = UnitClass(this.unitPlayer);

	    frame:UnregisterEvent(this.eventPlayerAlive);
	    frame:RegisterEvent(this.eventPlayerRegenEnabled);
	    frame:RegisterEvent(this.eventPlayerRegenDisabled);
	    frame:RegisterEvent(this.eventPlayerEnterCombat);
	    frame:RegisterEvent(this.eventPlayerLeaveCombat);
	    frame:RegisterEvent(this.eventReadyCheck);
	    frame:RegisterEvent(mod.eventUpdateMouseoverUnit);
	    frame:RegisterEvent(mod.eventUnitTarget);

	    if opt.classes[this.playerClassEn] ~= nil
	    then
		if opt.classes[this.playerClassEn]
		then
		    if RoleBuff_ClassEventHandlerTable[this.playerClassEn] ~= nil
		    then
			RoleBuff_EventHandlerTable = RoleBuff_ClassEventHandlerTable[this.playerClassEn];
			RoleBuffAddOn:OnEvent(frame, event, ...);
			print(this.addonLoadedMessage);
		    else
			print(this:NoClassSupportMessage(this.playerClassLocalized));
		    end
		else
		    print(this:ClassDisabledMessage(this.playerClassLocalized));
		end
	    else
		print(this:NoClassSupportMessage(this.playerClassLocalized));
	    end

	    if RoleBuff_ClassCommandHandlerTable[this.playerClassEn] ~= nil
	    then
		RoleBuff_SlashCommandHandlerTable = RoleBuff_ClassCommandHandlerTable[this.playerClassEn];
	    end

	    this:GearSpec_InitialPlayerAlive(frame, event, ...)
	end
    end
end

RoleBuff_EventHandlerTable[this.eventPlayerAlive] = RoleBuff_OnInitialPlayerAlive;

-- called from XML
function RoleBuffAddOn:OnEvent(frame, event, ...)
    if RoleBuff_Enabled
    then
	if RoleBuff_EventHandlerTable[event] ~= nil
	then
	    RoleBuff_EventHandlerTable[event](frame, event, ...);
	end

	if RoleBuff_BaseEventHandlerTable[event] ~= nil
	then
	    RoleBuff_BaseEventHandlerTable[event](frame, event, ...);
	end
    end
end

function RoleBuffAddOn:OnUpdate(frame, elapsedFrameTime)
    if self.UpdateHandlersSet ~= nil
    then
	for _, handlerFn in pairs(self.UpdateHandlersSet)
	do
	    handlerFn(elapsedFrameTime)
	end
    end
end

function RoleBuffAddOn:SlashCmdHandler(msg)
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
	msg = "";
    else
	msg = string.lower(cmdLine[1]);
    end

    if RoleBuff_SlashCommandHandlerTable[msg] ~= nil or RoleBuff_BaseCommandHandlerTable[msg] ~= nil
    then
	if RoleBuff_SlashCommandHandlerTable[msg] ~= nil
	then
	    RoleBuff_SlashCommandHandlerTable[msg](cmdLine);
	end

	if RoleBuff_BaseCommandHandlerTable[msg] ~= nil
	then
	    RoleBuff_BaseCommandHandlerTable[msg](cmdLine);
	end
    else
	print(self.commandSyntaxIntroLine);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandSpec);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandEnable);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandDisable);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandPlayerCheck);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandCombatCheck);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandEquipmentSet .. " <EquipmentSet> <ExpectedRole>");
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandGearSpec);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandSetDebug .. " on|off");
    end
end

function RoleBuffAddOn:OptionsFrameLoad(panel)
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
