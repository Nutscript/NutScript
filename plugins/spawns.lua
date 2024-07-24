local PLUGIN = PLUGIN

PLUGIN.name = "Spawns"
PLUGIN.desc = "Spawn points for factions and classes."
PLUGIN.author = "Chessnut"
PLUGIN.spawns = PLUGIN.spawns or {}

function PLUGIN:PostPlayerLoadout(client)
	if (self.spawns and table.Count(self.spawns) > 0 and client:getChar()) then
		local class = client:getChar():getClass()
		local points
		local className = ""

		for k, v in ipairs(nut.faction.indices) do
			if (k == client:Team()) then
				points = self.spawns[v.uniqueID] or {}

				break
			end
		end

		if (points) then
			for k, v in ipairs(nut.class.list) do
				if (class == v.index) then
					className = v.uniqueID

					break
				end
			end

			points = points[className] or points[""]

			if (points and table.Count(points) > 0) then
				local position = table.Random(points)

				client:SetPos(position)
			end
		end
	end
end

function PLUGIN:LoadData()
	self.spawns = self:getData() or {}
end

function PLUGIN:SaveSpawns()
	self:setData(self.spawns)
end

nut.command.add("spawnadd", {
	adminOnly = true,
	arguments = {
		nut.type.faction,
		nut.type.tor(nut.type.class, nut.type.optional)
	},
	onRun = function(client, factionName, className)
		local info = factionName
		local info2 = className

		local faction = info.uniqueID
		local class = ""

		if (info2) then
			class = info2.uniqueID
		end

		PLUGIN.spawns[faction] = PLUGIN.spawns[faction] or {}
		PLUGIN.spawns[faction][class] = PLUGIN.spawns[faction][class] or {}

		table.insert(PLUGIN.spawns[faction][class], client:GetPos())

		PLUGIN:SaveSpawns()

		local name = L(info.name, client)

		if (info2) then
			name = name.." ("..L(info2.name, client)..")"
		end

		return L("spawnAdded", client, name)
	end
})

nut.command.add("spawnremove", {
	adminOnly = true,
	arguments = nut.type.tor(nut.type.number, nut.type.optional),
	onRun = function(client, radius)
		local position = client:GetPos()
		radius = radius or 120
		local i = 0

		for k, v in pairs(PLUGIN.spawns) do
			for k2, v in pairs(v) do
				for k3, v3 in pairs(v) do
					if (v3:Distance(position) <= radius) then
						v[k3] = nil
						i = i + 1
					end
				end
			end
		end

		if (i > 0) then
			PLUGIN:SaveSpawns()
		end

		return L("spawnDeleted", client, i)
	end
})