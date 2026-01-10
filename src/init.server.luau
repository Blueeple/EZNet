--!strict
-- Services
local RunService = game:GetService("RunService")

-- Folders
local Utils = script.Utils

-- Modules
local Types = require(Utils.Types)
local CheckForUpdates = require(Utils.CheckForUpdates)
local Icons = require(Utils.Icons)

-- Bootstrapper [Prevent Plugin Start up in studio runmode]
if RunService:IsRunning()  then
    return
end

-- Variables
local RobloxDiagnostics = settings().Diagnostics

local RobloxVersion = RobloxDiagnostics.RobloxVersion

local GitHubUser = "rojo-rbx"
local GithubRepo = "rojo"

local CurrentUpdateCheck = {} :: Types.GithubRelease_Latest

-- Plugin Toolbar
local ToolBar = plugin:CreateToolbar("EZNet Installer")

-- Plugin Buttons
local EZNet_Install = ToolBar:CreateButton("1", "Opens the EZ-Net installer window.", Icons.OpenInstaller, "EZN - Install")
local EZNet_Update = ToolBar:CreateButton("2", "Checks for an availible eznet update.", Icons.OpenInstaller, "EZN - Update")
local EZNet_Edit = ToolBar:CreateButton("3", "Opens the EZ-Net editor window.", Icons.OpenInstaller, "EZN - Edit")

-- Plugin window info
local InstallWinInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 600, 400, 600, 300)

-- Plugin windows
local InstallWindow = plugin:CreateDockWidgetPluginGuiAsync("EZNet_Install", InstallWinInfo)
InstallWindow.Title = "EZNet Installer"

EZNet_Update.Click:Connect(function()
	CurrentUpdateCheck = CheckForUpdates(GitHubUser, GithubRepo)

	print(CurrentUpdateCheck)
end)

EZNet_Install.Click:Connect(function()
	InstallWindow.Enabled = EZNet_Install.Enabled
    print(RobloxVersion)
end)
