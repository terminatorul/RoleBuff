# RoleBuff
World of Warcraft AddOn to warn if your character enters combat without the expected buffs or spells active.

Requires World of Warcraft _Wrath of the Lich King_ expansion, game version **3.3.5a**

_Beware_ WoW 3.3.5a is an old game version now, and the game normally auto-updates to newest version
whenever you start it, so unless you know this is the expansion that you currently use, this
add-on will not work for you.

The RoleBuff addon will check your character for a number of buffs and for expected gear set when
entering combat, and will warn you with the raid warning sound and on-screen message if any of the
buffs are missing.

It only covers some of the classes, because I do not own a character for every class in the game, and most
of the buffs that are checked are selected from my own experience.

Currently included classes are Warrior, Paladin, Death Knight, Warlock and to some extent Rogue, Shaman. A
few basic checks exist for any character, regardless of class.

The buff and gear checks depend mostly on what role the add-on believes your character has:
Tank, Healer or DPS (damager, from damage-per-second). Hence the add-on name: RoleBuff.

Your character role sometimes can be seen easily from your spec, other times some non-intuitive rules
must be used. Following game expansions have removed these rules, so that your spec always indicates
your intended role in a group.

The gear checks are based on the _Equipment Manager_ game feature. This feature is disabled by default
so if you are new to the game this may be new to you. The addon will ask that you assing a role
for every set of gear that you carray. The role for the currently equipped gear set will be matched
with your character role (spec) upon entering combat.

These checks are based on the author own experiance in-game, contact me if you have other suggestions.

####All classes
- check that a weapon/shield is equipped, check for fishing pole instead of weapon
- check the role for the current equipment set to match the character build/spec.

####Warrior
- for tanks:
    - check that Vigilance ability is cast, if in group.
    - check shield is equipped
    - check for Defensive Stance.

####Paladin
- check that the paladin has an aura, a seal and blessing cast
- for tanks:
    - check that Rightous Fury is active
    - check the paladin has Blessing of Sanctuary
    - check shield is equipped
- for healers and DPSes
    - check Rightoues Fury is not active

####Death Knight
- character role is Tank if all three talents Blade Barrier, Anticipation, Toughness are learned
  or if they have the most of the invested talent points, DPS otherwise.
- if Threat of Thassarian talent is learned, character is expected to dual-wield (two single-handed
  weapons, instead of a single two-handed weapon).
- for tanks:
    - check Frost Presence is active
- for DPS:
    - check Blood Presence or Unholy Presence is active

####Warlock
- check for Daemon Skin, Daemon Armor or Fel Armor
- check for weapon enchantment (warn for Firestone or Spellstone applied)
- check for a warlock minion or enslaved daemon
- check for minion-specific buff: Imp - Blood Pact, Felhunter - Fel Intelligence.
- check for conjured healthstone
- check for soulshards for combat abilities that consume shards
- check (without the warning sound) that you have at least 6 shards.

####Rogue
- check all equipped weapons have an enchantment, warn user to use poisons otherwise.

####Shaman
- check Elemental Weapon
- check Elemental Shield

Any ability is checked only if your character has already learned it.

###TODO
- add some UI to allow individual selection for any of the checks involved - in progress
- casters can transition between combat and out-of-combat very frequently (on every spell cast), if they do
  not use melee auto-attack ability to stay in combat. Add a timer to the warning messages for this case.
- add some addon command to allow user to explicitly choose a role, for example a dual-spec protection and
  holy paladin may still want to DPS sometimes.
- add an addon command to temporary disable the warnings, for example until user leaves the instance or
  walks to another map
- only show warnings if the mob being fought is not trivial (not grey mobs, but green, yellow or red).
  The problem here is the game client does not really know the level of a world mob untill user or her
  party targets the mob, or user hovers the mouse over the mob.
- fix add-on behavior on /reloadui - in progress
- disable the warnings when player is mounted or in a vehicle
- party/raid abilities should also check if any of the group members are in the range of most spells.

####Warrior
- for DPSes
    - check shield is not equipped
    - check for Battle Stance or Berseker Stance

####Death Knights
- check pet is present when DK has Master of Ghouls talent

####Warlocks
- check for basic healthstone present when improved (talented) healthstone can be used

