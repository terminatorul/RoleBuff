-- Check Rogue for:
--	- weapon enchantment (poisons)

local this = RoleBuffAddOn;
local checkRoguePoisons = true;

local hasRoguePoisons = false;
local RoleBuff_RogueAttacked, RoleBuff_RogueAttacking = false, false;

local function RoleBuff_InitialPlayerAliveRogue(frame, event, ...)
    hasRoguePoisons = this:CheckPlayerHasAbility(this.poisonsSpellName);
end

local function RoleBuff_CombatCheckRogue(chatOnly, frame, event, ...)
    if checkRoguePoisons and hasRoguePoisons
    then
	local hasMainHandEnchant, hasOffHandEnchant = this:HasWeaponEnchants();

	if hasMainHandEnchant == nil or (hasOffHandEnchant == nil and OffhandHasWeapon())
	then
	    this:ReportMessage(this:UseEnhancementMessage(this.rogueWeaponPoison), chatOnly)
	end
    end
end

RoleBuffAddOn.EventHandlerTableRogue = 
{
    [this.eventPlayerAlive] = function(frame, event, ...)
	RoleBuff_InitialPlayerAliveRogue(frame, event, ...);

	frame:RegisterEvent(this.eventPlayerEnterCombat);
	frame:RegisterEvent(this.eventPlayerLeaveCombat);
	frame:RegisterEvent(this.eventPlayerRegenDisabled);
	frame:RegisterEvent(this.eventPlayerRegenEnabled)
    end,

    [this.eventPlayerEnterCombat] = function(frame, event, ...)
	if not RoleBuff_RogueAttacked and not RoleBuff_RogueAttacking
	then
	    RoleBuff_CombatCheckRogue(false, frame, event, ...)
	end

	RoleBuff_RogueAttacking = true
    end,

    [this.eventPlayerLeaveCombat] = function(frame, event, ...)
	RoleBuff_RogueAttacking = false
    end,

    [this.eventPlayerRegenEnabled] = function(frame, event, ...)
	RoleBuff_RogueAttacked = false
    end,
    
    [this.eventPlayerRegenDisabled] = function(frame, event, ...)
	if not RoleBuff_RogueAttacked and not RoleBuff_RogueAttacking
	then
	    RoleBuff_CombatCheckRogue(false, frame, event, ...)
	end

	RoleBuff_RogueAttacked = true
    end
};

RoleBuffAddOn.SlashCommandHandlerRogue = 
{
    [this.slashCommandPlayerCheck] = function()
	return RoleBuff_InitialPlayerAliveRogue(nil, nil)
    end,

    [this.slashCommandCombatCheck] = function()
	return RoleBuff_CombatCheckRogue(true, nil, nil)
    end
};

RoleBuffAddOn.CommandHandlerRogue = 
{
};

function RoleBuffAddOn.GetRogueRole()
    return this.roleDPS;
end

function RoleBuffAddOn:RogueOptionsFrameLoad(panel)
    panel.name = this.classNameRogue;
    panel.parent = this.displayName;
    InterfaceOptions_AddCategory(panel)
end
