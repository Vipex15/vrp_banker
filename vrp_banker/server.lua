local vrp_banker = class("vrp_banker", vRP.Extension)
vrp_banker.event = {}
vrp_banker.tunnel = {}
vrp_banker.cfg = module("vrp_banker", "cfg")


function vrp_banker:BankMissions()
    local banks = {}
    local rows = exports.oxmysql:executeSync("SELECT bank_id, bank_name, request_stacks FROM vrp_banks WHERE request_stacks > 0")
    if rows and #rows > 0 then
        for _, row in ipairs(rows) do
            local bank = {
                bank_id = row.bank_id,
                bank_name = row.bank_name,
                request_stacks = row.request_stacks
            }
            table.insert(banks, bank)
        end
    end
    return banks 
end

function vrp_banker:getBankCoordinates(bankId)
    local rows = exports.oxmysql:executeSync("SELECT bank_id FROM vrp_banks WHERE request_stacks > 0")
    if rows then
        for _, row in ipairs(rows) do
            if row.bank_id == bankId then
                local bank = vrp_banker.cfg.bank_missions[bankId]
                if bank then
                    return bank.bank_dep
                else
                    return nil
                end
            end
        end
        print("Bank ID not found in bank_missions: " .. bankId)
        return nil
    else
        print("Error fetching bank_id from database.")
        return nil
    end
end

local function banks_missions(self)
    vRP.EXT.GUI:registerMenuBuilder("Bank Missions", function(menu)
        menu.title = "Bank Missions"
        menu.css.header_color = "rgba(0,255,0,0.75)"
        local user = vRP.users_by_source[menu.user.source]
        local user_id = user.id
        if user_id then
            local banks = self:BankMissions() 
            
            if #banks > 0 then
                for _, bank in ipairs(banks) do
                    local display_request = bank.bank_id .. " Bank<br>Requested: " .. bank.request_stacks
                    menu:addOption(bank.bank_name, function()
                        local bank_dep = self:getBankCoordinates(bank.bank_id)
                        if bank_dep then
                            print("Bank coordinates: x = " .. bank_dep.x .. ", y = " .. bank_dep.y .. ", z = " .. bank_dep.z)
                            self.remote._StartMission(user_id, bank.bank_id, bank_dep.x, bank_dep.y,bank_dep.z)
                        else
                            print("Bank coordinates not found for bank ID: " .. bank.bank_id)
                        end
                    end, display_request)
                end
                user:actualizeMenu(menu)
            else
                menu:addOption("No Missions", nil, "")
            end
        end
    end)
end


-- Banker mission menu
local function bank_missions()
    vRP.EXT.GUI:registerMenuBuilder("Banker Missions", function(menu)
        menu.title = "Banker Missions"
        menu.css.header_color = "rgba(0,255,0,0.75)"
        local user = vRP.users_by_source[menu.user.source]
        local user_id = user.id
        if user_id then 
            menu:addOption("Banks Missions", function() user:openMenu("Bank Missions") end, "Banks request stacks of money")
            menu:addOption("ATM Missions", nil, "ATM Mission")
        end
    end)
end

function vrp_banker:__construct()
    vRP.Extension.__construct(self)
    bank_missions(self) 
    banks_missions(self)
end

local mission_take = { x = 6.2572498321533, y =-701.43310546875, z = 16.1310482025159}  -- 6.2572498321533,-701.43310546875,16.1310482025159

function vrp_banker.event:playerSpawn(user, first_spawn)
    if first_spawn then
            local x, y, z = mission_take.x, mission_take.y, mission_take.z
        
            local function BankerMission(user)
                    user:openMenu("Banker Missions")
                end
        
            local function BankerMissionLeave(user)
                user:closeMenu("Banker Missions")
            end

            local bank_info = {"PoI", {blip_id = 521, blip_color = 75, marker_id = 1}}
            local ment = clone(bank_info)
            ment[2].pos = {x, y, z - 1}
            vRP.EXT.Map.remote._addEntity(user.source, ment[1], ment[2])
        
                user:setArea("vRP:vrp_banking:info:", x, y, z, 1, 1.5, BankerMission, BankerMissionLeave)
            end
        end

vRP:registerExtension(vrp_banker)
