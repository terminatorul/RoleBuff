local checkPaladinAura, checkPaladinSeal, checkPaladinBlessing = true, true, true;
local checkProtectionPaladinShield, checkBlessingOfSanctuary, checkRighteousFury = true, true, true;

hasPaladinAura = false;
hasPaladinBlessing = false;
paladinBlessingRank = { };
isProtectionPaladin = false;
isHolyPaladin = false;
hasBlock = false;
hasRighteousFury = false;
hasBlessingOfSanctuaryRank = 0;
hasGreaterBlessingOfSanctuaryRank = 0;

auraIndex, auraCount = 0, 0;
RoleBuff_PaladinAttacked, RoleBuff_PaladinAttacking = false, false;

function RoleBuff_InitialPlayerAlivePaladin(event, frame, ...)
    local specIndex, specName = RoleBuff_GetPlayerBuild();

    if specIndex ~= nil
    then
	print(RoleBuff_FormatSpecialization(playerClassLocalized, specName));
	isProtectionPaladin = (specName == protectionSpecName);
	isHolyPaladin = (specName == holySpecName);
    end

    if checkPaladinAura
    then
	hasPaladinAura = false;
	local idx, paladinAura;
        for idx, paladinAura in pairs( { devotionAura, retributionAura, concentrationAura, frostResistanceAura, shadowReistanceAura, fireResistanceAura } )
        do
            if RoleBuff_CheckPlayerHasAbility(paladinAura)
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
	for idx, paladinSeal in pairs( { sealOfWisdom, sealOfLight, sealOfRighteousness, sealOfJustice, sealOfCommand, sealOfVengeance, sealOfTruth, sealOfInsight } )
	do
	    if RoleBuff_CheckPlayerHasAbility(paladinSeal)
	    then
		hasPaladinSeal = true;
		break;
	    end
	end
    end

    if checkPaladinBlessing
    then
	paladinBlessingRank = { ["wisdom"] = { }, ["might"] = { }, ["kings"] = { }, ["sanctuary"] = { } };

	for kind, list in pairs( { ["wisdom"] = { blessingOfWisdom, greaterBlessingOfWisdom }, ["might"] = { blessingOfMight, greaterBlessingOfMight },
	    ["kings"] = { blessingOfKings, greaterBlessingOfKings }, ["sanctuary"] = { blessingOfSanctuary, greaterBlessingOfSanctuary } } )
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
	local name, rank = GetSpellInfo(blessingOfSanctuary);
	if name == nill
	then
	    hasBlessingOfSanctuaryRank = 0;
	else
	    if rank == "" or rank == nil or rank == 0
	    then
		rank = 1;
	    end
	    hasBlessingOfSanctuaryRank = rank;
	    RoleBuff_DebugMessage("Found " .. blessingOfSanctuary .. " rank " .. rank);
	end

	name, rank = GetSpellInfo(greaterBlessingOfSanctuary);
	if name == nill
	then
	    hasGreaterBlessingOfSanctuaryRank = 0;
	else
	    if rank == "" or rank == nil or rank == 0
	    then
		rank = 1;
	    end
	    hasGreaterBlessingOfSanctuaryRank = rank;
	    RoleBuff_DebugMessage("Found " .. greaterBlessingOfSanctuary .. " rank " .. rank);
	end
    end

    if checkProtectionPaladinShield and isProtectionPaladin
    then
	hasBlock = RoleBuff_CheckPlayerHasAbility(blockSpellName);
    end

    if checkRighteousFury
    then
	hasRighteousFury = RoleBuff_CheckPlayerHasAbility(righteousFury);
    end
end

function RoleBuff_UpdatePaladinAura(event, frame, ...)
    auraIndex, auraCount = GetShapeshiftForm(), GetNumShapeshiftForms();
end

local paladinSealList =
{
    [sealOfCommand] = true, [sealOfLight] = true, [sealOfWisdom] = true, [sealOfJustice] = true,
    [sealOfVengeance] = true, [sealOfTruth] = true, [sealOfRighteousness] = true, 
    [sealOfInsight] = true
};

local paladinBlessingBuffList = 
{
    [blessingOfWisdom] = { ["kind"] = "wisdom" }, [greaterBlessingOfWisdom] = { ["kind"] = "wisdom" },
    [blessingOfMight] = { ["kind"] = "might" }, [greaterBlessingOfMight] = { ["kind"] = "might" }, [battleShout] = { ["kind"] = "might" },
    [blessingOfKings] = { ["kind"] = "kings" }, [greaterBlessingOfKings] = { ["kind"] = "kings" }, [blessingOfForgottenKings] = { ["kind"] = "kings" },
    [blessingOfSanctuary] = { ["kind"] = "sanctuary" }, [greaterBlessingOfSanctuary] = { ["kind"] = "sanctuary" }
};

function RoleBuff_CheckPaladinBlessings(paladinBlessingRank, paladinBlessingBuffs)
    for kind, list in pairs(paladinBlessingRank)
    do
	for blessing, rank in pairs(list)
	do
	    if rank ~= 0
	    then
		-- paladin can cast this kind of blessing
		RoleBuff_DebugMessage("[" .. kind .. "] " .. blessing .. " Rank " .. rank);
		if paladinBlessingBuffs[kind] == nil or paladinBlessingBuffs[kind][blessing] == nil or paladinBlessingBuffs[kind][blessing] < rank
		then
		    -- blessing is not buffed or is lower rank than paladin ability
		    return blessing;
		end
	    end
	end
    end
end

function RoleBuff_CombatCheckPaladin(chatOnly, event, frame, ...)
    if checkPaladinAura and auraIndex <= 0 and auraCount > 0
    then
	RoleBuff_ReportMessage(RoleBuff_AbilityToCastMessage(paladinAura), chatOnly);
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

	RoleBuff_DebugMessage("Paladin Blessings:")
	for blessing, props in pairs(paladinBlessingBuffList)
	do
	    RoleBuff_DebugMessage("  " .. blessing);
	end

	repeat
	    buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster = UnitBuff(unitPlayer, i);
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
		    if UnitIsUnit(unitCaster, unitPlayer)
		    then
			RoleBuff_DebugMessage("Paladin self-blessing: " .. buffName);
			hasBlessingSelfBuff = true;
		    else
			paladinBlessingBuffs[paladinBlessingList[buffName]["kind"]] = { [buffName] = rank };
		    end
		end

		if checkSanctuaryBlessingBuff and not hasSanctuaryBlessingBuff
		then
		    if buffName == blessingOfSanctuary and rank >= hasBlessingOfSanctuaryRank
		    then
			RoleBuff_DebugMessage("Has " .. blessingOfSanctuary .. " buff");
			hasSanctuaryBlessingBuff = true;
		    end

		    if buffName == greaterBlessingOfSanctuary and rank >= hasGreaterBlessingOfSanctuaryRank
		    then
			RoleBuff_DebugMessage("Has " .. greaterBlessingOfSanctuary .. " buff");
			hasSanctuaryBlessingBuff = true
		    end
		end
	    end
	until buffName == nil;

	if checkSealBuff and not hasPaladinSealBuff
	then
	    RoleBuff_ReportMessage(RoleBuff_AbilityToCastMessage(paladinSeal), chatOnly);
	end

	if checkSanctuaryBlessingBuff and not hasSanctuaryBlessingBuff
	then
	    RoleBuff_ReportMessage(RoleBuff_AbilityToCastMessage(blessingOfSanctuary), chatOnly)
	else
	    if checkBlessingBuffs and not hasBlessingSelfBuff
	    then
		local blessingToCast = RoleBuff_CheckPaladinBlessings(paladinBlessingRank, paladinBlessingBuffs);
		if blessingToCast ~= nil 
		then
		    RoleBuff_ReportMessage(RoleBuff_AbilityToCastMessage(paladinBlessing), chatOnly);
		end
	    end
	end
    end

    if checkProtectionPaladinShield and isProtectionPaladin and hasBlock and not IsEquippedItemType(itemTypeShields)
    then
	RoleBuff_ReportMessage(RoleBuff_ItemEquipMessage(itemShield), chatOnly);
    end

    if checkRighteousFury and hasRighteousFury
    then
	local name, rank = UnitBuff(unitPlayer, righteousFury);

	if isProtectionPaladin and name == nil and RoleBuff_PlayerIsInGroup()
	then
	    RoleBuff_ReportMessage(RoleBuff_AbilityToCastMessage(righteousFury), chatOnly);
	end

	if not isProtectionPaladin and name ~= nill and RoleBuff_PlayerIsInGroup()
	then
	    RoleBuff_ReportMessage(RoleBuff_AbilityActiveMessage(righteousFury), chatOnly);
	end
    end
end

RoleBuff_EventHandlerTablePaladin = 
{
    [eventPlayerAlive] = function(frame, event, ...)
	RoleBuff_InitialPlayerAlivePaladin(frame, event, ...);

	frame:RegisterEvent(eventActiveTalentGroupChanged);
	frame:RegisterEvent(eventUpdateShapeshiftForm);
	frame:RegisterEvent(eventUpdateShapeshiftForms);
	frame:RegisterEvent(eventPlayerEnterCombat);
	frame:RegisterEvent(eventPlayerLeaveCombat);
	frame:RegisterEvent(eventPlayerRegenDisabled);
	frame:RegisterEvent(eventPlayerRegenEnabled);
    end,

    [eventActiveTalentGroupChanged] = RoleBuff_InitialPlayerAlivePaladin,
    [eventUpdateShapeshiftForm] = RoleBuff_UpdatePaladinAura,
    [eventUpdateShapeshiftForms] = RoleBuff_UpdatePaladinAura,

    [eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_PaladinAttacked and not RoleBuff_PaladinAttacking
	then
	    RoleBuff_CombatCheckPaladin(false, frame, event, ...)
	end

	RoleBuff_PaladinAttacking = true;
    end,

    [eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_PaladinAttacking = false;
    end,

    [eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_PaladinAttacked and not RoleBuff_PaladinAttacking
	then
	    RoleBuff_CombatCheckPaladin(false, frame, event, ...)
	end
	
	RoleBuff_PaladinAttacked = true;
    end,

    [eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_PaladinAttacked = false;
    end
};

RoleBuff_SlashCommandHandlerPaladin =
{
    [slashCommandPlayerCheck] = function()
	RoleBuff_InitialPlayerAlivePaladin(nil, nil);
    end,

    [slashCommandCombatCheck] = function()
	RoleBuff_CombatCheckPaladin(true, nil, nil);
    end
};

function RoleBuff_GetPaladinRole()
    if isProtectionPaladin
    then
	return roleTank;
    else
	if isHolyPaladin
	then
	    return roleHealer;
	else
	    return roleDPS;
	end
    end
end

