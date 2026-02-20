--!strict
--!native
-- Services
local RunService = game:GetService("RunService")

if RunService:IsRunning() then
	return
end

-- Directories
local Configs = script.Configs
local Utils = script.Utils

-- Packages
local Setup = require(Configs.Setup)
local LuauMessager = require(Utils.LuauMessager)

local ModuleLoad = LuauMessager.CreateListener()

print("Hello world!")