--!strict
local Camera = workspace.CurrentCamera :: Camera
local PluginWindowSize = Camera.ViewportSize * 0

-- Directories
local Utils = script.Parent.Parent.Utils

local Modules = {
	LuauMessager = require(Utils.LuauMessager),
}

-- Variables
local Widget: DockWidgetPluginGui

local PluginWidget = {}

function PluginWidget.Init(plugin: Plugin)
	local Toolbar = plugin:CreateToolbar("EZNet")

	local Button = Toolbar:CreateButton("EZNet", "Opens the EZNet configurator plugin.", "rbxassetid://117539866471692")

	Widget = plugin:CreateDockWidgetPluginGuiAsync(
		"EZNetConfigurator",
		DockWidgetPluginGuiInfo.new(
			Enum.InitialDockState.Float,
			false,
			false,
			PluginWindowSize.X,
			PluginWindowSize.Y * 1.5,
			PluginWindowSize.X,
			PluginWindowSize.Y * 1.5
		)
	)

	Widget.Title = "EZNet Configurator"

	Button.Click:Connect(function()
		Widget.Enabled = not Widget.Enabled
	end)

	Modules.LuauMessager.SendMessageAsync("EZNetPlugin", script.Name .. " initialized.")
end

function PluginWidget.GetWidget()
	return Widget
end

return PluginWidget
