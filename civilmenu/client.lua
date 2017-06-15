--
-- Created by IntelliJ IDEA.
-- User: Djyss
-- Date: 09/05/2017
-- Time: 09:55
-- To change this template use File | Settings | File Templates.
--




local options = {
    x = 0.1,
    y = 0.2,
    width = 0.2,
    height = 0.04,
    scale = 0.4,
    font = 0,
    menu_title = "Menu personnel",
    menu_subtitle = "Categories",
    color_r = 51,
    color_g = 51,
    color_b = 102,
}


------------------------------------------------------------------------------------------------------------------------

-- Base du menu
function PersonnalMenu()
    options.menu_subtitle = "CATEGORIES" 
    options.rightText = "1/4"  
    ClearMenu()
    Menu.addButton("Animations", "animsMenu", nil)
    Menu.addButton("Inventaire", "inventoryMenu", nil)
    Menu.addButton("GPS", "gps", nil)    
    Menu.addButton("Ma carte d'identité", "identite", nil)
    Menu.addButton("Téléphone", "phoneMenu", nil)
end

--------------------------------------------------- NUI CALLBACKS ------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

RegisterNetEvent('phone:unreaded')
AddEventHandler('phone:unreaded', function()
    SendNUIMessage({unreaded = true})
end)
RegisterNetEvent('phone:nbMsgUnreaded')
AddEventHandler('phone:nbMsgUnreaded', function(counter)
    SendNUIMessage({nbMsgUnreaded = counter})
end)

--------------------------------------------------- LISTENER MENU ------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent('phone:setSteamId')
AddEventHandler('phone:setSteamId', function(steam_id)
   current_steam_id = steam_id
end)

RegisterNetEvent('phone:getPhoneNumberOnLoaded')
AddEventHandler('phone:getPhoneNumberOnLoaded', function(number)
    Citizen.Trace(number)
    phone_number = number
end)

RegisterNetEvent('phone:toggleMenu')
AddEventHandler('phone:toggleMenu', function()
    phoneMenu() -- Menu to draw
	Menu.hidden = not Menu.hidden -- Hide/Show the menu
end)

RegisterNetEvent("phone:repertoryGetNumberListFromServer")
AddEventHandler("phone:repertoryGetNumberListFromServer", function(NUMBERSLIST)
    NUMBERS_LIST = {}
    NUMBERS_LIST = NUMBERSLIST
end)

RegisterNetEvent("phone:messageryGetOldMsgFromServer")
AddEventHandler("phone:messageryGetOldMsgFromServer", function(OLDSMSG)
    OLDS_MSG = {}
    OLDS_MSG = OLDSMSG
end)

RegisterNetEvent('phone:notifsNewMsg')
AddEventHandler('phone:notifsNewMsg', function(notif)
    SendNUIMessage({unreaded = true})
    PlaySound(-1, "Menu_Accept", "Phone_SoundSet_Default", 0, 0, 1)
    notifs( notif )
end)

RegisterNetEvent('phone:readMsg')
AddEventHandler('phone:readMsg', function(msg)
    SendNUIMessage({read = true, by = msg.by, msg = msg.msg})
end)

RegisterNetEvent('phone:deleteUnreaded')
AddEventHandler('phone:deleteUnreaded', function(msg)
    SendNUIMessage({deleteUnreaded = true})
end)

RegisterNetEvent('phone:closeMsg')
AddEventHandler('phone:closeMsg', function()
    SendNUIMessage({closeRead = true})
end)

RegisterNetEvent("phone:notifs")
AddEventHandler("phone:notifs", function(msg)
    notifs(msg)
end)

--------------------------------------------------- BASE MENU ----------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function phoneMenu()
    TriggerServerEvent("phone:repertoryGetNumberList")
    TriggerServerEvent("phone:messageryGetOldMsg")
    options.menu_subtitle = "CATEGORIES" 
    ClearMenu()
    if not IsEntityDead(GetPlayerPed(-1)) then
        Menu.addButton("Repertoire", "repertoryMenu", nil)
        Menu.addButton("Messagerie", "messageryMenu", nil)
    end
    Menu.addButton("Services public", "publicMenu", nil)
    if not IsEntityDead(GetPlayerPed(-1)) then
        Menu.addButton("Vider la mémoire", "cleanMemoryMenu", nil)
    end
    Menu.addButton("Ranger le téléphone", "closePhone", nil)
end

function closePhone()
    Menu.hidden = not Menu.hidden
end
------------------------------------------------ REPERTORY MENU --------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

------- REPERTORY MENU -----------
function repertoryMenu()
    options.menu_subtitle = "Repertoire"
    ClearMenu()
    Menu.addButton("Ajouter un numéro", "newNumero", nil )
    Menu.addButton('Retour', 'phoneMenu', nil )
    for ind, value in pairs(NUMBERS_LIST) do
        Menu.addButton(value.name, "repertoryContact", value.identifier)
    end
end

------- ADD NUMBER ------------
function newNumero()
    DisplayOnscreenKeyboard(2, "FMMC_KEY_TIP8", '', '', '', '', '', 11)
    while (UpdateOnscreenKeyboard() == 0) do
        DisableAllControlActions(0);
        Wait(0);
    end
    if (GetOnscreenKeyboardResult()) then
        local result = GetOnscreenKeyboardResult()
        TriggerServerEvent("phone:addNewNumero", result)
        phoneMenu()
    end
end

------- CONTACT MENU ----------
function repertoryContact(contact)
    options.menu_subtitle = 'Repertoire'
    ClearMenu()
    Menu.addButton('Afficher le numéro', 'checkContact', contact )
    Menu.addButton('Envoyer un message', 'writeMsg', contact )
    Menu.addButton('Supprimer', 'deleteContact', contact )
    Menu.addButton('Retour', 'repertoryMenu', nil )

end

---- CONTACT MENU ACTIONS -----
function checkContact(contact)
    TriggerServerEvent("phone:checkContactServer", {identifier = contact})
end

function writeMsg(receiver)
    DisplayOnscreenKeyboard(2, "FMMC_KEY_TIP8", "(250 characters max)", "", "", "", "", 250)
    while (UpdateOnscreenKeyboard() == 0) do
        DisableAllControlActions(0);
        Wait(0);
    end
    if (GetOnscreenKeyboardResult()) then
        local result = GetOnscreenKeyboardResult()
        local msg = {
            receiver = receiver,
            msg = result
        }
        TriggerServerEvent("phone:sendNewMsg", msg)
        phoneMenu()
    end
end

function deleteContact(contact)
    TriggerServerEvent("phone:deleteContact", contact)
    phoneMenu()
end

------------------------------------------------ MESSAGERY MENU --------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

------- MESSAGERY MENU --------
function messageryMenu()
    options.menu_subtitle = "Messagerie"
    ClearMenu()
    Menu.addButton("Supprimer tout", "deleteAll", nil )
    Menu.addButton("Retour", "phoneMenu", nil )
    for ind, value in pairs(OLDS_MSG) do
        local n = ""
        if value.has_read == 0 then
            n = " - ~r~Non lu"
        end
        Menu.addButton(value.name .. " " .. n, "msgMenu", {msg = value.msg, name = value.name, date= value.date, has_read = value.has_read, receiver_id = value.receiver_id, owner_id = value.owner_id})
    end
end

------- ONE MESSAGE MENU --------
function msgMenu(msg)

    TriggerServerEvent("phone:messageryGetOldMsg")
    options.menu_subtitle = "Message de "..msg.name
    ClearMenu()
    Citizen.Trace(json.encode(msg))

    Menu.addButton("Lire", "readMsg", {msg = msg.msg, name = msg.name, date= msg.date, has_read = msg.has_read, receiver_id = msg.receiver_id})
    Menu.addButton("Répondre", "respondTo", msg.owner_id)
    Menu.addButton("Supprimer", "deleteMsg", {msg = msg.msg, name = msg.name, date= msg.date, has_read = msg.has_read, receiver_id = msg.receiver_id, owner_id = msg.owner_id})
    Menu.addButton("Retour", "messageryMenu", nil )
end

------- MESSAGE ACTIONS --------
function readMsg(msg)
    TriggerEvent('phone:readMsg', {by = msg.name, msg = msg.msg})
    options.menu_subtitle = "Message de "..msg.name
    ClearMenu()
    if msg.has_read == 0 then
        TriggerServerEvent("phone:setMsgReaded", msg)
        TriggerEvent('phone:setReaded')
        SendNUIMessage({read = true})
    end
    Menu.addButton("Fermer", "closeMsg", nil)
end

function closeMsg()
    TriggerEvent('phone:closeMsg')
    phoneMenu()
end

function respondTo(contact)
    DisplayOnscreenKeyboard(2, "FMMC_KEY_TIP8", "(250 characters max)", "", "", "", "", 250)
    while (UpdateOnscreenKeyboard() == 0) do
        DisableAllControlActions(0);
        Wait(0);
    end
    if (GetOnscreenKeyboardResult()) then
        local result = GetOnscreenKeyboardResult()
        local msg = {
            receiver = contact,
            msg = result
        }
        TriggerServerEvent("phone:sendNewMsg", msg)
        phoneMenu()
    end
end

function deleteMsg(msg)

    local delmsg = {
        owner = msg.owner_id,
        receiver = msg.receiver_id,
        msg = msg.msg
    }
    TriggerEvent('phone:deleteUnreaded')
    TriggerServerEvent("phone:deleteMsg", delmsg)
    phoneMenu()
end

function deleteAll()
    options.menu_subtitle = "Supprimer tout"
    ClearMenu()
    Menu.addButton("Oui", "deleteAllAction", nil)
    Menu.addButton("Non", "messageryMenu", nil )
end

function deleteAllAction()
    TriggerServerEvent('phone:deleteAllMsg')
    phoneMenu()
end

------------------------------------------------ PUBLIC CALLS MENU -----------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--------- PUBLIC CALLS MENU ------
function publicMenu()
    options.menu_subtitle = "Services public"
    ClearMenu()
    Menu.addButton("Police", "callPolice", nil)
    Menu.addButton("Médecins", "callMedics", nil)
    Menu.addButton("Dépanneur", "callTroubleshooters", nil)
    Menu.addButton("Taxi", "callTaxis", nil)
    Menu.addButton("Retour", "phoneMenu", nil )
end

---------- POLICE CALL EVENT -----
function callPolice()
    options.menu_subtitle = "Appel police"
    ClearMenu()
    Menu.addButton("Signaler un vol", "callPoliceAction", {fn= "police:callPolice", type = 'vole'})
    Menu.addButton("Signaler une aggression", "callPoliceAction", {fn= "police:callPolice", type = 'aggression'})
    Menu.addButton("Raison personnalisée", "callPoliceAction", {fn= "police:callPoliceCustom", type = nil})
    Menu.addButton("Annuler mon appel", "callPoliceAction", {fn= "police:cancelCall", type = nil})
    Menu.addButton("Retour", "phoneMenu", nil )
end

function callPoliceAction(arg)
    TriggerEvent(arg.fn, {type = arg.type})
    publicMenu()
end

---------- MEDICS CALL EVENT -----
function callMedics()
    options.menu_subtitle = "Medecins"
    ClearMenu()
    Menu.addButton("Appel Coma", "callMedicsAction", {type= 'Coma', fn='ambulancier:callAmbulancier'})
    Menu.addButton("Appel Ambulancier", "callMedicsAction", {type='Demande', fn='ambulancier:callAmbulancier'})
    Menu.addButton("Respawn", "callMedicsAction", {type=nil, fn='ambulancier:selfRespawn'})
    Menu.addButton("Annuler mon appel", "callMedicsAction", {type=nil, fn='ambulancier:cancelCall'})
    Menu.addButton("Retour", "phoneMenu", nil )
end

function callMedicsAction(arg)
    TriggerEvent(arg.fn, {type = arg.type})
    publicMenu()
end

----- TROUBLESHOOTERS CALL EVENT -----
function callTroubleshooters()
    options.menu_subtitle = "Depanneurs"
    ClearMenu()
    Menu.addButton("Moto", "callTroubleshootersAction", {type="moto", fn="mecano:callMecano"})
    Menu.addButton("Voiture", "callTroubleshootersAction", {type="voiture", fn="mecano:callMecano"})
    Menu.addButton("Camionnette", "callTroubleshootersAction", {type="camionnette", fn="mecano:callMecano"})
    Menu.addButton("Camion", "callTroubleshootersAction", {type="camion", fn="mecano:callMecano"})
    Menu.addButton("Annuler mon appel", "callTroubleshootersAction", {type=nil, fn="mecano:cancelCall"})
    Menu.addButton("Retour", "phoneMenu", nil )
end

function callTroubleshootersAction(arg)
    TriggerEvent(arg.fn, {type = arg.type})
    publicMenu()
end

----- TAXIS CALL EVENT -----
function callTaxis()
    options.menu_subtitle = "Taxis"
    ClearMenu()
    Menu.addButton("1 personne", "callTaxisAction", {type="1 personne", fn="taxi:callService"})
    Menu.addButton("2 personne", "callTaxisAction", {type="2 personne", fn="taxi:callService"})
    Menu.addButton("3 personne", "callTaxisAction", {type="3 personne", fn="taxi:callService"})
    Menu.addButton("Annuler mon appel", "callTaxisAction", {type=nil, fn="taxi:cancelCall"})
    Menu.addButton("Retour", "phoneMenu", nil )
end
function callTaxisAction(arg)
    TriggerEvent(arg.fn, {type = arg.type})
    publicMenu()
end

------------------------------------------------ RESET PHONE MENU ------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function cleanMemoryMenu()
    options.menu_subtitle = "Vider la memoire"
    ClearMenu()
    Menu.addButton("Oui", "cleanMemoryMenuAction", nil)
    Menu.addButton("Non", "phoneMenu", nil )
end

function cleanMemoryMenuAction()
    TriggerServerEvent('phone:resetPhone')
end

--------------------------------------------------------------------------------------------------------
function openGuiIdentity(data)
  --SetNuiFocus(true)
  TriggerServerEvent('gc:openMeIdentity')
  menuIsOpen = 1
end

function montrecarte()
  --SetNuiFocus(true)
  TriggerServerEvent('gc:openIdentity', GetPlayerServerId(p))
end

function identite()
    options.menu_subtitle = "Carte d identite"
    options.rightText = "4/4"  
    ClearMenu()
    Menu.addButton("Voir ma carte d'identite", "openGuiIdentity", nil )
	--Menu.addButton("Montrer ma carte", "montrecarte", nil )
    Menu.addButton("Retour", "PersonnalMenu", nil )
end

function gps()
	options.menu_subtitle = "GPS"
    options.rightText = "3/4"  	
    ClearMenu()
    Menu.addButton("Pole emploi", "poleemploi", nil )
    Menu.addButton("Concessionnaire", "concepoint", nil )
    Menu.addButton("Comissariat", "comico", nil )    
    Menu.addButton("Retour", "PersonnalMenu", nil )    
end	

function poleemploi()
	x, y, z = -266.775268554688, -959.946960449219, 31.2197742462158
	SetNewWaypoint(x, y, z)
end

function concepoint()
	x, y, z = -34.2844390869141, -1101.75170898438, 26.4223537445068
	SetNewWaypoint(x, y, z)
end

function comico()
	x, y, z = 462.319854736328, -989.413513183594, 24.9148712158203
	SetNewWaypoint(x, y, z)
end

function medic()
	BLIP_EMERGENCY = AddBlipForCoord(x, y, z)

	SetBlipSprite(BLIP_EMERGENCY, 2)
	SetNewWaypoint(x, y)

	SendNotification(txt[lang]['gps'])

	Citizen.CreateThread(
		function()
			local isRes = false
			local ped = GetPlayerPed(-1);
			while not isRes do
				Citizen.Wait(0)

				if (GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)), x,y,z, true)<3.0) then
						DisplayHelpText(txt[lang]['res'])
						if (IsControlJustReleased(1, Keys['E'])) then
							TaskStartScenarioInPlace(ped, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
							Citizen.Wait(8000)
							ClearPedTasks(ped);
	            TriggerServerEvent('es_em:sv_resurectPlayer', sourcePlayerInComa)
	            isRes = true
	          end
				end
			end
	end)
end

------------------------------------------------------------------------------------------------------------------------

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsPedUsingAnyScenario(GetPlayerPed(-1)) then
            if IsControlJustPressed(1, 34) or IsControlJustPressed(1, 32) or IsControlJustPressed(1, 8) or IsControlJustPressed(1, 9) then
                ClearPedTasks(GetPlayerPed(-1))
            end
        end

    end
end)

function animsMenu()
    options.menu_subtitle = "Animations"
    options.rightText = "2/4"  
    ClearMenu()
	Menu.addButton("Avoir peur ", "animsAction", { lib = "amb@code_human_cower_stand@female@idle_a", anim = "idle_c" })    
    Menu.addButton("Calme toi ", "animsAction", { lib = "gestures@m@standing@casual", anim = "gesture_easy_now" })    
    Menu.addButton("Dire bonjour", "animsAction", { lib = "gestures@m@standing@casual", anim = "gesture_hello" })
    Menu.addButton("Doigt d'honneur", "animsAction", { lib = "mp_player_int_upperfinger", anim = "mp_player_int_finger_01_enter" })      
    Menu.addButton("Faire des pompes", "animsActionScenario", { anim = "WORLD_HUMAN_PUSH_UPS" })
    Menu.addButton("Enlacer", "animsAction", { lib = "mp_ped_interaction", anim = "kisses_guy_a" })          
    Menu.addButton("Faire du yoga", "animsActionScenario", { anim = "WORLD_HUMAN_YOGA" })
    Menu.addButton("Feliciter", "animsActionScenario", {anim = "WORLD_HUMAN_CHEERING" })
    Menu.addButton("Fumer une clope", "animsActionScenario", { anim = "WORLD_HUMAN_SMOKING" })        
    Menu.addButton("Jouer de la musique", "animsActionScenario", {anim = "WORLD_HUMAN_MUSICIAN" })
    Menu.addButton("Prendre des notes", "animsActionScenario", { anim = "WORLD_HUMAN_CLIPBOARD" })    
    Menu.addButton("S'assoir", "animsActionScenario", { anim = "WORLD_HUMAN_PICNIC" })    
    Menu.addButton("S'assoir (par terre)", "animsActionScenario", { anim = "WORLD_HUMAN_PICNIC" })    	
    Menu.addButton("Serrer la main", "animsAction", { lib = "mp_common", anim = "givetake1_a" })
    Menu.addButton("Se gratter les c**", "animsAction", { lib = "mp_player_int_uppergrab_crotch", anim = "mp_player_int_grab_crotch" })        
    Menu.addButton("Super", "animsAction", { lib = "mp_action", anim = "thanks_male_06" })    
    Menu.addButton("Retour","PersonnalMenu",nil)
end

function animsAction(animObj)
    RequestAnimDict( animObj.lib )
    while not HasAnimDictLoaded( animObj.lib ) do
        Citizen.Wait(0)
    end
    if HasAnimDictLoaded( animObj.lib ) then
        TaskPlayAnim( GetPlayerPed(-1), animObj.lib , animObj.anim ,8.0, -8.0, -1, 0, 0, false, false, false )
    end
end

function animsActionScenario(animObj)
    local ped = GetPlayerPed(-1);

    if ped then
        local pos = GetEntityCoords(ped);
        local head = GetEntityHeading(ped);
        --TaskStartScenarioAtPosition(ped, animObj.anim, pos['x'], pos['y'], pos['z'] - 1, head, -1, false, false);
        TaskStartScenarioInPlace(ped, animObj.anim, 0, false)
        if IsControlJustPressed(1,188) then
        end

    end
end

function animsWithModelsSpawn(object)

    local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(-1), true))

    RequestModel(object.object)
    while not HasModelLoaded(object.object) do
        Wait(1)
    end

    local object = CreateObject(object.object, x, y+2, z, true, true, true)
    -- local vX, vY, vZ = table.unpack(GetEntityCoords(object,  true))

    -- AttachEntityToEntity(object, PlayerId(), GetPedBoneIndex(PlayerId()), vX,  vY,  vZ, -90.0, 0, -90.0, true, true, true, false, 0, true)
    PlaceObjectOnGroundProperly(object) -- This function doesn't seem to work.

end

------------------------------------------------------------------------------------------------------------------------

-- register events, only needs to be done once
RegisterNetEvent("item:reset")
RegisterNetEvent("item:getItems")
RegisterNetEvent("item:updateQuantity")
RegisterNetEvent("item:setItem")
RegisterNetEvent("item:sell")
RegisterNetEvent("gui:getItems")
RegisterNetEvent("player:receiveItem")
RegisterNetEvent("player:looseItem")
RegisterNetEvent("player:sellItem")

ITEMS = {}
local playerdead = false
local maxCapacity = 64

-- handles when a player spawns either from joining or after death
AddEventHandler("playerSpawned", function()
    TriggerServerEvent("item:getItems")
    -- reset player dead flag
    playerdead = false
end)

AddEventHandler("gui:getItems", function(THEITEMS)
    ITEMS = {}
    ITEMS = THEITEMS
end)

AddEventHandler("player:receiveItem", function(item, quantity)
    if (inventoryGetPods() + quantity <= maxCapacity) then
        item = tonumber(item)
        if (ITEMS[item] == nil) then
            inventoryNew(item, quantity)
        else
            inventoryAdd({ item, quantity })
        end
    end
end)

AddEventHandler("player:looseItem", function(item, quantity)
    item = tonumber(item)
    if (ITEMS[item].quantity >= quantity) then
        inventoryDelete({ item, quantity })
    end
end)

AddEventHandler("player:sellItem", function(item, price)
    item = tonumber(item)
    if (ITEMS[item].quantity > 0) then
        inventorySell({ item, price })
    end
end)

-- Menu de l'inventaire
function inventoryMenu()
    ped = GetPlayerPed(-1);
    options.menu_subtitle = "Items  "
    options.rightText = (inventoryGetPods() or 0) .. "/" .. maxCapacity
    ClearMenu()
    for ind, value in pairs(ITEMS) do
        if (value.quantity > 0) then
            Menu.addButton(tostring(value.quantity) .. " " ..tostring(value.libelle), "inventoryItemMenu", ind)
        end
    end
    Menu.addButton("Retour", "PersonnalMenu", ind)
end

function inventoryItemMenu(itemId)
    ClearMenu()
    options.menu_subtitle = "Details "
    Menu.addButton("Utiliser", "use", itemId)
	Menu.addButton("Supprimer 1", "delete", { itemId, 1 })
    Menu.addButton("Donner", "give", itemId)

end

function use(item)
	TriggerServerEvent("player:useItem", item, ITEMS[item].libelle,1)
	Menu.hidden = not Menu.hidden
end

function delete(arg)
    local itemId = tonumber(arg[1])
    local qty = arg[2]
    local item = ITEMS[itemId]
    item.quantity = item.quantity - qty
    NewItems[itemId] = item.quantity
    -- TriggerServerEvent("item:updateQuantity", item.quantity, itemId)
    InventoryMenu()
end


function inventorySell(arg)
    local itemId = tonumber(arg[1])
    local price = arg[2]
    local item = ITEMS[itemId]
    item.quantity = item.quantity - 1
    TriggerServerEvent("item:sell", itemId, item.quantity, price)
    inventoryMenu()
end

function inventoryDelete(arg)
    local itemId = tonumber(arg[1])
    local qty = arg[2]
    local item = ITEMS[itemId]
    item.quantity = item.quantity - qty
    TriggerServerEvent("item:updateQuantity", item.quantity, itemId)
    inventoryMenu()
end

function inventoryAdd(arg)
    local itemId = tonumber(arg[1])
    local qty = arg[2]
    local item = ITEMS[itemId]
    item.quantity = item.quantity + qty
    TriggerServerEvent("item:updateQuantity", item.quantity, itemId)
    InventoryMenu()
end

function inventoryNew(item, quantity)
    TriggerServerEvent("item:setItem", item, quantity)
    TriggerServerEvent("item:getItems")
end

function give(item)
    local player = getNearPlayer()
    if player then
        local res = DisplayInput()
        if (ITEMS[item].quantity - res >= 0) then
            TriggerServerEvent("player:giveItem", item, ITEMS[item].libelle, res, GetPlayerServerId(player))
        end
    end
end

function inventoryGetQuantity(itemId)
    return ITEMS[tonumber(itemId)].quantity
end

function inventoryGetPods()
    local pods = 0
    for _, v in pairs(ITEMS) do
        pods = pods + v.quantity
    end
    return pods
end

function notFull()
    if (inventoryGetPods() < maxCapacity) then return true end
end

function PlayerIsDead()
    -- do not run if already ran
    if playerdead then
        return
    end
    TriggerServerEvent("item:reset")
end

function getPlayers()
    local playerList = {}
    for i = 0, 32 do
        local player = GetPlayerFromServerId(i)
        if NetworkIsPlayerActive(player) then
            table.insert(playerList, player)
        end
    end
    return playerList
end

function getNearPlayer()
    local players = getPlayers()
    local pos = GetEntityCoords(GetPlayerPed(-1))
    local pos2
    local distance
    local minDistance = 3
    local playerNear
    for _, player in pairs(players) do
        pos2 = GetEntityCoords(GetPlayerPed(player))
        distance = GetDistanceBetweenCoords(pos["x"], pos["y"], pos["z"], pos2["x"], pos2["y"], pos2["z"], true)
        if (pos ~= pos2 and distance < minDistance) then
            playerNear = player
            minDistance = distance
        end
    end
    if (minDistance < 3) then
        return playerNear
    end
end
-------------------------gps------------------------------------

------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------


function drawTxt(text,font,centre,x,y,scale,r,g,b,a)
  SetTextFont(font)
  SetTextProportional(0)
  SetTextScale(scale, scale)
  SetTextColour(r, g, b, a)
  SetTextDropShadow(0, 0, 0, 0,255)
  SetTextEdge(1, 0, 0, 0, 255)
  SetTextDropShadow()
  SetTextOutline()
  SetTextCentre(centre)
  SetTextEntry("STRING")
  AddTextComponentString(text)
  DrawText(x , y) 
end

function f(n)
  return n + 0.0001
end

function LocalPed()
  return GetPlayerPed(-1)
end

function try(f, catch_f)
local status, exception = pcall(f)
if not status then
  catch_f(exception)
end
end

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function OpenCreator()
  boughtcar = false
  personnelmenu.currentmenu = "main"
  personnelmenu.opened = true
  personnelmenu.selectedbutton = 0
end

function CloseCreator()
  Citizen.CreateThread(function()
    local ped = LocalPed()
    if not boughtcar then
      local pos = currentlocation.pos.entering
    else
            
    end
    personnelmenu.opened = false
    personnelmenu.menu.from = 1
    personnelmenu.menu.to = 5
  end)
end

function drawMenuButton(button,x,y,selected)
  local menu = personnelmenu.menu
  SetTextFont(menu.font)
  SetTextProportional(0)
  SetTextScale(menu.scale, menu.scale)
  if selected then
    SetTextColour(0, 0, 0, 255)
  else
    SetTextColour(255, 255, 255, 255)
  end
  SetTextCentre(0)
  SetTextEntry("STRING")
  AddTextComponentString(button.title)
  if selected then
    DrawRect(x,y,menu.width,menu.height,255,255,255,255)
  else
    DrawRect(x,y,menu.width,menu.height,0,0,0,150)
  end
  DrawText(x - menu.width/2 + 0.005, y - menu.height/2 + 0.0028)  
end

function drawMenuInfo(text)
  local menu = personnelmenu.menu
  SetTextFont(menu.font)
  SetTextProportional(0)
  SetTextScale(0.45, 0.45)
  SetTextColour(255, 255, 255, 255)
  SetTextCentre(0)
  SetTextEntry("STRING")
  AddTextComponentString(text)
  DrawRect(0.675, 0.95,0.65,0.050,0,0,0,150)
  DrawText(0.365, 0.934)  
end

function drawMenuRight(txt,x,y,selected)
  local menu = personnelmenu.menu
  SetTextFont(menu.font)
  SetTextProportional(0)
  SetTextScale(menu.scale, menu.scale)
  SetTextRightJustify(1)
  if selected then
    SetTextColour(0, 0, 0, 255)
  else
    SetTextColour(255, 255, 255, 255)
  end
  SetTextCentre(0)
  SetTextEntry("STRING")
  AddTextComponentString(txt)
  DrawText(x + menu.width/2 - 0.03, y - menu.height/2 + 0.0028) 
end

function drawMenuTitle(txt,x,y)
local menu = personnelmenu.menu
  SetTextFont(2)
  SetTextProportional(0)
  SetTextScale(0.5, 0.5)
  SetTextColour(255, 255, 255, 255)
  SetTextEntry("STRING")
  AddTextComponentString(txt)
  DrawRect(x,y,menu.width,menu.height,0,0,0,150)
  DrawText(x - menu.width/2 + 0.005, y - menu.height/2 + 0.0028)  
end
function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


-- FR -- Fonction : Permet d'envoyer une notification à l'utilisateur
-- FR -- Paramètre(s) : text = Texte à afficher dans la notification
---------------------------------------------------------
-- EN -- Function : Sends a notification to the user
-- EN -- Param(s) : text = Text to display in the notification
function Notify(text)
  SetNotificationTextEntry('STRING')
  AddTextComponentString(text)
  DrawNotification(false, false)
end

function round(num, idp)
  if idp and idp>0 then
    local mult = 10^idp
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end

function ButtonSelected(button)
  local ped = GetPlayerPed(-1)
  local this = personnelmenu.currentmenu
  local btn = button.name
  if this == "main" then
    if btn == "Rehabille" then
      changeSkin()
      boughtcar = true
      CloseCreator()
    elseif btn ==  'CarteIdentite' then
      boughtcar = true
      CloseCreator()
      TriggerServerEvent('id_card:getinfos')
    elseif btn == 'Animations' then
      OpenMenu('Animations')
    end
  elseif this == "Animations" then
      if btn == "Stop" then
        boughtcar = true
        ClearPedTasks(ped);
        playing_emote = false
        CloseCreator()
      elseif btn == "Animation" then
        ped = GetPlayerPed(-1);
        if ped then
          TaskStartScenarioInPlace(ped, button.anim, 0, true);
          playing_emote = true;
        end
      end
     
  end
end

function OpenMenu(menu)
  personnelmenu.lastmenu = personnelmenu.currentmenu
  if menu == "Contact" then
    personnelmenu.lastmenu = "main"
  elseif menu == "main"  then
    personnelmenu.lastmenu = nil
  elseif menu == "ActionContact"  then
    personnelmenu.lastmenu = "Contact"
  elseif menu == "Animations" then
    personnelmenu.lastmenu = "main"
  end
  personnelmenu.menu.from = 1
  personnelmenu.menu.to = 5
  personnelmenu.selectedbutton = 0
  personnelmenu.currentmenu = menu
end


function Back()
  if backlock then
    return
  end
  backlock = true
  if personnelmenu.currentmenu == "main" then
    boughtcar = true
    CloseCreator()
  elseif personnelmenu.currentmenu == "Contact" then
    OpenMenu(personnelmenu.lastmenu)
  elseif personnelmenu.currentmenu == "Animations" then
    OpenMenu(personnelmenu.lastmenu)
  elseif personnelmenu.currentmenu == "ActionContact" then
    OpenMenu(personnelmenu.lastmenu)
  else
    OpenMenu(personnelmenu.lastmenu)
  end
end

function stringstarts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end


function drawTxt(text,font,centre,x,y,scale,r,g,b,a)
  SetTextFont(font)
  SetTextProportional(0)
  SetTextScale(scale, scale)
  SetTextColour(r, g, b, a)
  SetTextDropShadow(0, 0, 0, 0,255)
  SetTextEdge(1, 0, 0, 0, 255)
  SetTextDropShadow()
  SetTextOutline()
  SetTextCentre(centre)
  SetTextEntry("STRING")
  AddTextComponentString(text)
  DrawText(x , y)
end


-- FR -- Fonction : Permet de remettre le skin du joueur
-- FR -- Paramètre(s) : Aucun
---------------------------------------------------------
-- EN -- Function : Allows to reset the skin of the player
-- EN -- Param(s) : None
function changeSkin()
  TriggerServerEvent("menuuser:changeSkin")
end

---------------------------------- CITIZEN ----------------------------------

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if IsControlJustPressed(1,74) then -- FR -- Modifier la valeur 202 pour modifier la touche sur le quel le joueur doit appuyer pour afficher le menu -- EN -- Change the value 202 to change the key on which the player must press to display the menu
      if personnelmenu.opened then
        CloseCreator()
      else
        OpenCreator()
      end
    end
    if personnelmenu.opened then
      local ped = LocalPed()
      local menu = personnelmenu.menu[personnelmenu.currentmenu]
      drawTxt(personnelmenu.title,1,1,personnelmenu.menu.x,personnelmenu.menu.y,1.0, 255,255,255,255)
      drawMenuTitle(menu.title, personnelmenu.menu.x,personnelmenu.menu.y + 0.08)
      drawTxt(personnelmenu.selectedbutton.."/"..tablelength(menu.buttons),0,0,personnelmenu.menu.x + personnelmenu.menu.width/2 - 0.0385,personnelmenu.menu.y + 0.067,0.4, 255,255,255,255)
      local y = personnelmenu.menu.y + 0.12
      buttoncount = tablelength(menu.buttons)
      local selected = false
      
      for i,button in pairs(menu.buttons) do
        if i >= personnelmenu.menu.from and i <= personnelmenu.menu.to then
          
          if i == personnelmenu.selectedbutton then
            selected = true
          else
            selected = false
          end
          drawMenuButton(button,personnelmenu.menu.x,y,selected)
          y = y + 0.04
          if selected and IsControlJustPressed(1,201) then
            ButtonSelected(button)
          end
        end
      end 
    end
    if personnelmenu.opened then
      if IsControlJustPressed(1,288) then 
        Back()
      end
      if IsControlJustReleased(1,288) then
        backlock = false
      end
      if IsControlJustPressed(1,188) then
        if personnelmenu.selectedbutton > 1 then
          personnelmenu.selectedbutton = personnelmenu.selectedbutton -1
          if buttoncount > 5 and personnelmenu.selectedbutton < personnelmenu.menu.from then
            personnelmenu.menu.from = personnelmenu.menu.from -1
            personnelmenu.menu.to = personnelmenu.menu.to - 1
          end
        end
      end
      if IsControlJustPressed(1,187)then
        if personnelmenu.selectedbutton < buttoncount then
          personnelmenu.selectedbutton = personnelmenu.selectedbutton +1
          if buttoncount > 5 and personnelmenu.selectedbutton > personnelmenu.menu.to then
            personnelmenu.menu.to = personnelmenu.menu.to + 1
            personnelmenu.menu.from = personnelmenu.menu.from + 1
          end
        end 
      end
    end
    
  end
end)
------------------------------------------------------------------------------------------------------------------------
