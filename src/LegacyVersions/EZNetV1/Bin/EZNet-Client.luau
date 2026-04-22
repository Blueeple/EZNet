--!strict
--!native
--!optimize 2

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local RemoteStorage = ReplicatedStorage:WaitForChild("EZNet-Remotes", 3) :: Folder
local EZNetTypes = ReplicatedStorage:WaitForChild("EZN-Types")

-- Modules
local DataTypes = require("@game/ReplicatedStorage/EZN-Types")

-- Variables
local StartTick = tick()
local PacketsLoaded = false
local Internal = {
	_Packets = {} :: {
		[string]: {
			Name: string,
			Replicator: string,
			TypesList: { string },
			PacketId: number,
			Signal: typeof(GoodSignal.new()),
			methods: any,
		},
	},
	_Link = {} :: { [number]: string },
	_RemoteConnections = {} :: { [string]: RBXScriptConnection },
}
local Settings = {
	DebugMode = false,
	BypassPacketIntegrity = false,
	StudioKickEnabled = false,
	DoubleRegisterProtection = true,
	YeildInterval = 0.1,
	MaxYeildTime = 5,
}
local VerifyRemote = ReplicatedStorage:WaitForChild("EZNet-VerifyRemote", 3) :: RemoteEvent

-- Types
type PacketMethods = {
	Fire: (...any) -> (),
	OnPacket: (Callback: (...any) -> ()) -> { Disconnect: () -> () },
	OnPacketOnce: (Callback: (...any) -> ()) -> { Disconnect: () -> () },
}

-- Global functions
-- [[ Debug Engine]]
--[=[
	Debug print function

	@param ...
]=]
local function DebugPrint(...)
	if Settings.DebugMode then
		print(...)
	end
end

--[=[
	Debug warn function

	@param ...
]=]
local function DebugWarn(...)
	if Settings.DebugMode then
		warn(...)
	end
end

--[=[
	Unpacks buffers from a single buffer

	@param ...
]=]
local function HandleInBoundPacket(...)
	-- Variables
	local Args = table.pack(...)

	task.spawn(function()
		local PacketId = buffer.readu8(Args[1], 0) :: number
		local PacketName = Internal._Link[PacketId]

		if not PacketName then
			DebugWarn("[EZNet] - Received invalid PacketId: " .. tostring(PacketId))
			return
		end

		local PacketObject = Internal._Packets[PacketName]

		local DecodedArgs = {} :: { any }

		for i, Type in PacketObject.TypesList do
			local Buffer = Args[i + 1] :: buffer

			local Decoder = DataTypes.Reads[Type] :: (Buffer: buffer) -> any
			if Decoder then
				local DecodedValue = Decoder(Buffer)
				table.insert(DecodedArgs, DecodedValue)
			else
				DebugWarn("[EZNet] - Failed to find decoder for type: " .. Type)
			end
		end

		PacketObject.Signal:Fire(table.unpack(DecodedArgs))
	end)
end

task.spawn(function()
	DebugPrint("[EZNet][Client] - " .. tostring(tick() - StartTick))

	VerifyRemote:FireServer()

	VerifyRemote.OnClientEvent:Connect(function(PacketList: { [string]: { PacketId: number, Replicator: string, TypesList: { string } } })
		for Name, Packet in PacketList do
			Internal._Packets[Name] = {
				Name = Name,
				Replicator = Packet.Replicator,
				TypesList = Packet.TypesList,
				PacketId = Packet.PacketId,
				Signal = GoodSignal.new(),
				methods = {},
			}
			Internal._Link[Packet.PacketId] = Name

			local self = Internal._Packets[Name]
			local methods = Internal._Packets[Name].methods

			methods.OnPacket = function(Callback: (Player: Player, ...any) -> ())
				local Connection = self.Signal:Connect(function(...)
					Callback(...)
				end)

				return {
					Disconnect = function()
						Connection:Disconnect()
					end,
				}
			end

			methods.OnPacketOnce = function(Callback: (Player: Player, ...any) -> ())
				local Connection = self.Signal:Once(function(...)
					Callback(...)
				end)

				return {
					Disconnect = function()
						Connection:Disconnect()
					end,
				}
			end

			methods.Fire = function(...)
				local Args = table.pack(...)

				task.spawn(function()
					local EncodedData = {} :: { buffer }
					local PacketId = buffer.create(1)
					buffer.writeu8(PacketId, 0, self.PacketId)

					table.insert(EncodedData, PacketId)

					for i = 1, #self.TypesList do
						local Value = Args[i]
						local Type = self.TypesList[i]

						local Encoder = DataTypes.Writes[Type] :: (any) -> buffer
						if Encoder then
							local EncodedValue = Encoder(Value) :: buffer
							table.insert(EncodedData, EncodedValue)
						else
							DebugWarn("[EZNet] - Failed to find encoder for type: " .. Type)
						end
					end

					local Remote = RemoteStorage:FindFirstChild(Packet.Replicator) :: RemoteEvent
					Remote:FireServer(table.unpack(EncodedData))

					DebugPrint("[EZNet] - Fired remote: " .. Name)
				end)
			end

			if not Internal._RemoteConnections[Packet.Replicator] then
				local Remote = RemoteStorage:FindFirstChild(Packet.Replicator) :: RemoteEvent

				Internal._RemoteConnections[Packet.Replicator] = Remote.OnClientEvent:Connect(HandleInBoundPacket)
			end
		end

		PacketsLoaded = true
	end)
end)

-- EZNet Module
local EZNet = {}

function EZNet.GetPacket(Name: string): PacketMethods
	local object = Internal._Packets[Name]

	if object then
		return object.methods
	else
		warn("[EZNet] - Packet Yeilded waiting until response.")

		local TotalTick = 0

		repeat
			task.wait(Settings.YeildInterval)

			if TotalTick >= Settings.MaxYeildTime then
				print(TotalTick)

				warn("[EZNet] - Yeilded too long waiting for packet '" .. Name .. "'.")
				break
			end

			TotalTick += Settings.YeildInterval
		until PacketsLoaded

		if Internal._Packets[Name] then
			return Internal._Packets[Name].methods
		else
			warn("[EZNet] - Packet '" .. Name .. "' does not exist after yeild.")
			return nil :: any
		end
	end
end

print("[EZNet][Client] - " .. tostring(tick() - StartTick))

return EZNet
