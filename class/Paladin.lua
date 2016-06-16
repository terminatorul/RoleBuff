local mod = RoleBuffAddOn;

local checkPaladinAura, checkPaladinSeal, checkPaladinBlessing = true, true, true;
local checkProtectionPaladinShield, checkBlessingOfSanctuary, checkRighteousFury = true, true, true;

local hasPaladinAura = false;
local hasPaladinBlessing = false;
local paladinBlessingRank = { };
local isProtectionPaladin = false;
local isHolyPaladin = false;
local hasBlock = false;
local hasRighteousFury = false;
local hasBlessingOfSanctuaryRank = 0;
local hasGreaterBlessingOfSanctuaryRank = 0;

local auraIndex, auraCount = 0, 0;
local RoleBuff_PaladinAttacked, RoleBuff_PaladinAttacking = false, false;

local function initialPlayerAlivePaladin(event, frame, ...)
    local specIndex, specName = mod:GetPlayerBuild();

    if specIndex ~= nil
    then
	print(mod:FormatSpecialization(mod.playerClassLocalized, specName));
	isProtectionPaladin = (specName == mod.protectionSpecName);
	isHolyPaladin = (specName == mod.holySpecName);
    end

    if checkPaladinAura
    then
	hasPaladinAura = false;
	local idx, paladinAura;
        for idx, paladinAura in pairs( { mod.devotionAura, mod.retributionAura, mod.concentrationAura, mod.frostResistanceAura, mod.shadowReistanceAura, mod.fireResistanceAura } )
        do
            if mod:CheckPlayerHasAbility(paladinAura)
            then
		hasPaladinAura = true;
		break;
            end
        end
    end

    if checkPaladinSeal
    then
	hasPaladinSeal = false;
	local idx, paladinSeal;
	for idx, paladinSeal in pairs( { mod.sealOfWisdom, mod.sealOfLight, mod.sealOfRighteousness, mod.sealOfJustice, mod.sealOfCommand, mod.sealOfVengeance, mod.sealOfTruth, mod.sealOfInsight } )
	do
	    if mod:CheckPlayerHasAbility(paladinSeal)
	    then
		hasPaladinSeal = true;
		break;
	    end
	end
    end

    if checkPaladinBlessing
    then
	paladinBlessingRank = { ["wisdom"] = { }, ["might"] = { }, ["kings"] = { }, ["sanctuary"] = { } };

	for kind, list in pairs( { ["wisdom"] = { mod.blessingOfWisdom, mod.greaterBlessingOfWisdom }, ["might"] = { mod.blessingOfMight, mod.greaterBlessingOfMight },
	    ["kings"] = { mod.blessingOfKings, mod.greaterBlessingOfKings }, ["sanctuary"] = { mod.blessingOfSanctuary, mod.greaterBlessingOfSanctuary } } )
	do
	    for idx, paladinBlessing in pairs( list )
	    do
		local spellName, spellRank = GetSpellInfo(paladinBlessing);
		if spellName == nil
		then
		    spellRank = 0;
		else
		    if spellRank == "" or spellRank == nil or spellRank == 0
		    then
			spellRank = 1;
		    end
		    hasPaladinBlessing = true;
		end

		paladinBlessingRank[kind][paladinBlessing] = spellRank;
	    end
	end
    end

    if checkBlessingOfSanctury
    then
	local name, rank = GetSpellInfo(mod.blessingOfSanctuary);
	if name == nill
	then
	    hasBlessingOfSanctuaryRank = 0;
	else
	    if rank == "" or rank == nil or rank == 0
	    then
		rank = 1;
	    end
	    hasBlessingOfSanctuaryRank = rank;
	    mod:DebugMessage("Found " .. mod.blessingOfSanctuary .. " rank " .. rank);
	end

	name, rank = GetSpellInfo(mod.greaterBlessingOfSanctuary);
	if name == nill
	then
	    hasGreaterBlessingOfSanctuaryRank = 0;
	else
	    if rank == "" or rank == nil or rank == 0
	    then
		rank = 1;
	    end
	    hasGreaterBlessingOfSanctuaryRank = rank;
	    mod:DebugMessage("Found " .. mod.greaterBlessingOfSanctuary .. " rank " .. rank);
	end
    end

    if checkProtectionPaladinShield and isProtectionPaladin
    then
	hasBlock = mod:CheckPlayerHasAbility(mod.blockSpellName);
    end

    if checkRighteousFury
    then
	hasRighteousFury = mod:CheckPlayerHasAbility(mod.righteousFury);
    end
end

local function updatePaladinAura(event, frame, ...)
    auraIndex, auraCount = GetShapeshiftForm(), GetNumShapeshiftForms();
end

local paladinSealList =
{
    [mod.sealOfCommand] = true, [mod.sealOfLight] = true, [mod.sealOfWisdom] = true, [mod.sealOfJustice] = true,
    [mod.sealOfVengeance] = true, [mod.sealOfTruth] = true, [mod.sealOfRighteousness] = true,
    [mod.sealOfInsight] = true
};

local paladinBlessingBuffList =
{
    [mod.blessingOfWisdom] = { ["kind"] = "wisdom" }, [mod.greaterBlessingOfWisdom] = { ["kind"] = "wisdom" },
    [mod.blessingOfMight] = { ["kind"] = "might" }, [mod.greaterBlessingOfMight] = { ["kind"] = "might" }, [mod.battleShout] = { ["kind"] = "might" },
    [mod.blessingOfKings] = { ["kind"] = "kings" }, [mod.greaterBlessingOfKings] = { ["kind"] = "kings" }, [mod.blessingOfForgottenKings] = { ["kind"] = "kings" },
    [mod.blessingOfSanctuary] = { ["kind"] = "sanctuary" }, [mod.greaterBlessingOfSanctuary] = { ["kind"] = "sanctuary" }
};

local function checkPaladinBlessings(paladinBlessingRank, paladinBlessingBuffs)
    for kind, list in pairs(paladinBlessingRank)
    do
	for blessing, rank in pairs(list)
	do
	    if rank ~= 0
	    then
		-- paladin can cast this kind of blessing
		mod:DebugMessage("[" .. kind .. "] " .. blessing .. " Rank " .. rank);
		if paladinBlessingBuffs[kind] == nil or paladinBlessingBuffs[kind][blessing] == nil or paladinBlessingBuffs[kind][blessing] < rank
		then
		    -- blessing is not buffed or is lower rank than paladin ability
		    return blessing;
		end
	    end
	end
    end
end

local function combatCheckPaladin(chatOnly, event, frame, ...)
    if checkPaladinAura and auraIndex <= 0 and auraCount > 0
    then
	mod:ReportMessage(mod:AbilityToCastMessage(mod.paladinAura), chatOnly);
    end

    local checkSealBuff, checkBlessingBuffs = (checkPaladinSeal and hasPaladinSeal), (checkPaladinBlessing and hasPaladinBlessing);
    local checkSanctuaryBlessingBuff = (checkBlessingOfSanctuary and (hasBlessingOfSanctuaryRank > 0 or hasGreaterBlessingOfSanctuaryRank > 0));

    if checkSealBuff or checkBlessingBuffs or checkSanctuaryBlessingBuff
    then
	local hasPaladinSealBuff = false;
	local hasBlessingSelfBuff = false;
	local hasSanctuaryBlessingBuff = false;
	local paladinBlessingBuffs = { ["wisdom"] = { }, ["might"] = { }, ["kings"] = { }, ["sanctuary"] = { } };
	local buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster = nil, nil, nil, nil, nil, nil, nil, nil;
	local i = 1;

	mod:DebugMessage("Paladin Blessings:")
	for blessing, props in pairs(paladinBlessingBuffList)
	do
	    mod:DebugMessage("  " .. blessing);
	end

	repeat
	    buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster = UnitBuff(mod.unitPlayer, i);
	    i = i + 1;

	    if buffName ~= nil
	    then
		if rank == "" or rank == nil
		then
		    rank = 1;
		end

		if checkSealBuff and paladinSealList[buffName] ~= nil
		then
		    hasPaladinSealBuff = true;
		end

		if checkBlessingBuffs and not hasBlessingSelfBuff and paladinBlessingBuffList[buffName] ~= nil
		then
		    if UnitIsUnit(unitCaster, mod.unitPlayer)
		    then
			mod:DebugMessage("Paladin self-blessing: " .. buffName);
			hasBlessingSelfBuff = true;
		    else
			paladinBlessingBuffs[paladinBlessingBuffList[buffName]["kind"]] = { [buffName] = rank };
		    end
		end

		if checkSanctuaryBlessingBuff and not hasSanctuaryBlessingBuff
		then
		    if buffName == mod.blessingOfSanctuary and rank >= hasBlessingOfSanctuaryRank
		    then
			mod:DebugMessage("Has " .. mod.blessingOfSanctuary .. " buff");
			hasSanctuaryBlessingBuff = true;
		    end

		    if buffName == mod.greaterBlessingOfSanctuary and rank >= hasGreaterBlessingOfSanctuaryRank
		    then
			mod:DebugMessage("Has " .. mod.greaterBlessingOfSanctuary .. " buff");
			hasSanctuaryBlessingBuff = true
		    end
		end
	    end
	until buffName == nil;

	if checkSealBuff and not hasPaladinSealBuff
	then
	    mod:ReportMessage(mod:AbilityToCastMessage(mod.paladinSeal), chatOnly);
	end

	if checkSanctuaryBlessingBuff and not hasSanctuaryBlessingBuff
	then
	    mod:ReportMessage(mod:AbilityToCastMessage(mod.blessingOfSanctuary), chatOnly)
	else
	    if checkBlessingBuffs and not hasBlessingSelfBuff
	    then
		local blessingToCast = checkPaladinBlessings(paladinBlessingRank, paladinBlessingBuffs);
		if blessingToCast ~= nil
		then
		    mod:ReportMessage(mod:AbilityToCastMessage(mod.paladinBlessing), chatOnly);
		end
	    end
	end
    end

    if checkProtectionPaladinShield and isProtectionPaladin and hasBlock and not IsEquippedItemType(mod.itemTypeShields)
    then
	mod:ReportMessage(mod:ItemEquipMessage(mod.itemShield), chatOnly);
    end

    if checkRighteousFury and hasRighteousFury
    then
	local name, rank = UnitBuff(mod.unitPlayer, mod.righteousFury);

	if isProtectionPaladin and name == nil and mod:PlayerIsInGroup()
	then
	    mod:ReportMessage(mod:AbilityToCastMessage(mod.righteousFury), chatOnly);
	end

	if not isProtectionPaladin and name ~= nill and mod:PlayerIsInGroup()
	then
	    mod:ReportMessage(mod:AbilityActiveMessage(mod.righteousFury), chatOnly);
	end
    end
end

mod.EventHandlerTablePaladin =
{
    [mod.eventPlayerAlive] = function(frame, event, ...)
	initialPlayerAlivePaladin(frame, event, ...);

	frame:RegisterEvent(mod.eventActiveTalentGroupChanged);
	frame:RegisterEvent(mod.eventUpdateShapeshiftForm);
	frame:RegisterEvent(mod.eventUpdateShapeshiftForms);
	frame:RegisterEvent(mod.eventPlayerEnterCombat);
	frame:RegisterEvent(mod.eventPlayerLeaveCombat);
	frame:RegisterEvent(mod.eventPlayerRegenDisabled);
	frame:RegisterEvent(mod.eventPlayerRegenEnabled);
    end,

    [mod.eventActiveTalentGroupChanged] = initialPlayerAlivePaladin,
    [mod.eventUpdateShapeshiftForm] = updatePaladinAura,
    [mod.eventUpdateShapeshiftForms] = updatePaladinAura,

    [mod.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_PaladinAttacked and not RoleBuff_PaladinAttacking
	then
	    combatCheckPaladin(false, frame, event, ...)
	end

	RoleBuff_PaladinAttacking = true;
    end,

    [mod.eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_PaladinAttacking = false;
    end,

    [mod.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_PaladinAttacked and not RoleBuff_PaladinAttacking
	then
	    combatCheckPaladin(false, frame, event, ...)
	end

	RoleBuff_PaladinAttacked = true;
    end,

    [mod.eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_PaladinAttacked = false;
    end
};

mod.SlashCommandHandlerPaladin =
{
    [mod.slashCommandPlayerCheck] = function()
	initialPlayerAlivePaladin(nil, nil);
    end,

    [mod.slashCommandCombatCheck] = function()
	combatCheckPaladin(true, nil, nil);
    end
};

function mod.GetPaladinRole()
    if isProtectionPaladin
    then
	return mod.roleTank;
    else
	if isHolyPaladin
	then
	    return mod.roleHealer;
	else
	    return mod.roleDPS;
	end
    end
end

function mod:PaladinOptionsFrameLoad(panel)
    panel.name = self.classNamePaladin;
    panel.parent = self.displayName;
    InterfaceOptions_AddCategory(panel)
end
