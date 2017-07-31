-- Jail Mod
-- Prototype created by kaeza and RAPHAEL (mostly kaeza)
-- Enhanced by BillyS
-- license: whatever

minetest.register_privilege("jail", { description = "Allows one to send/release prisoners" })

local jailpos = { x = -517, y = 36, z = 169 }
local players_in_jail = {};
local datapath = minetest.get_worldpath() .. "/"

local function saveJailData (path)
	local file = io.open(path .. "jailData.txt", "w")
	if not file then return false end
	file:write(minetest.serialize(players_in_jail))
	file:close()
	return true
end

local function loadJailData (path)
	local file = io.open(path .. "jailData.txt", "r")
	if not file then return false end
	jData = minetest.deserialize(file:read("*all"))
	file:close()
	return jData
end

jData = loadJailData (datapath)
if jData then
	players_in_jail = jData
end

minetest.register_chatcommand("jail", {
    params = "<player>",
    description = "Sends a player to Jail",
	privs = {jail=true},
    func = function ( name, param )
        local player = minetest.env:get_player_by_name(param)
        if (player) then
            players_in_jail[param] = {name = param, privs = minetest.get_player_privs(param)};
            minetest.set_player_privs(param, {shout = true})
            player:setpos(jailpos)
			minetest.chat_send_player(param, "You have been sent to jail")
			minetest.chat_send_all(""..param.." has been sent to jail by "..name.."")
			saveJailData (datapath)
        end
    end,
})


local releasepos = { x = -512, y = 36, z = 169 }
 
minetest.register_chatcommand("release", {
    params = "<player>",
    description = "Releases a player from Jail",
	privs = {jail=true},
    func = function ( name, param )
        if (param == "") then return end
        local player = minetest.env:get_player_by_name(param)
        if (player) then
			minetest.set_player_privs(param, players_in_jail[param].privs)
			players_in_jail[param] = nil;
            player:setpos(releasepos)
			minetest.chat_send_player(param, "You have been released from jail")
			minetest.chat_send_all(""..param.." has been released from jail by "..name.."")
			saveJailData (datapath)
        end
    end,
})

minetest.register_on_respawnplayer(function(player) return true end)

local function do_teleport ( )
    for name, player in pairs(players_in_jail) do
            minetest.env:get_player_by_name(player.name):setpos(jailpos)
    end
    minetest.after(30, do_teleport)
end
minetest.after(30, do_teleport)

minetest.register_alias("wardenpick", "jail:pick_warden")

minetest.register_node("jail:jailwall", {
	description = "Unbreakable Jail Wall",
	tile_images = {"jail_wall.png"},
	is_ground_content = true,
	groups = {unbreakable=1, not_in_creative_inventory=1}
--	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("jail:glass", {
	description = "Unbreakable Jail Glass",
	drawtype = "glasslike",
	tile_images = {"jail_glass.png"},
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = true,
	groups = {unbreakable=1, not_in_creative_inventory=1},
--	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("jail:ironbars", {
	drawtype = "fencelike",
	tiles = {"jail_ironbars.png"},
	inventory_image = "jail_ironbars_icon.png",
	light_propagates = true,
	paramtype = "light",
	is_ground_content = true,
	selection_box = {
		type = "fixed",
		fixed = {-1/7, -1/2, -1/7, 1/7, 1/2, 1/7},
	},
	groups = {unbreakable=1, not_in_creative_inventory=1},
--	sounds = default.node_sound_stone_defaults(),
})

minetest.register_tool("jail:pick_warden", {
	description = "Warden Pickaxe",
	inventory_image = "jail_wardenpick.png",
	groups = {not_in_creative_inventory=1},
	tool_capabilities = {
		full_punch_interval = 0,
		max_drop_level=3,
		groupcaps={
			unbreakable={times={[1]=0, [2]=0, [3]=0}, uses=0, maxlevel=3},
			fleshy = {times={[1]=0, [2]=0, [3]=0}, uses=0, maxlevel=3},
			choppy={times={[1]=0, [2]=0, [3]=0}, uses=0, maxlevel=3},
			bendy={times={[1]=0, [2]=0, [3]=0}, uses=0, maxlevel=3},
			cracky={times={[1]=0, [2]=0, [3]=0}, uses=0, maxlevel=3},
			crumbly={times={[1]=0, [2]=0, [3]=0}, uses=0, maxlevel=3},
			snappy={times={[1]=0, [2]=0, [3]=0}, uses=0, maxlevel=3},
		}
	},
})
