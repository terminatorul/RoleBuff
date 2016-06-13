
-- If you translate this file to your WoW client language, you can contribute
-- the translated file back to the add-on author at the e-mail address:
--	Timothy Madden <terminatorul@gmail.com>
--
-- Translation here must match the in-game item and ability names

local mod = RoleBuffAddOn;

if GetLocale() == mod.enUS or GetLocale() == mod.enGB
then

    local translationTableEn =
    {
	-- WoW API
	itemTypeShields = "Shields";
	itemTypeTwoHand = "Two-Hand";
	itemTypeFishingPole = "Fishing Pole";	    -- used before 2.3 (build number 7561)
	itemTypeFishingPoles = "Fishing Poles";	    -- used on 2.3
	itemTypeBows = "Bows";
	itemTypeCrossbows = "Crossbows";
	itemTypeGuns = "Guns";
	itemTypeProjectile = "Projectile";
	itemTypeArrow = "Arrow";
	itemDisplayTypeArrows = "Arrows";
	itemTypeBullet = "Bullet";
	itemDisplayTypeBullets = "Bullets";
	mainHandSlot = "MainHandSlot";
	secondaryHandSlot = "SecondaryHandSlot";
	creatureFamilyImp = "Imp";		    -- warlock minion (daemon)
	creatureFamilyFelhunter = "Felhunter";	    -- warlock minion (daemon)

	classNameDeathKnight = "Death Knight";
	classNameDruid = "Druid";
	classNameHunter = "Hunter";
	classNameMage = "Mage";
	classNameMong = "Monk";
	classNamePaladin = "Paladin";
	classNamePriest = "Priest";
	classNameRogue = "Rogue";
	classNameShaman = "Shaman";
	classNameWarlock = "Warlock";
	classNameWarrior = "Warrior";

	-- Warrior
	defensiveStanceSpellName = "Defensive Stance";
	beserkerStanceSpellName = "Beserker Stance";
	vigilanceSpellName = "Vigilance";
	vigilanceBuffName = "Vigilance"; -- vigilanceSpellName;
	blockSpellName = "Block";
	battleShoutSpellname = "Battle Shout";
	armsSpecName = "Arms";
	furySpecName = "Fury";
	protectionSpecName = "Protection";	    -- same as Paladin Protection spec
	battleShout = "Battle Shout";
	commandingShout = "Commanding Shout";
	demoralizingShout = "Demoralizing Shout";
	intimidatingShout = "Intimidating Shout";
	rankTooltipPrefix = "Rank ";

	-- Death Knight
	frostSpecName = "Frost";
	bloodPresenceSpellname = "Blood Presence";
	frostPresenceSpellName = "Frost Presence";
	unholypresenceSpellname = "Unholy Presence";
	hornOfWinter = "Horn of Winter";

	-- Paladin
	blessingOfWisdom = "Blessing of Wisdom";
	blessingOfMight = "Blessing of Might";
	blessingOfKings = "Blessing of Kings";
	blessingOfForgottenKings = "Blessing of Forgotten Kings";   -- Leatherworking "Drums"
	blessingOfSanctuary = "Blessing of Sanctuary";
	greaterBlessingOfWisdom = "Greater Blessing of Wisdom";
	greaterBlessingOfMight = "Greater Blessing of Might";
	greaterBlessingOfKings = "Greater Blessing of Kings"; -- no "Greater Blessing of Forgotten Kings"
	greaterBlessingOfSanctuary = "Greater Blessing of Sanctuary";
	sealOfCommand = "Seal of Command";
	sealOfLight = "Seal of Light";
	sealOfWisdom = "Seal of Wisdom";
	sealOfJustice = "Seal of Justice";
	sealOfVengeance = "Seal of Vengeance";	    -- alliance only
	sealOfTruth = "Seal of Truth";		    -- horde only
	sealOfRighteousness = "Seal of Righteousness";
	sealOfInsight = "Seal of Insight";  -- patch 4.0.1
	devotionAura = "Devotion Aura";
	retributionAura = "Retribution Aura";
	concentrationAura = "Concentration Aura";
	frostResistanceAura = "Frost Resistance Aura";
	shadowReistanceAura = "Shadow Resistance Aura";
	fireResistanceAura = "Fire Resistance Aura";
	crusaderAura = "Crusader Aura";
	protectionSpecName = "Protection";	-- same as Warrior Protection spec
	retributionSpecName = "Retribution";
	holySpecName = "Holy";			-- same as Priest Holy spec ?
	righteousFury = "Righteous Fury";

	-- Warlock
	soulstoneBuffName = "Soulstone";
	soulstoneResurrection = "Soulstone Resurrection";
	soulShard = "Soul Shard";
	drainSoulSpellName = "Drain Soul";
	shadowburnSpellName = "Shadowburn";
	soulFireSpellName = "Soul Fire";
	soulShatterSpellName = "Soulshatter";
	summonImp = "Summon Imp";
	summonVoidwalker = "Summon Voidwalker";
	summonSuccubuss = "Summon Succubus";
	summonFelhunter = "Summon Felhunter";
	summonFelgurard = "Summon Felguard";
	summonInfernal = "Summon Infernal";
	summonDoomguard = "Summon Doomguard";
	eyeOfKilrogg = "Eye of Kilrogg";
	enslaveDemon = "Enslave Demon";
	demonSkin = "Demon Skin";
	demonArmor = "Demon Armor";
	felArmor = "Fel Armor";
	createFirestone = "Create Firestone";
	createSpellstone = "Create Spellstone";
	createSoulstone = "Create Soulstone";
	createHealthstone = "Create Healthstone";
	createSoulwell = "Create Soulwell";
	ritualOfSouls = "Ritual of Souls";
	minorHealthstone = "Minor Healthstone";
	lesserHealthstone = "Lesser Healthstone";
	plainHealthstone = "Healthstone";
	greaterHealthstone = "Greater Healthstone";
	majorHealthstone = "Major Healthstone";
	masterHealthstone = "Master Healthstone";
	demonicHealthstone = "Demonic Healthstone";
	felHealthstone = "Fel Healthstone";
	minorSoulstone = "Minor Soulstone";
	lesserSoulstone = "Lesser Soulstone";
	plainSoulstone = "Soulstone";
	greaterSoulstone = "Greater Soulstone";
	majorSoulstone = "Major Soulstone";
	masterSoulstone = "Master Soulstone";
	demonicSoulstone = "Demonic Soulstone";
	bloodPact = "Blood Pact";
	felIntelligence = "Fel Intelligence";

	-- Priest
	prayerOfShadowProtection = "Prayer of Shadow Protection";

	-- Shaman
	restaurationSpecName = "Restauration";
	elementalSpecName = "Elemental";
	enhancementSpecName = "Enhancement";
	flametongueWeapon = "Flametongue Weapon";
	earthlivingWeapon = "Earthliving Weapon";
	frostbrandWeapon = "Frostband Weapon";
	rockbiterWeapon = "Rockbiter Weapon";
	windfuryWeapon = "Windfury Weapon";
	lightningShield = "Lightning Shield";
	waterShield = "Water Shield";
	earthShield = "Earth Shield";

	-- Rogue
	poisonsSpellName = "Poisons";
    };

    for key, val in pairs(translationTableEn)
    do
	mod[key] = val
    end

    mod.AddOnLocalized = true;
end
