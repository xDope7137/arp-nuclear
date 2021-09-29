Framework = nil
TriggerEvent('QBCore:GetObject', function(obj) Framework = obj end)

local hiddencoords = vector3(1272.15, -1711.00, 54.77)
local onDuty = 0

Framework.Functions.CreateCallback('nuclear:getlocation', function(source, cb)
    cb(hiddencoords)
end)

Framework.Functions.CreateCallback('nuclear:getCops', function(source, cb)
    cb(getCops())
end)

function getCops()
    local Players = Framework.Functions.GetPlayers()
    onDuty = 0
    return 5
end

RegisterServerEvent("nuclear:GiveItem")
AddEventHandler("nuclear:GiveItem", function(x, y, z)
    local src = source
    local Player = Framework.Functions.GetPlayer(src)
    Player.Functions.AddItem('nuclear', 10)
    TriggerClientEvent('inventory:client:ItemBox', src, Framework.Shared.Items['nuclear'], "add")
end)

RegisterNetEvent('nuclear:updatetable')
AddEventHandler('nuclear:updatetable', function(bool)
    TriggerClientEvent('nuclear:synctable', -1, bool)
end)

RegisterServerEvent("nuclear:syncMission")
AddEventHandler("nuclear:syncMission", function(missionData)
    local missionData = missionData
    TriggerClientEvent('nuclear:syncMissionClient', -1, missionData)
end)

RegisterServerEvent("nuclear:delivery")
AddEventHandler("nuclear:delivery", function()
    local src = source
    local Player = Framework.Functions.GetPlayer(src)
    local check = Player.Functions.GetItemByName('nuclear').amount

    if check >= 1 then
        Player.Functions.RemoveItem('nuclear', 1)
        Player.Functions.AddMoney('cash', Config.reward)
        TriggerClientEvent('XD:Notify', src, "You received ".. Config.reward .." for your job.", "success", 3500)
    elseif Config.useNotification then
        TriggerClientEvent('XD:Notify', src, "You have no nuclear files left.", "success", 3500)
    end
end)



