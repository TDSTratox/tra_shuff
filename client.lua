-- Optimisations
local tonumber = tonumber
local CreateThread = Citizen.CreateThread
local Wait = Citizen.Wait
local TriggerEvent = TriggerEvent
local RegisterCommand = RegisterCommand
local PlayerPedId = PlayerPedId
local IsPedInAnyVehicle = IsPedInAnyVehicle
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetVehiclePedIsIn = GetVehiclePedIsIn
local SetPedIntoVehicle = SetPedIntoVehicle

-- Variable pour désactiver temporairement le changement de siège
local disabled = false

-- Boucle principale
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local restrictSwitching = false

        -- Vérifie si le joueur est dans un véhicule et n'a pas désactivé le changement de siège
        if IsPedInAnyVehicle(ped, false) and not disabled then
            -- Vérifie si le joueur est au siège du conducteur
            if GetPedInVehicleSeat(GetVehiclePedIsIn(ped, false), 0) == ped then
                restrictSwitching = true
            end
        end

        -- Active ou désactive le changement de siège en fonction des conditions
        SetPedConfigFlag(ped, 184, restrictSwitching)
        Wait(150)
    end
end)

-- Fonction pour changer de siège
local function switchSeat(_, args)
    local seatIndex = tonumber(args[1])

    -- Vérifie si le numéro de siège est valide
    if seatIndex == nil or seatIndex < -1 or seatIndex >= 4 then
        -- Affiche un message d'erreur
        SetNotificationTextEntry('STRING')
        AddTextComponentString("~r~Siège non valide")
        DrawNotification(true, true)
        return
    end

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    -- Vérifie si le joueur est dans un véhicule
    if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
        local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)

        -- Vérifie si le siège est valide pour ce véhicule
        if seatIndex < -1 or seatIndex >= maxSeats then
            SetNotificationTextEntry('STRING')
            AddTextComponentString("~r~Siège non valide pour ce véhicule")
            DrawNotification(true, true)
            return
        end

        local driverSeat = GetPedInVehicleSeat(vehicle, -1)

        -- Vérifie si le joueur est déjà au volant
        if driverSeat == ped then
            SetNotificationTextEntry('STRING')
            AddTextComponentString("~r~Vous êtes déjà au volant.")
            DrawNotification(true, true)
        else
            -- Crée un thread pour désactiver temporairement le changement de siège, puis change le siège
            CreateThread(function()
                disabled = true
                TaskWarpPedIntoVehicle(ped, vehicle, seatIndex)
                Wait(50)
                disabled = false
            end)
        end
    else
        print("Erreur lors de la récupération du véhicule.")
    end
end

-- Fonction pour désactiver temporairement le changement de siège
local function shuffleSeat()
    CreateThread(function()
        disabled = true
        Wait(3000)
        disabled = false
    end)
end

-- Enregistre les commandes
RegisterCommand("seat", switchSeat)
RegisterCommand("shuff", shuffleSeat)

-- Ajoute des suggestions pour les commandes dans le chat
TriggerEvent('chat:addSuggestion', '/shuff', "Changer pour le siège conducteur")
TriggerEvent('chat:addSuggestion', '/seat', 'Changer de siège dans le véhicule',
  { { name = 'siège', help = "Changer de siège dans le véhicule. conducteur = 0, passager = 1, sièges arrière = 2-3" } })

-- Gère l'événement de fin de ressource
AddEventHandler('onClientResourceStop', function(name)
    -- Réactive le changement de siège lorsque la ressource est arrêtée
    if name == 'tra_shuff' then
        SetPedConfigFlag(PlayerPedId(), 184, false)
    end
end)

