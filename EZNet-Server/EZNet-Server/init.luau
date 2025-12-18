--!strict
--!native
--!optimize 2

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Folders
local ReplicatorRemoteStorage = Instance.new("Folder")
ReplicatorRemoteStorage.Name = "ReplicatorRemoteStorage"
ReplicatorRemoteStorage.Parent = ReplicatedStorage

-- Variables
local StartTick = tick()
local ObjectEngine = {}
local PlayersLoaded = {} :: { [Player]: boolean }
local PacketDataLoaded = false
local PacketCreateYeildTask: thread
local PlayerVerifyRemote: RemoteEvent

-- Modules
local DataTypes = require(ReplicatedStorage:WaitForChild("EZN-Types"))
local GoodSignal = require(ReplicatedStorage.Frameworks:WaitForChild("GoodSignal"))
local Types = require(script.Types)

-- Object oriented module constructor
local EZNet = {}
EZNet.Packets = {} :: { [number]: Types.InternalPacket }
EZNet.PacketYeilds = {} :: { [string]: Types.InternalPacket }
EZNet.DataType = DataTypes.Types
EZNet.Engine = {
	Cached = {
		Tables = {},
		Arrays = {},
	},
	Replicators = {
		PlayerVerify = {
			StepMode = RunService.Heartbeat,
		},
		Reliable = {
			StepMode = RunService.PreAnimation,
			Reliable = true,
			TickPerSecond = 64,
			ThrottleEnabled = true,
			ThrottleRate = 8,
			ThrottleInterval = 1 / 8,
		},
		Uneliable = {
			StepMode = RunService.PreAnimation,
			Reliable = false,
			TickPerSecond = 64,
			ThrottleEnabled = true,
			ThrottleRate = 8,
			ThrottleInterval = 1 / 8,
		},
	} :: { [string]: Types.Replicator },
	ReplicatorHandlers = {} :: {
		[string]: {
			Thread: RBXScriptConnection | {},
			Receiver: RBXScriptConnection | {},
			InBoundQueue: { [number]: { Player: Player, Buffer: buffer | any } },
			OutBoundQueue: { [number]: { Player: Player, Buffer: buffer | any } },
		},
	},
	PacketObjectEngine = {},
	Settings = {
		DebugMode = false,
		BypassPacketIntegrity = false,
		StudioKickEnabled = false,
		MaxBufferSize = 256,
		ProcessPacketOnFire = false, -- Will be added in rmv4.1
		SkipReplicatorOutboundQueue = false, -- Will be added in rmv4.1
		EngineYieldTime = if RunService:IsStudio() then 30 else 15,
		MaxCompileTime = 0.05,
	},
}
EZNet.Engine.PacketObjectEngine.__index = EZNet.Engine.PacketObjectEngine
ObjectEngine = EZNet.Engine.PacketObjectEngine

-- [[ Debug Engine]]
--[=[
	Debug print function

	@param ...
]=]
local function DebugPrint(...)
	if EZNet.Engine.Settings.DebugMode then
		print(...)
	end
end

--[=[
	Debug warn function

	@param ...
]=]
local function DebugWarn(...)
	if EZNet.Engine.Settings.DebugMode then
		warn(...)
	end
end

-- [[ Packet handling Engine ]]
--[=[
	Unpacks buffers from a single buffer

	@param ...
]=]
local function HandleInBoundPacket(Player: Player, ...)
	-- Variables
	local PacketReciveData = table.pack(...)
	local PacketId = nil :: number?
	local PacketMemoryInfo = nil :: Types.InternalPacket?
	local BufferTypesInfo = nil :: { [number]: string }?
	local Signal = nil :: Types.Signal?
	local InBoundData = {} :: { [number]: buffer }
	local DecodedData = {} :: { [number]: any }

	-- Converts all argument into tables
	for index, Data: buffer in PacketReciveData do
		InBoundData[index] = Data
	end

	-- Sets the packet ID and memory info
	PacketId = buffer.readu8(PacketReciveData[1], 0) + 1
	PacketMemoryInfo = EZNet.Packets[PacketId]
	BufferTypesInfo = PacketMemoryInfo.Types
	Signal = PacketMemoryInfo.Signal

	-- Decodes all inbound data
	for index, TypeName in BufferTypesInfo do
		DebugPrint("[EZNet][Engine][BufferEngine] - Decoding Type: " .. TypeName .. " at index : " .. index .. " for packet: " .. PacketMemoryInfo.Name)
		local BufferData = InBoundData[index + 1]
		local ReadData = DataTypes.Reads[TypeName](BufferData)
		DecodedData[index] = ReadData
	end

	-- Fires the decoded data to the signal
	Signal:Fire(Player, table.unpack(DecodedData))
end

-- [[ Object Engine Methods ]]
--[=[
	Fires a Pacekt to the client

	@param Player: Player
	@param ...
]=]
function ObjectEngine:Fire(Player: Player, ...)
	-- Args
	local ReplicatorObject = self :: { PacketInfo: Types.InternalPacket, PacketId: number }
	local PacketMemoryInfo = ReplicatorObject.PacketInfo

	if not PacketDataLoaded then
		warn("[EZNet][Server] - Attempted to fire a packet: " .. PacketMemoryInfo.Name .. " before packet data was loaded.")
		return
	end

	-- Variables
	local ReplicatorName = PacketMemoryInfo.Replicator
	local OutBoundData = {}
	local Replicator = ReplicatorRemoteStorage:FindFirstChild(ReplicatorName) :: RemoteEvent
	local PackedData = table.pack(...)
	local PacketId = ReplicatorObject.PacketId

	if Replicator and Player:IsA("Player") and PlayersLoaded[Player] then
		DebugPrint("[EZNet] - Firing packet: " .. PacketMemoryInfo.Name .. " using replicator: " .. ReplicatorName)

		-- Packs the buffers into the packet
		for index, TypeName in PacketMemoryInfo.Types do
			local Data = PackedData[index]

			if not Data then
				warn("[EZNet][Client] - Warning: Packet: " .. PacketMemoryInfo.Name .. " had nil data for type: " .. TypeName)
				return
			end

			local WriteData = DataTypes.Writes[TypeName](Data)
			OutBoundData[index + 1] = WriteData
		end

		-- Adds Packet ID to the front of the buffer list
		OutBoundData[1] = buffer.create(1)
		buffer.writeu8(OutBoundData[1], 0, (PacketId - 1))

		Replicator:FireClient(Player, table.unpack(OutBoundData))
	elseif not PlayersLoaded[Player] then
		warn("[EZNet][Engine] - Cannot fire packet to unloaded player.")
	else
		DebugWarn("[EZNet][Engine] - Server Fire error.")
	end
end

--[=[
	Fires a Pacekt to all clients connected to the server.

	@param ...
]=]
function ObjectEngine:FireAll(...)
	-- Args
	local ReplicatorObject = self :: { PacketInfo: Types.InternalPacket, PacketId: number }
	local PacketMemoryInfo = ReplicatorObject.PacketInfo

	if not PacketDataLoaded then
		warn("[EZNet][Server] - Attempted to fire a packet: " .. PacketMemoryInfo.Name .. " before packet data was loaded.")
		return
	end

	-- Variables
	local ReplicatorName = PacketMemoryInfo.Replicator
	local OutBoundData = {}
	local Replicator = ReplicatorRemoteStorage:FindFirstChild(ReplicatorName) :: RemoteEvent
	local PackedData = table.pack(...) :: { [number]: any }

	if Replicator then
		DebugPrint("[EZNet][Engine] - Firing packet: " .. PacketMemoryInfo.Name .. " using replicator: " .. ReplicatorName)

		for index, TypeName in PacketMemoryInfo.Types do
			if DataTypes.Writes[TypeName] then
				local Data = PackedData[index]
				local WriteData = DataTypes.Writes[TypeName](Data)
				OutBoundData[index + 1] = WriteData
			else
				warn("[EZNet][Engine] - Sever encode error with encoder: " .. TypeName)
			end
		end

		-- Adds Packet ID to the front of the buffer list
		OutBoundData[1] = buffer.create(1)
		buffer.writeu8(OutBoundData[1], 0, (ReplicatorObject.PacketId - 1))

		for Player, _ in PlayersLoaded do
			Replicator:FireClient(Player, table.unpack(OutBoundData))
		end
	else
		DebugWarn("[EZNet][Engine] - Client Fire error.")
	end
end

--[=[
	Sets the activity of an remote.

	@param ...
]=]
function ObjectEngine:SetEnabled(...)
	assert(typeof(...) == "boolean", "Value must be boolean.")

	-- Variables
	local ReplicatorObject = self :: { PacketInfo: Types.InternalPacket, PacketId: number }
	local PacketMemoryInfo = ReplicatorObject.PacketInfo

	PacketMemoryInfo.Enabled = ...
end

--[=[
	Adds a player to the block list.

	@param Player: Player
]=]
function ObjectEngine:BlockPlayer(Player: Player)
	-- Packet Object data
	local ReplicatorObject = self :: { PacketInfo: Types.InternalPacket, PacketId: number }
	local PackedId = ReplicatorObject.PacketId
	local PacketMemoryInfo = ReplicatorObject.PacketInfo

	-- Variables
	--local Replicator = ReplicatorRemoteStorage:FindFirstChild(PacketMemoryInfo.Replicator) :: RemoteEvent
	local Blocked_PID = buffer.create(2)

	ReplicatorObject.PacketInfo.BlockedPlayers = {}
	buffer.writeu8(Blocked_PID, 0, PackedId)
	buffer.writeu8(Blocked_PID, 1, 1)

	PacketMemoryInfo.BlockedPlayers[Player.UserId] = true
	PlayerVerifyRemote:FireClient(Player, Blocked_PID)
	DebugPrint("[EZNet][Engine] - Blocked player: " .. Player.Name)
end

--[=[
	Removes a player from the block list.

	@param Player: Player
]=]
function ObjectEngine:UnBlockPlayer(Player: Player)
	-- Packet Object Data
	local ReplicatorObject = self :: { PacketInfo: Types.InternalPacket, PacketId: number }
	local PackedId = ReplicatorObject.PacketId
	local PacketMemoryInfo = ReplicatorObject.PacketInfo

	-- Variables
	--local Replicator = ReplicatorRemoteStorage:FindFirstChild(PacketMemoryInfo.Replicator) :: RemoteEvent
	local UnBlocked_PID = buffer.create(2)

	buffer.writeu8(UnBlocked_PID, 0, PackedId)
	buffer.writeu8(UnBlocked_PID, 1, 0)

	-- Checks if the player being unblocked exists, then unblocks
	if PacketMemoryInfo.BlockedPlayers[Player.UserId] then
		PacketMemoryInfo.BlockedPlayers[Player.UserId] = nil
		PlayerVerifyRemote:FireClient(Player, UnBlocked_PID)
		DebugPrint("[EZNet][Engine] - Unblocked player: " .. Player.Name)
	end
end

--[=[
	Fires a function when ever a packet revices a signal

	@param func: (layer: Player, ...any) -> ()
	@return { Disconnect: () -> () }
]=]
function ObjectEngine:OnPacket(func: (Player: Player, ...any) -> ())
	-- Variables
	local ReplicatorObject = self :: { PacketInfo: Types.InternalPacket, PacketId: number }
	local PacketMemoryInfo = ReplicatorObject.PacketInfo
	local Connection = PacketMemoryInfo.Signal:Connect(func)

	return {
		Disconnect = function()
			Connection:Disconnect()
		end,
	}
end

--[[ EZNet Internal ]]
--[=[
	Requests a packet by its name.
	
	@param Name: string
	@return PacketObjectEngine?
	@return number?
]=]
local function RequestPacketByName(Name: string): (Types.InternalPacket?, number)
	for Id, Packet in EZNet.Packets do
		if Packet.Name == Name then
			return Packet, Id
		end
	end

	return nil, -1
end

--[=[
	Performs a Packet integrity check

	@param Player: Player
	@param ...any
]=]
local function PerformPacketIntegrityCheck(Player: Player, ...)
	-- Engine
	local EngineSettings = EZNet.Engine.Settings

	-- Checks if the player has made a handshake to the server.
	if PlayersLoaded[Player] ~= true and not EngineSettings.DebugMode then
		DebugWarn("[EZNet][Integrity] - Player: " .. Player.Name .. " fired an unverified event, terminating connection.")
		return false
	elseif RunService:IsStudio() and EngineSettings.DebugMode and EngineSettings.BypassPacketIntegrity then
		DebugPrint("[EZNet][Integrity] - Packet proccessed under debug mode.")
		return true
	end

	-- Core Variables
	local Args = table.pack(...)

	-- Variables
	local ArgCount = 0 :: number
	local DetectedArgs = #Args
	local VerifiedArgs = 0 :: number
	local BufferSizeCount = 0 :: number

	local BufferCheck1 = nil :: boolean?
	local BufferCheck2 = nil :: boolean?

	local PacketInfo: Types.InternalPacket

	-- Check if the first argument is a buffer and has at least 1 byte
	if Args["n"] > 0 and typeof(Args[1]) == "buffer" and buffer.len(Args[1]) == 1 then
		local IdentifierPacket = Args[1]
		local PacketId = buffer.readu8(IdentifierPacket, 0) + 1

		-- Check if the packet with id exists
		if EZNet.Packets[PacketId] then
			PacketInfo = EZNet.Packets[PacketId]

			ArgCount = #PacketInfo.Types + 1

			BufferCheck1 = true
		else
			BufferCheck1 = false
		end
	end

	-- Checks if the player is blocked by the system.
	if PacketInfo.BlockedPlayers[Player.UserId] then
		DebugWarn("[EZNet][Integrity] - Player: " .. Player.Name .. " player block bypass detected.")
		return false
	end

	-- detects if all args in the packet are a packet
	for Index = 1, #Args do
		if typeof(Args[Index]) == "buffer" then
			BufferSizeCount += buffer.len(Args[Index])
			VerifiedArgs += 1
		else
			break
		end
	end

	-- Checks if all the args are verified
	if VerifiedArgs * 2 == (DetectedArgs + ArgCount) and DetectedArgs == ArgCount and BufferSizeCount <= EngineSettings.MaxBufferSize and PacketInfo.Enabled then
		BufferCheck2 = true
	else
		BufferCheck2 = false
	end

	-- Checks if the Packet passed all buffer checks
	if BufferCheck1 and BufferCheck2 then
		return true
	else
		return false
	end
end

--[=[
	Initializes server Player manager EZNet components
]=]
local function InitializePlayerManager()
	-- [[ Player binding ]]
	Players.PlayerAdded:Connect(function(Player: Player)
		coroutine.wrap(function()
			task.wait(EZNet.Engine.Settings.EngineYieldTime)

			if not PlayersLoaded[Player] then
				Player:Kick("[EZNet][Verify] - Player loading took too long.")
			end
		end)()
	end)

	Players.PlayerRemoving:Connect(function(Player: Player)
		if PlayersLoaded[Player] then
			PlayersLoaded[Player] = nil
		end
	end)
end

--[=[
	Initializes EZNet Replicator manager.
]=]
local function InitializeReplicatorManager()
	-- [[ Replicator binding ]]
	for ReplicatorName, _ in EZNet.Engine.Replicators do
		EZNet.Engine.ReplicatorHandlers[ReplicatorName] = {
			Thread = {},
			Receiver = {},
			InBoundQueue = {},
			OutBoundQueue = {},
		}
	end

	-- [[ Replicator Setup ]]
	for ReplicatorName, ReplicatorInfo in EZNet.Engine.Replicators do
		if ReplicatorInfo.Reliable and ReplicatorName ~= "PlayerVerify" then
			-- Variables
			local ReplicatorObject = EZNet.Engine.ReplicatorHandlers[ReplicatorName]
			--local ReplicatorConfig = EZNet.Engine.Replicators[ReplicatorName]
			local Remote = Instance.new("RemoteEvent")
			Remote.Name = ReplicatorName
			Remote.Parent = ReplicatorRemoteStorage

			-- Reciver signal connection
			ReplicatorObject.Receiver = Remote.OnServerEvent:Connect(function(Player: Player, ...: any)
				DebugPrint("[EZNet] - Reveived packet from remote: " .. ReplicatorName)

				local Success = PerformPacketIntegrityCheck(Player, ...)

				if Success then
					HandleInBoundPacket(Player, ...)
				else
					if not RunService:IsStudio() or EZNet.Engine.Settings.StudioKickEnabled then
						Player:Kick("[EZNet][Integrity] - Packet failed to pass Integrity test.")
					else
						-- Variables
						local Args = table.pack(...)
						local PacketName = "${Packet_Name_Fetch_Failed}"

						-- Check if the packet has more than 1 args and checks if the first arg is a buffer
						if Args["n"] > 0 and typeof(Args[1]) == "buffer" and buffer.len(Args[1]) == 1 and EZNet.Packets[buffer.readu8(Args[1], 0) + 1] then
							PacketName = EZNet.Packets[buffer.readu8(Args[1], 0) + 1].Name
						end
						DebugWarn("[EZNet][Integrity] - Integrity failure detected, check your packet implementation for packet: " .. PacketName)
					end
				end
			end)
		elseif not ReplicatorInfo.Reliable and ReplicatorName ~= "PlayerVerify" then
			-- Variables
			local ReplicatorObject = EZNet.Engine.ReplicatorHandlers[ReplicatorName]
			--local ReplicatorConfig = EZNet.Engine.Replicators[ReplicatorName]
			PlayerVerifyRemote = Instance.new("RemoteEvent") :: RemoteEvent
			PlayerVerifyRemote.Name = ReplicatorName
			PlayerVerifyRemote.Parent = ReplicatorRemoteStorage

			-- Reciver signal connection
			ReplicatorObject.Receiver = PlayerVerifyRemote.OnServerEvent:Connect(function(Player: Player, ...: any)
				DebugPrint("[EZNet] - Reveived packet from remote: " .. ReplicatorName)

				local Success = PerformPacketIntegrityCheck(Player, ...)

				if Success then
					HandleInBoundPacket(Player, ...)
				else
					if not RunService:IsStudio() or EZNet.Engine.Settings.StudioKickEnabled then
						Player:Kick("[EZNet][Integrity] - Packet failed to pass Integrity test.")
					else
						-- Variables
						local Args = table.pack(...)
						local PacketName = "${Packet_Name_Fetch_Failed}"

						-- Check if the packet has more than 1 args and checks if the first arg is a buffer
						if Args["n"] > 0 and typeof(Args[1]) == "buffer" and buffer.len(Args[1]) == 1 and EZNet.Packets[buffer.readu8(Args[1], 0) + 1] then
							PacketName = EZNet.Packets[buffer.readu8(Args[1], 0) + 1].Name
						end
						DebugWarn("[EZNet][Integrity] - Integrity failure detected, check your packet implementation for packet: " .. PacketName)
					end
				end
			end)
		elseif ReplicatorName == "PlayerVerify" then
			-- Variables
			local ReplicatorObject = EZNet.Engine.ReplicatorHandlers[ReplicatorName]
			local _ReplicatorConfig = EZNet.Engine.Replicators[ReplicatorName]
			local Remote = Instance.new("RemoteEvent")
			Remote.Name = ReplicatorName
			Remote.Parent = ReplicatedStorage

			-- Reciver signal connection
			ReplicatorObject.Receiver = Remote.OnServerEvent:Connect(function(Player: Player)
				if PlayersLoaded[Player] == nil then
					DebugPrint("[EZNet][Verify] - Recieved Packet from: " .. Player.Name)

					-- Variables
					local PacketDataToSend = {}

					for Id, PacketMemoryInfo in EZNet.Packets do
						PacketDataToSend[Id] = {
							Name = PacketMemoryInfo.Name,
							Replicator = PacketMemoryInfo.Replicator,
							Types = PacketMemoryInfo.Types,
							PacketId = PacketMemoryInfo.PacketId,
						}
					end

					if #PacketDataToSend > 0 then
						Remote:FireClient(Player, PacketDataToSend)
						PlayersLoaded[Player] = false
						DebugPrint("[EZNet][Verify] - Sent packet data to player: " .. Player.Name)
					else
						warn("[EZNet][Verify] - No packet data to send to player: " .. Player.Name)
					end
				elseif PlayersLoaded[Player] == false then
					PlayersLoaded[Player] = true
					DebugPrint("[EZNet][Verify] - Player: " .. Player.Name .. " has been verified.")
				else
					Player:Kick("[EZNet][Verify] - Player re-verification detected, terminating connection.")
					warn("[EZNet][Verify] - Player: " .. Player.Name .. " attempted to re-verify.")
				end
			end)
		end
	end
end

-- [[ EZNet Initialization ]]
InitializePlayerManager()
InitializeReplicatorManager()

table.freeze(EZNet.Engine.ReplicatorHandlers)
table.freeze(EZNet.Engine.Replicators)

--[ EZNet Methods ]
--[=[
	Creates a new custom remote.
		
	@param Name: string
	@param Enabled: boolean?
	@param Replicator: string
	@param TypesList: { string }
]=]
function EZNet.CreatePacket(Name: string, Enabled: boolean, Replicator: string, TypesList: { string })
	local Packet = EZNet.PacketYeilds[Name]

	if not Packet then
		-- Assertions
		assert(table.maxn(EZNet.Packets) <= 256, "Cannot create more than 256 packets.")
		assert(EZNet.Engine.Replicators[Replicator], "Unable to find replicator with name: " .. Replicator)
		assert(Replicator ~= "PlayerVerify", "The use of Replicator: 'PlayerVerify' is reserved for internal use.")

		-- Variables
		local self = {}

		self.Name = Name
		self.Replicator = Replicator
		self.Types = TypesList
		self.Signal = GoodSignal.new()
		self.PacketId = table.maxn(EZNet.Packets) + 1
		self.Enabled = Enabled
		self.BlockedPlayers = {} :: { [number]: boolean }

		EZNet.Packets[table.maxn(EZNet.Packets) + 1] = self :: Types.InternalPacket

		if not PacketCreateYeildTask then
			PacketCreateYeildTask = task.spawn(function()
				task.wait(EZNet.Engine.Settings.MaxCompileTime)
				PacketDataLoaded = true
				task.wait(2)
				EZNet.PacketYeilds = {}
			end)
		end
	elseif Packet then
		local self = EZNet.PacketYeilds[Name]

		self.Name = Name
		self.Enabled = Enabled
		self.Replicator = Replicator
		self.Types = TypesList
		self.BlockedPlayers = {} :: { [number]: boolean }

		EZNet.Packets[self.PacketId] = self :: Types.InternalPacket
		EZNet.PacketYeilds[Name] = nil
	else
		error("Packet with this name already exists.")
	end
end

--[=[
	Gets a packet by its name.
		
	@param Name: string
	@return PacketObjectEngine
]=]
function EZNet.GetPacket(Name: string)
	if PacketDataLoaded then
		-- Start variables
		local Packet, PacketId = RequestPacketByName(Name)

		-- Assertions
		assert(Packet, "Packet with this name: " .. Name .. " does not exist.")

		-- Variables
		local self = {}

		-- Packet Info
		self.PacketInfo = Packet :: Types.InternalPacket
		self.PacketId = PacketId :: number

		return setmetatable(self, ObjectEngine) :: Types.PacketObjectEngine
	else
		-- Variables
		local self = {}
		local PacketInfo = {}

		PacketInfo.Name = Name
		PacketInfo.Replicator = ""
		PacketInfo.Types = {}
		PacketInfo.Signal = GoodSignal.new()
		PacketInfo.PacketId = table.maxn(EZNet.Packets) + 1
		PacketInfo.Enabled = false
		PacketInfo.BlockedPlayers = {} :: { [number]: boolean }

		self.PacketInfo = PacketInfo
		self.PacketId = table.maxn(EZNet.Packets) + 1

		EZNet.Packets[PacketInfo.PacketId] = PacketInfo :: Types.InternalPacket

		EZNet.PacketYeilds[Name] = PacketInfo :: Types.InternalPacket

		return setmetatable(self, ObjectEngine) :: Types.PacketObjectEngine
	end
end

print("[EZNet][Engine] - " .. tostring(tick() - StartTick))

return EZNet
