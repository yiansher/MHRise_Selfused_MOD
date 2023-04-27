log.info("[Infinite Consumables] started loading")

local IC_debug = false

local isOnline = false

local config = {
	runInMultiplayer = false, --other options will take effect in Lobby and Joined/Joinable Hub Quests
	infiniteCoatings = true,
	infiniteAmmo = true,
	infiniteItems = true,
	infiniteEndemicLife = false --Beetles and Toads and such
	}

local configPath = "Infinte_Consumables_Config.json"

if json ~= nil then
    file = json.load_file(configPath)
    if file ~= nil then
		config = file
    else
        json.dump_file(configPath, config)
    end
end

function IC_logDebug(argStr)
	if IC_debug then
		log.info("[Infinite Consumables] "..tostring(argStr));
	end
end

sdk.hook(sdk.find_type_definition("snow.QuestManager"):get_method("onChangedGameStatus"),
function(args)
	local LobbyManager = sdk.get_managed_singleton("snow.LobbyManager")
	isOnline = LobbyManager:call("isInInternetQuestSession")
end,
function(retval)
	return retval;
end
)

sdk.hook(sdk.find_type_definition("snow.data.bulletSlider.BottleSliderFunc"):get_method("consumeItem"),
function(args)
	if (not isOnline or config.runInMultiplayer) and config.infiniteCoatings then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end,
function(retval)
	return retval;
end
)

sdk.hook(sdk.find_type_definition("snow.data.bulletSlider.BulletSliderFunc"):get_method("consumeItem"),
function(args)
	if (not isOnline or config.runInMultiplayer) and config.infiniteAmmo then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end,
function(retval)
	return retval;
end
)

function isEcItem(itemID)
	IC_logDebug(itemID)
	return (69206016 <= itemID and itemID <= 69206047)
end

function isDemonPuppet(itemID)
	return (69206037 == itemID)
end

local doThing = false

sdk.hook(sdk.find_type_definition("snow.data.ItemSlider"):get_method("notifyConsumeItem(snow.data.ContentsIdSystem.ItemId, System.Boolean)"),
function(args)
	if isEcItem(sdk.to_int64(args[3])) and (not isOnline or config.runInMultiplayer) and config.infiniteEndemicLife then
		return sdk.PreHookResult.SKIP_ORIGINAL
	elseif not isEcItem(sdk.to_int64(args[3])) and (not isOnline or config.runInMultiplayer) and config.infiniteItems then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end,
function(retval)
	
	return retval
end
)

sdk.hook(sdk.find_type_definition("snow.envCreature.EnvironmentCreatureManager"):get_method("addEc057UseCount"),
function(args)
	local playerManager = sdk.get_managed_singleton("snow.player.PlayerManager")
	if (not isOnline or config.runInMultiplayer) and config.infiniteEndemicLife and (playerManager:call("getMasterPlayerID") == sdk.to_int64(args[3])) then
		return sdk.PreHookResult.SKIP_ORIGINAL
	end
end,
function(retval)

	return retval
end
)

re.on_draw_ui(function()
	if imgui.button("[Infinite Consumables] Options") then
		drawInfiniteConsumablesOptionsWindow = true
	end
	
    if drawInfiniteConsumablesOptionsWindow then
        if imgui.begin_window("Infinite Consumables Options", true, 64) then
			local doWrite = false
			imgui.text("Multiplayer being False will override the other individual settings.")
			changed, value = imgui.checkbox('Enabled in Multiplayer Quests', config.runInMultiplayer)
			if changed then
				doWrite = true
				config.runInMultiplayer = value
			end
			changed, value = imgui.checkbox('Infinite Coatings (for Bow)', config.infiniteCoatings)
			if changed then
				doWrite = true
				config.infiniteCoatings = value
			end
			changed, value = imgui.checkbox('Infinite Ammo (for Bowguns)', config.infiniteAmmo)
			if changed then
				doWrite = true
				config.infiniteAmmo = value
			end
			changed, value = imgui.checkbox('Infinite Items (Potions, Food, Traps, etc.)', config.infiniteItems)
			if changed then
				doWrite = true
				config.infiniteItems = value
			end
			changed, value = imgui.checkbox('Infinite Endemic Life (Spiders, Beetles, etc)', config.infiniteEndemicLife)
			if changed then
				doWrite = true
				config.infiniteEndemicLife = value
			end
			if doWrite then
				json.dump_file(configPath, config)
			end
			imgui.end_window()
        else
            drawInfiniteConsumablesOptionsWindow = false
        end
    end
end)