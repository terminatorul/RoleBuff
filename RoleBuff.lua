-- Wow 3.3.5a add-on to check for simple role-specific buffs when entering combat
-- Uses WowAPI.lua, RoleBuffWarrior.lua
-- Check any player for:
--	- fishing pole equipped
--	- missing gear items above some level

RoleBuff_Enabled = true;

RoleBuff_EventHandlerTable =
{
    [eventPlayerAlive] = RoleBuff_OnInitialPlayerAlive
};

RoleBuff_PlayerAttacking, RoleBuff_PlayerAttacked = false, false;

RoleBuff_Debug = false;

function RoleBuff_DebugMessage(msg)
    if RoleBuff_Debug
    then
	print(msg);
    end
end

function RoleBuff_CombatCheckPlayer(chatOnly)
    if RoleBuff_CheckFishingPole and
	(
	    tonumber(clientBuildNumber) < 7561 and IsEquippedItemType(itemTypeFishingPole)
		or
	    tonumber(clientBuildNumber) >= 7561 and IsEquippedItemType(itemTypeFishingPoles)	-- patch 2.3 The Gods of Zul'Aman
	)
    then
	RoleBuff_ReportMessage(RoleBuff_ItemEquippedMessage(itemTypeFishingPole), chatOnly);
    end

    RoleBuff_CombatCheckGearSpec(chatOnly)
end

local RoleBuff_BaseEventHandlerTable = 
{
    [eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_PlayerAttacking and not RoleBuff_PlayerAttacked
	then
	    RoleBuff_CombatCheckPlayer(false);
	end

	RoleBuff_PlayerAttacked = true;
    end,

    [eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_PlayerAttacked = false;
	RoleBuff_GearSetRoleAnnounce(frame, event, ...)
    end,

    [eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_PlayerAttacking and not RoleBuff_PlayerAttacked
	then
	    RoleBuff_CombatCheckPlayer(false);
	end

	RoleBuff_PlayerAttacking = true;
    end,

    [eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_PlayerAttacking = false;
    end,

    [eventUnitInventoryChanged] = RoleBuff_OnGearSetEvent,
    [eventEquipmentSetsChanged] = RoleBuff_OnGearSetEvent,
    [eventEquipmentSwapPending] = RoleBuff_OnGearSetEvent,
    [eventEquipmentSwapFinished] = RoleBuff_OnGearSetEvent,
    [eventWearEquipmentSet] = RoleBuff_OnGearSetEvent,
    [eventActiveTalentGroupChanged] = RoleBuff_OnGearSetEvent
};

RoleBuff_BaseCommandHandlerTable =
{
    [slashCommandEnable] = function()
	RoleBuff_Enabled = true;
	print(addonEnabledMessage);
    end,

    [slashCommandDisable] = function()
	RoleBuff_Enabled = false;
	print(addonDisabledMessage);
    end,

    [slashCommandSpec] = function()
	if playerClassEn ~= nil
	then
	    local specIndex, specName = RoleBuff_GetPlayerBuild();
	    print(RoleBuff_FormatSpecialization(playerClassLocalized, specName));
	end

	if not RoleBuff_Enabled
	then
	    print(addonDisabledMessage);
	end
    end,

    [slashCommandPlayerCheck] = function()
	if RoleBuff_ClassEventHandlerTable[playerClassEn] == nil
	then
	    print(RoleBuff_NoClassSupportMessage(playerClassLocalized));
	else
	    if RoleBuff_EnableClassTable[playerClassEn] ~= nil and not RoleBuff_EnableClassTable[playerClassEn]
	    then
		print(RoleBuff_ClassDisabledMessage(playerClassLocalized));
	    end
	end
    end,

    [slashCommandCombatCheck] = function()
	RoleBuff_CombatCheckPlayer(true);
	RoleBuff_BaseCommandHandlerTable[slashCommandPlayerCheck]();
    end,

    [slashCommandEquipmentSet] = RoleBuff_SlashCommandEquipmentSet,

    [slashCommandGearSpec] = RoleBuff_GearSpecCheck,

    [slashCommandSetDebug] = function(cmdLine)
	if cmdLine[2] ~= nil and cmdLine[2] == "on"
	then
	    RoleBuff_Debug = true;
	end

	if cmdLine[2] ~= nil and cmdLine[2] == "off"
	then
	    RoleBuff_Debug = false;
	end
    end
};

-- called from XML
function RoleBuff_OnLoad()
    if RoleBuff_AddOnLocalized and RoleBuff_UserStringsLocalized
    then
	this:RegisterEvent(eventPlayerAlive);
    else
	print("RoleBuff: New add-on translation is needed for your World of Warcraft client language.");
	print("RoleBuff: Not loaded.");
    end
end

RoleBuff_CheckFishingPole, RoleBuff_CheckEmptyGear = true, false;

RoleBuff_EnableClassTable = 
{
    [playerClassEnWarrior] = true,
    [playerClassEnDeathKnight] = true,
    [playerClassEnPaladin] = true,
    [playerClassEnWarlock] = true,
    [playerClassEnShaman] = false,
    [playerClassEnRogue] = false
};

RoleBuff_ClassEventHandlerTable =
{
    [playerClassEnWarrior] = RoleBuff_EventHandlerTableWarrior,
    [playerClassEnDeathKnight] = RoleBuff_EventHandlerTableDeathKnight,
    [playerClassEnPaladin] = RoleBuff_EventHandlerTablePaladin,
    [playerClassEnWarlock] = RoleBuff_EventHandlerTableWarlock,
    [playerClassEnShaman] = nil,
    [playerClassEnRogue] = nil
};

RoleBuff_ClassGetRoleTable =
{
    [playerClassEnWarrior] = RoleBuff_GetWarriorRole,
    [playerClassEnDeathKnight] = RoleBuff_GetDeathKnightRole,
    [playerClassEnPaladin] = RoleBuff_GetPaladinRole,
    [playerClassEnWarlock] = RoleBuff_GetWarlockRole,
    [playerClassEnShaman] = RoleBuff_GetShamanRole,
    [playerClassEnRogue] = RoleBuff_GetRogueRole,
    [playerClassEnPriest] = function()
	local specIndex, specName = RoleBuff_GetPlayerBuild()

	if specName == holySpecName
	then
	    return roleHealer;
	else
	    return roleDPS;
	end
    end,
    [playerClassEnDruid] = function() return nil; end
};

RoleBuff_SlashCommandHandlerTable = 
{
};

local RoleBuff_ClassCommandHandlerTable = 
{
    [playerClassEnWarrior] = RoleBuff_SlashCommandHandlerWarrior,
    [playerClassEnDeathKnight] = RoleBuff_SlashCommandHandlerDeathKnight,
    [playerClassEnPaladin] = RoleBuff_SlashCommandHandlerPaladin,
    [playerClassEnWarlock] = RoleBuff_SlashCommandHandlerWarlock,
    [playerClassEnShaman] = nil,
    [playerClassEnRogue] = nil
};

function RoleBuff_ErrorHandler(errorMessage)
    print(displayName .. ": " .. errorMessage);
    return errorMessage;
end

function RoleBuff_OnInitialPlayerAlive(frame, event, ...)
    if playerClassEn == nil
    then
	if event == eventPlayerAlive
	then
	    playerClassLocalized, playerClassEn, playerClassIndex = UnitClass(unitPlayer);

	    frame:UnregisterEvent(eventPlayerAlive);
	    frame:RegisterEvent(eventPlayerRegenEnabled);
	    frame:RegisterEvent(eventPlayerRegenDisabled);
	    frame:RegisterEvent(eventPlayerEnterCombat);
	    frame:RegisterEvent(eventPlayerLeaveCombat);

	    if RoleBuff_EnableClassTable[playerClassEn] ~= nil
	    then
		if RoleBuff_EnableClassTable[playerClassEn]
		then
		    if RoleBuff_ClassEventHandlerTable[playerClassEn] ~= nil
		    then
			RoleBuff_EventHandlerTable = RoleBuff_ClassEventHandlerTable[playerClassEn];
			RoleBuff_OnEvent(frame, event, ...);
			print(addonLoadedMessage);
		    else
			print(RoleBuff_NoClassSupportMessage(playerClassLocalized));
		    end
		else
		    print(RoleBuff_ClassDisabledMessage(playerClassLocalized));
		end
	    else
		print(RoleBuff_NoClassSupportMessage(playerClassLocalized));
	    end

	    if RoleBuff_ClassCommandHandlerTable[playerClassEn] ~= nil
	    then
		RoleBuff_SlashCommandHandlerTable = RoleBuff_ClassCommandHandlerTable[playerClassEn];
	    end

	    RoleBuff_GearSpec_InitialPlayerAlive(frame, event, ...)
	end
    end
end

-- called from XML
function RoleBuff_OnEvent(frame, event, ...)
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

function RoleBuff_OnUpdate(frame, elapsedFrameTime)
    if RoleBuff_UpdateHandlersSet ~= nil
    then
	for _, handlerFn in pairs(RoleBuff_UpdateHandlersSet)
	do
	    handlerFn(elapsedFrameTime)
	end
    end
end

function RoleBuff_SlashCmdHandler(msg)
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
	print(commandSyntaxIntroLine);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. slashCommandSpec);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. slashCommandEnable);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. slashCommandDisable);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. slashCommandPlayerCheck);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. slashCommandCombatCheck);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. slashCommandEquipmentSet .. " <EquipmentSet> <ExpectedRole>");
	print("  " .. SLASH_ROLEBUFF1 .. " " .. slashCommandGearSpec);
	print("  " .. SLASH_ROLEBUFF1 .. " " .. slashCommandSetDebug .. " on|off");
    end
end

SLASH_ROLEBUFF1 = "/rolebuff";
function SlashCmdList.ROLEBUFF(msgLine, editbox)
    -- xpcall(RoleBuff_SlashCmdHandler, RoleBuff_ErrorHandler, msg)
    RoleBuff_SlashCmdHandler(msgLine)
end
