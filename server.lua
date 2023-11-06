local business = {}

exports.oxmysql:query('SELECT identifier, name, price, number FROM `gandalf_multibusiness`', {}, function(result)
    if result then
        for i = 1, #result do
            local row = result[i]
            table.insert(business, row)
        end
    end
end)

-- RegisterCommand('listbusiness', function(source, args)
--     print(json.encode(business, {indent = true}))
-- end)

RegisterCommand('createonlinebusiness', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = nil

    if args[1] ~= nil then
        xTarget = ESX.GetPlayerFromId(tonumber(args[1]))
    end
    for i = 1, #Config.AuthPlayer do
        if xPlayer.identifier == Config.AuthPlayer[i] then
            if xTarget ~= nil and args[2] ~= nil and args[3] ~= nil then
                local data = {
                    target = xTarget.identifier,
                    name = GetPlayerName(xTarget.source),
                    price = tonumber(args[2]),
                    number = tonumber(args[3])
                }
                createBusiness(data)
            end
        end
    end
end)

function createBusiness(data)
    if data ~= nil then
        MySQL.update('INSERT INTO `gandalf_multibusiness` (`identifier`, `name`, `price`, `number`) VALUES (?, ?, ?, ?)', 
        {
            data.target, 
            data.name, 
            data.price,
            data.number
        }, function(result)
            if result ~= nil then
                table.insert(business, {
                    identifier = data.target,
                    name = data.name,
                    price = data.price,
                    number = data.number
                })
                showNotify(source, 'Sikeresen létrehoztad a businesst!', 'info')
            end
        end)
    end
end

RegisterCommand('createofflinebusiness', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = nil

    if args[1] ~= nil then
        xTarget = tostring(args[1])
    end
    for i = 1, #Config.AuthPlayer do
        if xPlayer.identifier == Config.AuthPlayer[i] then
            if xTarget ~= nil and args[2] ~= nil and args[3] ~= nil then
                local data = {
                    target = xTarget,
                    price = tonumber(args[2]),
                    number = tonumber(args[3])
                }
                createofflineBusiness(data, xPlayer.source)
            end
        end
    end
end)

function createofflineBusiness(data, source)
    exports.oxmysql:query('SELECT name FROM `users` WHERE identifier=@identifier', {['@identifier']=data.target}, function(result)
        if result then
            for i = 1, #result do
                local row = result[i]
                data.name = row.name
                if data ~= nil and data.name ~= nil then
                    print(data.name)
                    MySQL.update('INSERT INTO `gandalf_multibusiness` (`identifier`, `name`, `price`, `number`) VALUES (?, ?, ?, ?)', 
                    {
                        data.target, 
                        data.name, 
                        data.price,
                        data.number
                    }, function(result)
                        if result ~= nil then
                            table.insert(business, {
                                identifier = data.target,
                                name = data.name,
                                price = data.price,
                                number = data.number
                            })
                            showNotify(source, 'Sikeresen létrehoztad az offline businesst!', 'info')
                        end
                    end)
                end
            end
        end
    end)
end

-- RegisterCommand('tesztcommand', function(source, args)

--     addAccountOfflineMoney("bank", 123123, 'char1:9e8ca54b020117ddf7b252fbd372cf859c37189e')
-- end)

function addAccountOfflineMoney(account, price, identifier)
    exports.oxmysql:query('SELECT accounts FROM `users` WHERE identifier=@identifier', {['@identifier'] = identifier}, function(result)
        if result then
            local foundAccounts = {}

            if result[1].accounts and result[1].accounts ~= '' then
                local accounts = json.decode(result[1].accounts)
            
                for account, money in pairs(accounts) do
                    if account == "bank" then
                        foundAccounts[account] = money+price
                    else
                        foundAccounts[account] = money
                    end
                end
            end

            MySQL.prepare('UPDATE `users` SET `accounts` = ? WHERE `identifier` = ?', {json.encode(foundAccounts), identifier}, function(affectedRows)
                if affectedRows == 1 then
                    --print("sikeres")
                end
            end) 
        end
    end)
end

CreateThread(function()
    while true do
        Wait(1000*Config.addMoney*60)
        for i = 0, #business do
            if business[i] ~= nil then
                --print(json.encode(business[i], {indent = true}))
                if business[i].identifier ~= nil then
                    local xPlayer = ESX.GetPlayerFromIdentifier(business[i].identifier)
                    if xPlayer then
                        showNotify(xPlayer.source, 'Megkaptad a fizetésed', 'info')
                        xPlayer.addAccountMoney("bank", business[i].price)
                    else
                        addAccountOfflineMoney("bank", business[i].price, business[i].identifier)
                    end
                    business[i].number = business[i].number - 1
                end
            end
            Wait(1000)
        end
    end
end)

function showNotify(player, msg, type)
    TriggerClientEvent('okokNotify:Alert', player, "Business", msg, 5000, type)
end