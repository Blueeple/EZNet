local ServerScriptService = game:GetService("ServerScriptService")
local EZNet_Server = require(ServerScriptService.EZNet_Installer.EZNet.EZNetServer)

local obj1 = EZNet_Server.new("Hello")
local obj2 = EZNet_Server.new("World!")

EZNet_Server.new("Test")
EZNet_Server.setEnabled(obj1, false)
