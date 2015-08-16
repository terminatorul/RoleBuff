# RoleBuff
World of Warcraft AddOn to warn if your character enters combat without the expected spells active.

Requires World of Warcraft Wrath of the Lich King expansion, game version 3.3.5a

Beware WoW 3.3.5a is an old game version now, and the game normally auto-updates to newest version
whenever you start it, so unless you know this is the expansion that you currently use, this
add-on will not work for you.


The RoleBuff addon will check your character for a number of buffs and for expected gear set upon
entering combat, and will warn you with the radio warning sound and message on the screen if any
of the buffs are missing.

It only covers a few classes, because I do not own a character for every possible class in the game,
and most of the buffs that are checked are selected from my own experience.

Currently included classes are Warrior, Paladin, Death Kinght and Warlock. A few basic checks exist
for other classes.

The buff and gear checks depend heavily on what role the add-on believes your character has:
Tank, Healer or DPS (damager, from damage-per-second). Hence the add-on name: RoleBuff.

The choice of role for your character sometimes can be seen easily from your spec, other times some
rules must be used, some not very intuitive.

The gear checks are based on the Equipment Manager game feature. This feature is disabled by default
so if you are new to the game this may be new to you. The addon will ask that you assing a role
for every set of gear that you carray. The role for the currently equipped gear set will be matched
with your character role (spec) upon entering combat.


These checks are based on the author's own game experience, contact me if you have other suggestions.

For all classes:
    - check that a weapon is equipped, check for fishing pole instead of weapon
    - check the role for the current equipment set to match the character build/spec.

For Warriors:
    - character role is Tank if most talents are invested in the Protection tree, DPS otherwise
    - for tanks:
	- check that Vigilance ability is cast, if in group.
	- check shield is equipped
	- check for Defensive Stance.
    - for DPSes
	- check shield is not equipped
	- check for Battle Stance or Berseker Stance

For Paladins:
    - character roles is Tank if most talen are invested in the Protection tree, Healer if most
      talents are invested in the Holy tree, and DPS if most talents are invested in the Retribution
      tree
    - check that the paladin has an aura, a seal and blessing cast
    - for tanks:
	- check that Rightous Fury is active
	- check the paladin has Blessing of Sanctuary
	- check shield is equipped
    - for healers and DPSes
	- check Rightoues Fury is not active

For Death Knights:
    - character role is Tank if all three talents Blade Barrier, Anticipation, Toughness are learned
      or have most of the invested talent points, DPS otherwise.
    - if Threat of Thassarian talent is learned, character is expected to dual-wield two single-handed
      weapons, instead of a single two-handed weapon.
    - for tanks:
	- check Frost Presence is active
    - for DPS:
	- check Blood Presence or Unholy Presence is active

For Warlocks:
    - character class is DPS, no gear checks included
    - check for Daemon Skin, Daemon Armor or Fel Armor
    - check for weapon Firestone or Spellstone applied
    - check for a warlock minion or enslaved daemon
    - check for minion-specific buff, Imp has Blood Pact.
    - check for conjured healthstone
    - check for soulshards, if the character has abilities consume shards
    - check without the warning sound that you have at least 8 shards.

If the character does not have any of the abilites included here, the ability is not checked until it is
learned.

TODO:
    - only check the abilities if the mob being fought is not trivial (not grey mobs, but green, yellow or red).

Shaman:
    - check shaman healer has Water Shield.
