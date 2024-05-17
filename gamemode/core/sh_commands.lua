
nut.command.add("roll", {
	arguments = nut.type.tor(nut.type.number, nut.type.optional),
	onRun = function(client, maximum)
		nut.chat.send(client, "roll", math.random(0, math.min(tonumber(maximum) or 100, 100)))
	end
})

nut.command.add("pm", {
	arguments = {
		nut.type.player,
		nut.type.string
	},
	onRun = function(client, target, message)
		local voiceMail = target:getNutData("vm")

		if (voiceMail and voiceMail:find("%S")) then
			return target:Name()..": "..voiceMail
		end

		if ((client.nutNextPM or 0) < CurTime()) then
			nut.chat.send(client, "pm", message, false, {client, target})

			client.nutNextPM = CurTime() + 0.5
			target.nutLastPM = client
		end
	end
})

nut.command.add("reply", {
	arguments = {
		nut.type.string
	},
	onRun = function(client, message)
		local target = client.nutLastPM

		if (IsValid(target) and (client.nutNextPM or 0) < CurTime()) then
			nut.chat.send(client, "pm", message, false, {client, target})
			client.nutNextPM = CurTime() + 0.5
		end
	end
})

nut.command.add("setvoicemail", {
	arguments = nut.type.tor(nut.type.string, nut.type.optional),
	onRun = function(client, message)
		if (message and message:find("%S")) then
			client:setNutData("vm", message:sub(1, 240))

			return "@vmSet"
		else
			client:setNutData("vm")

			return "@vmRem"
		end
	end
})

nut.command.add("flaggive", {
	adminOnly = true,
	arguments = {
		nut.type.character,
		nut.type.tor(nut.type.string, nut.type.optional)
	},
	onRun = function(client, target, flags)
		if (not flags) then
			local available = ""

			-- Aesthetics~~
			for k in SortedPairs(nut.flag.list) do
				if (not target:hasFlags(k)) then
					available = available..k
				end
			end

			return client:requestString("@flagGiveTitle", "@flagGiveDesc", function(text)
				nut.command.run(client, "flaggive", {target, text})
			end, available)
		end

		target:giveFlags(flags)

		nut.util.notifyLocalized("flagGive", nil, client:Name(), target:getName(), flags)
	end
})

nut.command.add("flagtake", {
	adminOnly = true,
	arguments = {
		nut.type.character,
		nut.type.tor(nut.type.string, nut.type.optional)
	},
	onRun = function(client, target, flags)
		if (not flags) then
			return client:requestString("@flagTakeTitle", "@flagTakeDesc", function(text)
				nut.command.run(client, "flagtake", {target, text})
			end, target:getFlags())
		end

		target:takeFlags(flags)

		nut.util.notifyLocalized("flagTake", nil, client:Name(), flags, target:getName())
	end
})

nut.command.add("charsetmodel", {
	adminOnly = true,
	arguments = {
		nut.type.character,
		nut.type.string
	},
	onRun = function(client, target, model)
		target:setModel(model)
		target:getPlayer():SetupHands()

		nut.util.notifyLocalized("cChangeModel", nil, client:Name(), target:getName(), model)
	end
})

nut.command.add("charsetskin", {
	adminOnly = true,
	arguments = {
		nut.type.character,
		nut.type.number
	},
	onRun = function(client, target, skin)
		target:setData("skin", skin)
		target:getPlayer():SetSkin(skin or 0)

		nut.util.notifyLocalized("cChangeSkin", nil, client:Name(), target:getName(), skin or 0)
	end
})

nut.command.add("charsetbodygroup", {
	adminOnly = true,
	arguments = {
		nut.type.character,
		nut.type.string,
		nut.type.tor(nut.type.number, nut.type.optional)
	},
	onRun = function(client, target, bodygroup, value)
		local index = target:getPlayer():FindBodygroupByName(bodygroup)

		if (index != -1) then
			if (value and value < 1) then
				value = nil
			end

			local groups = target:getData("groups", {})
				groups[index] = value
			target:setData("groups", groups)
			target:getPlayer():SetBodygroup(index, value or 0)

			nut.util.notifyLocalized("cChangeGroups", nil, client:Name(), target:getName(), bodygroup, value or 0)
		else
			client:notify("Bodygroup \'" .. bodygroup .. "\' was not found for \'" .. target:getName() .. "\'")
		end
	end
})

nut.command.add("charsetname", {
	adminOnly = true,
	arguments = {
		nut.type.character,
		nut.type.tor(nut.type.string, nut.type.optional)
	},
	onRun = function(client, target, name)
		if (not name) then
			return client:requestString("@chgName", "@chgNameDesc", function(text)
				nut.command.run(client, "charsetname", {target, text})
			end, target:getName())
		end

		nut.util.notifyLocalized("cChangeName", nil, client:Name(), target:getName(), name)
		target:setName(name)
	end
})

nut.command.add("chargiveitem", {
	adminOnly = true,
	arguments = {
		nut.type.character,
		nut.type.item,
		nut.type.tor(nut.type.number, nut.type.optional),
	},
	onRun = function(client, target, name, amount)
		local item = name.uniqueID

		target:getInv():add(item, amount or 1)
			:next(function(res)
				if (IsValid(target:getPlayer())) then
					target:getPlayer():notifyLocalized("itemCreated")
				end
				if (IsValid(client) and client ~= target:getPlayer()) then
					client:notifyLocalized("itemCreated")
				end
				hook.Run("CharGivenItem", target:getPlayer(), res)
			end)
			:catch(function(err)
				if (IsValid(client)) then
					client:notifyLocalized(err)
				end
			end)
	end
})

nut.command.add("charkick", {
	adminOnly = true,
	arguments = nut.type.character,
	onRun = function(client, target)
		for k, v in ipairs(player.GetAll()) do
			v:notifyLocalized("charKick", client:Name(), target:getName())
		end

		target:kick()
	end
})

nut.command.add("charban", {
	adminOnly = true,
	arguments = nut.type.character,
	onRun = function(client, target)
		nut.util.notifyLocalized("charBan", client:Name(), target:getName())
		target:ban()
	end
})

nut.command.add("charunban", {
	adminOnly = true,
	arguments = nut.type.tor(nut.type.character, nut.type.string),
	onRun = function(client, target)
		if ((client.nutNextSearch or 0) >= CurTime()) then
			return L("charSearching", client)
		end

		if (nut.type(target) == nut.type.character) then
			if (target:getData("banned")) then
				target:setData("banned", nil)
				target:setData("permakilled", nil)
				nut.util.notifyLocalized("charUnBan", nil, client:Name(), target:getName())
				return
			else
				client:notifyLocalized("charNotBanned")
				return
			end
		end

		client.nutNextSearch = CurTime() + 15

		nut.db.query("SELECT _id, _name, _data FROM nut_characters WHERE _name LIKE \"%" .. nut.db.escape(target) .. "%\" LIMIT 1", function(data)
			if (data and data[1]) then
				local charID = tonumber(data[1]._id)
				local data = util.JSONToTable(data[1]._data or "[]")

				client.nutNextSearch = 0

				if (not data.banned) then
					return client:notifyLocalized("charNotBanned")
				end

				data.banned = nil

				nut.db.updateTable({_data = data}, nil, "characters", "_id = " .. charID)
				nut.util.notifyLocalized("charUnBan", nil, client:Name(), nut.char.loaded[charID]:getName())
			else
				client:notify("Could not find the character \'" .. target .. "\'")
				return
			end
		end)
	end
})

nut.command.add("givemoney", {
	arguments = nut.type.number,
	onRun = function(client, number)
		local amount = math.floor(number)

		if (amount < 1) then
			return client:notify("Amount must be greater than zero.")
		end

		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*96
			data.filter = client
		local target = util.TraceLine(data).Entity

		if (IsValid(target) and target:IsPlayer() and target:getChar()) then
			amount = math.Round(amount)

			if (not client:getChar():hasMoney(amount)) then
				return
			end

			target:getChar():giveMoney(amount)
			client:getChar():takeMoney(amount)

			target:notifyLocalized("moneyTaken", nut.currency.get(amount))
			client:notifyLocalized("moneyGiven", nut.currency.get(amount))

			client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_ITEM_PLACE, true)
		end
	end
})

nut.command.add("charsetmoney", {
	adminOnly = true,
	arguments = {
		nut.type.character,
		nut.type.number
	},
	onRun = function(client, target, money)
		local amount = math.floor(money)

		if (amount < 0) then
			return client:notify("Amount must be atleast zero.")
		end

		target:setMoney(amount)
		client:notifyLocalized("setMoney", target:getName(), nut.currency.get(amount))
	end
})

nut.command.add("dropmoney", {
	arguments = nut.type.number,
	onRun = function(client, money)
		local amount = math.floor(number)

		if (amount < 1) then
			return client:notify("Amount must be greater than zero.")
		end

		if (not client:getChar():hasMoney(amount)) then
			return
		end

		client:getChar():takeMoney(amount)
		local money = nut.currency.spawn(client:getItemDropPos(), amount)
		money.client = client
		money.charID = client:getChar():getID()

		client:doGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_ITEM_PLACE, true)
	end
})

nut.command.add("plywhitelist", {
	adminOnly = true,
	arguments = {
		nut.type.player,
		nut.type.faction
	},
	onRun = function(client, target, name)
		local faction = name

		if (target:setWhitelisted(faction.index, true)) then
			for k, v in ipairs(player.GetAll()) do
				v:notifyLocalized("whitelist", client:Name(), target:Name(), L(faction.name, v))
			end
		end
	end
})

nut.command.add("chargetup", {
	onRun = function(client)
		local entity = client.nutRagdoll

		if (IsValid(entity) and entity.nutGrace and entity.nutGrace < CurTime() and entity:GetVelocity():Length2D() < 8 and not entity.nutWakingUp) then
			entity.nutWakingUp = true

			client:setAction("@gettingUp", 5, function()
				if (not IsValid(entity)) then
					return
				end

				entity:Remove()
			end)
		end
	end
})

nut.command.add("plyunwhitelist", {
	adminOnly = true,
	arguments = {
		nut.type.player,
		nut.type.faction
	},
	onRun = function(client, target, name)
		local faction = name

		if (target:setWhitelisted(faction.index, false)) then
			for k, v in ipairs(player.GetAll()) do
				v:notifyLocalized("unwhitelist", client:Name(), target:Name(), L(faction.name, v))
			end
		end
	end
})

nut.command.add("fallover", {
	arguments = nut.type.tor(nut.type.number, nut.type.optional),
	onRun = function(client, time)
		if (not isnumber(time)) then
			time = 5
		end

		if (time > 0) then
			time = math.Clamp(time, 1, 60)
		else
			time = nil
		end

		if (not IsValid(client.nutRagdoll)) then
			client:setRagdolled(true, time)
		end
	end
})

nut.command.add("beclass", {
	arguments = nut.type.class,
	onRun = function(client, name)
		local class = name

		local char = client:getChar()

		if (IsValid(client) and char) then
			if (char:joinClass(class.index)) then
				client:notifyLocalized("becomeClass", L(class.name, client))
				return
			else
				client:notifyLocalized("becomeClassFail", L(class.name, client))
				return
			end
		else
			client:notifyLocalized("illegalAccess")
		end
	end
})

nut.command.add("chardesc", {
	arguments = nut.type.tor(nut.type.string, nut.type.optional),
	onRun = function(client, desc)
		if (not desc or not desc:find("%S")) then
			return client:requestString("@chgDesc", "@chgDescDesc", function(text)
				nut.command.run(client, "chardesc", {text})
			end, client:getChar():getDesc())
		end

		local info = nut.char.vars.desc
		local result, fault, count = info.onValidate(desc)

		if (result == false) then
			return "@"..fault, count
		end

		client:getChar():setDesc(desc)

		return "@descChanged"
	end
})

nut.command.add("plytransfer", {
	adminOnly = true,
	arguments = {
		nut.type.player,
		nut.type.faction
	},
	onRun = function(client, target, name)
		local character = target:getChar()
		local faction = name

		if (not IsValid(target) or not character) then
			return "@plyNotExist"
		end

		-- Find the specified faction.
		local oldFaction = nut.faction.indices[character:getFaction()]

		-- Change to the new faction.
		target:getChar():setFaction(faction.index)
		if (faction.onTransfered) then
			faction:onTransfered(target, oldFaction)
		end
		hook.Run("CharacterFactionTransfered", character, oldFaction, faction)

		-- Notify everyone of the change.
		for k, v in ipairs(player.GetAll()) do
			nut.util.notifyLocalized(
				"cChangeFaction",
				v, client:Name(), target:Name(), L(faction.name, v)
			)
		end
	end,
	alias = "charsetfaction"
})

-- Credit goes to SmithyStanley
nut.command.add("clearinv", {
	adminOnly = true,
	arguments = nut.type.character,
	onRun = function (client, target)
		for k, v in pairs(target:getInv():getItems()) do
			v:remove()
		end

		client:notifyLocalized("resetInv", target:getName())
	end
})

nut.command.add("content", {
	onRun = function(client)
		client:SendLua([[gui.OpenURL(nut.config.get("contentURL", "https://nutscript.net"))]])
	end
})
