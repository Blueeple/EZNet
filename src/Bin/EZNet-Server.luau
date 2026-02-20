--!strict
--!native
--!optimize 2

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local RemoteStorage = Instance.new("Folder")
RemoteStorage.Name = "EZNet-Remotes"
RemoteStorage.Parent = ReplicatedStorage
local EZNetTypes = ReplicatedStorage["EZN-Types"]

-- Modules
local GoodSignal = require(ReplicatedStorage.Utils.GoodSignal)
local DataTypes = require(EZNetTypes)

-- Variabless
local StartTick = tick()
local Internal = {
	_Packets = {} :: {
		[string]: {
			Name: string,
			Enabled: boolean,
			Replicator: string,
			TypesList: { string },
			PacketId: number,
			BlockedPlayers: { [string]: boolean },
			Signal: typeof(GoodSignal.new()),
			methods: any,
		},
	},
	_Link = {} :: { [number]: string },
	_RemoteConnections = {} :: { [string]: RBXScriptConnection },
	_GSConnections = {} :: { [string]: RBXScriptConnection },
}
local PacketCount = -1
local LoadedPlayers = {} :: { Player }
local Settings = {
	DebugMode = true,
	--BypassPacketIntegrity = false,
	StudioKickEnabled = false,
	--MaxBufferSize = 256,
	DoubleRegisterProtection = true,
	YeildAmountOnPacketNotFound = 100, -- in milliseconds
}
local VerifyRemote = Instance.new("RemoteEvent")
VerifyRemote.Name = "EZNet-VerifyRemote"
VerifyRemote.Parent = ReplicatedStorage

-- Types
type PacketMethods = {
	Fire: (Player: Player, ...any) -> (),
	FireAll: (...any) -> (),
	BlockPlayer: (Player: Player) -> (),
	UnblockPlayer: (Player: Player) -> (),
	SetEnabled: (Value: boolean) -> (),
	OnPacket: (Callback: (Player: Player, ...any) -> ()) -> { Disconnect: () -> () },
	OnPacketOnce: (Callback: (Player: Player, ...any) -> ()) -> { Disconnect: () -> () },
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
local function HandleInBoundPacket(Player: Player, ...)
	-- Variables
	local Args = table.pack(...)

	task.spawn(function()
		local PacketId = buffer.readu8(Args[1], 0) :: number
		local PacketName = Internal._Link[PacketId]

		if not PacketName then
			DebugWarn("[EZNet] - Received invalid PacketId: " .. tostring(PacketId) .. " from Player: " .. Player.Name)
			return
		end
		local PacketObject = Internal._Packets[PacketName]
		if not PacketObject.Enabled then
			warn(
				"[EZNet] - Packet: "
					.. PacketName
					.. " is currently disabled. Ignoring packet from Player: "
					.. Player.Name
			)
			return
		end

		if PacketObject.BlockedPlayers[Player.Name] == true then
			warn("[EZNet] - Player: " .. Player.Name .. " is blocked from receiving Packet: " .. PacketName)
			return
		end

		local DecodedArgs = {} :: { any }

		for i = 1, #PacketObject.TypesList do
			local Type = PacketObject.TypesList[i]
			local Buffer = Args[i + 1] :: buffer

			local Decoder = DataTypes.Reads[Type]
			if Decoder then
				local DecodedValue = Decoder(Buffer)
				table.insert(DecodedArgs, DecodedValue)
			else
				DebugWarn("[EZNet] - Failed to find decoder for type: " .. Type)
			end
		end

		PacketObject.Signal:Fire(Player, table.unpack(DecodedArgs))
	end)
end

-- EZNet Module
local EZNet = { Types = DataTypes.Types }

-- Variable / DOP based OOP solver
local HybridObjectConst = function(Name: string, Enabled: boolean, Replicator: string, TypesList: { string })
	assert(PacketCount <= 255, "Cannot make more that 256 packets.")
	assert(
		RemoteStorage:FindFirstChild(Replicator),
		"Replicator with name '" .. Replicator .. "' does not exist in RemoteStorage."
	)

	PacketCount += 1

	-- [Object]
	Internal._Link[PacketCount] = Name
	Internal._Packets[Name] = {
		Name = Name,
		Enabled = Enabled,
		Replicator = Replicator,
		TypesList = TypesList,
		PacketId = PacketCount,
		BlockedPlayers = {} :: { [string]: boolean },
		Signal = GoodSignal.new(),
		methods = {},
	}
	local self = Internal._Packets[Name]
	local methods = self.methods

	local Remote = RemoteStorage:FindFirstChild(Replicator) :: RemoteEvent

	methods.BlockPlayer = function(Player: Player)
		if self.BlockedPlayers[Player.Name] == true then
			warn(
				"[EZNet] - Player '"
					.. Player.Name
					.. "' is already blocked from receiving packet '"
					.. self.Name
					.. "'!"
			)
			return
		end

		self.BlockedPlayers[Player.Name] = true

		Remote:FireClient(Player, false)
	end

	methods.UnblockPlayer = function(Player: Player)
		if not self.BlockedPlayers[Player.Name] then
			warn("[EZNet] - Player '" .. Player.Name .. "' is not blocked from receiving packet '" .. self.Name .. "'!")
			return
		end

		Remote:FireClient(Player, true)
	end

	methods.Fire = function(Player: Player, ...: any)
		local Args = table.pack(...)

		task.spawn(function()
			local EncodedData = {} :: { buffer }
			local PacketId = buffer.create(1)
			buffer.writeu8(PacketId, 0, self.PacketId)

			table.insert(EncodedData, PacketId)

			for i = 1, #self.TypesList do
				local Type = self.TypesList[i]
				local Value = Args[i] :: buffer

				local Encoder = DataTypes.Writes[Type]
				if Encoder then
					local EncodedValue = Encoder(Value) :: buffer
					table.insert(EncodedData, EncodedValue)
				else
					DebugWarn("[EZNet] - Failed to find encoder for type: " .. Type)
				end
			end

			Remote:FireClient(Player, table.unpack(EncodedData))
			DebugPrint("[EZNet] - Fired remote: " .. Name)
		end)
	end

	methods.FireAll = function(...)
		local Args = table.pack(...)

		task.spawn(function()
			local EncodedData = {} :: { buffer }
			local PacketId = buffer.create(1)
			buffer.writeu8(PacketId, 0, self.PacketId)

			table.insert(EncodedData, PacketId)

			for i = 1, #self.TypesList do
				local Type = self.TypesList[i]
				local Value = Args[i] :: buffer

				local Encoder = DataTypes.Writes[Type]
				if Encoder then
					local EncodedValue = Encoder(Value) :: buffer
					table.insert(EncodedData, EncodedValue)
				else
					DebugWarn("[EZNet] - Failed to find encoder for type: " .. Type)
				end
			end

			for _, Player in LoadedPlayers do
				Remote:FireClient(Player, table.unpack(EncodedData))
			end

			DebugPrint("[EZNet] - Fired remote: " .. Name)
		end)
	end

	methods.SetEnabled = function(Value: boolean)
		self.Enabled = Value
	end

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

	DebugPrint("[EZNet] - Created packet: " .. Name)

	return methods
end

--[ EZNet Methods ]
--[=[
	Creates a new communication channel.
		
	@param Name: string
	@param Reliable: boolean
]=]
function EZNet.CreateChannel(Name: string, Reliable: boolean)
	assert(not RemoteStorage:FindFirstChild(Name), "RemoteEvent with name '" .. Name .. "' already exists!")

	if Reliable then
		local RemoteEvent = Instance.new("RemoteEvent")
		RemoteEvent.Name = Name
		RemoteEvent.Parent = RemoteStorage

		Internal._RemoteConnections[Name] = RemoteEvent.OnServerEvent:Connect(HandleInBoundPacket)
	else
		local RemoteEvent = Instance.new("UnreliableRemoteEvent")
		RemoteEvent.Name = Name
		RemoteEvent.Parent = RemoteStorage

		Internal._RemoteConnections[Name] = RemoteEvent.OnServerEvent:Connect(HandleInBoundPacket)
	end

	DebugPrint("[EZNet] - Created channel: " .. Name)

	return Name
end

--[=[
	Creates a new custom remote.
		
	@param Name: string
	@param Enabled: boolean?
	@param Replicator: string
	@param TypesList: { string }
]=]
function EZNet.CreatePacket(Name: string, Enabled: boolean, Replicator: string, TypesList: { string }): PacketMethods
	return HybridObjectConst(Name, Enabled, Replicator, TypesList)
end

function EZNet.GetPacket(Name: string): PacketMethods
	local object = Internal._Packets[Name]

	if object then
		return object.methods
	else
		DebugWarn("[EZNet] - Packet Yeilded waiting until response.")

		repeat
			task.wait(Settings.YeildAmountOnPacketNotFound / 1000)
			object = Internal._Packets[Name]
		until object

		return object.methods
	end
end

task.spawn(function()
	VerifyRemote.OnServerEvent:Connect(function(Player: Player)
		if not table.find(LoadedPlayers, Player) then
			table.insert(LoadedPlayers, Player)

			local Packets = {}

			for Name, Packet in Internal._Packets do
				Packets[Name] = {
					Replicator = Packet.Replicator,
					PacketId = Packet.PacketId,
					TypesList = Packet.TypesList,
				}
			end

			VerifyRemote:FireClient(Player, Packets)

			DebugPrint("[EZNet] - Player '" .. Player.Name .. "' has been verified and loaded.")
		else
			if Settings.DoubleRegisterProtection and Settings.StudioKickEnabled then
				Player:Kick("EZNet double registration detected. You have been kicked.")
			end

			DebugWarn("[EZNet] - Player '" .. Player.Name .. "' has already been loaded.")
		end
	end)
end)

print("[EZNet][Server] - " .. tostring(tick() - StartTick))

return EZNet
