-- Check Rogue for:
--	- weapon enchantment (poisons)

local mod = RoleBuffAddOn;
local checkRoguePoisons = true;

local hasRoguePoisons = false;
local RoleBuff_RogueAttacked, RoleBuff_RogueAttacking = false, false;

local function initialPlayerAliveRogue(frame, event, ...)
    hasRoguePoisons = mod:CheckPlayerHasAbility(mod.poisonsSpellName);
end

local function combatCheckRogue(chatOnly, frame, event, ...)
    if checkRoguePoisons and hasRoguePoisons
    then
	local hasMainHandEnchant, hasOffHandEnchant = mod:HasWeaponEnchants();

	if hasMainHandEnchant == nil or (hasOffHandEnchant == nil and OffhandHasWeapon())
	then
	    mod:ReportMessage(mod:UseEnhancementMessage(mod.rogueWeaponPoison), chatOnly)
	end
    end
end

mod.EventHandlerTableRogue =
{
    [mod.eventPlayerAlive] = function(frame, event, ...)
	initialPlayerAliveRogue(frame, event, ...);

	frame:RegisterEvent(mod.eventPlayerEnterCombat);
	frame:RegisterEvent(mod.eventPlayerLeaveCombat);
	frame:RegisterEvent(mod.eventPlayerRegenDisabled);
	frame:RegisterEvent(mod.eventPlayerRegenEnabled)
    end,

    [mod.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_RogueAttacked and not RoleBuff_RogueAttacking
	then
	    combatCheckRogue(false, frame, event, ...)
	end

	RoleBuff_RogueAttacking = true
    end,

    [mod.eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_RogueAttacking = false
    end,

    [mod.eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_RogueAttacked = false
    end,

    [mod.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_RogueAttacked and not RoleBuff_RogueAttacking
	then
	    combatCheckRogue(false, frame, event, ...)
	end

	RoleBuff_RogueAttacked = true
    end
};

mod.SlashCommandHandlerRogue =
{
    [mod.slashCommandPlayerCheck] = function()
	return initialPlayerAliveRogue(nil, nil)
    end,

    [mod.slashCommandCombatCheck] = function()
	return combatCheckRogue(true, nil, nil)
    end
};

mod.CommandHandlerRogue =
{
};

function mod.GetRogueRole()
    return mod.roleDPS;
end

function mod:RogueOptionsFrameLoad(panel)
    panel.name = mod.classNameRogue;
    panel.parent = mod.displayName;
    InterfaceOptions_AddCategory(panel)
end
