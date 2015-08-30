-- Global table for the RoleBuff addon
-- These should be the only global symbols ever declared by the AddOn

RoleBuffAddOn = { };
RoleBuffAddOn_StorageTable = nil;
RoleBuffAddOn_CharacterStorageTable = nil;

SLASH_ROLEBUFF1 = "/rolebuff";
function SlashCmdList.ROLEBUFF(msgLine, editbox)
    RoleBuffAddOn:SlashCmdHandler(msgLine)
end

