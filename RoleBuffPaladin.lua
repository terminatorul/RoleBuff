local this = RoleBuffAddOn;

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

local function RoleBuff_InitialPlayerAlivePaladin(event, frame, ...)
    local specIndex, specName = this:GetPlayerBuild();

    if specIndex ~= nil
    then
	print(this:FormatSpecialization(this.playerClassLocalized, specName));
	isProtectionPaladin = (specName == this.protectionSpecName);
	isHolyPaladin = (specName == this.holySpecName);
    end

    if checkPaladinAura
    then
	hasPaladinAura = false;
	local idx, paladinAura;
        for idx, paladinAura in pairs( { this.devotionAura, this.retributionAura, this.concentrationAura, this.frostResistanceAura, this.shadowReistanceAura, this.fireResistanceAura } )
        do
            if this:CheckPlayerHasAbility(paladinAura)
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
	for idx, paladinSeal in pairs( { this.sealOfWisdom, this.sealOfLight, this.sealOfRighteousness, this.sealOfJustice, this.sealOfCommand, this.sealOfVengeance, this.sealOfTruth, this.sealOfInsight } )
	do
	    if this:CheckPlayerHasAbility(paladinSeal)
	    then
		hasPaladinSeal = true;
		break;
	    end
	end
    end

    if checkPaladinBlessing
    then
	paladinBlessingRank = { ["wisdom"] = { }, ["might"] = { }, ["kings"] = { }, ["sanctuary"] = { } };

	for kind, list in pairs( { ["wisdom"] = { this.blessingOfWisdom, this.greaterBlessingOfWisdom }, ["might"] = { this.blessingOfMight, this.greaterBlessingOfMight },
	    ["kings"] = { this.blessingOfKings, this.greaterBlessingOfKings }, ["sanctuary"] = { this.blessingOfSanctuary, this.greaterBlessingOfSanctuary } } )
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
	local name, rank = GetSpellInfo(this.blessingOfSanctuary);
	if name == nill
	then
	    hasBlessingOfSanctuaryRank = 0;
	else
	    if rank == "" or rank == nil or rank == 0
	    then
		rank = 1;
	    end
	    hasBlessingOfSanctuaryRank = rank;
	    this:DebugMessage("Found " .. this.blessingOfSanctuary .. " rank " .. rank);
	end

	name, rank = GetSpellInfo(this.greaterBlessingOfSanctuary);
	if name == nill
	then
	    hasGreaterBlessingOfSanctuaryRank = 0;
	else
	    if rank == "" or rank == nil or rank == 0
	    then
		rank = 1;
	    end
	    hasGreaterBlessingOfSanctuaryRank = rank;
	    this:DebugMessage("Found " .. this.greaterBlessingOfSanctuary .. " rank " .. rank);
	end
    end

    if checkProtectionPaladinShield and isProtectionPaladin
    then
	hasBlock = this:CheckPlayerHasAbility(this.blockSpellName);
    end

    if checkRighteousFury
    then
	hasRighteousFury = this:CheckPlayerHasAbility(this.righteousFury);
    end
end

local function RoleBuff_UpdatePaladinAura(event, frame, ...)
    auraIndex, auraCount = GetShapeshiftForm(), GetNumShapeshiftForms();
end

local paladinSealList =
{
    [this.sealOfCommand] = true, [this.sealOfLight] = true, [this.sealOfWisdom] = true, [this.sealOfJustice] = true,
    [this.sealOfVengeance] = true, [this.sealOfTruth] = true, [this.sealOfRighteousness] = true, 
    [this.sealOfInsight] = true
};

local paladinBlessingBuffList = 
{
    [this.blessingOfWisdom] = { ["kind"] = "wisdom" }, [this.greaterBlessingOfWisdom] = { ["kind"] = "wisdom" },
    [this.blessingOfMight] = { ["kind"] = "might" }, [this.greaterBlessingOfMight] = { ["kind"] = "might" }, [this.battleShout] = { ["kind"] = "might" },
    [this.blessingOfKings] = { ["kind"] = "kings" }, [this.greaterBlessingOfKings] = { ["kind"] = "kings" }, [this.blessingOfForgottenKings] = { ["kind"] = "kings" },
    [this.blessingOfSanctuary] = { ["kind"] = "sanctuary" }, [this.greaterBlessingOfSanctuary] = { ["kind"] = "sanctuary" }
};

local function RoleBuff_CheckPaladinBlessings(paladinBlessingRank, paladinBlessingBuffs)
    for kind, list in pairs(paladinBlessingRank)
    do
	for blessing, rank in pairs(list)
	do
	    if rank ~= 0
	    then
		-- paladin can cast this kind of blessing
		this:DebugMessage("[" .. kind .. "] " .. blessing .. " Rank " .. rank);
		if paladinBlessingBuffs[kind] == nil or paladinBlessingBuffs[kind][blessing] == nil or paladinBlessingBuffs[kind][blessing] < rank
		then
		    -- blessing is not buffed or is lower rank than paladin ability
		    return blessing;
		end
	    end
	end
    end
end

local function RoleBuff_CombatCheckPaladin(chatOnly, event, frame, ...)
    if checkPaladinAura and auraIndex <= 0 and auraCount > 0
    then
	this:ReportMessage(this:AbilityToCastMessage(this.paladinAura), chatOnly);
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

	this:DebugMessage("Paladin Blessings:")
	for blessing, props in pairs(paladinBlessingBuffList)
	do
	    this:DebugMessage("  " .. blessing);
	end

	repeat
	    buffName, rank, icon, count, debuffType, duration, expirationTime, unitCaster = UnitBuff(this.unitPlayer, i);
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
		    if UnitIsUnit(unitCaster, this.unitPlayer)
		    then
			this:DebugMessage("Paladin self-blessing: " .. buffName);
			hasBlessingSelfBuff = true;
		    else
			paladinBlessingBuffs[paladinBlessingList[buffName]["kind"]] = { [buffName] = rank };
		    end
		end

		if checkSanctuaryBlessingBuff and not hasSanctuaryBlessingBuff
		then
		    if buffName == this.blessingOfSanctuary and rank >= hasBlessingOfSanctuaryRank
		    then
			this:DebugMessage("Has " .. this.blessingOfSanctuary .. " buff");
			hasSanctuaryBlessingBuff = true;
		    end

		    if buffName == this.greaterBlessingOfSanctuary and rank >= hasGreaterBlessingOfSanctuaryRank
		    then
			this:DebugMessage("Has " .. this.greaterBlessingOfSanctuary .. " buff");
			hasSanctuaryBlessingBuff = true
		    end
		end
	    end
	until buffName == nil;

	if checkSealBuff and not hasPaladinSealBuff
	then
	    this:ReportMessage(this:AbilityToCastMessage(this.paladinSeal), chatOnly);
	end

	if checkSanctuaryBlessingBuff and not hasSanctuaryBlessingBuff
	then
	    this:ReportMessage(this:AbilityToCastMessage(this.blessingOfSanctuary), chatOnly)
	else
	    if checkBlessingBuffs and not hasBlessingSelfBuff
	    then
		local blessingToCast = RoleBuff_CheckPaladinBlessings(paladinBlessingRank, paladinBlessingBuffs);
		if blessingToCast ~= nil 
		then
		    this:ReportMessage(this:AbilityToCastMessage(this.paladinBlessing), chatOnly);
		end
	    end
	end
    end

    if checkProtectionPaladinShield and isProtectionPaladin and hasBlock and not IsEquippedItemType(this.itemTypeShields)
    then
	this:ReportMessage(this:ItemEquipMessage(this.itemShield), chatOnly);
    end

    if checkRighteousFury and hasRighteousFury
    then
	local name, rank = UnitBuff(this.unitPlayer, this.righteousFury);

	if isProtectionPaladin and name == nil and this:PlayerIsInGroup()
	then
	    this:ReportMessage(this:AbilityToCastMessage(this.righteousFury), chatOnly);
	end

	if not isProtectionPaladin and name ~= nill and this:PlayerIsInGroup()
	then
	    this:ReportMessage(this:AbilityActiveMessage(this.righteousFury), chatOnly);
	end
    end
end

RoleBuffAddOn.EventHandlerTablePaladin = 
{
    [this.eventPlayerAlive] = function(frame, event, ...)
	RoleBuff_InitialPlayerAlivePaladin(frame, event, ...);

	frame:RegisterEvent(this.eventActiveTalentGroupChanged);
	frame:RegisterEvent(this.eventUpdateShapeshiftForm);
	frame:RegisterEvent(this.eventUpdateShapeshiftForms);
	frame:RegisterEvent(this.eventPlayerEnterCombat);
	frame:RegisterEvent(this.eventPlayerLeaveCombat);
	frame:RegisterEvent(this.eventPlayerRegenDisabled);
	frame:RegisterEvent(this.eventPlayerRegenEnabled);
    end,

    [this.eventActiveTalentGroupChanged] = RoleBuff_InitialPlayerAlivePaladin,
    [this.eventUpdateShapeshiftForm] = RoleBuff_UpdatePaladinAura,
    [this.eventUpdateShapeshiftForms] = RoleBuff_UpdatePaladinAura,

    [this.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_PaladinAttacked and not RoleBuff_PaladinAttacking
	then
	    RoleBuff_CombatCheckPaladin(false, frame, event, ...)
	end

	RoleBuff_PaladinAttacking = true;
    end,

    [this.eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_PaladinAttacking = false;
    end,

    [this.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_PaladinAttacked and not RoleBuff_PaladinAttacking
	then
	    RoleBuff_CombatCheckPaladin(false, frame, event, ...)
	end
	
	RoleBuff_PaladinAttacked = true;
    end,

    [this.eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_PaladinAttacked = false;
    end
};

RoleBuffAddOn.SlashCommandHandlerPaladin =
{
    [this.slashCommandPlayerCheck] = function()
	RoleBuff_InitialPlayerAlivePaladin(nil, nil);
    end,

    [this.slashCommandCombatCheck] = function()
	RoleBuff_CombatCheckPaladin(true, nil, nil);
    end
};

function RoleBuffAddOn.GetPaladinRole()
    if isProtectionPaladin
    then
	return this.roleTank;
    else
	if isHolyPaladin
	then
	    return this.roleHealer;
	else
	    return this.roleDPS;
	end
    end
end

function RoleBuffAddOn:PaladinOptionsFrameLoad(panel)
    panel.name = self.classNamePaladin;
    panel.parent = self.displayName;
    InterfaceOptions_AddCategory(panel)
end
