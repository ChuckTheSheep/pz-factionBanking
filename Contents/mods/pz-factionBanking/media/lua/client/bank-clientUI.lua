
local original_ISFactionUI_onClick = ISFactionUI.onClick
function ISFactionUI:onClick(button)
    if button.internal == "REMOVE" then

    end
    original_ISFactionUI_onClick(self, button)
end