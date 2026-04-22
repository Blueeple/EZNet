--!strict
--!native
-- Services
local RunService = game:GetService("RunService")

if RunService:IsRunning() then
	return
end

-- Directories
local Bin = script.Bin
local Configs = script.Configs
local Core = script.Core
local Dump = script.Dump
local Extensions = script.Extensions
local Utils = script.Utils
local Packages = script.Packages

-- Modules
local Modules = {
	LuauMessager = require(Utils.LuauMessager),
	PluginWidget = require(Core.PluginWidget),
	ReactApp = require(Core.ReactApp),
}

-- [ Luau messager ]
Modules.LuauMessager.CreateListener("EZNetPlugin")

Modules.LuauMessager.OnMessageAsync("EZNetPlugin", function(Message: string)
	print("[EZNetPlugin] " .. Message)
end)

-- [ EZNet Plugin ]
Modules.PluginWidget.Init(plugin)

local Widget =  Modules.PluginWidget.GetWidget()

Modules.ReactApp.Init(Widget)