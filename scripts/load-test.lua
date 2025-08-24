-- Load test script for wrk
-- Tests the POST /payments endpoint with random UUIDs and amounts

local uuid = require("uuid")

request = function()
    local correlation_id = uuid()
    local amount = math.random(1, 1000) + math.random() -- Random amount between 1-1000 with decimals
    
    local body = string.format([[
    {
        "correlationId": "%s",
        "amount": %.2f
    }]], correlation_id, amount)
    
    return wrk.format("POST", "/payments", {
        ["Content-Type"] = "application/json"
    }, body)
end

response = function(status, headers, body)
    if status ~= 200 then
        print("Error response: " .. status .. " - " .. body)
    end
end