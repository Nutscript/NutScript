PLUGIN.name = "Integrated SAM Commands"
PLUGIN.desc = "Integrates SAM Commands into NutScript"
PLUGIN.author = "Tov"

if not (sam and sam.command) then return end -- Make sure SAM is installed

local color_red = Color(255, 0, 0)
local color_green = Color(0, 255, 0)

nut.command.add("asay", {
    arguments = nut.type.string,
    onCheckAccess = function(client)
        return client:IsAdmin() or sam.config.get_updated("Reports", true).value
    end,
    onRun = function(client, message)
        local text = message

        if (text:find("%S")) then
            if client:IsAdmin() then
                nut.chat.send(client, "asay", text)
            else
                if sam.config.get_updated("Reports", true).value then
                    local message = table.concat(arguments, " ")
                    local success, time = sam.player.report(client, message)
                    if success == false then
                        client:sam_send_message("You need to wait {S Red} seconds.", {
                            S = time
                        })
                    else
                        client:sam_send_message("to_admins", {
                            A = client, V = message
                        })
                    end
                end
            end
        else
            client:notifyLocalized("invalid", "text")
        end
    end
})

nut.chat.register("asay", {
    onCanSay = function(speaker, text)
        return speaker:IsAdmin()
    end,
    onCanHear = function(speaker, listener)
        return listener:IsAdmin()
    end,
    onChatAdd = function(speaker, text)
        if speaker:IsAdmin() then
            chat.AddText(color_red, "[Admin] ", speaker, " (" .. speaker:steamName() .. ") ", color_green, ": " .. text)
        end
    end,
    font = "nutChatFont",
    filter = "admin"
})

hook.Remove("PlayerSay", "SAM.Chat.Asay")

function PLUGIN:PlayerSay(client, text)
    if text:sub(1, 1) == "@" then
        nut.command.run(client, "asay", {text:sub(2)})
        return ""
    end
end

function PLUGIN:InitializedPlugins()
        -- Add all the commands
    for _, commandInfo in ipairs(sam.command.get_commands()) do
        local customSyntax = ""
        for _, argInfo in ipairs(commandInfo.args) do
            customSyntax = customSyntax == "" and "[" or customSyntax .. " ["
            customSyntax = customSyntax .. (argInfo.default and tostring(type(argInfo.default)) or "string") .. " "
            customSyntax = customSyntax .. argInfo.name .. "]"
        end

        if nut.command.list[commandInfo.name] then
            print("SAM command " .. commandInfo.name .. " conflicts with a NutScript command, skipping!")
            continue
        end

        nut.command.add(commandInfo.name, {
            adminOnly = commandInfo.default_rank == "admin",
            superAdminOnly = commandInfo.default_rank == "superadmin",
            syntax = customSyntax,
            onRun = function(client, arguments)
                --run the sam command
                RunConsoleCommand("sam", commandInfo.name, unpack(arguments))
            end
        })
    end
end