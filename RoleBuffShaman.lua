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

local checkShamanTotems, checkShamanWeapon, cheackShamanShielding = true, true, true;

function RoleBuff_GetShamanRole()
    local specIndex, specName = RoleBuff_GetPlayerBuild();

    if specName == restaurationSpecName
    then
	return roleHealer;
    else
	return roleDPS;
    end
end
