--!strict
-- Directories
local Utils = script.Parent.Parent.Utils
local Packages = script.Parent.Parent.Packages

local Modules = {
	LuauMessager = require(Utils.LuauMessager),
	ReactRoblox = require(Packages.ReactRoblox),
	React = require(Packages.React),
}

local ReactApp = {}

function ReactApp.Init(pluginGui: DockWidgetPluginGui)
	local EZNetAppGui = Instance.new("ScreenGui")
	EZNetAppGui.Name = "EZNetApp"
	EZNetAppGui.Parent = pluginGui

	local Root = Modules.ReactRoblox.createRoot(EZNetAppGui)

	local EZNetApp = Modules.React.createElement("Frame", {
		Name = "EZN-App",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 0,
	})

	Root:render(EZNetApp)

	Modules.LuauMessager.SendMessageAsync("EZNetPlugin", script.Name .. " initialized.")
end

return ReactApp
