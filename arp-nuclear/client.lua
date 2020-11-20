ARPCore = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        if ARPCore == nil then
            TriggerEvent('ARPCore:GetObject', function(obj) ARPCore = obj end)
            Citizen.Wait(200)
        end
    end
end)


local enemyblips = {}
local coords
local requiredItemsShowed = false
local usedItem = false
local active = false
local blip
local cleanDead
local enroute
local radius
local marker
local enemies = {}
local box2
local inUse = false
local location = nil
local rand

if not Config.hideBlip then
	Citizen.CreateThread(function()
		while not coords do
			Citizen.Wait(1000)
		end
		marker = AddBlipForCoord(coords.x, coords.y, coords.z)	
		SetBlipSprite(marker, Config.blipSprite)
		SetBlipScale(marker, 0.9)      
	    SetBlipAsShortRange(marker, true)
	    BeginTextCommandSetBlipName("STRING")
	    EndTextCommandSetBlipName(marker)
	    SetBlipColour(marker, 4)
	    if Config.hideBlip then
			RemoveBlip(marker)
		end
	end)
end

Citizen.CreateThread(function()
	while ARPCore == nil do TriggerEvent('ARPCore:GetObject', function(obj) ARPCore = obj end) Wait(0) end
   ARPCore.Functions.TriggerCallback('nuclear:getlocation', function(servercoords)
        coords = servercoords
	end)
end)

RegisterNetEvent('nuclear:synctable')
AddEventHandler('nuclear:synctable', function(bool)
    inUse = bool
end)

Citizen.CreateThread(function()
	while not coords do
		Citizen.Wait(1000)
	end
	local sleep
	while true do
		sleep = 5
		local player = GetPlayerPed(-1)
		local playercoords = GetEntityCoords(player)
		local dist = #(vector3(playercoords.x, playercoords.y, playercoords.z)-vector3(coords.x, coords.y, coords.z))
		local inRange = false
	
		if ARPCore ~= nil then
			local requiredItems = {
				[1] = {name = ARPCore.Shared.Items["bluechip"]["name"], image = ARPCore.Shared.Items["bluechip"]["image"]},
			}

		if not inUse then
			if dist <= 1.3 then										 	
				DrawText3Ds(coords.x, coords.y, coords.z, '[E] - Decipher Nuclear Location')
				if IsControlJustPressed(0, 51) then
					ARPCore.Functions.TriggerCallback('ARPCore:HasItem', function(result)
						if result then
							decipherAnim()
							TriggerEvent("mhacking:show")
                                            TriggerEvent("mhacking:start", math.random(5, 7), math.random(20, 35), OnHackDone)
							--main()
					else
						ARPCore.Functions.Notify("You need blue encryption chip.", "error")
						inUse = false
						end
				end, 'bluechip')
				Citizen.Wait(10700)									
			end			
		if not requiredItemsShowed then
		requiredItemsShowed = true
		TriggerEvent('inventory:client:requiredItems', requiredItems, true)
			end
		else
			if requiredItemsShowed then
			requiredItemsShowed = false
			TriggerEvent('inventory:client:requiredItems', requiredItems, false)
		end			
			end
		elseif dist <= 1.3 and inUse then			
			sleep = 5
			DrawText3Ds(coords.x, coords.y, coords.z, 'Already Started')
		else
			if requiredItemsShowed then
				requiredItemsShowed = false
				TriggerEvent('inventory:client:requiredItems', requiredItems, false)
			end
			sleep = 3000
		end
		Citizen.Wait(sleep)
	end
end
end)


RegisterNetEvent('nuclear:syncMissionClient')
AddEventHandler('nuclear:syncMissionClient', function(missionData)
  locations = missionData
  inUse = missionData
end)

function OnHackDone(success, timeremaining)
    if success then
        TriggerEvent('mhacking:hide')
        main()
    else
		TriggerEvent('mhacking:hide')
	end
end

function main()
	TriggerServerEvent('nuclear:updatetable', true)
	inUse = true
	rand = math.random(1,#Config.locations)
	location = Config.locations[rand]
	SetNewWaypoint(location.addBlip.x,location.addBlip.y)
	addBlip(location.addBlip.x,location.addBlip.y,location.addBlip.z)
	if Config.useNotification then
		ARPCore.Functions.Notify("Go to the highlighted area to search for the crate.", "error", 2500)
	end
	local player = GetPlayerPed(-1)
	local playerpos
	enroute = true
	local howmany
	Citizen.CreateThread(function()
		while enroute == true do
			Citizen.Wait(200)
			playerpos = GetEntityCoords(player)
			local disttocoord = #(vector3(location.enemy.x, location.enemy.y, location.enemy.z)-vector3(playerpos.x,playerpos.y,playerpos.z))
			if disttocoord < Config.distance then
				if Config.useNotification then
					ARPCore.Functions.Notify("Kill all the enemies to steal.", "error", 2500)
				end
				spawnPed(location.enemy.x,location.enemy.y,location.enemy.z)
				enroute = false
				if Config.removeArea then
					RemoveBlip(radius)
				end			
				return
			else
				Citizen.Wait(1000)
			end
		end
	end)
	Citizen.CreateThread(function()
		while inUse do
			playerpos = GetEntityCoords(player)												
			local disttocoord = #(vector3(location.enemy.x, location.enemy.y, location.enemy.z)-vector3(playerpos.x,playerpos.y,playerpos.z))
			if IsEntityDead(player) then
				Citizen.Wait(1000)
				clearmission()
				return
			else
				howmany = checkisdead()
				if howmany == Config.enemies then
					Citizen.Wait(2000)
					clearmission()
					success(location.crate.x, location.crate.y, location.crate.z, location.crate.h)
				end	
				if disttocoord > Config.maxDistance and not enroute then
					ARPCore.Functions.Notify("You went far away from the location.", "error", 2500)
					maxDist()
					return
				end
			end
			Citizen.Wait(1000)
		end
	end)
	if Config.printRemaining then
		Citizen.CreateThread(function()
			local sleep = 5
			while inUse do
				if not enroute then
					sleep = 5
					DrawText2D("Enemies Killed: "..howmany,0,1,0.5,0.92,0.6,255,255,255,255)
				else
					sleep = 1000
				end
				Citizen.Wait(sleep)
			end
		end)
	end
end

function maxDist()
	inUse = false
	TriggerServerEvent('nuclear:updatetable', false)
	RemoveBlip(radius)
	RemoveBlip(blip)
	usedItem = false
	active = false
	for a = 1, #enemies do
		if DoesEntityExist(enemies[a]) then
			DeleteEntity(enemies[a])
		end
	end
end

function success(x,y,z,h)
	local box = GetHashKey(Config.boxProp)
	box2 = CreateObject(box, x,y,z-1, true, true, false)
	local crate = false
	local player = GetPlayerPed(-1)
	if Config.useNotification then
		ARPCore.Functions.Notify("Search for the nuclear files.", "error", 2500)
	end
	FreezeEntityPosition(box2, true)
	SetEntityHeading(box2, h)
	Citizen.CreateThread(function()
		while not crate do 
			local sleep = 5
			local playercoords = GetEntityCoords(player)
			local disttocoord = #(vector3(x,y,z)-vector3(playercoords.x, playercoords.y, playercoords.z))
			if disttocoord <= 3 then
				sleep = 5
				DrawText3Ds(x, y, z, '[E] - Search Crate')
				if IsControlJustPressed(1, 51) then
					crate = true
					TaskTurnPedToFaceEntity(player, box2, 5500)
					FreezeEntityPosition(GetPlayerPed(-1), true)
					playAnim("anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 6000)
					Citizen.Wait(5000)
					DoScreenFadeOut(1000)
					Citizen.Wait(1500)
					DoScreenFadeIn(2000)
					FreezeEntityPosition(GetPlayerPed(-1), false)
					DeleteEntity(box2)
					if Config.useNotification then
						ARPCore.Functions.Notify("You received nuclear files. Now get to safety.", "error", 2500)
					end
					TriggerServerEvent('nuclear:GiveItem', location.crate.x, location.crate.y, location.crate.z, location.crate.h)
					Citizen.Wait(2000)
					Config.locations[rand]['active'] = false
					TriggerServerEvent('nuclear:syncMission', locations)
				end
			else
				sleep = 1200
			end
			Citizen.Wait(sleep)
		end
	end)
end

Citizen.CreateThread(function()
	while true do
		sleep = 5
		local player = GetPlayerPed(-1)
		local playercoords = GetEntityCoords(player)
		local disttocoord = #(vector3(2475.588, -384.1472, 94.39928)-vector3(playercoords.x, playercoords.y, playercoords.z))
		if disttocoord < 3 then
			DrawText3Ds(2475.588, -384.1472, 94.39928, '[E] - Sell Nuclear Files')
			if IsControlJustPressed(1, 51) then
				TriggerServerEvent('nuclear:delivery')
				Citizen.Wait(2000)
			end
		else
			sleep = 1500
		end
		Citizen.Wait(sleep)
	end
end)

function decipherAnim()
	local player = GetPlayerPed(-1)
	SetEntityCoords(player, 1272.31, -1711.65, 54.00, 0.0, 0.0, 0.0, false)
	SetEntityHeading(player, 44.4)
	FreezeEntityPosition(player, true)
	if requiredItemsShowed then
		requiredItemsShowed = false
		TriggerEvent('inventory:client:requiredItems', requiredItems, false)
	end		
	ARPCore.Functions.Progressbar("hack", "Deciphering Location", 10500, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
		playAnim('anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 10500)

    }, {}, {}, function() 
	end)-- Done
	
	Citizen.Wait(10500)
	FreezeEntityPosition(player, false)
end

function playAnim(animDict, animName, duration)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do 
      Citizen.Wait(0) 
    end
    TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1.0, duration, 49, 1, false, false, false)
    RemoveAnimDict(animDict)
end

function clearmission()
	inUse = false
	TriggerServerEvent('nuclear:updatetable', false)
	RemoveBlip(radius)
	RemoveBlip(blip)
	usedItem = false
	active = false
	if Config.cleanDead then
		for a = 1, #enemies do
			if DoesEntityExist(enemies[a]) then
				DeleteEntity(enemies[a])
			end
		end
	end
end

function checkisdead()
	local dead = 0
	for a = 1, #enemies do
		if IsEntityDead(enemies[a]) then
			dead = dead + 1
		end
	end
	return dead
end

function addBlip(x,y,z)
	radius = AddBlipForRadius(x, y, z, Config.radius)
	blip = AddBlipForCoord(x, y, z)
	SetBlipSprite(blip, 433)
	SetBlipColour(blip, 1)
	SetBlipHighDetail(radius, true)
	SetBlipColour(radius, 1)
	SetBlipAlpha (radius, 128)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString('Mission')
	EndTextCommandSetBlipName(blip)
end

function spawnPed(x,y,z)
	local hashKey = "mp_m_bogdangoon"
	RequestModel(hashKey)
    while not HasModelLoaded(hashKey) do
        RequestModel(hashKey)
        Citizen.Wait(100)
	end	

	ARPCore.Functions.TriggerCallback("nuclear:getCops", function(getCops)
		if Config.waypoint then 
    		SetNewWaypoint(x, y)
    	end
		for i=1,Config.enemies do
			local rnum = math.random(10,50)
			local pick = math.random(1,5)
			local wep
			local enemy

			if getCops >= Config.amountCop then
				if pick == 1 then
					enemy = CreatePed(4, hashKey, x+rnum, y+rnum, z, 100.0, true, true)
					wep = GetHashKey(Config.difficulty1_1)
				elseif pick == 2 then
					enemy = CreatePed(4, hashKey, x+rnum, y+rnum, z, 100.0, true, true)
					wep = GetHashKey(Config.difficulty1_2)
				elseif pick == 3 then
					enemy = CreatePed(4, hashKey, x+rnum, y+rnum, z, 100.0, true, true)
					wep = GetHashKey(Config.difficulty1_3)
				elseif pick == 4 then
					enemy = CreatePed(4, hashKey, x+rnum, y+rnum, z, 100.0, true, true)
					wep = GetHashKey(Config.difficulty1_4)
				else 
					enemy = CreatePed(4, hashKey, x+rnum, y+rnum, z, 100.0, true, true)
					wep = GetHashKey(Config.difficulty1_5)
				end

			elseif getCops < Config.amountCop then
				if pick == 1 then
					enemy = CreatePed(4, hashKey, x+rnum, y+rnum, z, 100.0, true, true)
					wep = GetHashKey(Config.difficulty2_1)
				elseif pick == 2 then
					enemy = CreatePed(4, hashKey, x+rnum, y+rnum, z, 100.0, true, true)
					wep = GetHashKey(Config.difficulty2_t2)
				elseif pick == 3 then
					enemy = CreatePed(4, hashKey, x+rnum, y+rnum, z, 100.0, true, true)
					wep = GetHashKey(Config.difficulty2_3)
				elseif pick == 4 then
					enemy = CreatePed(4, hashKey, x+rnum, y+rnum, z, 100.0, true, true)
					wep = GetHashKey(Config.difficulty2_4)
				else 
					enemy = CreatePed(4, hashKey, x+rnum, y+rnum, z, 100.0, true, true)
					wep = GetHashKey(Config.difficulty2_5)
				end
			end

			AddRelationshipGroup("enemies")
			SetPedRelationshipGroupHash(enemy, GetHashKey("enemies"))
			SetPedRelationshipGroupHash(GetPlayerPed(-1), GetHashKey("PLAYER"))
			SetRelationshipBetweenGroups(5, GetHashKey("enemies"), GetHashKey("PLAYER"))
    		SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("enemies"))
			SetRelationshipBetweenGroups(1, GetHashKey("enemies"), GetHashKey("enemies"))
			GiveWeaponToPed(enemy, wep, 500, false, true)
			SetPedCombatAttributes(enemy, 46, true)
			SetPedCombatAbility(enemy, 100)
			SetPedCombatMovement(enemy, 2)
			SetPedCombatRange(enemy, 2)
			SetEntityMaxHealth(enemy, Config.enemyHealth)
			SetEntityHealth(enemy, Config.enemyHealth)
			SetPedAccuracy(enemy, Config.enemyAcc)
			SetPedDropsWeaponsWhenDead(enemy, false)
			table.insert(enemies, enemy)
			if Config.enemyVest then
				SetPedArmour(enemy, Config.enemyArmor)
			end		
		end
	end)
end

function DrawText3Ds(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function DrawText2D(text,font,centre,x,y,scale,r,g,b,a)
	SetTextFont(6)
	SetTextProportional(6)
	SetTextScale(scale/1.0, scale/1.0)
	SetTextColour(r, g, b, a)
	SetTextDropShadow(0, 0, 0, 0,255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(centre)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end
