-- Jail Mod
-- Prototype created by kaeza and RAPHAEL (mostly kaeza)
-- Enhanced by BillyS
-- license: whatever

minetest.register_privilege("jail", { description = "Allows one to send/release prisoners" })
minetest.register_privilege("freeze", { description = "Allows one to freeze/defrost players" })

jailpos = { x = -20, y = 48, z = -67 }
releasepos = { x = -512, y = 36, z = 169 }
local players_in_jail = {}
local frozen_players = {}
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

local function jailPlayer (pName, by)
	local player = minetest.env:get_player_by_name(pName)
	if (player and not players_in_jail[pName] and not minetest.get_player_privs(pName).jail) then
		players_in_jail[pName] = {name = pName, privs = minetest.get_player_privs(pName)};
		minetest.set_player_privs(pName, {shout = true})
		player:setpos(jailpos)
		minetest.chat_send_player(pName, "You have been sent to jail")
		minetest.chat_send_all(""..pName.." has been sent to jail by "..by.."")
		saveJailData (datapath)
	end
end

local function releasePlayer (pName, by)
	local player = minetest.env:get_player_by_name(pName)
	if (player and players_in_jail[pName]) then
		minetest.set_player_privs(pName, players_in_jail[pName].privs)
		players_in_jail[pName] = nil;
		player:setpos(releasepos)
		minetest.chat_send_player(pName, "You have been released from jail")
		minetest.chat_send_all(""..pName.." has been released from jail by "..by.."")
		saveJailData (datapath)
	end
end

local jData = loadJailData (datapath)
if jData then
	players_in_jail = jData
end

minetest.register_chatcommand("jail", {
    params = "<player>",
    description = "Sends a player to Jail",
	privs = {jail=true},
    func = function ( name, param )
        jailPlayer (param, name)
    end,
})

minetest.register_chatcommand("tempjail", {
	params = "<player> <time>",
	description = "Sends a player in jail for a certain amount of time (in minutes)",
	privs = {jail = true},
	func = function (name, param)
		pName = param:gsub("%s.+", "")
		jailTime = param:gsub(".+%s", "")
		if (pName == param or jailTime == param) then return end
		jailTime = tonumber(jailTime)
		if jailTime then
			jailPlayer (pName, name)
			minetest.after(jailTime * 60, function (params)
											local pName = params[1]
											local by = params[2]
											releasePlayer (pName, by)
										  end,
			 {pName, name})
		end
	end
})
 
minetest.register_chatcommand("release", {
    params = "<player>",
    description = "Releases a player from Jail",
	privs = {jail=true},
    func = function ( name, param )
        if (param == "") then return end
        releasePlayer (param, name)
    end,
})

minetest.register_chatcommand("freeze", {
	params = "<player>",
	description = "Immobilizes a player",
	privs = {freeze=true},
	func = function (name, param)
		local player = minetest.env:get_player_by_name(param)
		if player and not frozen_players[param] then
			player:set_physics_override({speed = 0, jump = 0, gravity = 1.0, sneak = false, sneak_glitch = false})
			minetest.chat_send_player(param, "You have been frozen!")
			frozen_players[param] = true
		end
	end,	
})

minetest.register_chatcommand("defrost", {
	params = "<player>",
	description = "Remobilizes a player",
	privs = {freeze=true},
	func = function (name, param)
		local player = minetest.env:get_player_by_name(param)
		if player and frozen_players[param] then
			player:set_physics_override({speed = 1.0, jump = 1.0, gravity = 1.0, sneak = true, sneak_glitch = false})
			minetest.chat_send_player(param, "You have been defrosted!")
			frozen_players[param] = nil
		end
	end,	
})

minetest.register_on_chat_message(function(name, msg)
	for i, _ in pairs(players_in_jail) do
		if name == i then
			minetest.chat_send_all("<" .. name .. "@jail> " .. msg)
			return true
		end
	end
end
)

minetest.register_on_respawnplayer(function(player) return true end)

local playerInst
local function do_teleport ( )
    for name, player in pairs(players_in_jail) do
            playerInst = minetest.env:get_player_by_name(player.name)
            if playerInst then
				playerInst:setpos(jailpos)
            end
    end
    minetest.after(30, do_teleport)
end
minetest.after(30, do_teleport)

minetest.register_node("jail:barbed_wire", {
	description = "Barbed Wire",
	drawtype = "glasslike",
	tile_images = {"jail_barbed_wire.png"},
	sunlight_propagates = true,
	groups = {snappy = 2}
--	sounds = default.node_sound_stone_defaults(),
})
