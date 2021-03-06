-- Under Construction
local component = require("component")
local event = require("event")
local serialize = require("serialization")

local modem = component.modem
if component.isAvailable("tunnel") then
    local tunnel = component.tunnel
end

local childNodes = {}
local childNum = 1
local tier = 0

-- open port
modem.open(4378)
-- functions to store the children and then sort the table
local function storeChild(eventName, receivingModem, sendingModem, port, distance, package)
    -- register neighbors for communication to gateway
    childNodes[childNum] = {}
    childNodes[childNum]["address"] = sendingModem
    childNodes[childNum]["tier"] = tonumber(package)
    childNodes[childNum]["port"] = tonumber(port)
    childNodes[childNum]["children"]={}
    print("inside store Child")
    print(childNodes[childNum]["address"])
    childNum = childNum + 1
end
local function sortTable(elementOne, elementTwo)
    if tonumber(elementOne["tier"]) < tonumber(elementTwo["tier"]) then
        return true
    else
        return false
    end
end
local function transmitInformation(sendTo, port, ...)
    if port ~= 0 then
        modem.send(sendTo, port, ...)
    else
        tunnel.send(...)
    end
end
local function receivePacket(eventName, receivingModem, sendingModem, port, distance, ...)
    local doesExist = false
    if (...) == "GERTiStart" then
        print("GERTiStartReceived")
        for key,value in pairs(childNodes) do
            if value["address"] == sendingModem then
                doesExist = true
                childNodes[key]["tier"] = ...
                childNodes[key]["port"] = port
                childNodes[key]["children"] = {}
                break
            end
        end
        if doesExist == false then
            storeChild(eventName, receivingModem, sendingModem, port, distance, ...)
        end
        transmitInformation(sendingModem, port, tier)
    elseif (...) == "GERTiForwardTable" then
        
        local junk, originatorAddress, childTable = ...
        childTable = serialize.unserialize(childTable)
        local childDex = 1
        
        for key, value in pairs(childNodes) do
            if value["address"] == originatorAddress then
                childDex = key
            end
        end
        for key, value in pairs(childTable) do
            if childTable[key]["address"] ~= modem.address then
                childNodes[childDex]["children"][key] = value
            end
        end
        for key, value in pairs(childNodes) do
            for key2, value2 in pairs(childNodes[key]["children"]) do
                print("dave")
                print(value2["address"])
            end
        end
    end
end
event.listen("modem_message", receivePacket)