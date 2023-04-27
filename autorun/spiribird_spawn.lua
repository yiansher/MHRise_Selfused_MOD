-- By Shadowy

-------------EDIT ME-------------------
-- if you already have a predetermined 
-- number of birds you can edit here according to each one of them
----------------------------------
-- for default is zero (0)
local birds_invoks = {
    [11] = 0, -- atk
    [12] = 0, -- def
    [13] = 0, -- hp
    [14] = 0, -- stm
    [15] = 0  -- prism
};

---------------------------------------------



-- OBJ
local app_type = sdk.find_type_definition("via.Application")
local get_elapsed_second = app_type:get_method("get_UpTimeSecond")
local Player_Obj;
local envCreature;
local Quest_Obj;

-- MENU
local menu_open = true;
local prism_auto_spwan = true;
local auto_summon = false;

-- SUMMON
local ecIndex = 11
local this_index = 0;
local ec_level = 0;


-- States
local state_check_in = 0;
local canSpwan = false
local max_summon = false;
local wait = 0;
local sec_status = "actived?";

-- Quest type dont work
local quest_type_block = {256, 64, 128};



local birds_auto_invok = {
    [11] = 0,
    [12] = 0,
    [13] = 0,
    [14] = 0,
    [15] = 0
};
local bdi = 11;
local birds_list = {};

local function get_time()
    return get_elapsed_second:call(nil)
end
local function has_type(val)
    for index, value in ipairs(quest_type_block) do
        if value == val then
            return true
        end
    end
    return false
end
local function get_player_obj()
    Player_Obj = sdk.get_managed_singleton("snow.player.PlayerManager"):call("findMasterPlayer")
    if (Player_Obj) then
        Player_Obj = Player_Obj:call("get_GameObject");
    end
    return Player_Obj;
end

local function get_Player_location()
    get_player_obj()
    local p_location = Player_Obj:call("get_Transform"):call("get_Position")
    if not p_location then
        scState = "no locate"
        return
    end
    return p_location;
end

local function get_Quest_obj()
    Quest_Obj = sdk.get_managed_singleton("snow.QuestManager")
    if not Quest_Obj then
        return nil
    end
    return Quest_Obj
end

local function get_envCreature()
    envCreature = sdk.get_managed_singleton("snow.envCreature.EnvironmentCreatureManager")
    if not envCreature then
        scState = "no ecm"
        return nil
    end
end

local function get_Quest_State()
    local quest_obj = get_Quest_obj();
    if not quest_obj  then
       return nil
    end
    return quest_obj:get_field("_QuestStatus")
end

local function get_Type_Quest()
    local quest_obj = get_Quest_obj();
    if quest_obj  then
       return nil
    end
    return quest_obj:get_field("_QuestType")
end

local function check_map_birds(ty)
    if has_type(ty) then
        state_check_in = 5;
        return false
    end
    return true
end

local function state_check()
    local state_quest = get_Quest_State();
    local type_quest = get_Type_Quest();

    if (not check_map_birds(type_quest)) then
        return nil
    end
    if (state_quest == 2) then
        state_check_in = 0;
    else
        state_check_in = 1;
    end

end

local function invok_bird(index)
    get_envCreature()
    local pLoc = get_Player_location()
    local ecList = envCreature:get_field("_EcPrefabList"):get_field("mItems"):get_elements()
    if not ecList then
        state_check_in = 10;
        return nil
    end
    local ecPrefab = ecList[index]
    if not ecPrefab then
        state_check_in = 11;
        return nil
    end
    
    if not ecPrefab:call("get_Standby") then
        ecPrefab:call("set_Standby", true)
        state_check_in = 12;
        return nil
    end
    local ecInst = ecPrefab:call("instantiate(via.vec3)", pLoc)
    if not ecInst then
        state_check_in = 13;
        return nil
    end
    return ecInst;
end


--[[ KEYBOARD BY alphaZomega#7111 and praydog ]]
local function generate_statics(typename)
    local t = sdk.find_type_definition(typename)
    if not t then
        return {}
    end

    local fields = t:get_fields()
    local enum = {}
    local enum_string = "\ncase \"" .. typename .. "\":" .. "\n    enum {"

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)
            enum_string = enum_string .. "\n        " .. name .. " = " .. tostring(raw_value) .. ","
            enum[name] = raw_value
        end
    end

    log.info(enum_string .. "\n    }" .. typename:gsub("%.", "_") .. ";\n    break;\n") -- enums for RSZ template

    return enum
end

local function generate_statics_global(typename)
    local parts = {}
    for part in typename:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    local global = _G
    for i, part in ipairs(parts) do
        if not global[part] then
            global[part] = {}
        end
        global = global[part]
    end
    if global ~= _G then
        local static_class = generate_statics(typename)

        for k, v in pairs(static_class) do
            global[k] = v
            global[v] = k
        end
    end
    return global
end

local wanted_static_classes = {"via.hid.GamePadButton", "via.hid.MouseButton", "via.hid.KeyboardKey"}
for i, typename in ipairs(wanted_static_classes) do
    generate_statics_global(typename)
end
local function get_kb_device()
    return sdk.call_native_func(sdk.get_native_singleton("via.hid.Keyboard"),
        sdk.find_type_definition("via.hid.Keyboard"), "get_Device")
end


local kb_state = {
    down = {
        [via.hid.KeyboardKey.Home] = false,
        [via.hid.KeyboardKey.Control] = false,
        [via.hid.KeyboardKey.Menu] = false,
        [via.hid.KeyboardKey.Shift] = false
        -- [via.hid.KeyboardKey.Control] = false,
    },
    released = {
        [via.hid.KeyboardKey.Home] = false,
        [via.hid.KeyboardKey.Control] = false,
        [via.hid.KeyboardKey.Menu] = false,
        [via.hid.KeyboardKey.Shift] = false
        -- [via.hid.KeyboardKey.Control] = false,
    }
}


local function update_keyboard_state()
    local kb = get_kb_device()
    if not kb then
        return
    end
    for button, state in pairs(kb_state.down) do
        kb_state.down[button] = kb:call("isDown", button)
    end
    for button, state in pairs(kb_state.released) do
        kb_state.released[button] = kb:call("isRelease", button)
    end

end




local function get_device_gamepad()
    return sdk.call_native_func(sdk.get_native_singleton("via.hid.GamePad"),
    sdk.find_type_definition("via.hid.GamePad"), "get_Device");
end


local gamepad_state = {
    down = {
        [via.hid.GamePadButton.LStickPush] = false,
        [via.hid.GamePadButton.RStickPush] = false,
        [via.hid.GamePadButton.RRight] = false
    },
    released = {
        [via.hid.GamePadButton.LStickPush] = false,
        [via.hid.GamePadButton.RStickPush] = false,
        [via.hid.GamePadButton.RRight] = false
    }
}


local function update_gamepad_state()
    local gamepad = get_device_gamepad()
    if not gamepad then
        return
    end

    for button, state in pairs(gamepad_state.down) do
        local value = gamepad:call("isDown", button);
        gamepad_state.down[button] = value;
    end

    for button, state in pairs(gamepad_state.released) do
        local value = gamepad:call("isRelease", button);
        gamepad_state.down[button] = value;

    end

end

--[[ Thanks for all ]]

--[[
local function get_enumerator(enumerator, owner)
    if not enumerator then return end
    local tbl = {}
    enumerator:call(".ctor", 0)
    local try, output = pcall(sdk.call_object_func, enumerator, "MoveNext")
    while try and output do
        local object = enumerator:get_field("<>2__current")
        local parent = object:call("get_Parent")
        if not parent or parent == owner then 
            local sub_tbl, name = {object=object}
            sub_tbl.children = get_enumerator(object:call("get_Children"), object)
            if object:get_type_definition():is_a("via.Component") then 
                name = object:call("get_GameObject")
                name = name and name:call("get_Name")
            else
                sub_tbl.folders = get_enumerator(object:call("get_Folders"), object)
                name = object:call("get_Name")
            end
            tbl[name] = sub_tbl
        end
        try, output = pcall(sdk.call_object_func, enumerator, "MoveNext")
    end
    return next(tbl) and tbl
end

local scene_manager = sdk.get_native_singleton("via.SceneManager")
local scene = scene_manager and sdk.call_native_func(scene_manager, sdk.find_type_definition("via.SceneManager"), "get_CurrentScene")
local folders = scene and get_enumerator(scene:call("get_Folders"), scene)
]]




re.on_pre_application_entry("UpdateBehavior", function()

    -- I need check game state too
    state_check();

    if state_check_in == 0 then

        if (wait == 0) then
            wait = get_time() + 3.0;
        end

        if (wait > get_time()) then
            return
        end

        if auto_summon or max_summon then
            if (birds_auto_invok[bdi] > birds_invoks[bdi]) then
                this_index = bdi;
                canSpwan = true;
                
                -- wait = get_time() + 0.15;

            elseif (bdi >= 14) then
                canSpwan = false;
                max_summon = false;
            else
                bdi = bdi + 1;
                return;
            end
        end

        if (prism_auto_spwan) and (birds_invoks[15] < 1) then
            this_index = 15
            canSpwan = true
            sec_status = "gotcha";
            --return;
        end

        if canSpwan then
            local new_bird = invok_bird(this_index)
            if( sdk.is_managed_object(new_bird) ) then
                table.insert(birds_list, new_bird);
                birds_invoks[this_index] = birds_invoks[this_index] + 1;
                canSpwan = false;
                sec_status = "Done";
            else 
                sec_status = "Dont Return object ERROR";
            end
        end

    else

        -- clear birds
        for i, v in ipairs(birds_list) do
            v:call("destroy", v)
        end
        for item in pairs(birds_list) do
            birds_list[item] = nil;
            sec_status = "Cleaning..."
        end
        bdi = 11;
        birds_invoks[11] = 0;
        birds_invoks[12] = 0; 
        birds_invoks[13] = 0; 
        birds_invoks[14] = 0; 
        birds_invoks[15] = 0;
        wait = 0;
        sec_status = "wait";
    end

end)


local function new_checkbox(name, value)
    local change, new_value = imgui.checkbox(name, value)
    return new_value;
end

local function new_IntInput(name, value)
    local change, new_value = imgui.drag_int(name, value, 1, 0, 20)
    return new_value;
end


re.on_frame(function()

    update_keyboard_state()
    update_gamepad_state();

        --local rbutton = gamepad_state.down[via.hid.GamePadButton.RRight];


    local home_release  = kb_state.released[via.hid.KeyboardKey.Home];
    local controlD = kb_state.down[via.hid.KeyboardKey.Control];
    local altD = kb_state.down[via.hid.KeyboardKey.Menu];
    local shiftD = kb_state.down[via.hid.KeyboardKey.Shift];

    

    local my_r_button   = gamepad_state.down[via.hid.GamePadButton.RRight];
    local lstick        = gamepad_state.down[via.hid.GamePadButton.LStickPush];
    local rstick        = gamepad_state.down[via.hid.GamePadButton.RStickPush];
 
    --local rbuton = gp_state.down[via.hid.GamePadButton.RRight];



    if home_release then
        if not ( controlD or altD or shiftD ) then
            menu_open = not menu_open;
        end
    end

    if (lstick) and (rstick) then
        canSpwan = true;
        ec_level = 4;
    end


    if (menu_open) then

        menu_open = imgui.begin_window('Bird Summoner MOD', menu_open, ImGuiWindowFlags_AlwaysAutoResize)

            imgui.text("Press 'home' to hide or show");
            imgui.text("if you use gamepad press R3 & L3 to summon prism");
            prism_auto_spwan = new_checkbox("Auto Spawn prism", prism_auto_spwan);
            if (imgui.tree_node("Buttons of birds")) then

                auto_summon = new_checkbox("Auto Summon", auto_summon);

                if imgui.button("Attack") then
                    canSpwan = true;
                    ec_level = 0;
                end
                imgui.same_line()

                if imgui.button("Vitality") then
                    canSpwan = true;
                    ec_level = 2;
                end

                if imgui.button("Defense") then
                    canSpwan = true;
                    ec_level = 1;
                end
                imgui.same_line()
                if imgui.button("Stamina") then
                    canSpwan = true;
                    ec_level = 3;
                end
                
                if imgui.button("Prism") then
                    canSpwan = true;
                    ec_level = 4;
                end
                imgui.same_line()
                if imgui.button("Summor max") then
                    max_summon = true;
                    ec_level = 0;
                end

                imgui.tree_pop()
            end

            
            if (canSpwan) then
                this_index = ecIndex + ec_level;
            end
            

            if (imgui.tree_node("Values of birds")) then
                birds_auto_invok[11] = new_IntInput("Auto Birds ATK", birds_auto_invok[11])
                birds_auto_invok[12] = new_IntInput("Auto Birds DEF", birds_auto_invok[12])
                birds_auto_invok[13] = new_IntInput("Auto Birds HP", birds_auto_invok[13])
                birds_auto_invok[14] = new_IntInput("Auto Birds STM", birds_auto_invok[14])
                imgui.tree_pop()
            end

            if (imgui.tree_node("infos of birds")) then
                imgui.text(string.format("auto birds id : %d", bdi));
                imgui.text(string.format("Total birds: %d",
                    birds_invoks[11] + birds_invoks[12] + birds_invoks[13] + birds_invoks[14]))
                imgui.new_line()
                imgui.text(string.format("Attack:%d", birds_invoks[11]))
                imgui.same_line()
                imgui.text(string.format("Defense:%d", birds_invoks[12]))
                imgui.text(string.format("Stamina:%d", birds_invoks[14]))
                imgui.same_line()
                imgui.text(string.format("Vitality:%d", birds_invoks[13]))
                imgui.text(string.format("Prism:%d", birds_invoks[15]))
                imgui.new_line()
                imgui.tree_pop()
            end

            if (imgui.tree_node("Status and timer cheat")) then
                imgui.text(string.format("Count timer: %f", get_time()));
                imgui.text(string.format("My timer wait: %f", wait));
                imgui.text(string.format("Last index: %d", this_index));
                imgui.text("STATUS-> Code: " .. state_check_in);
                imgui.same_line()
                imgui.text(" Auto summon teste: " .. sec_status)
                if(lstick)then
                    imgui.text(" as true");
                else
                    imgui.text(" as false");
                end
            
                imgui.text("VER: 0.0.1.0");
            end
            imgui.end_window()

    end
end)

