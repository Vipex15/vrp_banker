local cfg = module("vrp_banker", "cfg")
local vrp_banker = class("vrp_banker", vRP.Extension)

vrp_banker.tunnel = {}

function vrp_banker:__construct()
    vRP.Extension.__construct(self)
    self.CartsStated = {} 
    self.startMission = false 
end   

-- Function to load animation dictionary
function LoadAnimDict(dict)  
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(10)
    end    
end

function CreateCar(model, x,y,z, heading)
    local hash = GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(500)
    end
    vehicleModel = CreateVehicle(hash, x, y, z, heading, true, false)
    SetEntityHeading(vehicleModel, heading)
    SetVehicleOnGroundProperly(vehicleModel)
    SetEntityInvincible(vehicleModel, false)
    SetVehicleDirtLevel(vehicleModel, 0.0)
    SetVehicleEngineOn(vehicleModel, true, true)

    return vehicleModel
end

function vrp_banker:StartMission(bank_id, bank_dep_x, bank_dep_y, bank_dep_z)
    self.startMission = true
    LoadAnimDict("anim@heists@box_carry@")
    if self.startMission then 
        Citizen.CreateThread(function()
            for k, value in pairs(cfg.LocationCart) do
                if self.startMission then
                    local veh_job = "stockade"
                    vRP.EXT.Base:notifyPicture("CHAR_BANK_MAZE", "Generic Title", "Maze Bank", "Mission:", "You started a mission", 3000)

                    --local spawn_veh = vRP.EXT.Garage:spawnVehicle(veh_job, false,  -4.5730991363525,-670.46520996094,31.944389343262,185.0) 
                    --local spawn_veh = CreateCar(veh_job, -4.5730991363525,-670.46520996094,31.944389343262,185.0)
                    --local veh_poz = vRP.EXT.Garage:getOwnedVehiclePosition(spawn_veh)

                    local cartmoney = CreateObject(GetHashKey("v_corp_cashtrolley_2"), value.x, value.y, value.z, true, true, true)
                    SetEntityAsMissionEntity(cartmoney, true, true)
                    SetEntityHeading(cartmoney, 70.0)
                    FreezeEntityPosition(cartmoney, true)

                    local moneycartblip = AddBlipForEntity(cartmoney)
                    SetBlipSprite(moneycartblip, 1)
                    SetBlipColour(moneycartblip, 2)
                    SetBlipFlashes(moneycartblip, true)

                    table.insert(self.CartsStated, { id = cartmoney, blipId = moneycartblip, location = value, taken = false })                

                end
            end

            while self.startMission do 
                Citizen.Wait(5)

                for _, cart in ipairs(self.CartsStated) do
                    local cartmoney = cart.id
                    local cartlocation = GetEntityCoords(cartmoney)
                    local pedloc = GetEntityCoords(PlayerPedId())
                    local vehicleModel = GetVehiclePedIsIn(PlayerPedId())
                    local backdoor = GetOffsetFromEntityInWorldCoords(vehicleModel, 0.0, -4.0, 0.0) 

                    if not cart.taken and Vdist2(cartlocation, pedloc) < 2.0 then
                        DisplayHelpText("[E] Take the cart")

                        if IsControlJustPressed(1, 46) then
                            AttachEntityToEntity(cartmoney, PlayerPedId(), boneIndex, 0, 0.8, -0.95, 0.0, 0.0, 85.0, false, false, false, true, 5, true)

                            if IsEntityAttached(cartmoney) then
                                SetBlipColour(cart.blipId, 42)
                                local vehBLip = AddBlipForEntity(vehicleModel)
                                SetBlipSprite(vehBLip, 67)
                                SetBlipColour(vehBLip, 42)
                                SetVehicleNumberPlateText(vehicleModel, " Banker")
                                cart.taken = true
                                Citizen.Wait(1)
                                DisableControlAction(0, 21, true)
                                TaskPlayAnim(PlayerPedId(), 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
                                vRP.EXT.Base:notifyPicture("CHAR_BANK_MAZE", "Generic Title", "Maze Bank", "Mission:", "You took the cart, now go to the vehicle job", 2000)
                                break
                            end
                        end
                    end
                    
                    if cart.taken and not IsEntityAttachedToAnyVehicle(cartmoney) and Vdist2(backdoor.x, backdoor.y, backdoor.z, pedloc.x, pedloc.y, pedloc.z) < 2.5 then
                        DisplayHelpText("[E] Baga-l")
                        SetVehicleDoorOpen(vehicleModel, 2, 0, 0)
                        SetVehicleDoorOpen(vehicleModel, 3, 0, 0)

                        if IsControlJustPressed(1, 46) then
                            RemoveBlip(cart.blipId)
                            AttachEntityToEntity(cartmoney, vehicleModel, 0, 0, -2.5, 0.4, 0.0, 0.0, 85.0, false, false, false, true, 5, true)
                            cart.taken = false
                            ClearPedTasks(PlayerPedId())
                            vRP.EXT.Base:notify("l ai bagat sanatos")
                            vRP.EXT.Base:notifyPicture("CHAR_BANK_MAZE", "Generic Title", "Maze Bank", "Mission:", "You put the cart in the vehicle", 2000)

                            local BankBlip = AddBlipForCoord(bank_dep_x, bank_dep_y)
                            SetBlipSprite(BankBlip, 605)
                            SetBlipColour(BankBlip, 46)
                            SetNewWaypoint(bank_dep_x, bank_dep_y)
                        end 
                    end
                    if not cart.taken and IsEntityAttachedToAnyVehicle(cartmoney) and Vdist2(backdoor.x, backdoor.y, backdoor.z, pedloc.x, pedloc.y, pedloc.z) < 2.0 then
                        DisplayHelpText("[E] Scoate l")
                        if IsControlJustPressed(1, 46) then 
                            AttachEntityToEntity(cartmoney, PlayerPedId(), boneIndex, 0, 0.8, -0.95, 0.0, 0.0, 85.0, false, false, false, true, 5, true)
                            if IsEntityAttached(cartmoney) then
                                SetBlipColour(cart.blipId, 42)
                                cart.taken = true
                                Citizen.Wait(1)
                                DisableControlAction(0, 21, true)
                                TaskPlayAnim(PlayerPedId(), 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
                                vRP.EXT.Base:notifyPicture("CHAR_BANK_MAZE", "Generic Title", "Maze Bank", "Mission:", "Take the cart from the vehicle", 2000)
                                
                            end
                        end
                    end 
                    if cart.taken and Vdist2(bank_dep_x, bank_dep_y, bank_dep_z, pedloc.x, pedloc.y, pedloc.z) < 1.5 then 
                        DisplayHelpText("[E] Bank")
                        if IsControlJustPressed(1, 46) then 
                            cart.taken = false
                            DeleteEntity(cartmoney)
                            ClearPedTasksImmediately(PlayerPedId())
                            Citizen.Wait(1000)
                            vRP.EXT.Base:notifyPicture("CHAR_BANK_MAZE", "Generic Title", "Maze Bank", "Mission:", "Now you finished", 2000)
                            RemoveBlip(BankBlip)
                        end
                    end
                end
            end
        end)
    end
end

function DisplayHelpText(str)
    SetTextComponentFormat("STRING")
    AddTextComponentString(str)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

vrp_banker.tunnel.StartMission = vrp_banker.StartMission

vRP:registerExtension(vrp_banker)
