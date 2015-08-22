-- Check Warlock for:
--	- armor buff
--	- summoned minion or enslaved demon
--	- minion buff (Blood Pact, Fel Intelligence, Enrage)
--	- conjured healthstone
--	- soulstone ressurection
--	- firestone or spellstone weapon buff
--	- soul shard for combat spells
--

local checkWarlockArmor, checkWarlockMinion, checkWarlockHealthstone, checkWarlockSoulstone, checkWarlockWeapon, checkWarlockSoulShard = true, true, true, true, true, true;
local checkWarlockMinionBuff = true;
local warlockArmorList = { [demonSkin] = true, [demonArmor] = true, [felArmor] = true };
local warlockMinionList =
{
    [summonImp] = true, [summonVoidwalker] = true, [summonSuccubuss] = true, [summonFelhunter] = true,
    [summonFelgurard] = true, [summonInfernal] = true, [summonDoomguard] = true
};
local warlockMinionBuff = { [creatureFamilyImp] = bloodPact, [creatureFamilyFelhunter] = felIntelligence };
local warlockHealthstoneList = { [createHealthstone] = true, [ritualOfSouls] = true };
local warlockWeaponStoneList = { [createFirestone] = true, [createSpellstone] = true };
local warlockSoulShardCombatList = { [shadowburnSpellName] = true, [soulFireSpellName] = true };

local hasWarlockArmorAbilities = false;
local hasMinion = false;
local hasHealthstone = false
local hasWeaponStone = false;
local hasSoulstone = false;
local hasDrainSoul = false;
local hasSoulShardCombat = false;
local hasSoulshatter = false;
local RoleBuff_WarlockAttacked, RoleBuff_WarlockAttacking, RoleBuff_WarlockMountedAttack = false, false, false;

local warlockArmorRank = { };
local warlockMinionRank = { };
local warlockHealthstoneRank = { };
local warlockWeaponStoneRank = { };
local warlockSoulShardCombatRank = { };
local warlockSoulstoneRank = 0;
local warlockDrainSoulRank = 0;
local warlockSoulshatterRank = 0;

local healthstoneRank =
{
    [1] = minorHealthstone, [2] = lesserHealthstone, [3] = plainHealthstone, [4] = greaterHealthstone, [5] = majorHealthstone,
    [6] = masterHealthstone, [7] = demonicHealthstone, [8] = felHealthstone
};

local soulwellHealthstoneRank = 6;

local soulstoneRank = 
{
    [1] = minorSoulstone, [2] = lesserSoulstone, [3] = plainSoulstone, [4] = greaterSoulstone, [5] = majorSoulstone,
    [6] = masterSoulstone, [7] = demonicSoulstone
};

function RoleBuff_InitialPlayerAliveWarlock(event, frame, ...)
    hasWarlockArmorAbilities =	RoleBuff_GetPlayerAbilityRanks(warlockArmorList, warlockArmorRank);
    hasMinion =			RoleBuff_GetPlayerAbilityRanks(warlockMinionList, warlockMinionRank);
    hasHealthstone =		RoleBuff_GetPlayerAbilityRanks(warlockHealthstoneList, warlockHealthstoneRank);
    hasWeaponStone =		RoleBuff_GetPlayerAbilityRanks(warlockWeaponStoneList, warlockWeaponStoneRank);
    hasSoulShardCombat =	RoleBuff_GetPlayerAbilityRanks(warlockSoulShardCombatList, warlockSoulShardCombatRank);

    hasSoulstone, warlockSoulstoneRank =	RoleBuff_GetPlayerAbilityAndRank(createSoulstone);
    hasDrainSoul, warlockDrainSoulRank =	RoleBuff_GetPlayerAbilityAndRank(drainSoulSpellName);
    hasSoulshatter, warlockSoulshatterRank =	RoleBuff_GetPlayerAbilityAndRank(soulShatterSpellName);
end

function RoleBuff_CheckWarlockArmor(chatOnly)
    if checkWarlockArmor and hasWarlockArmorAbilities
    then
	local i = 1;
	repeat
	    buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster = UnitBuff(unitPlayer, i);
	    i = i + 1;

	    if buffName ~= nil
	    then
		if type(rank) == "string" and string.find(rank, rankTooltipPrefix, 1, true) == 1
		then
		    rank = string.sub(rank, string.len(rankTooltipPrefix) + 1)
		end
		if rank == nil or rank == "" or rank == 0
		then
		    rank = 1;
		end

		rank = tonumber(rank);

		if rank == nil
		then
		    rank = 1;
		end

		-- RoleBuff_DebugMessage("Player buff " .. buffName .. " rank " .. rank .. ".");

		if warlockArmorRank[buffName] ~= nil and warlockArmorRank[buffName] <= rank and (buffName ~= demonSkin or not warlockArmorRank[demonArmor])
		then
		    return;	    -- warlock armor buff of sufficient rank found
		end
	    end
	until buffName == nil;

	RoleBuff_ReportMessage(RoleBuff_AbilityToCastMessage(warlockArmor), chatOnly);
    end
end

function RoleBuff_CheckWarlockMinion(chatOnly)
    if checkWarlockMinion and hasMinion
    then
	if not UnitExists(unitPet) and not IsMounted()
	then
	    RoleBuff_ReportMessage(RoleBuff_SummonUnitMessage(warlockMinion), chatOnly)
	end
    end
end

function RoleBuff_CheckWarlockMinionBuff(chatOnly)
    if checkWarlockMinionBuff and hasMinion and UnitExists(unitPet)
    then
	local creatureFamily = UnitCreatureFamily(unitPet);

	if warlockMinionBuff[creatureFamily] ~= nil
	then
	    local daemonHasBuffAbility, demonAbilityRank = RoleBuff_GetPlayerAbilityAndRank(warlockMinionBuff[creatureFamily]);

	    if daemonHasBuffAbility
	    then
		local autocastable, autocast = GetSpellAutocast(warlockMinionBuff[creatureFamily], BOOKTYPE_PET);

		if not autocast
		then
		    local minionBuffName, minionBuffRank = UnitBuff(unitPlayer, warlockMinionBuff[creatureFamily]);

		    if not minionBuffRank or minionBuffRank == "" or minionBuffRank == 0
		    then
			minionBuffRank = 1;
		    end

		    if tonumber(minionBuffRank) ~= nil
		    then
			minionBuffRank = tonumber(minionBuffRank);
		    else
			local numericRank, matched = string.gsub(minionBuffRank, "Rank ", "");
			if matched > 0 and tonumber(numericRank) ~= nil
			then
			    minionBuffRank = tonumber(numericRank);
			else
			    minionBuffRank = 1;
			end
		    end

		    if minionBuffName == nil or minionBuffRank < demonAbilityRank
		    then
			RoleBuff_ReportMessage(RoleBuff_AbilityToCastMessage(warlockMinionBuff[creatureFamily]), chatOnly);
		    end
		end
	    end
	else
	    -- if UnitAura(unitPet, enslaveDemon) ~= nil
	    -- then
		-- -- warlock has a demon enslaved instead of a minion, check for Enrage buff
		-- local demonHasEnrage, enrageAbilityRank = RoleBuff_GetPlayerAbilityAndRank(enrageSpellName);

		-- if deamonHasEnrage
		-- then
		--     local autocastable, autocast = GetSpellAutocast(warlockMinionBuff[creatureFamily], BOOKTYPE_PET);

		--     if not autocast
		--     then
		-- 	local minionBuffName, minionBuffRank = UnitAura(unitPet, enrageSpellName);

		-- 	if not minionBuffRank or minionBuffRank == "" or minionBuffRank == 0
		-- 	then
		-- 	    minionBuffRank = 1;
		-- 	end

		-- 	if tonumber(minionBuffRank) ~= nil
		-- 	then
		-- 	    minionBuffRank = tonumber(minionBuffRank);
		-- 	else
		-- 	    local numericRank, matched = string.gsub(minionBuffRank, "Rank ", "");
		-- 	    if matched > 0 and tonumber(numericRank) ~= nil
		-- 	    then
		-- 		minionBuffRank = tonumber(numericRank);
		-- 	    else
		-- 		minionBuffRank = 1;
		-- 	    end
		-- 	end

		-- 	if minionBuffName == nil or minionBuffRank < enrageAbilityRank
		-- 	then
		-- 	    RoleBuff_ReportMessage(RoleBuff_AbilitytoCastMessage(enrageSpellName), chatOnly);
		-- 	end
		--     end
		-- end
	    -- end
	end
    end
end

function RoleBuff_CheckWarlockHasHealthstone(chatOnly)
    if checkWarlockHealthstone and hasHealthstone
    then
	local minHealthstoneRank = 1;
	
	if warlockHealthstoneRank[createHealthstone] ~= nil
	then
	    minHealthstoneRank = warlockHealthstoneRank[createHealthstone];
	else
	    minHealthstoneRank = soulwellHealthstoneRank;
	end

	local currentHealthstoneRank = minHealthstoneRank;

	while healthstoneRank[currentHealthstoneRank] ~= nil
	do
	    if GetItemCount(healthstoneRank[currentHealthstoneRank], false, false) > 0
	    then
		return;	    -- healthstone of sufficient rank found in bags
	    end
	    currentHealthstoneRank = currentHealthstoneRank + 1;
	end

	RoleBuff_ReportMessage(RoleBuff_CreateItemMessage(healthstoneRank[minHealthstoneRank]), chatOnly);
    end
end

function RoleBuff_CheckWarlockHasSoulstone(chatOnly)
    if checkWarlockSoulstone and hasSoulstone
    then
	local soulstoneItemId = RoleBuff_GetItemId(soulstoneRank[warlockSoulstoneRank]);

	if soulstoneItemId == nil
	then
	    -- no way to get remaining cooldown, a soulstone item was never seen before
	    buffName, buffRank = UnitBuff(unitPlayer, soulstoneResurrection, nil, filterPlayer);
	    if buffName == nil
	    then
		-- player is not soulstoned by herself
		RoleBuff_ReportMessage(RoleBuff_CreateItemMessage(soulstoneRank[warlockSoulstoneRank]), chatOnly)
	    end
	else
	    local startTime, soulstoneCooldown = GetItemCooldown(soulstoneItemId);
	    if tartTime ~= 0 and startTime + soulstoneCooldown > GetTime()
	    then
		-- soulstone on cooldown
	    else
		buffName, buffRank = UnitBuff(unitPlayer, soulstoneResurrection, nil, filterPlayer);
		if buffName == nil
		then
		    RoleBuff_ReportMessage(RoleBuff_UseItemMessage(soulstoneRank[warlockSoulstoneRank]), chatOnly)
		-- else
		--	Player has soulstone buff (although soulstone is off couldown, can happen after login)
		end
	    end
	end
    end
end

function RoleBuff_CheckWarlockWeaponStone(chatOnly)
    if checkWarlockWeapon and hasWeaponStone
    then
	local hasMainHandEnchant, hasOffHandEnchant = RoleBuff_HasWeaponEnchants();

	if hasMainHandEnchant ~= nil and (hasOffhandEnchant ~= nil or not OffhandHasWeapon())
	then
	else
	    RoleBuff_ReportMessage(RoleBuff_ApplyEnchantmentMessage(warlockWeaponEnchantment), chatOnly);
	end
    end
end

function RoleBuff_CheckWarlockHasSoulShard(chatOnly)
    if checkWarlockSoulShard and hasDrainSoul and (hasSoulShardCombat or hasSoulshatter and RoleBuff_PlayerIsInGroup())
    then
	local shardsCount = GetItemCount(soulShard, false, false);
	if shardsCount > 5	-- Expect 6 shards at all times
	then
	    return;
	else
	    if shardsCount > 0
	    then
		RoleBuff_ShowMessage(RoleBuff_CreateItemMessage(soulShard), chatOnly);
	    else
		RoleBuff_ReportMessage(RoleBuff_CreateItemMessage(soulShard), chatOnly);
	    end
	end
    end
end

local warlockDismountToMinionTime = 0;

function RoleBuff_CheckWarlockDismountToMinionInterval(elapsedTime)
    warlockDismountToMinionTime = warlockDismountToMinionTime + 1;

    if warlockDismountToMinionTime >= 10
    then
	RoleBuff_CheckWarlockMinion(false);
	RoleBuff_RemoveUpdateHandler("warlockDismountToMinionTime");
	warlockDismountToMinionTime = 0
    end
end


function RoleBuff_CombatCheckWarlock(chatOnly, event, frame, ...)
    RoleBuff_CheckWarlockArmor(chatOnly);
    RoleBuff_CheckWarlockMinion(chatOnly);
    RoleBuff_CheckWarlockMinionBuff(chatOnly);
    RoleBuff_CheckWarlockHasHealthstone(chatOnly);
    RoleBuff_CheckWarlockHasSoulstone(chatOnly);
    RoleBuff_CheckWarlockWeaponStone(chatOnly);
    RoleBuff_CheckWarlockHasSoulShard(chatOnly)
end

RoleBuff_EventHandlerTableWarlock = 
{
    [eventPlayerAlive] = function(frame, event, ...)
	RoleBuff_InitialPlayerAliveWarlock(frame, event, ...);

	frame:RegisterEvent(eventActiveTalentGroupChanged);
	frame:RegisterEvent(eventPlayerEnterCombat);
	frame:RegisterEvent(eventPlayerLeaveCombat);
	frame:RegisterEvent(eventPlayerRegenDisabled);
	frame:RegisterEvent(eventPlayerRegenEnabled);
	frame:RegisterEvent(eventCompanionUpdate);
    end,

    [eventActiveTalentGroupChanged] = RoleBuff_InitialPlayerAliveWarlock,

    [eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_WarlockAttacked and not RoleBuff_WarlockAttacking
	then
	    RoleBuff_CombatCheckWarlock(false, frame, event, ...)
	end

	RoleBuff_WarlockAttacking = true;
	RoleBuff_WarlockMountedAttack = IsMounted();
    end,

    [eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_WarlockAttacking = false;
	RoleBuff_WarlockMountedAttack = false;
    end,

    [eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_WarlockAttacked and not RoleBuff_WarlockAttacking
	then
	    RoleBuff_CombatCheckWarlock(false, frame, event, ...)
	end
	
	RoleBuff_WarlockAttacked = true;
	RoleBuff_WarlockMountedAttack = IsMounted()
    end,

    [eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_WarlockAttacked = false;
	RoleBuff_WarlockMountedAttack = false
    end,

    [eventCompanionUpdate] = function(frame, event, arg1, arg2, ...)
	if RoleBuff_WarlockMountedAttack and not IsMounted()
	then
	    -- Warlock dismounted during combat
	    RoleBuff_AddUpdateHandler("warlockDismountToMinionTime", RoleBuff_CheckWarlockDismountToMinionInterval);	 -- wait for 0.5 sec. and check minion
	    RoleBuff_WarlockMountedAttack = false
	end
    end
};

RoleBuff_SlashCommandHandlerWarlock =
{
    [slashCommandPlayerCheck] = function()
	RoleBuff_InitialPlayerAliveWarlock(nil, nil)
    end,

    [slashCommandCombatCheck] = function()
	RoleBuff_CombatCheckWarlock(true, nil, nil)
    end
};

function RoleBuff_GetWarlockRole()
    return roleDPS
end
