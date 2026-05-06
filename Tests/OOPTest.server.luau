local ServerScriptService = game:GetService("ServerScriptService")
local EZNet_Server = require(ServerScriptService.EZNet_Installer.EZNet.EZNetServer)

EZNet_Server.newChannel("Test", false)
local packet1 = EZNet_Server.newPacket("Packet1", {
    enabled = false,
    channel = "Test",
    types = { "string", "number" },
})
EZNet_Server.setEnabled(packet1, true)
EZNet_Server.readEngineMemory()
EZNet_Server.readSignalMemory()