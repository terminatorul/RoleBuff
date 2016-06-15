-- Check Rogue for:
--	- weapon enchantment (poisons)

local mod = RoleBuffAddOn;
local checkRoguePoisons = true;

local hasRoguePoisons = false;
local RoleBuff_RogueAttacked, RoleBuff_RogueAttacking = false, false;

local function RoleBuff_InitialPlayerAliveRogue(frame, event, ...)
    hasRoguePoisons = mod:CheckPlayerHasAbility(mod.poisonsSpellName);
end

local function RoleBuff_CombatCheckRogue(chatOnly, frame, event, ...)
    if checkRoguePoisons and hasRoguePoisons
    then
	local hasMainHandEnchant, hasOffHandEnchant = mod:HasWeaponEnchants();

	if hasMainHandEnchant == nil or (hasOffHandEnchant == nil and OffhandHasWeapon())
	then
	    mod:ReportMessage(mod:UseEnhancementMessage(mod.rogueWeaponPoison), chatOnly)
	end
    end
end

RoleBuffAddOn.EventHandlerTableRogue = 
{
    [mod.eventPlayerAlive] = function(frame, event, ...)
	RoleBuff_InitialPlayerAliveRogue(frame, event, ...);

	frame:RegisterEvent(mod.eventPlayerEnterCombat);
	frame:RegisterEvent(mod.eventPlayerLeaveCombat);
	frame:RegisterEvent(mod.eventPlayerRegenDisabled);
	frame:RegisterEvent(mod.eventPlayerRegenEnabled)
    end,

    [mod.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_RogueAttacked and not RoleBuff_RogueAttacking
	then
	    RoleBuff_CombatCheckRogue(false, frame, event, ...)
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
	    RoleBuff_CombatCheckRogue(false, frame, event, ...)
	end

	RoleBuff_RogueAttacked = true
    end
};

RoleBuffAddOn.SlashCommandHandlerRogue = 
{
    [mod.slashCommandPlayerCheck] = function()
	return RoleBuff_InitialPlayerAliveRogue(nil, nil)
    end,

    [mod.slashCommandCombatCheck] = function()
	return RoleBuff_CombatCheckRogue(true, nil, nil)
    end
};

RoleBuffAddOn.CommandHandlerRogue = 
{
};

function RoleBuffAddOn.GetRogueRole()
    return mod.roleDPS;
end

function RoleBuffAddOn:RogueOptionsFrameLoad(panel)
    panel.name = mod.classNameRogue;
    panel.parent = mod.displayName;
    InterfaceOptions_AddCategory(panel)
end
