nut.command.add("charsetattrib", {
	adminOnly = true,
	arguments = {
		nut.type.character,
		nut.type.string,
		nut.type.number
	},
	onRun = function(client, target, attribName, level)
		for k, v in pairs(nut.attribs.list) do
			if (nut.util.stringMatches(L(v.name, client), attribName) or nut.util.stringMatches(k, attribName)) then
				target:setAttrib(k, math.abs(level))
				client:notifyLocalized("attribSet", target:getName(), L(v.name, client), math.abs(level))

				return
			end
		end
	end
})

nut.command.add("charaddattrib", {
	adminOnly = true,
	arguments = {
		nut.type.character,
		nut.type.string,
		nut.type.number
	},
	onRun = function(client, target, attribName, level)
		for k, v in pairs(nut.attribs.list) do
			if (nut.util.stringMatches(L(v.name, client), attribName) or nut.util.stringMatches(k, attribName)) then
				target:updateAttrib(k, math.abs(level))
				client:notifyLocalized("attribUpdate", target:getName(), L(v.name, client), math.abs(level))

				return
			end
		end
	end
})
