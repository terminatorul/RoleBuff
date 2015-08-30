-- Check Shaman for:
--	- totems
--	- flametongue weapon
--	- water shield
--
--
--  add plugin options UI
--  check attacked while mounted
--  check gray mobs attacking
--  check plugin loading after reloadui
--  check range for warrior vigilance
--  check RDF role versus player available specs

local this = RoleBuffAddOn;

local checkShamanTotems, checkShamanWeapon, cheackShamanShielding = true, true, true;

function RoleBuffAddOn.GetShamanRole()
    local specIndex, specName = this:GetPlayerBuild();

    if specName == this.restaurationSpecName
    then
	return this.roleHealer;
    else
	return this.roleDPS;
    end
end
