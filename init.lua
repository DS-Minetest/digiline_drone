local load_time_start = os.clock()


minetest.register_entity("digiline_drone:ent", {
	visual = "cube", -- todo: make a nice mesh
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	nametag = "Drone",
	nametag_color = "#234C66",
	on_activate = function(self, staticdata, dtime_s)
		local s = minetest.deserialize(staticdata) or {}
		self.owner = s.owner or staticdata
		self.channel = s.channel or ""
		self.object:set_properties({nametag = "Drone\n(owned by "..self.owner..")"})
	end,
	--~ on_step = function(self, dtime)
	--~ end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		minetest.add_item(self.object:get_pos(), "digiline_drone:item")
	end,
	on_rightclick = function(self, clicker)
		local playername = clicker:get_player_name()
		local formname = "digiline_drone_"..playername..minetest.pos_to_string(self.object:get_pos(), 2)
		minetest.show_formspec(playername, formname, "field[channel;Channel;"..self.channel.."]")
	end,
	get_staticdata = function(self)
		return minetest.serialize({owner = self.owner, channel = self.channel})
	end,
	_on_digiline_remote_receive = function(self, channel, msg)
		minetest.chat_send_all("msg = "..msg)
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.channel == nil then
		return
	end
	local b, e = string.find(formname, "digiline_drone_"..player:get_player_name())
	if b ~= 1 then
		return
	end
	local dronepos = minetest.string_to_pos(string.sub(formname, e + 1, -1))
	local obj = minetest.get_objects_inside_radius(dronepos, 0.25)
	local ldrone
	local ok = false
	for i = 1, #obj do
		if not obj[i]:is_player() then
			ldrone = obj[i]:get_luaentity()
			if ldrone.name == "digiline_drone:ent" then
				ok = true
				break
			end
		end
	end
	if not ok then
		return
	end
	ldrone.channel = fields.channel
end)

minetest.register_craftitem("digiline_drone:item", {
	description = "Drone\n"..core.colorize("#233566", "Digiline controlled"),
	inventory_image = "digiline_drone_item.png",
	--~ wield_scale = {x = 10, y = 10, z = 10},
	on_place = function(itemstack, placer, pointed_thing)
		if minetest.get_node(pointed_thing.above).name ~= "air" then
			return
		end
		minetest.add_entity(pointed_thing.above, "digiline_drone:ent", placer:get_player_name())
		itemstack:take_item()
		return itemstack
	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "nothing" then
			return
		end
		local look_pos = user:get_pos()
		look_pos.y = look_pos.y + 1.625
		look_pos = vector.add(look_pos, vector.multiply(user:get_look_dir(), 2))
		if minetest.get_node(look_pos).name ~= "air" then
			return
		end
		minetest.add_entity(look_pos, "digiline_drone:ent", user:get_player_name())
		itemstack:take_item()
		return itemstack
	end,
})


local time = math.floor(tonumber(os.clock()-load_time_start)*100+0.5)/100
local msg = "[digiline_remote] loaded after ca. "..time
if time > 0.05 then
	print(msg)
else
	minetest.log("info", msg)
end
