-- AddOn Options frame for the Blizzard default AddOn Options UI
--

function RoleBuff_OptionsFrame_Load(panel)
    panel.name = displayName;
    panel.okay = function(self)
	-- print(displayName .. ": Interface options Okay.")
    end;
    panel.cancel = function(self)
	-- print(displayName .. ": Interface options Cancel.")
    end;
    panel.default = function(self)
	-- print(displayName .. ": Interface options defaults.")
    end;
    InterfaceOptions_AddCategory(panel);
end
