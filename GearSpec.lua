--
-- Check if items from sets for other roles are quipped instead of items for current player role sets.
-- Note only some of the classes classes can perform different roles with different specializations

RoleBuff_CheckEquipmentSet = RoleBuff_ReadAddOnStorage(true, { "options", "global" }, "optGearSpec")["optGearSpec"];

local multipleRoleClass, equipmentMatchCount, equipmentMissmatchCount, equipmentSwapPending = false, nil, nil, false;

local gearSlotList =
{
    [headSlot] = true, [neckSlot] = true, [shoulderSlot] = true, [chestSlot] = true, [shirtSlot] = true, [tabardSlot] = true,
    [handsSlot] = true, [wristSlot] = true, [waistSlot] = true, [fingerSlot0] = true, [fingerSlot1] = true, [trinketSlot0] = true,
    [trinketSlot1] = true, [mainHandSlot] = true, [offHandSlot] = true, [rangedSlot] = true, [ammoSlot] = true
};

function RoleBuff_EquipmentSetUsage(currentRole)
    local setRoles = RoleBuff_GetEquipmentSetRoles();

    local currentSetNo, setName, numEquipmentSets = 1, nil, GetNumEquipmentSets();
    local roleMatch, setUsage = false, { };
    local slotIndex, locationClassifier, locations;

    if numEquipmentSets < 2
    then
	return 0, 0;
    end

    while currentSetNo <= numEquipmentSets
    do
	setName = GetEquipmentSetInfo(currentSetNo);
	if setRoles[setName] == nil
	then
	    RoleBuff_DebugMessage("Equipment set " .. setName .. " needs to be assigned a role.");
	    return nil, nil;
	end

	if setRoles[setName] == currentRole
	then
	    roleMatch = true;
	else
	    roleMatch = false;
	end

	for slotIndex, locationClassifier in pairs(GetEquipmentSetLocations(setName))
	do
	    if setUsage[slotIndex] == nil
	    then
		setUsage[slotIndex] = { };
	    end

	    if locationClassifier == -1 or locationClassifier == 0 or locationClassifier == 1
	    then
		-- missing, empty or ignored item slot for this set
		setUsage[slotIndex]["skip"] = true;
	    else
		local equippedOrInBags, _, inBags = EquipmentManager_UnpackLocation(locationClassifier);

		if equippedOrInBags
		then
		    if inBags
		    then
			if roleMatch
			then
			    setUsage[slotIndex]["bags"] = true;
			else
			    setUsage[slotIndex]["offspec"] = true;
			end
		    else
			if roleMatch
			then
			    setUsage[slotIndex]["equipped"] = true;
			else
			    setUsage[slotIndex]["missmatch"] = true;
			end
		    end
		else
		    -- item is away (in bank)
		    setUsage[slotIndex]["skip"] = true;
		end
	    end
	end

	currentSetNo = currentSetNo + 1;  -- advance to next set
    end

    -- check accumulated number of matches and missmatches per slot
    -- across all user equipment sets

    local matches, missmatches = 0, 0;

    for slotIndex, locations in pairs(setUsage)
    do
	if locations["equipped"] ~= nil
	then
	    -- proper item for current role is equipped in slot
	    matches = matches + 1;
	else
	    if locations["missmatch"] ~= nil and locations["bags"] ~= nil
	    then
		-- item should be replaced with a proper one from bags
		missmatches = missmatches + 1;
	    -- else
	    --	    -- otherwise no good set properly covers this slot
	    --	    -- so there can be anything in, including a miss-match
	    end
	end
    end

    return matches, missmatches;
end

function RoleBuff_PlayerEquipmentUsage()
    local playerRole = nil;
    
    if RoleBuff_ClassGetRoleTable[playerClassEn] ~= nil
    then
	playerRole = RoleBuff_ClassGetRoleTable[playerClassEn]();
    end

    if playerRole ~= nil and playerRole ~= ""
    then
	equipmentMatchCount, equipmentMissmatchCount = RoleBuff_EquipmentSetUsage(playerRole);
    end
end

-- display chat window message to the player asking to assign 
-- a role to an equipment set
function RoleBuff_GearSetRoleAnnounce(frame, event, ...)
    if multipleRoleClass and equipmentMissmatchCount == nil
    then
	print(setCommandUsageIntroLine);
	for i = 1, GetNumEquipmentSets()
	do
	    local setName = GetEquipmentSetInfo(i);

	    if RoleBuff_GetEquipmentSetRoles()[setName] == nil
	    then
		print("  " .. SLASH_ROLEBUFF1 .. " " .. slashCommandEquipmentSet .. " " .. setName  .. " <ExpectedRole>");
	    end
	end
	print(setCommandUsageClosingLine);
    end
end

function RoleBuff_OnGearSetEvent(frame, event, ...)
    if event == eventEquipmentSwapPending
    then
	equipmentSwapPending = true;
	RoleBuff_DebugMessage("Equipment swap pending...");
    else
	-- inventory changed
	-- sets changed
	-- wear set
	-- swap finished

	if event == eventEquipmentSwapFinished
	then
	    equipmentSwapPending = false;
	    RoleBuff_DebugMessage("Equipment swapped.");
	end

	RoleBuff_PlayerEquipmentUsage();

	if event == eventEquipmentSetsChanged
	then
	    -- Announce "/rolebuff set" command for a new gear set
	    RoleBuff_GearSetRoleAnnounce();
	end
    end
end

function RoleBuff_GearSpec_InitialPlayerAlive(frame, event, ...)
    if RoleBuff_CheckEquipmentSet
    then
	multipleRoleClass = (classRolesCount[playerClassEn] ~= nil and classRolesCount[playerClassEn] > 1);

	if multipleRoleClass
	then
	    RoleBuff_PlayerEquipmentUsage();

	    frame:RegisterEvent(eventUnitInventoryChanged);
	    frame:RegisterEvent(eventEquipmentSetsChanged);
	    frame:RegisterEvent(eventEquipmentSwapPending);
	    frame:RegisterEvent(eventEquipmentSwapFinished);
	    frame:RegisterEvent(eventWearEquipmentSet);

	    RoleBuff_GearSetRoleAnnounce();
	end
    end
end

function RoleBuff_CombatCheckGearSpec(chatOnly)
    if RoleBuff_CheckEquipmentSet and equipmentMissmatchCount ~= nil and equipmentMissmatchCount > 0
    then
	RoleBuff_ReportMessage(warningSwitchGear, chatOnly);
    end
end

local playerRolesMap =
{
    [string.lower(playerRoleDPS)] = roleDPS,
    [string.lower(playerRoleTank)] = roleTank,
    [string.lower(playerRoleHealer)] = roleHealer
};

function RoleBuff_GetRoleName(roleName)
    return playerRolesMap[string.lower(roleName)];
end

function RoleBuff_FindGearSet(setName)
    for i = 1, GetNumEquipmentSets()
    do
	currentSetName = GetEquipmentSetInfo(i)

	if string.lower(setName) == string.lower(currentSetName)
	then
	    return currentSetName;
	end
    end

    return nil;
end

function RoleBuff_ClassRolesFind(classRoles, roleName)
    for index, name in pairs(classRoles)
    do
	if name == roleName
	then
	    return true;
	end
    end

    return false;
end

function RoleBuff_SlashCommandEquipmentSet(cmdLine)
    if cmdLine[2] == nil or cmdLine[3] == nil or cmdLine[4] ~= nil
    then
	-- <EquipmentSet> and <ExpectedRole> arguments are expected --
	print(setCommandArgsMessage);
	return;
    end

    local setNameArg, setRoleArg = cmdLine[2], cmdLine[3];

    if multipleRoleClass
    then
	local equipmentSetName, roleName, setRoles = RoleBuff_FindGearSet(setNameArg), RoleBuff_GetRoleName(setRoleArg), RoleBuff_GetEquipmentSetRoles();

	if equipmentSetName == nil
	then
	    print(setCommandFirstArgMessage);
	    return;
	end

	if roleName == nil or not RoleBuff_ClassRolesFind(classRoles[playerClassEn], roleName)
	then
	    print(setCommandSecondArgMessage);
	    return;
	end

	setRoles[equipmentSetName] = roleName;
    else
	print(setCommandSingleRoleClass);
    end
end

function RoleBuff_GearSpecCheck()
    if RoleBuff_CheckEquipmentSet
    then
	if multipleRoleClass
	then
	    RoleBuff_PlayerEquipmentUsage();

	    if equipmentMissmatchCount ~= nil
	    then
		if equipmentMissmatchCount > 0
		then
		    print(equipmentMissmatchMessage);
		else
		    if equipmentMatchCount > 0
		    then
			print(equipmentMatchMessage);
		    else
			print(equipmentMatchNeededMessage);
		    end
		end
	    else
		RoleBuff_GearSetRoleAnnounce();
	    end
	else
	    print(equipmentMatchSingleRoleClass);
	end
    else
	print(equipmentMatchDisabled);
    end
end
