-- Check Warlock for:
--	- armor buff
--	- summoned minion or enslaved demon
--	- minion buff (Blood Pact, Fel Intelligence, Enrage)
--	- conjured healthstone
--	- soulstone ressurection
--	- firestone or spellstone weapon buff
--	- soul shard for combat spells
--

local mod = RoleBuffAddOn;
local checkWarlockArmor, checkWarlockMinion, checkWarlockHealthstone, checkWarlockSoulstone, checkWarlockWeapon, checkWarlockSoulShard = true, true, true, true, true, true;
local checkWarlockMinionBuff, minShardsCount = true, 6;

local warlockArmorList = { [mod.demonSkin] = true, [mod.demonArmor] = true, [mod.felArmor] = true };
local warlockMinionList =
{
    [mod.summonImp] = true, [mod.summonVoidwalker] = true, [mod.summonSuccubuss] = true, [mod.summonFelhunter] = true,
    [mod.summonFelgurard] = true, [mod.summonInfernal] = true, [mod.summonDoomguard] = true
};
local warlockMinionBuff = { [mod.creatureFamilyImp] = mod.bloodPact, [mod.creatureFamilyFelhunter] = mod.felIntelligence };
local warlockHealthstoneList = { [mod.createHealthstone] = true, [mod.ritualOfSouls] = true };
local warlockWeaponStoneList = { [mod.createFirestone] = true, [mod.createSpellstone] = true };
local warlockSoulShardCombatList = { [mod.shadowburnSpellName] = true, [mod.soulFireSpellName] = true };

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
    [1] = mod.minorHealthstone, [2] = mod.lesserHealthstone, [3] = mod.plainHealthstone, [4] = mod.greaterHealthstone, [5] = mod.majorHealthstone,
    [6] = mod.masterHealthstone, [7] = mod.demonicHealthstone, [8] = mod.felHealthstone
};

local soulwellHealthstoneRank = 6;

local soulstoneRank = 
{
    [1] = mod.minorSoulstone, [2] = mod.lesserSoulstone, [3] = mod.plainSoulstone, [4] = mod.greaterSoulstone, [5] = mod.majorSoulstone,
    [6] = mod.masterSoulstone, [7] = mod.demonicSoulstone
};

function initialPlayerAliveWarlock(event, frame, ...)
    hasWarlockArmorAbilities =	mod:GetPlayerAbilityRanks(warlockArmorList, warlockArmorRank);
    hasMinion =			mod:GetPlayerAbilityRanks(warlockMinionList, warlockMinionRank);
    hasHealthstone =		mod:GetPlayerAbilityRanks(warlockHealthstoneList, warlockHealthstoneRank);
    hasWeaponStone =		mod:GetPlayerAbilityRanks(warlockWeaponStoneList, warlockWeaponStoneRank);
    hasSoulShardCombat =	mod:GetPlayerAbilityRanks(warlockSoulShardCombatList, warlockSoulShardCombatRank);

    hasSoulstone, warlockSoulstoneRank =	mod:GetPlayerAbilityAndRank(mod.createSoulstone);
    hasDrainSoul, warlockDrainSoulRank =	mod:GetPlayerAbilityAndRank(mod.drainSoulSpellName);
    hasSoulshatter, warlockSoulshatterRank =	mod:GetPlayerAbilityAndRank(mod.soulShatterSpellName);
end

local function combatCheckWarlockArmor(chatOnly)
    if checkWarlockArmor and hasWarlockArmorAbilities
    then
	local i = 1;
	repeat
	    local buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster = UnitBuff(mod.unitPlayer, i);
	    i = i + 1;

	    if buffName ~= nil
	    then
		if type(rank) == "string" and string.find(rank, mod.rankTooltipPrefix, 1, true) == 1
		then
		    rank = string.sub(rank, string.len(mod.rankTooltipPrefix) + 1)
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

		if warlockArmorRank[buffName] ~= nil and warlockArmorRank[buffName] <= rank and (buffName ~= mod.demonSkin or not warlockArmorRank[mod.demonArmor])
		then
		    return;	    -- warlock armor buff of sufficient rank found
		end
	    end
	until buffName == nil;

	mod:ReportMessage(mod:AbilityToCastMessage(mod.warlockArmor), chatOnly);
    end
end

local function combatCheckWarlockMinion(chatOnly)
    if checkWarlockMinion and hasMinion
    then
	if not UnitExists(mod.unitPet) and not IsMounted()
	then
	    mod:ReportMessage(mod:SummonUnitMessage(mod.warlockMinion), chatOnly)
	end
    end
end

local function combatCheckWarlockMinionBuff(chatOnly)
    if checkWarlockMinionBuff and hasMinion and UnitExists(mod.unitPet)
    then
	local creatureFamily = UnitCreatureFamily(mod.unitPet);

	if warlockMinionBuff[mod.creatureFamily] ~= nil
	then
	    local daemonHasBuffAbility, demonAbilityRank = mod:GetPlayerAbilityAndRank(warlockMinionBuff[mod.creatureFamily]);

	    if daemonHasBuffAbility
	    then
		local autocastable, autocast = GetSpellAutocast(warlockMinionBuff[mod.creatureFamily], BOOKTYPE_PET);

		if not autocast
		then
		    local minionBuffName, minionBuffRank = UnitBuff(mod.unitPlayer, warlockMinionBuff[mod.creatureFamily]);

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
			mod:ReportMessage(mod:AbilityToCastMessage(warlockMinionBuff[mod.creatureFamily]), chatOnly);
		    end
		end
	    end
	end
    end
end

local function checkWarlockHasHealthstone(chatOnly)
    if checkWarlockHealthstone and hasHealthstone
    then
	local minHealthstoneRank = 1;
	
	if warlockHealthstoneRank[mod.createHealthstone] ~= nil
	then
	    minHealthstoneRank = warlockHealthstoneRank[mod.createHealthstone];
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

	mod:ReportMessage(mod:CreateItemMessage(healthstoneRank[minHealthstoneRank]), chatOnly);
    end
end

local function checkWarlockHasSoulstone(chatOnly)
    if checkWarlockSoulstone and hasSoulstone
    then
	local soulstoneItemId = mod:GetItemId(soulstoneRank[warlockSoulstoneRank]);

	if soulstoneItemId == nil
	then
	    -- no way to get remaining cooldown, a soulstone item was never seen before
	    local buffName, buffRank = UnitBuff(mod.unitPlayer, mod.soulstoneResurrection, nil, mod.filterPlayer);
	    if buffName == nil
	    then
		-- player is not soulstoned by herself
		mod:ReportMessage(mod:CreateItemMessage(soulstoneRank[warlockSoulstoneRank]), chatOnly)
	    end
	else
	    local startTime, soulstoneCooldown = GetItemCooldown(soulstoneItemId);
	    if tartTime ~= 0 and startTime + soulstoneCooldown > GetTime()
	    then
		-- soulstone on cooldown
	    else
		local buffName, buffRank = UnitBuff(mod.unitPlayer, mod.soulstoneResurrection, nil, mod.filterPlayer);
		if buffName == nil
		then
		    mod:ReportMessage(mod:UseItemMessage(soulstoneRank[warlockSoulstoneRank]), chatOnly)
		-- else
		--	Player has soulstone buff (although soulstone is off couldown, can happen after login)
		end
	    end
	end
    end
end

local function checkWarlockWeaponStone(chatOnly)
    if checkWarlockWeapon and hasWeaponStone
    then
	local hasMainHandEnchant, hasOffHandEnchant = mod:HasWeaponEnchants();

	if hasMainHandEnchant ~= nil and (hasOffhandEnchant ~= nil or not OffhandHasWeapon())
	then
	else
	    mod:ReportMessage(mod:ApplyEnchantmentMessage(mod.warlockWeaponEnchantment), chatOnly);
	end
    end
end

local function checkWarlockHasSoulShard(chatOnly)
    if checkWarlockSoulShard and hasDrainSoul and (hasSoulShardCombat or hasSoulshatter and mod:PlayerIsInGroup())
    then
	local soulShard = mod.soulShard;
	local shardsCount = GetItemCount(soulShard, false, false);
	if shardsCount < minShardsCount -- Expect 6 shards at all times
	then
	    if shardsCount > 0
	    then
		mod:ShowMessage(mod:CreateItemMessage(soulShard), chatOnly);
	    else
		mod:ReportMessage(mod:CreateItemMessage(soulShard), chatOnly);
	    end
	end
    end
end

local warlockDismountToMinionTime = 0;

local function RoleBuff_CheckWarlockDismountToMinionInterval(elapsedTime)
    warlockDismountToMinionTime = warlockDismountToMinionTime + 1;

    if warlockDismountToMinionTime >= 10
    then
	combatCheckWarlockMinion(false);
	mod:RemoveUpdateHandler("warlockDismountToMinionTime");
	warlockDismountToMinionTime = 0
    end
end


local function combatCheckWarlock(chatOnly, event, frame, ...)
    combatCheckWarlockArmor(chatOnly);
    combatCheckWarlockMinion(chatOnly);
    combatCheckWarlockMinionBuff(chatOnly);
    checkWarlockHasHealthstone(chatOnly);
    checkWarlockHasSoulstone(chatOnly);
    checkWarlockWeaponStone(chatOnly);
    checkWarlockHasSoulShard(chatOnly)
end

mod.EventHandlerTableWarlock = 
{
    [mod.eventPlayerAlive] = function(frame, event, ...)
	initialPlayerAliveWarlock(frame, event, ...);

	frame:RegisterEvent(mod.eventActiveTalentGroupChanged);
	frame:RegisterEvent(mod.eventPlayerEnterCombat);
	frame:RegisterEvent(mod.eventPlayerLeaveCombat);
	frame:RegisterEvent(mod.eventPlayerRegenDisabled);
	frame:RegisterEvent(mod.eventPlayerRegenEnabled);
	frame:RegisterEvent(mod.eventCompanionUpdate);
    end,

    [mod.eventActiveTalentGroupChanged] = initialPlayerAliveWarlock,

    [mod.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_WarlockAttacked and not RoleBuff_WarlockAttacking
	then
	    combatCheckWarlock(false, frame, event, ...)
	end

	RoleBuff_WarlockAttacking = true;
	RoleBuff_WarlockMountedAttack = IsMounted();
    end,

    [mod.eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_WarlockAttacking = false;
	RoleBuff_WarlockMountedAttack = false;
    end,

    [mod.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_WarlockAttacked and not RoleBuff_WarlockAttacking
	then
	    combatCheckWarlock(false, frame, event, ...)
	end
	
	RoleBuff_WarlockAttacked = true;
	RoleBuff_WarlockMountedAttack = IsMounted()
    end,

    [mod.eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_WarlockAttacked = false;
	RoleBuff_WarlockMountedAttack = false
    end,

    [mod.eventCompanionUpdate] = function(frame, event, arg1, arg2, ...)
	if RoleBuff_WarlockMountedAttack and not IsMounted()
	then
	    -- Warlock dismounted during combat
	    mod:AddUpdateHandler("warlockDismountToMinionTime", RoleBuff_CheckWarlockDismountToMinionInterval);	 -- wait for 0.5 sec. and check minion
	    RoleBuff_WarlockMountedAttack = false
	end
    end
};

mod.SlashCommandHandlerWarlock =
{
    [mod.slashCommandPlayerCheck] = function()
	initialPlayerAliveWarlock(nil, nil)
    end,

    [mod.slashCommandCombatCheck] = function()
	combatCheckWarlock(true, nil, nil)
    end
};

function mod.GetWarlockRole()
    return mod.roleDPS
end

function mod:WarlockOptionsFrameLoad(panel)
    RoleBuff_WarlockSoulshardCountBox:SetNumber(minShardsCount);
    RoleBuff_WarlockSoulshardCountBox:SetCursorPosition(0);

    panel.name = self.classNameWarlock;
    panel.parent = self.displayName;
    InterfaceOptions_AddCategory(panel);
end
