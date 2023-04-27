local nameInput = "\n"
local debug = ""
re.on_draw_ui(
    function()
        if imgui.tree_node("NameChangeUtil") then
            local tm = sdk.get_managed_singleton("snow.gui.fsm.title.GuiTitleMenuFsmManager")
            if not tm then
                imgui.text("You can only use this in the title screen.")
                imgui.tree_pop()
                return
            elseif tm:get_TitleMenuState() ~= 2 then
                imgui.text("Loading")
                imgui.tree_pop()
                return
            end

            c,slotId = imgui.slider_int("Slot", slotId, 0,2)
            if c or nameInput == "\n" then
                local data = sdk.get_managed_singleton("snow.SnowSaveService")
                local info = data:get_field("_LoadInfoData")
                local hunterinfo = info:get_field("_HunterArray")
                local slot = hunterinfo:call("get_Item", slotId)
                if not slot then
                    nameInput = "This slot is empty"
                else
                    nameInput = slot:get_field("_HunterName")
                end
            end
            _,nameInput = imgui.input_text("Name", nameInput)
            if imgui.button("Change name") then
                local data = sdk.get_managed_singleton("snow.SnowSaveService")
                local info = data:get_field("_LoadInfoData")
                local hunterinfo = info:get_field("_HunterArray")
                local slot = hunterinfo:call("get_Item", slotId)
                local strin = sdk.create_managed_string(nameInput):add_ref()
                local old = slot:get_field("_HunterName")
                slot:set_field("_HunterName", strin)
                debug = "Successfully changed name from " .. old .. " to " .. nameInput .. ".\nRemember to play with the character and save in order to apply."
            end
            imgui.same_line()
            imgui.text(debug)
            imgui.tree_pop();
        end
    end
)