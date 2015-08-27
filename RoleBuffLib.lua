-- Global addon functions
-- Query player abilities and items

RoleBuff_UpdateHandlersSet = nil;

function RoleBuff_TableSelection(sourceTable, entries, defaultVal)
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

function RoleBuff_ReadStorageTable(storageTable, defaultVal, categories, ...)
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

    return RoleBuff_TableSelection(sourceTable, entries, defaultVal)
end

function RoleBuff_WriteStorageTable(storageTable, categories, entries)
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

function RoleBuff_ReadAddOnStorage(defaultVal, categories, ...)
    return RoleBuff_ReadStorageTable(AddOnStorageTable, defaultVal, categories, ...)
end

function RoleBuff_ReadCharacterStorage(defaultVal, categories, ...)
    return RoleBuff_ReadStorageTable(CharacterStorageTable, defaultVal, categories, ...)
end

function RoleBuff_WriteAddOnStorage(categories, entries)
    if AddOnStorageTable == nil
    then
	AddOnStorageTable = { }
    end

    RoleBuff_WriteStorageTable(AddOnStorageTable, categories, entries)
end

function RoleBuff_WriteCharacterStorage(categories, entries)
    if CharacterStorageTable == nil
    then
	CharacterStorageTable = { }
    end

    RoleBuff_WriteStorageTable(CharacterStorageTable, categories, entries)
end

local itemCacheEntry = "itemCache";
local rolesPerSetEntry = "setRoles";

local localCache = { };


function RoleBuff_GetEquipmentSetRoles()
    if CharacterStorageTable == nil
    then
	CharacterStorageTable = { };
    end
    
    if CharacterStorageTable[rolesPerSetEntry] == nil
    then
	CharacterStorageTable[rolesPerSetEntry] = { };
    end

    return CharacterStorageTable[rolesPerSetEntry];
end

function RoleBuff_GetItemId(itemName)
    if localCache[itemName] == nil
    then
	-- Given item not yet cached or not yet validated
	if AddOnStorageTable == nil
	then
	    AddOnStorageTable = { };
	end

	if AddOnStorageTable[itemCacheEntry] == nil
	then
	    AddOnStorageTable[itemCacheEntry] = { };
	end

	local itemDisplayName, itemLink = GetItemInfo(itemName);
	if itemDisplayName ~= nil
	then
	    local _, itemId = strsplit(":", string.match(itemLink, "item[%-?%d:]+"));

	    if itemId ~= nil and tonumber(itemId) ~= nil
	    then
		AddOnStorageTable[itemCacheEntry][itemName] = itemId;
		localCache[itemName] = itemId;
	    else
		RoleBuff_DebugMessage("No item ID for " .. itemName .. ".");
		return nil;	    -- error retrieving soulstone item ID
	    end
	else
	    -- item not loaded in this client session, search addon cache
	    if AddOnStorageTable[itemCacheEntry][itemName] ~= nil
	    then
		local itemId = nil
		local itemDisplayName, itemLink = GetItemInfo(AddOnStorageTable[itemCacheEntry][itemName]);

		if itemDisplayName ~= nil
		then
		    local itemString = string.match(itemLink, "item[%-?%d:]+");
		    if itemString ~= nil
		    then
			_, itemId = strsplit(":", itemString);
		    end
		end

		if itemDisplayName == itemName and itemId == AddOnStorageTable[itemCacheEntry][itemName]
		then
		    -- cached item passes validation
		    localCache[itemName] = itemId;
		else
		    -- cached item no longer valid
		    AddOnStorageTable[itemCacheEntry][itemName] = nil;
		end
	    end
	end
    end

    return localCache[itemName];
end

function RoleBuff_GetGroupMembersCount()
    local groupMembersCount;

    if tonumber(clientBuildNumber) < 16016  -- Patch 5.0.4 "Mists of Pandaria Systems"
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

function RoleBuff_PlayerIsInGroup()
    return (RoleBuff_GetGroupMembersCount()) > 1;
end


function RoleBuff_CountTalentsInTree(tabIndex)
    if tonumber(clientBuildNumber) < 13164  -- Patch 4.0.1 "Cataclysm Systems"
    then
	local tabName, tabIcon, tabPoints = GetTalentTabInfo(tabIndex);
	return tabName, tabPoints;
    else
	local tabId, tabName, tabDescription, tabIcon, tabPoints = GetTalentTabInfo(tabIndex);
	return tabName, tabPoints;
    end
end

function RoleBuff_GetPlayerBuild()
    local specPoints = { };
    local lastName, maxIndex, maxName, maxPoints = nil, 0, 0, -1;

    for tabIndex = 1, GetNumTalentTabs()
    do
	local tabName, tabPoints = RoleBuff_CountTalentsInTree(tabIndex);

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
	print(displayName .. ": " .. hybridPlayerBuildIntroLine ..
	    lastName .. " - " .. specPoints[lastName] .. ", " .. maxName .. " - " .. specPoints[maxName] .. ".");
	print(warningRoleBuffDisabled);
	return nil;
    end

    return maxIndex, maxName;
end

function RoleBuff_GetPlayerAbilityAndRank(abilityName)
    local spellName, spellRank = GetSpellInfo(abilityName);
    if spellName == nil
    then
	RoleBuff_DebugMessage("No " .. abilityName .. " ability.");
	return false, 0;
    else
	if spellRank == "" or spellRank == nil or spellRank == 0
	then
	    RoleBuff_DebugMessage("Found " .. spellName .. " ability rank " .. 1 .. ".");
	    return true, 1;
	else
	    if type(spellRank) == "string" and string.find(spellRank, rankTooltipPrefix, 1, true) == 1
	    then
		spellRank = string.sub(spellRank, string.len(rankTooltipPrefix) + 1);
	    end

	    spellRank = tonumber(spellRank);

	    if spellRank == nil
	    then
		-- spellRank = 1;
	    end
	    RoleBuff_DebugMessage("Found " .. spellName .. " ability rank " .. spellRank .. ".");
	    return true, spellRank;
	end
    end
end

function RoleBuff_CheckPlayerHasAbility(abilityName)
    local spellName, spellRank = GetSpellInfo(abilityName);
    if spellName ~= nil
    then
	print(RoleBuff_AbilityFoundMessage(abilityName));
    end
    return spellName ~= nil;
end

function RoleBuff_GetPlayerAbilityRanks(playerAbilities, abilityRanks)
    local hasAbilities = false;
    for playerSpell, enabled in pairs(playerAbilities)
    do
	local spellName, spellRank = GetSpellInfo(playerSpell);
	if spellName == nil
	then
	    spellRank = 0;
	    RoleBuff_DebugMessage("No " .. playerSpell .. " ability.");
	else
	    if spellRank == "" or spellRank == nil or spellRank == 0 or spellRank == "Rank 0"
	    then
		spellRank = 1;
	    else
		if type(spellRank) == "string" and string.find(spellRank, rankTooltipPrefix, 1, true) == 1
		then
		    spellRank = string.sub(spellRank, string.len(rankTooltipPrefix) + 1);
		end

		spellRank = tonumber(spellRank);

		if spellRank == nil
		then
		    spellRank = 1;  -- spell has no rank, default to rank 1
		end
	    end
	    hasAbilities = true;
	    RoleBuff_DebugMessage("Found " .. playerSpell .. " ability rank " .. spellRank .. ".")
	end

	abilityRanks[playerSpell] = spellRank;
    end

    return hasAbilities;
end

function RoleBuff_HasWeaponEnchants()
    local hasMainHandEnchant, hasOffHandEnchant = nil, nil;

    if tonumber(clientBuildNumber) >= 18482 -- Patch 6.0 The Iron Tide
    then
	hasMainHandEnchant, _, _, _, hasOffHandEnchant = GetWeaponEnchantInfo();
    else
	hasMainHandEnchant, _, _, hasOffHandEnchant = GetWeaponEnchantInfo();
    end

    return hasMainHandEnchant, hasOffHandEnchant
end

function RoleBuff_ReportMessage(message, chatOnly)
    if chatOnly
    then
	print(displayName .. ": " .. message)
    else
	PlaySoundFile("Sound\\Interface\\RaidWarning.wav");
	RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
	--UIErrorsFrame:AddMessage(message, 1.0, 0.5, 0.0, 3);
    end
end

function RoleBuff_ShowMessage(message, chatOnly)
    if chatOnly
    then
	print(displayName .. ": * " .. message)
    else
	RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
    end
end

function RoleBuff_AddUpdateHandler(indexString, handlerFn)
    if RoleBuff_UpdateHandlersSet == nil
    then
	RoleBuff_UpdateHandlersSet = { [indexString] = handlerFn }
    else
	RoleBuff_UpdateHandlersSet[indexString] = handlerFn
    end
end

function RoleBuff_RemoveUpdateHandler(indexString)
    if RoleBuff_UpdateHandlersSet ~= nil
    then
	RoleBuff_UpdateHandlersSet[indexString] = nil;

	for _, _ in pairs(RoleBuff_UpdateHandlersSet)
	do
	    return
	end

	RoleBuff_UpdateHandlersSet = nil
    end
end
