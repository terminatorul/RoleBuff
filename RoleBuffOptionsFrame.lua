-- AddOn Options frame for the Blizzard default AddOn Options UI
--

function RoleBuff_OptionsFrame_Load(panel)
    panel.name = displayName;
    panel.okay = function(self)
	print(displayName .. ": Interface options Okay.")
    end;
    panel.cancel = function(self)
	print(displayName .. ": Interface options Cancel.")
    end;
    panel.default = function(self)
	print(displayName .. ": Interface options defaults.")
    end;
    InterfaceOptions_AddCategory(panel);

    RoleBuff_DeathKnightOptionsFrame.name="Death Knight";
    RoleBuff_DeathKnightOptionsFrame.parent = panel.name;
    InterfaceOptions_AddCategory(RoleBuff_DeathKnightOptionsFrame);

    RoleBuff_RogueOptionsFrame.name = "Rogue";
    RoleBuff_RogueOptionsFrame.parent = panel.name;
    InterfaceOptions_AddCategory(RoleBuff_RogueOptionsFrame)

    RoleBuff_WarriorOptionsFrame.name = "Warrior";
    RoleBuff_WarriorOptionsFrame.parent = panel.name;
    InterfaceOptions_AddCategory(RoleBuff_WarriorOptionsFrame);
end

