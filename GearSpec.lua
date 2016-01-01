--
-- Check if items from sets for other roles are quipped instead of items for current player role sets.
-- Note only some of the classes classes can perform different roles with different specializations

local this, mod = RoleBuffAddOn, RoleBuffAddOn;

this.CheckEquipmentSet = this:ReadAddOnStorage(true, { "options", "global" }, "optGearSpec")["optGearSpec"];

local multipleRoleClass, equipmentMatchCount, equipmentMissmatchCount, equipmentSwapPending = false, nil, nil, false;

local gearSlotList =
{
    [this.headSlot] = true, [this.neckSlot] = true, [this.shoulderSlot] = true, [this.chestSlot] = true, [this.shirtSlot] = true, [this.tabardSlot] = true,
    [this.handsSlot] = true, [this.wristSlot] = true, [this.waistSlot] = true, [this.fingerSlot0] = true, [this.fingerSlot1] = true, [this.trinketSlot0] = true,
    [this.trinketSlot1] = true, [this.mainHandSlot] = true, [this.offHandSlot] = true, [this.rangedSlot] = true, [this.ammoSlot] = true
};

local function RoleBuff_EquipmentSetUsage(currentRole)
    local setRoles = this:GetEquipmentSetRoles();

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
	    this:DebugMessage("Equipment set " .. setName .. " needs to be assigned a role.");
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

local function RoleBuff_PlayerEquipmentUsage()
    local playerRole = nil;
    
    if this.ClassGetRoleTable[this.playerClassEn] ~= nil
    then
	playerRole = this.ClassGetRoleTable[this.playerClassEn]();
    end

    if playerRole ~= nil and playerRole ~= ""
    then
	equipmentMatchCount, equipmentMissmatchCount = RoleBuff_EquipmentSetUsage(playerRole);
    end
end

-- display chat window message to the player asking to assign 
-- a role to an equipment set
function RoleBuffAddOn:GearSetRoleAnnounce(frame, event, ...)
    if multipleRoleClass and equipmentMissmatchCount == nil
    then
	print(self.setCommandUsageIntroLine);
	for i = 1, GetNumEquipmentSets()
	do
	    local setName = GetEquipmentSetInfo(i);

	    if self:GetEquipmentSetRoles()[setName] == nil
	    then
		print("  " .. SLASH_ROLEBUFF1 .. " " .. self.slashCommandEquipmentSet .. " " .. setName  .. " <ExpectedRole>");
	    end
	end
	print(self.setCommandUsageClosingLine);
    end
end

-- scan containers for the expected item type
local function UseContainerItemWithType(scanAmmoItemType, itemDisplayType, chatOnly)
    local ammoItemId, foundContainer, foundSlotId = nil, nil, nil;

    for containerId = 0, NUM_BAG_SLOTS
    do
	for containerSlotId = 1, GetContainerNumSlots(containerId)
	do
	    local containerItemId = GetContainerItemID(containerId, containerSlotId)
	    if containerItemId ~= nil
	    then
		local _, _, _, _, _, _, itemType = GetItemInfo(containerItemId);

		if itemType == scanAmmoItemType
		then
		    if ammoItemId == nil
		    then
			ammoItemId, foundContainer, foundSlotId = containerItemId, containerId, containerSlotId
		    else
			if ammoItemId == containerItemId
			then
			    mod:DebugMessage("Container item with ID " .. ammoItemId .. " found in bags.");
			    -- same item found multiple times in player bags, ignore
			else
			    -- Two kinds of items with given itemType found in player backpack/containers
			    mod:ShowMessage(mod:ItemEquipMessage(itemDisplayType), chatOnly);
			    return
			end
		    end
		end
	    end
	end
    end

    if ammoItemId ~= nil
    then
	mod:DebugMessage("Container item ID " .. ammoItemId .. " found in bags.");
	if CursorHasItem()
	then
	    mod:ShowMessage(mod:ItemEquipMessage(itemDisplayType), chatOnly)
	else
	    PickupContainerItem(foundContainer, foundSlotId);
	    AutoEquipCursorItem();
	end
    else
	mod:ShowMessage(mod:MissingItemMessage(itemDisplayType), chatOnly)
    end
end

function RoleBuffAddOn:UnitInventoryChanged(unitID, chatOnly)
    if tonumber(mod.clientBuildNumber) < 13164  -- Patch 4.0.1 "Cataclysm Systems"
    then
	if UnitIsUnit(unitID, self.unitPlayer)
	then
	    local scanAmmoItemType, scanAmmoDisplayType = nil, nil;
	    if (IsEquippedItemType(mod.itemTypeBows) or IsEquippedItemType(mod.itemTypeCrossbows)) and not IsEquippedItemType(mod.itemTypeArrow)
	    then
		scanAmmoItemType, scanAmmoDisplayType = mod.itemTypeArrow, mod.itemDisplayTypeArrows;
		mod:DebugMessage("Missing arrows.")
	    else
		if IsEquippedItemType(mod.itemTypeGuns) and not IsEquippedItemType(mod.itemTypeBullet)
		then
		    scanAmmoItemType, scanAmmoDisplayType = mod.itemTypeBullet, mod.itemDisplayTypeBullets;
		    mod:DebugMessage("Missing bullets")
		else
		    mod:DebugMessage("No Ranged weapon missing the ammo.");
		    return
		end
	    end
	    UseContainerItemWithType(scanAmmoItemType, scanAmmoDisplayType, chatOnly);
	end
    end
end


function RoleBuffAddOn:OnGearSetEvent(frame, event, ...)
    if event == self.eventEquipmentSwapPending
    then
	equipmentSwapPending = true;
	self:DebugMessage("Equipment swap pending...");
    else
	-- inventory changed
	-- sets changed
	-- wear set
	-- swap finished

	if event == self.eventEquipmentSwapFinished
	then
	    equipmentSwapPending = false;
	    self:DebugMessage("Equipment swapped.");
	end

	RoleBuff_PlayerEquipmentUsage();

	if event == self.eventEquipmentSetsChanged
	then
	    -- Announce "/rolebuff set" command for a new gear set
	    self:GearSetRoleAnnounce(frame, event, ...);
	end
    end
end

function RoleBuffAddOn:GearSpec_InitialPlayerAlive(frame, event, ...)
    if self.CheckEquipmentSet
    then
	multipleRoleClass = (self.classRolesCount[self.playerClassEn] ~= nil and self.classRolesCount[self.playerClassEn] > 1);

	if multipleRoleClass
	then
	    RoleBuff_PlayerEquipmentUsage();

	    frame:RegisterEvent(self.eventUnitInventoryChanged);
	    frame:RegisterEvent(self.eventEquipmentSetsChanged);
	    frame:RegisterEvent(self.eventEquipmentSwapPending);
	    frame:RegisterEvent(self.eventEquipmentSwapFinished);
	    frame:RegisterEvent(self.eventWearEquipmentSet);

	    self:GearSetRoleAnnounce(frame, event, ...);
	end
    end
end

function RoleBuffAddOn:CombatCheckGearSpec(chatOnly)
    if self.CheckEquipmentSet and equipmentMissmatchCount ~= nil and equipmentMissmatchCount > 0
    then
	self:ReportMessage(self.warningSwitchGear, chatOnly);
    end
end

local playerRolesMap =
{
    [string.lower(this.playerRoleDPS)] = this.roleDPS,
    [string.lower(this.playerRoleTank)] = this.roleTank,
    [string.lower(this.playerRoleHealer)] = this.roleHealer
};

local function RoleBuff_GetRoleName(roleName)
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

local function RoleBuff_ClassRolesFind(classRoles, roleName)
    for index, name in pairs(classRoles)
    do
	if name == roleName
	then
	    return true;
	end
    end

    return false;
end

function RoleBuffAddOn:SlashCommandEquipmentSet(cmdLine)
    if cmdLine[2] == nil or cmdLine[3] == nil or cmdLine[4] ~= nil
    then
	-- <EquipmentSet> and <ExpectedRole> arguments are expected --
	print(self.setCommandArgsMessage);
	return;
    end

    local setNameArg, setRoleArg = cmdLine[2], cmdLine[3];

    if multipleRoleClass
    then
	local equipmentSetName, roleName, setRoles = RoleBuff_FindGearSet(setNameArg), RoleBuff_GetRoleName(setRoleArg), self:GetEquipmentSetRoles();

	if equipmentSetName == nil
	then
	    print(self.setCommandFirstArgMessage);
	    return;
	end

	if roleName == nil or not RoleBuff_ClassRolesFind(self.classRoles[self.playerClassEn], roleName)
	then
	    print(self.setCommandSecondArgMessage);
	    return;
	end

	setRoles[equipmentSetName] = roleName;
    else
	print(self.setCommandSingleRoleClass);
    end
end

function RoleBuffAddOn:GearSpecCheck()
    if self.CheckEquipmentSet
    then
	if multipleRoleClass
	then
	    RoleBuff_PlayerEquipmentUsage();

	    if equipmentMissmatchCount ~= nil
	    then
		if equipmentMissmatchCount > 0
		then
		    print(self.equipmentMissmatchMessage);
		else
		    if equipmentMatchCount > 0
		    then
			print(self.equipmentMatchMessage);
		    else
			print(self.equipmentMatchNeededMessage);
		    end
		end
	    else
		self:GearSetRoleAnnounce();
	    end
	else
	    print(self.equipmentMatchSingleRoleClass);
	end
    else
	print(self.equipmentMatchDisabled);
    end
end
