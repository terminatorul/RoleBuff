-- Check Rogue for:
--	- weapon enchantment (poisons)

local checkRoguePoisons = true;

local hasRoguePoisons = false;
local RoleBuff_RogueAttacked, RoleBuff_RogueAttacking = false, false;

function RoleBuff_InitialPlayerAliveRogue(frame, event, ...)
    hasRoguePoisons = RoleBuff_CheckPlayerHasAbility(poisonsSpellName);
end

function RoleBuff_CombatCheckRogue(chatOnly, frame, event, ...)
    if checkRoguePoisons and hasRoguePoisons
    then
	local hasMainHandEnchant, hasOffHandEnchant = RoleBuff_HasWeaponEnchants();

	if hasMainHandEnchant == nil or (hasOffHandEnchant == nil and OffhandHasWeapon())
	then
	    RoleBuff_ReportMessage(RoleBuff_UseEnhancementMessage(rogueWeaponPoison), chatOnly)
	end
    end
end

RoleBuff_EventHandlerTableRogue = 
{
    [eventPlayerAlive] = function(frame, event, ...)
	RoleBuff_InitialPlayerAliveRogue(frame, event, ...);

	frame:RegisterEvent(eventPlayerEnterCombat);
	frame:RegisterEvent(eventPlayerLeaveCombat);
	frame:RegisterEvent(eventPlayerRegenDisabled);
	frame:RegisterEvent(eventPlayerRegenEnabled)
    end,

    [eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_RogueAttacked and not RoleBuff_RogueAttacking
	then
	    RoleBuff_CombatCheckRogue(false, frame, event, ...)
	end

	RoleBuff_RogueAttacking = true
    end,

    [eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_RogueAttacking = false
    end,

    [eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_RogueAttacked = false
    end,
    
    [eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_RogueAttacked and not RoleBuff_RogueAttacking
	then
	    RoleBuff_CombatCheckRogue(false, frame, event, ...)
	end

	RoleBuff_RogueAttacked = true
    end
};

RoleBuff_SlashCommandHandlerRogue = 
{
    [slashCommandPlayerCheck] = function()
	return RoleBuff_InitialPlayerAliveRogue(nil, nil)
    end,

    [slashCommandCombatCheck] = function()
	return RoleBuff_CombatCheckRogue(true, nil, nil)
    end
};

RoleBuff_CommandHandlerRogue = 
{
};

function RoleBuff_GetRogueRole()
    return roleDPS;
end

function RoleBuff_RogueOptionsFrame_Load(panel)
    panel.name = classNameRogue;
    panel.parent = displayName;
    InterfaceOptions_AddCategory(panel)
end
