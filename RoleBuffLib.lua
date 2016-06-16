-- Global addon functions
-- Query player abilities and items

local mod = RoleBuffAddOn;

mod.printDebugMessages, mod.printChatMessages = false, true;

function mod:DebugMessage(msg)
    if self.printDebugMessages
    then
	print(msg)
    end
end

function mod:ChatMessage(msg)
    if self.printChatMessages
    then
	print(msg)
    end
end

local function tableSelection(sourceTable, entries, defaultVal)
    local resultTable = { };

    if sourceTable == nil
    then
	if defaultVal ~= nil
	then
	    for idx, entry in pairs(entries)
	    do
		resultTable[entry] = defaultVal
	    end
	end
    else
	for idx, entry in pairs(entries)
	do
	    if sourceTable[entry] == nil
	    then
		resultTable[entry] = defaultVal
	    else
		resultTable[entry] = sourceTable[entry]
	    end
	end
    end

    return resultTable;
end

local function readStorageTable(storageTable, defaultVal, categories, ...)
    local sourceTable = storageTable;

    if type(categories) == "string" or type(categories) == "nil"
    then
	categories = { categories }
    end

    local idx, category = 1, categories[1];

    while sourceTable ~= nil and category ~= nil
    do
	sourceTable = sourceTable[category];
	idx, category = idx + 1, categories[idx + 1];
    end

    local entries = ...;

    if type(entries) ~= 'table'
    then
	entries = { ... };
    end

    return tableSelection(sourceTable, entries, defaultVal)
end

local function writeStorageTable(storageTable, categories, entries)
    local destinationTable = storageTable;

    if type(categories) == "string" or type(categories) == "nil"
    then
	categories = { categories }
    end

    local idx, category = 1, categories[1];

    while category ~= nil
    do
	if destinationTable[category] == nil
	then
	    destinationTable[category] = { }
	end

	destinationTable = destinationTable[category]
    end

    for entry, value in entries
    do
	destinationTable[entry] = value
    end
end

-- return unitType, unitNpcID, unitPetID from a given unit GUID
function mod:GetTypeAndID(guid)
    local baseIndex = 0;

    if guid:sub(1, 2) == "0x"
    then
	baseIndex = 2
    end

    return tonumber(guid:sub(baseIndex + 3, baseIndex + 3), 16) % 8, tonumber(guid:sub(baseIndex + 7, baseIndex + 10), 16), tonumber(guid:sub(baseIndex + 4, baseIndex + 10), 16)
end

function mod:ReadAddOnStorage(defaultVal, categories, ...)
    return readStorageTable(RoleBuffAddOn_StorageTable, defaultVal, categories, ...)
end

function mod:ReadCharacterStorage(defaultVal, categories, ...)
    return readStorageTable(RoleBuffAddOn_CharacterStorageTable, defaultVal, categories, ...)
end

function mod:WriteAddOnStorage(categories, entries)
    if RoleBuffAddOn_StorageTable == nil
    then
	RoleBuffAddOn_StorageTable = { }
    end

    writeStorageTable(RoleBuffAddOn_StorageTable, categories, entries)
end

function mod:WriteCharacterStorage(categories, entries)
    if RoleBuffAddOn_CharacterStorageTable == nil
    then
	RoleBuffAddOn_CharacterStorageTable = { }
    end

    writeStorageTable(RoleBuffAddOn_CharacterStorageTable, categories, entries)
end

local itemCacheEntry = "itemCache";
local rolesPerSetEntry = "setRoles";

local localCache = { };


function mod:GetEquipmentSetRoles()
    if RoleBuffAddOn_CharacterStorageTable == nil
    then
	RoleBuffAddOn_CharacterStorageTable = { };
    end
    
    if RoleBuffAddOn_CharacterStorageTable[rolesPerSetEntry] == nil
    then
	RoleBuffAddOn_CharacterStorageTable[rolesPerSetEntry] = { };
    end

    return RoleBuffAddOn_CharacterStorageTable[rolesPerSetEntry];
end

function mod:GetItemId(itemName)
    if localCache[itemName] == nil
    then
	-- Given item not yet cached or not yet validated
	if RoleBuffAddOn_StorageTable == nil
	then
	    RoleBuffAddOn_StorageTable = { };
	end

	if RoleBuffAddOn_StorageTable[itemCacheEntry] == nil
	then
	    RoleBuffAddOn_StorageTable[itemCacheEntry] = { };
	end

	local itemDisplayName, itemLink = GetItemInfo(itemName);
	if itemDisplayName ~= nil
	then
	    local _, itemId = strsplit(":", string.match(itemLink, "item[%-?%d:]+"));

	    if itemId ~= nil and tonumber(itemId) ~= nil
	    then
		RoleBuffAddOn_StorageTable[itemCacheEntry][itemName] = itemId;
		localCache[itemName] = itemId;
	    else
		self:DebugMessage("No item ID for " .. itemName .. ".");
		return nil;	    -- error retrieving soulstone item ID
	    end
	else
	    -- item not loaded in this client session, search addon cache
	    if RoleBuffAddOn_StorageTable[itemCacheEntry][itemName] ~= nil
	    then
		local itemId = nil
		local itemDisplayName, itemLink = GetItemInfo(RoleBuffAddOn_StorageTable[itemCacheEntry][itemName]);

		if itemDisplayName ~= nil
		then
		    local itemString = string.match(itemLink, "item[%-?%d:]+");
		    if itemString ~= nil
		    then
			_, itemId = strsplit(":", itemString);
		    end
		end

		if itemDisplayName == itemName and itemId == RoleBuffAddOn_StorageTable[itemCacheEntry][itemName]
		then
		    -- cached item passes validation
		    localCache[itemName] = itemId;
		else
		    -- cached item no longer valid
		    RoleBuffAddOn_StorageTable[itemCacheEntry][itemName] = nil;
		end
	    end
	end
    end

    return localCache[itemName];
end

function mod:GetGroupMembersCount()
    local groupMembersCount;

    if tonumber(mod.clientBuildNumber) < 16016  -- Patch 5.0.4 "Mists of Pandaria Systems"
    then
	groupMembersCount = GetNumRaidMembers();
	if groupMembersCount > 1
	then
	    return groupMembersCount, "raid";
	else
	    return GetNumPartyMembers() + 1, "party";
	end
    else
	groupMembersCount = GetNumGroupMembers();
	if IsInRaid()
	then
	    return groupMembersCount, "raid";
	else
	    return groupMembersCount, "party";
	end
    end
end

function mod:PlayerIsInGroup()
    return self:GetGroupMembersCount() > 1;
end


function mod:CountTalentsInTree(tabIndex)
    if tonumber(mod.clientBuildNumber) < 13164  -- Patch 4.0.1 "Cataclysm Systems"
    then
	local tabName, tabIcon, tabPoints = GetTalentTabInfo(tabIndex);
	return tabName, tabPoints;
    else
	local tabId, tabName, tabDescription, tabIcon, tabPoints = GetTalentTabInfo(tabIndex);
	return tabName, tabPoints;
    end
end

function mod:GetPlayerBuild()
    local specPoints = { };
    local lastName, maxIndex, maxName, maxPoints = nil, 0, 0, -1;

    for tabIndex = 1, GetNumTalentTabs()
    do
	local tabName, tabPoints = self:CountTalentsInTree(tabIndex);

	specPoints[tabName] = tabPoints;

	if maxPoints <= tabPoints
	then
	    lastName = maxName;

	    maxIndex = tabIndex;
	    maxName = tabName;
	    maxPoints = tabPoints;
	end
    end

    for specName, specPointsCount in pairs(specPoints)
    do
	print("  " .. specName .. ": " .. specPointsCount);
    end

    if lastName ~= nil and specPoints[lastName] == specPoints[maxName]
    then
	print(self.displayName .. ": " .. self.hybridPlayerBuildIntroLine ..
	    lastName .. " - " .. specPoints[lastName] .. ", " .. maxName .. " - " .. specPoints[maxName] .. ".");
	print(self.warningRoleBuffDisabled);
	return nil;
    end

    return maxIndex, maxName;
end

function mod:GetPlayerAbilityAndRank(abilityName)
    local spellName, spellRank = GetSpellInfo(abilityName);
    if spellName == nil
    then
	self:DebugMessage("No " .. abilityName .. " ability.");
	return false, 0;
    else
	if spellRank == "" or spellRank == nil or spellRank == 0
	then
	    self:DebugMessage("Found " .. spellName .. " ability rank " .. 1 .. ".");
	    return true, 1;
	else
	    if type(spellRank) == "string" and string.find(spellRank, mod.rankTooltipPrefix, 1, true) == 1
	    then
		spellRank = string.sub(spellRank, string.len(mod.rankTooltipPrefix) + 1);
	    end

	    spellRank = tonumber(spellRank);

	    if spellRank == nil
	    then
		-- spellRank = 1;
	    end
	    self:DebugMessage("Found " .. spellName .. " ability rank " .. spellRank .. ".");
	    return true, spellRank;
	end
    end
end

function mod:CheckPlayerHasAbility(abilityName)
    local spellName, spellRank = GetSpellInfo(abilityName);
    if spellName ~= nil
    then
	print(self:AbilityFoundMessage(abilityName));
    end
    return spellName ~= nil;
end

function mod:GetPlayerAbilityRanks(playerAbilities, abilityRanks)
    local hasAbilities = false;
    for playerSpell, enabled in pairs(playerAbilities)
    do
	local spellName, spellRank = GetSpellInfo(playerSpell);
	if spellName == nil
	then
	    spellRank = 0;
	    self:DebugMessage("No " .. playerSpell .. " ability.");
	else
	    if spellRank == "" or spellRank == nil or spellRank == 0 or spellRank == "Rank 0"
	    then
		spellRank = 1;
	    else
		if type(spellRank) == "string" and string.find(spellRank, mod.rankTooltipPrefix, 1, true) == 1
		then
		    spellRank = string.sub(spellRank, string.len(mod.rankTooltipPrefix) + 1);
		end

		spellRank = tonumber(spellRank);

		if spellRank == nil
		then
		    spellRank = 1;  -- spell has no rank, default to rank 1
		end
	    end
	    hasAbilities = true;
	    self:DebugMessage("Found " .. playerSpell .. " ability rank " .. spellRank .. ".")
	end

	abilityRanks[playerSpell] = spellRank;
    end

    return hasAbilities;
end

function mod:HasWeaponEnchants()
    local hasMainHandEnchant, hasOffHandEnchant = nil, nil;

    if tonumber(mod.clientBuildNumber) >= 18482 -- Patch 6.0 The Iron Tide
    then
	hasMainHandEnchant, _, _, _, hasOffHandEnchant = GetWeaponEnchantInfo();
    else
	hasMainHandEnchant, _, _, hasOffHandEnchant = GetWeaponEnchantInfo();
    end

    return hasMainHandEnchant, hasOffHandEnchant
end

function mod:ReportMessage(message, chatOnly)
    if chatOnly
    then
	print(self.displayName .. ": " .. message)
    else
	PlaySoundFile("Sound\\Interface\\RaidWarning.wav");
	RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
	--UIErrorsFrame:AddMessage(message, 1.0, 0.5, 0.0, 3);
    end
end

function mod:ShowMessage(message, chatOnly)
    if chatOnly
    then
	print(self.displayName .. ": * " .. message)
    else
	RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
    end
end

function mod:AddUpdateHandler(indexString, handlerFn)
    if self.UpdateHandlersSet == nil
    then
	self.UpdateHandlersSet = { [indexString] = handlerFn }
    else
	self.UpdateHandlersSet[indexString] = handlerFn
    end
end

function mod:RemoveUpdateHandler(indexString)
    if self.UpdateHandlersSet ~= nil
    then
	self.UpdateHandlersSet[indexString] = nil;

	for _, _ in pairs(self.UpdateHandlersSet)
	do
	    return
	end

	self.UpdateHandlersSet = nil
    end
end
