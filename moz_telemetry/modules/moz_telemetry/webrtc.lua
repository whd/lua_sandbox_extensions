-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

--[[
# Mozilla Telemetry WebRTC Helper Module

## Functions

### filter_message

Return false if the message contains a WebRTC payload, true otherwise.

*Arguments*
- none, called in the context of an output's process_message

*Return*
- bool (boolean) false if the current message contains a WebRTC payload

--]]

-- Imports
local cjson = require "cjson"
local type = type
local read_message = read_message

local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local function check_payload (payload)
    if type(payload) ~= "table" then return false end
    local w = payload["webrtc"] or {}
    local i = w["IceCandidatesStats"] or {}
    if next(i["webrtc"] or {}) or next(i["loop"] or {}) then
        return true
    end
    return false
end

function filter_message ()
    local ok, json = pcall(cjson.decode, read_message("Fields[submission]"))
    if not ok then return false end
    local p = json["payload"] or {}
    local found = check_payload(p)
    if not found then
        -- check child payloads for E10s
        local children = read_message("Fields[payload.childPayloads]")
        if not children then return true end
        ok, json = pcall(cjson.decode, children)
        if not ok then return true end
        if type(json) ~= "table" then return true end
        for i, child in ipairs(json) do
            found = check_payload(child)
            if found then break end
        end
    end
    return not found
end

return M
