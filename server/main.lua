
if Config.Core == "qb" then
    Core = exports["qb-core"]:GetCoreObject()
elseif Config.Core == "esx" then
    Core = exports["es_extended"]:getSharedObject()
end

local jsonPath = "data.json"
local ResourceName = GetCurrentResourceName()

RemoveMoney = function(source, type, amount)
    local src = source
    if Config.Core == "qb" then
        local Player = Core.Functions.GetPlayer(src)
        Player.Functions.RemoveMoney(type, amount)
    else
        local Player = Core.GetPlayerFromId(src)
        Player.removeAccountMoney(type, amount)
    end
end

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local src = source
        Citizen.CreateThread(function()
            local jsonData = LoadResourceFile(ResourceName, jsonPath)
            if jsonData == nil then
                SaveResourceFile(ResourceName, jsonPath, "[]", -1)
                print("^1[src-billing] ^0 json data created.")
                GetJson()
            else
                print("^1[src-billing] ^0 json data loaded.")
                GetJson()
            end
        end)
    end
end)

lib.callback.register("src-billing:getPlayers", function(_, cb)
    local src = source
    local players = {}

    if Config.Core == "qb" then
        for _, v in pairs(Core.Functions.GetPlayers()) do
            local ped = Core.Functions.GetPlayer(v)
            local targetped = GetPlayerPed(v)
            local tCoords = GetEntityCoords(targetped)
            local dist = #(GetEntityCoords(GetPlayerPed(src)) - tCoords)
            players[#players + 1] = {
                id = v,
                coords = tCoords,
                name = ped.PlayerData.charinfo.firstname .. " " .. ped.PlayerData.charinfo.lastname,
                citizenid = ped.PlayerData.citizenid,
                sourceplayer = ped.PlayerData.source,
                bank = ped.PlayerData.money["bank"],
                job = ped.PlayerData.job.name,
                dist = dist,
            }
        end
    else
        -- if you are using latest esx (1.9)  Core.GetExtendedPlayers()  use this
        for _, v in pairs(Core.GetPlayers()) do
            local ped = Core.GetPlayerFromId(v)
            local targetped = GetPlayerPed(v)
            local tCoords = GetEntityCoords(targetped)
            local dist = #(GetEntityCoords(GetPlayerPed(src)) - tCoords)
            players[#players + 1] = {
                id = v,
                coords = tCoords,
                name = ped.variables.firstName .. " " .. ped.variables.lastName,
                citizenid = ped.identifier,
                sourceplayer = ped.source,
                bank = ped.bank,
                job = ped.job.name,
                dist = dist,
            }
        end
    end

    return players
end)

lib.callback.register("src-farm:getinfo", function(_, cb)
    local data = json.decode(LoadResourceFile(ResourceName, jsonPath))
    return data
end)

RegisterNetEvent("src-billing:paybill", function(data)
    local file = LoadResourceFile(GetCurrentResourceName(), "data.json")

    if file then
        local src = source
        local jsonData = json.decode(file)
        local nameFromData = data

        if Config.Core == "qb" then
            local ped = Core.Functions.GetPlayer(src)
            local bank = tonumber(ped.PlayerData.money["bank"])
            local billAmount = tonumber(data.amount)

            if bank > billAmount then
                RemoveMoney(src, "bank", billAmount)
                exports["qb-management"]:AddMoney(data.job, billAmount)
                SendDiscord(data, Config.Webhook.PayBill, 2)

                for i, fieldData in ipairs(jsonData) do
                    if fieldData.id == nameFromData.id then
                        fieldData.status = "paid"
                        break
                    end
                end

                local updatedJsonData = json.encode(jsonData)
                SaveResourceFile(GetCurrentResourceName(), "data.json", updatedJsonData, -1)

                TriggerClientEvent("src-farm:receivejson", -1)
                GetJson()

                notif = {
                    id = "billid",
                    title = "BILL NOTIFY",
                    description = "You Paid : $ " .. data.amount,
                    position = "top-right",
                    style = {
                        backgroundColor = "green",
                        color = "white",
                        [".description"] = {
                            color = "white"
                        }
                    },
                    icon = "check",
                    iconColor = "white"
                }
                TriggerClientEvent("ox_lib:notify", src, notif)
            end
        else
            local ped = Core.GetPlayerFromId(src)
            local bank = tonumber(ped.getAccount("bank").money)
            local billAmount = tonumber(data.amount)

            if bank > billAmount then
                RemoveMoney(src, "bank", billAmount)
                TriggerEvent("esx_society:depositMoney:src-billing", nameFromData.job, billAmount)
                SendDiscord(data, Config.Webhook.PayBill, 2)

                for i, fieldData in ipairs(jsonData) do
                    if fieldData.id == nameFromData.id then
                        fieldData.status = "paid"
                        break
                    end
                end

                local updatedJsonData = json.encode(jsonData)
                SaveResourceFile(GetCurrentResourceName(), "data.json", updatedJsonData, -1)

                TriggerClientEvent("src-farm:receivejson", -1)
                GetJson()

                notif = {
                    id = "billid",
                    title = "BILL NOTIFY",
                    description = "You Paid : $ " .. data.amount,
                    position = "top-right",
                    style = {
                        backgroundColor = "green",
                        color = "white",
                        [".description"] = {
                            color = "white"
                        }
                    },
                    icon = "check",
                    iconColor = "white"
                }
                TriggerClientEvent("ox_lib:notify", src, notif)
            end
        end
    end
end)

RegisterNetEvent("src-billing:deleteBill", function(data)
    local file = LoadResourceFile(GetCurrentResourceName(), "data.json")

    if file then
        local src = source
        local jsonData = json.decode(file)
        local nameFromData = data.data

        for i, fieldData in ipairs(jsonData) do
            if fieldData.id == nameFromData.id then
                table.remove(jsonData, i)
                break
            end
        end

        local updatedJsonData = json.encode(jsonData)
        SaveResourceFile(GetCurrentResourceName(), "data.json", updatedJsonData, -1)
        SendDiscord(nameFromData, Config.Webhook.DeleteBil, 3)

        TriggerClientEvent("src-farm:receivejson", -1)
        GetJson()

        notif = {
            id = "billid",
            title = "BILL NOTIFY",
            description = "You successfully deleted bill. Bill ID: " .. nameFromData.id,
            position = "top-right",
            style = {
                backgroundColor = "red",
                color = "white",
                [".description"] = {
                    color = "white"
                }
            },
            icon = "xmark",
            iconColor = "white"
        }
        TriggerClientEvent("ox_lib:notify", src, notif)
    else
        print("data.json dosyası bulunamadı.")
    end
end)

local lastID = 0

RegisterNetEvent("addBill")
AddEventHandler("addBill", function(amount, reason, data, job, author, pid, status)
    local Amount = tonumber(amount)
    local Reason = tostring(reason)
    local currentDateTime = os.date("%Y-%m-%d %H:%M:%S")

    local jsonData = LoadResourceFile(ResourceName, jsonPath)
    local fields = json.decode(jsonData)

    for _, field in ipairs(fields) do
        if field.id and field.id > lastID then
            lastID = field.id
        end
    end

    local newField = {
        id = lastID + 1,
        amount = Amount,
        reason = Reason,
        name = data.name,
        citizenid = data.citizenid,
        date = currentDateTime,
        job = job,
        author = author,
        status = status
    }

    SendDiscord(newField, Config.Webhook.SendBill, 1)

    table.insert(fields, newField)

    local encodedData = json.encode(fields)
    SaveResourceFile(ResourceName, jsonPath, encodedData, -1)
    TriggerClientEvent("src-farm:receivejson", -1)
    GetJson()

    notif = {
        id = "billid",
        title = "BILL NOTIFY",
        description = "Price: $" .. amount .. " | Reason: " .. reason,
        position = "top-right",
        style = {
            backgroundColor = "green",
            color = "white",
            [".description"] = {
                color = "white"
            }
        },
        icon = "ban",
        iconColor = "white"
    }

    TriggerClientEvent("ox_lib:notify", pid, notif)
end)

RegisterNetEvent("src-billing:getjson")
AddEventHandler("src-billing:getjson", function()
    local info = json.decode(LoadResourceFile(ResourceName, jsonPath))
    TriggerClientEvent("src-farm:receivejson", -1, info)
end)

function GetJson()
    local info = json.decode(LoadResourceFile(ResourceName, jsonPath))
    TriggerClientEvent("src-farm:receivejson", -1, info)
end

local function CheckVersion()
    PerformHttpRequest(
        "https://raw.githubusercontent.com/dollar-src/src-billing/main/version.txt",
        function(err, newestVersion, headers)
            local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version")
            if not newestVersion then
                print("Probably GitHub down, follow updates on discord: discord.gg/tebex")
                return
            end
            local advice = "^6You are currently running an outdated version^7, ^0please update"
            if newestVersion:gsub("%s+", "") == currentVersion:gsub("%s+", "") then
                advice = "^6You are running the latest version."
            else
                if currentVersion > newestVersion then
                    advice = "^6You are running the latest version."
                else
                    print("^3Version Check^7: ^2Current^7: " .. currentVersion .. " ^2Latest^7: " .. newestVersion)
                end
            end
            print(advice)
        end
    )
end

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CheckVersion()
    end
end)

function SendDiscord(data, webhook, state)
    local log = {
        {
            author = {
                name = "",
                icon_url = "",
                url = "https://discord.gg/tebex"
            },
            fields = {
                {
                    name = "Receiver Name",
                    value = "**" .. data.name .. "**",
                    inline = false
                },
                {
                    name = "Sender Name",
                    value = "**" .. data.author .. "**",
                    inline = true
                },
                {
                    name = "Price",
                    value = "**" .. data.amount .. "**",
                    inline = false
                },
                {
                    name = "Reason",
                    value = "**" .. data.reason .. "**",
                    inline = false
                },
                {
                    name = "Job",
                    value = "**" .. data.job .. "**",
                    inline = false
                },
                {
                    name = "Date",
                    value = "**" .. data.date .. "**",
                    inline = true
                },
                {
                    name = "Github",
                    value = "https://github.com/dollar-src",
                    inline = true
                }
            },
            thumbnail = {
                url = "https://avatars.cloudflare.steamstatic.com/0698ae9b5b24c98eebf677685eb0799ce24084d4_full.jpg"
            },
            color = state == 1 and 15741599 or (state == 2 and 65280 or 15728640)
        }
    }

    PerformHttpRequest(
        webhook,
        function(err, text, headers)
        end,
        "POST",
        json.encode(
            {
                username = state == 1 and "BILL SENT" or (state == 2 and "PAID" or "BILL DELETED"),
                embeds = log,
                avatar_url = "https://avatars.cloudflare.steamstatic.com/0698ae9b5b24c98eebf677685eb0799ce24084d4_full.jp"
            }
        ),
        {["Content-Type"] = "application/json"}
    )
end
