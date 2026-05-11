--[[
	Welcome to EZNet,
	You can customize settings and change how the core engine works here and modify it yourself!

	Built and scripted by @Blueeple (Bue) on github / RBLX

	Notices:
	- This is a custom networking framework I fear that calling this a library is a bad idea since it is more of a framework, so I call it an framework.
	It is built from the ground up with custom code and does not use any external libraries or modules, unless said module is 
	made by me or apart of the "EZ" libary of modules, such as "EZSignal" which is a custom DOD native event system built for this engine
	and other uses.

	- This engine is built with both OOP and DOD in mind, you can choose which paradigm you want to use by changing the "paradigmMode"
	setting below, and the engine will adapt to that paradigm and allow you to use type annotations for that paradigm as well.

	- The engine is built with a custom memory management system that allows for efficient storage and retrieval of packet data, channels, 
	and other necessary information for the engine to function.

	- The engine also has a custom update checking system that checks for updates on the github repository and warns the user if there is 
	an update available.

	- I have no clue if this engine will be used by anyone other than myself, but if you do end up using it, please credit me and consider
	contributing to the project if you have any ideas or improvements!

	- This is all part of my spitefull mission to make a better blink networking library or atleast be on par with 1Axen's blink library, 
	which is the most popular roblox networking library while also being more customizable and easier to use, and also to learn more about 
	how networking works in roblox and how to optimize it as much as possible.

	- Born out of pure rage and frustration with blink's type warning due to it's IDL compiler and the fact that it can't be easily modified
	 or customized without forking the entire library and maintaining your own version, which is a nightmare to do since it's codebase is so
	large and complex, and also due to the fact that it has a lot of features that I personally find unnecessary and bloated for my use case.

	- Can't forget the part where blink can't even send instances without having them be created and parented to the workspace first, which is
	a huge pain and also a security risk if you ask me, since it can lead to exploits if not used carefully.

	- Thanks you for reading this far, I hope you enjoy using EZNet as much as I enjoyed making it, and I hope it serves you well in your projects!
	although I highly doubt it will even be good enough to be used by anyone other than myself, but hey, maybe someone will find it useful or learn 
	something from it, who knows!

	- A little fun fact EZNet was originally called RMv which means RemoteManager version, but I changed the name to EZNet since I felt it was more
	fitting and also sounded cooler, and also to avoid confusion with other remote management libraries that are already out there.

	- Also EZNet started development in late 2024 around december where the first version was just a simple wrapper around remote events with no 
	memory management or anything, and it has evolved a lot since then to become the engine it is today, and I have learned a lot about how to 
	optimize and structure code in roblox along the way, and I hope to continue improving and updating the engine as I learn more and as roblox
	updates and changes.
]]
--!strict
--!native
--!optimize 2
-- [ SERVICES ]
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- [ TYPES ]
type object = {
	id: number,
	name: string,
	enabled: boolean,
	channel: string,
	types: { string },
	blockedPlayers: { number },
}
type EZN_PacketData = {
	name: string,
	channel: BaseRemoteEvent,
	types: { string },
	enabled: boolean,
}
type EZN_oopMethods = object & {
	__index: EZN_oopMethods,
	--[=[
		Enables or disables the object by id or name.

		@param identity: number | string
		@param state: boolean
	]=]
	setEnabled: (_: object, state: boolean) -> (),
}

type EZN_Debug = {
	--[[
		Reads the engine's memory and prints it to the console.

		* Debug function, only available when debug mode is enabled.
	]]
	readEngineMemory: () -> (),
	--[=[
		Reads the EZSignal Embedded memory and prints it to the console.
	]=]
	readSignalMemory: () -> (),
}
type EZN_VersionDOD = {
	--[=[
		Creates a new packet object.

		@param name: string
		@param enabled: boolean | EZN_PacketData
		@param channel: string | BaseRemoteEvent
		@param types: { string }?
		
		@return number
	]=]
	newPacket: (name: string, enabled: boolean | EZN_PacketData, channel: string? | BaseRemoteEvent?, types: { string }?) -> number,
	--[=[
		Creates a new channel also known as a remote event.

		@param name: string
		@param unreliable: boolean
	]=]
	newChannel: (name: string, unreliable: boolean) -> (),
	--[=[
		Enables or disables the object by id or name.

		@param identity: number | string
		@param state: boolean
	]=]
	setEnabled: (id: number | string, state: boolean) -> (),
	--[=[
		Blocks a player from receiving or sending a packet.

		@param identity: number | string
		@param player: Player
	]=]
	blockPlayer: (id: number | string, player: Player) -> (),
	--[=[
		Unblocks a player from receiving or sending a packet.

		@param identity: number | string
		@param player: Player
	]=]
	unblockPlayer: (id: number | string, player: Player) -> (),
	--[=[
		Binds a functions to the packet

		@param identity: number | string
		@param _func: (...any) -> ()
	]=]
	bindTo: (identity: number | string, _func: (...any) -> ()) -> (),
	--[=[
		Binds a functions to the packet, but only executes the command once.

		@param identity: number | string
		@param _func: (...any) -> ()
	]=]
	bindToOnce: (identity: number | string, _func: (...any) -> ()) -> (),
	--[=[
		Fires a packet to the player

		@param player: Player
		@param ...: any
	]=]
	fireToPlayer: (player: Player, ...any) -> (),
	--[=[
		Fires a packet all players connected to server-side framework

		@param ...: any
	]=]
	fireToAll: (...any) -> (),
	--[=[
		Fires a packet all players connected to server-side framework except for the other players specified.

		@param player: Player
		@param ...: any
	]=]
	fireToAllExcept: ({ Player }, ...any) -> (),
}
type EZN_VersionOOP = {
	--[=[
		Creates a new packet object.


	]=]
	newPacket: (name: string, enabled: boolean | EZN_PacketData, channel: string?, types: { string }?) -> EZN_oopMethods,
	--[=[
		Creates a new channel also known as a remote event.

		@param name: string
		@param unreliable: boolean
	]=]
	newChannel: (name: string, unreliable: boolean) -> (),
}

type GithubVersionInfo = {
	version: string,
	versionChannel: string,
	vendor: string,
	repository: string,
	isWallyVersion: boolean,
	isFork: boolean,
}

type Connection = {
	Connected: boolean,
	_isOnce: boolean,
	_function: (...any) -> any,
}

-- [ SETTINGS ]
local EZNSettings = {
	-- [ Engine Settings ]
	checkForUpdates = true, -- Checks for updates on the github repo and warns if there is an update available and only works when in studio. Default [true]
	debugMode = RunService:IsStudio(), -- Prints debug information about the engine, such as when objects are created, enabled, disabled, and when updates are checked for. Default [RunService:IsStudio()]
	githubRepository = "https://github.com/Blueeple/EZNet", -- The github repository URL for the engine, or your specific engine fork. Default ["https://github.com/Blueeple/EZNet"]
	paradigmMode = "dod", -- Can only be "OOP" or "DOD" default ["DOD"] not setting this properly WILL cause certain contructors to NOT works. default ["DOD"]
	updateRetryTime = 2, -- Time in seconds between update checks when an update is available, default [2]
	updateMaxRetries = 5, -- Maximum number of retries for update checks when an update is available, default [5]
	versionChannel = "InDev", -- The version channel of the engine, used for update checking. Default ["InDev"]
	isWallyVersion = false, -- Whether this version of the engine is a wally version, used for update checking. Default [false] (I BEG YALL DO NOT CHANGE THIS TO TRUE UNLESS YOU KNOW WHAT YOU ARE DOING)
	isFork = false, -- Whether this version of the engine is a fork, used for update checking. Default [false] (AGAIN I BEG YALL DO NOT CHANGE THIS TO TRUE UNLESS YOU KNOW WHAT YOU ARE DOING)
	-- [ Signal Settings ]
	yeildTime = 0.2, -- How long does the signal system poll for (EZNetV2 does not use poll based async by default)
	--[ Packet Receive settings ]
	performPacketIntegrityChecks = true, -- Good for security but SLOWER processing speed
	performKickOnInvalidPacketInStudio = false, -- Kicks player when a invalid packet is detected in studio
	-- [ EZNet handling ]
	preferInstanceHandling = false, -- Determines if EZNet will handle instances like regular remote events or EZNet style (EZNet might be more client authoritive here.)
}
type EZNet_TypeMode = EZN_VersionDOD -- By changing this to either "EZN_VersionDOD" or "EZN_VersionOOP" you can allow type annotations t, Default ["EZN_VersionDOD"]

-- [ Memory ]
local currentVersion = "0.1.0dev" -- The current version of the engine, used for update checking. (NO NOT CHANGE THIS UNLESS YOU KNOW WHAT YOU ARE DOING)
local ezsignal = {}
ezsignal._listeners = {} :: { [string]: { Connection } }
ezsignal._functionMap = {} :: { [() -> ()]: { string } }
local GlobalMemory = {
	Packets = {} :: { [number]: object },
	NameMap = {} :: { [string]: number },
	Channels = {} :: { [string]: BaseRemoteEvent },
	_RemoteEventConnections = {} :: { [string]: { RBXScriptConnection } },
	_ConnectedPlayers = {} :: { number },
	_isFreeRunning = false,
	_packetToProcess = {} :: { buffer },
}

-- [ Variables ]
local ChannelStore: Folder?

-- [ UTILS ]
--[[
	Utility functions for managing the EZNet engine.
]]
local Utils = {
	--[[
		Custom print function that only prints when debug mode is enabled.
	]]
	print = function(...)
		if EZNSettings.debugMode then
			print("[EZNet][Debug] - " .. table.concat({ ... }, " "))
		end
	end,
	--[[
		Custom warn function that only prints when debug mode is enabled.
	]]
	warn = function(...)
		if EZNSettings.debugMode then
			warn("[EZNet][Warning] - " .. table.concat({ ... }, " "))
		end
	end,
	--[[
		Checks for updates on the github repository and warns if there is an update available.
	]]
	checkForUpdates = function()
		if EZNSettings.debugMode and EZNSettings.checkForUpdates and HttpService.HttpEnabled then
			print(`[EZNet][Update] - Checking for updates.`)

			for i = 1, EZNSettings.updateMaxRetries do
				local success, result: GithubVersionInfo = pcall(function()
					local response = HttpService:GetAsync(EZNSettings.githubRepository .. "/raw/main/versionInfo.json")
					return HttpService:JSONDecode(response)
				end)

				if success then
					local latestVersion = result.version

					if latestVersion ~= currentVersion then
						warn(
							`[EZNet][Update] - Update available! Current version: {currentVersion}, Latest version: {latestVersion}. Please update at {EZNSettings.githubRepository}`
						)
						-- Maybe I add a way to contact the plugin to prompt an update in the future, but for now it will just print a warning in the console.
					else
						print(`[EZNet][Update] - You are using the latest version: {currentVersion}.`)
					end

					break
				else
					warn(`[EZNet][Update] - Failed to check for updates. Attempt {i} of {EZNSettings.updateMaxRetries}. Error: {result}`)
					task.wait(EZNSettings.updateRetryTime)
				end
			end
		else
			warn("[EZNet][Update] - Cannot check for updates when httpservice is disabled!")
		end
	end,
	--[=[
		Creates the necessary instances for the channel and sets up the event listeners for the channel.
	]=]
	createChannelStore = function()
		ChannelStore = Instance.new("Folder")
		ChannelStore.Name = "EZNet_ChannelStore"
		ChannelStore.Parent = ReplicatedStorage
	end,
	--[=[
		Reads the engine's memory and prints it to the console.
	]=]
	readEngineMemory = function()
		if EZNSettings.debugMode then
			print(GlobalMemory)
		end
	end,
	--[=[
		Reads the EZSignal Embedded memory and prints it to the console.
	]=]
	readSignalMemory = function()
		if EZNSettings.debugMode then
			print(ezsignal)
		end
	end,
}
-- [ EZSignal EMBEDDED CODE ]
function ezsignal.newSignal(Name: string)
	if ezsignal._listeners[Name] then
		warn(`[{script.Name}] - listener {Name} already exists!`)
		return false
	end

	ezsignal._listeners[Name] = {}
	return true
end

function ezsignal.destroy(Name: string)
	local listeners = ezsignal._listeners[Name]

	if not listeners then
		warn(`[{script.Name}] - listener {Name} does not exist!`)
		return
	end

	for _, connection in listeners do
		connection.Connected = false

		local map = ezsignal._functionMap[connection._function]
		if map then
			local index = table.find(map, Name)
			if index then
				table.remove(map, index)
			end

			if #map == 0 then
				ezsignal._functionMap[connection._function] = nil
			end
		end
	end

	ezsignal._listeners[Name] = nil
end

function ezsignal.bindToSignal(Name: string, _func: (...any) -> any, once: boolean?)
	local listener = ezsignal._listeners[Name]

	if not listener then
		error(`[{script.Name}] - listener {Name} does not exist!`)
	end

	local connection: Connection = {
		Connected = true,
		_isOnce = once or false,
		_function = _func,
	}

	local map = ezsignal._functionMap[_func]

	if not map then
		map = {}
		ezsignal._functionMap[_func] = map
	end

	table.insert(listener, connection)
	table.insert(map, Name)

	return connection
end

function ezsignal.bindToSignalAsync(Name: string, _func: () -> (), once: boolean?)
	local start = os.clock()

	while not ezsignal._listeners[Name] do
		if os.clock() - start > EZNSettings.yeildTime then
			error(`[{script.Name}] - yeild passed for listener {Name}`)
		end

		task.wait()
	end

	return ezsignal.bindToSignal(Name, _func, once)
end

function ezsignal.unbindFromSignal(Name: string, _func: () -> (), unbindAll: boolean?)
	local listener = ezsignal._listeners[Name]
	local map = ezsignal._functionMap[_func]

	if not listener or not map then
		return
	end

	for i = #listener, 1, -1 do
		local connection = listener[i]

		if connection._function == _func then
			connection.Connected = false
			table.remove(listener, i)

			local idx = table.find(map, Name)
			if idx then
				table.remove(map, idx)
			end

			if not unbindAll then
				break
			end
		end
	end

	if #map == 0 then
		ezsignal._functionMap[_func] = nil
	end
end

function ezsignal.fireSignal(Name: string, ...)
	local listener = ezsignal._listeners[Name]

	if not listener then
		warn(`[{script.Name}] - listener {Name} does not exist!`)
		return
	end

	for i = #listener, 1, -1 do
		local connection = listener[i]
		local listenerIndex = table.find(ezsignal._functionMap[connection._function], Name)

		if connection.Connected then
			task.spawn(connection._function, ...)
			if connection._isOnce and listenerIndex then
				table.remove(listener, i)
				table.remove(ezsignal._functionMap[connection._function], listenerIndex)
			end
		end
	end
end

function ezsignal.fireSignalAsync(Name: string, ...)
	local listener = nil
	local lastYeild = os.clock()
	local yeildTime = 0

	repeat
		listener = ezsignal._listeners[Name]
		yeildTime += (os.clock() - lastYeild)
		lastYeild = os.clock()
		task.wait()
	until (yeildTime > EZNSettings.yeildTime) or listener

	if listener then
		for i = #listener, 1, -1 do
			local connection = listener[i]
			local listenerIndex = table.find(ezsignal._functionMap[connection._function], Name)

			if connection.Connected then
				task.spawn(connection._function, ...)
				if connection._isOnce and listenerIndex then
					table.remove(listener, i)
					table.remove(ezsignal._functionMap[connection._function], listenerIndex)
				end
			end
		end

		return
	else
		warn(`[{script.Name}] - yeild passed for listener {Name}`)
		return
	end
end

-- [ ENGINE ]

--[=[
	Handles the engines packets integrity checks
]=]
local function perfromPacketIntegrityCheck(player: Player, args: { n: number, [number]: any })
	if args["n"] > 2 then
		return false
	end
	if args[2] and typeof(args[2]) ~= "table" then
		return false
	end
	if args[2] and typeof(args[2]) == "table" then
		for i, InstanceId in args[2] do
			if typeof(i) ~= "number" then
				return false
			end
			if typeof(InstanceId) ~= "string" then
				return false
			end
		end
	end
	if typeof(args[1]) ~= "buffer" then
		return false
	end

	-- Variables
	local packetId = buffer.readu8(args[1], 0) + 1
	local packetMemoryInfo = GlobalMemory.Packets[packetId]

	if not packetMemoryInfo then
		return false
	end
	if table.find(packetMemoryInfo.blockedPlayers, player.UserId) then
		return false
	end
	if not table.find(GlobalMemory._ConnectedPlayers, player.UserId) then
		warn(`[EZNet][Validation] - Player {player} is not connected.`)
		return false
	end

	-- add the other memory size checks here!

	return true
end

--[=[
	Decodes the packet for EZNet
]=]
local function performPacketBufferDecoding(args: { n: number, [number]: any })
	local packetId = buffer.readu8(args[1], 0) + 1
	local packetMemoryInfo = GlobalMemory.Packets[packetId]

	print(packetMemoryInfo, args[2] or {})
end

--[=[
	Handles the remote events server connection things idk
]=]
local function handleServerRemoteEvents(player: Player, ...)
	if EZNSettings.performPacketIntegrityChecks then
		local didPacketPassCheck = perfromPacketIntegrityCheck(player, table.pack(...))
		if not didPacketPassCheck and not RunService:IsStudio() then
			player:Kick(`EZNet was unable to handle a malformed packet, client has initiated disconnect.`)
			return
		elseif not didPacketPassCheck and not EZNSettings.performKickOnInvalidPacketInStudio then
			warn(`[EZNet][Sandbox] - EZNet was unable to handle a malformed packet, client has initiated disconnect.`)
			return
		end
	end
	performPacketBufferDecoding(table.pack(...))
end

--[=[
	Constructs the object and stores it in memory, returns the data object.

	Not even the OOP wrapper uses the data object, just the id.

	@param name: string
	@param enabled: boolean | EZN_PacketData
	@param channel: string | BaseRemoteEvent.
	@param types: { string }?
		
	@return object
]=]
local function constructObject(name: string, enabled: boolean | EZN_PacketData, channel: string? | BaseRemoteEvent?, types: { string }?): object
	local packetId = #GlobalMemory.Packets + 1

	local objectRemoteName: string
	local objectEnabled: boolean
	local objectTypes: { string } = types :: { string }

	-- Check if name already exists
	if GlobalMemory.NameMap[name] then
		Utils.warn(`Object with name "{name}" already exists!`)
		return nil :: any
	end

	-- Parse overloads
	if typeof(enabled) == "boolean" then
		objectEnabled = enabled
		objectRemoteName = tostring(channel)
		Utils.print(`Constructing packet: {name} as arguments`)
	elseif typeof(enabled) == "table" then
		local data = enabled :: EZN_PacketData

		objectEnabled = data.enabled
		objectTypes = data.types
		objectRemoteName = tostring(data.channel)

		Utils.print(`Constructing packet: {name} as table`)
	else
		Utils.warn("Invalid enabled parameter passed to constructObject")
		return nil :: any
	end

	-- Validate channel
	if objectRemoteName == "nil" then
		Utils.warn(`Invalid channel {objectRemoteName} passed to constructObject: {name}`)
	elseif not GlobalMemory.Channels[objectRemoteName] then
		Utils.warn(`Channel {objectRemoteName} does not exist for packet: {name}`)
		return nil :: any
	end

	local object: object = {
		id = packetId,
		name = name,
		enabled = objectEnabled,
		channel = objectRemoteName,
		types = objectTypes,
		blockedPlayers = {},
	}

	ezsignal.newSignal(name .. "_Signal")
	table.insert(GlobalMemory.Packets, object)
	GlobalMemory.NameMap[name] = packetId

	Utils.print(`Constructed object "{name}" with id: {packetId}`)

	return object
end

--[=[
	Constructs a channel also known as a remote event.

	@param name: string
	@param unreliable: boolean
]=]
local function constructChannel(name: string, unreliable: boolean)
	if ChannelStore and ChannelStore:FindFirstChild(name) then
		Utils.warn("Channel with name " .. name .. " already exists!")
		return
	end

	local channel: RemoteEvent

	if not unreliable then
		channel = Instance.new("RemoteEvent")
		channel.Name = name
		channel.Parent = ChannelStore
	else
		channel = Instance.new("UnreliableRemoteEvent") :: any
		channel.Name = name
		channel.Parent = ChannelStore
	end

	GlobalMemory._RemoteEventConnections[name] = channel.OnServerEvent:Connect(handleServerRemoteEvents)
	GlobalMemory.Channels[name] = channel
	Utils.print("Constructed channel with identity: " .. name)
end

--[=[
	Enables or disables the object by id or name.

	@param identity: number | string
	@param state: boolean
]=]
local function setObjectEnabled(identity: number | string, state: boolean)
	if typeof(identity) == "number" and GlobalMemory.Packets[identity] then
		GlobalMemory.Packets[identity].enabled = state
		Utils.print("Set object enabled state to " .. tostring(state) .. " for object with id: " .. identity)
	elseif typeof(identity) == "string" and GlobalMemory.NameMap[identity] then
		local id = GlobalMemory.NameMap[identity]
		GlobalMemory.Packets[id].enabled = state
		Utils.print("Set object enabled state to " .. tostring(state) .. " for object with name: " .. identity)
	end
end

--[=[
	Blocks a player from receiving or sending a packet.
]=]
local function blockPlayer(identity: number | string, player: Player)
	if typeof(identity) == "number" and GlobalMemory.Packets[identity] then
		table.insert(GlobalMemory.Packets[identity].blockedPlayers, player.UserId)
		Utils.print(`Blocked player {player.Name} with id {player.UserId} from packet with id: {identity}`)
	elseif typeof(identity) == "string" and GlobalMemory.NameMap[identity] then
		local id = GlobalMemory.NameMap[identity]
		table.insert(GlobalMemory.Packets[id].blockedPlayers, player.UserId)
		Utils.print(`Blocked player {player.Name} with id {player.UserId} from packet with id: {identity}`)
	end
end

--[=[
	Unblocks a player from receiving or sending a packet.
]=]
local function unblockPlayer(identity: number | string, player: Player)
	if typeof(identity) == "number" and GlobalMemory.Packets[identity] then
		local blockedPlayers = GlobalMemory.Packets[identity].blockedPlayers
		table.remove(blockedPlayers, table.find(blockedPlayers, player.UserId))
		Utils.print(`Unblocked player {player.Name} with id {player.UserId}`)
	elseif typeof(identity) == "string" and GlobalMemory.NameMap[identity] then
		local id = GlobalMemory.NameMap[identity]
		local blockedPlayers = GlobalMemory.Packets[id].blockedPlayers
		table.remove(blockedPlayers, table.find(blockedPlayers, player.UserId))
		Utils.print(`Unblocked player {player.Name} with id {player.UserId}`)
	end
end

--[=[
	Recieves a packet and fires the corresponding signal.

	@param packetId: number
	@param _func: (...any) -> ()
]=]
local function bindToPacketRecieve(identity: number | string, _func: (...any) -> ())
	if typeof(identity) == "number" and GlobalMemory.Packets[identity] then
		local signalName = GlobalMemory.Packets[identity].name .. "_Signal"
		ezsignal.bindToSignal(signalName, _func)
	elseif typeof(identity) == "string" and GlobalMemory.NameMap[identity] then
		local id = GlobalMemory.NameMap[identity]
		local signalName = GlobalMemory.Packets[id].name .. "_Signal"
		ezsignal.bindToSignal(signalName, _func)
	end
end

--[=[
	Recieves a packet and fires the corresponding signal.

	@param packetId: number
	@param _func: (...any) -> ()
]=]
local function bindToPacketRecieve_Once(identity: number | string, _func: (...any) -> ())
	if typeof(identity) == "number" and GlobalMemory.Packets[identity] then
		local signalName = GlobalMemory.Packets[identity].name .. "_Signal"
		ezsignal.bindToSignal(signalName, _func, true)
	elseif typeof(identity) == "string" and GlobalMemory.NameMap[identity] then
		local id = GlobalMemory.NameMap[identity]
		local signalName = GlobalMemory.Packets[id].name .. "_Signal"
		ezsignal.bindToSignal(signalName, _func, true)
	end
end

-- [ METHODS ]
local methods = {
	--[[
		These are the OOP methods, they return the data object and they use the self parameter since they return an object.
	]]
	object = {
		setEnabled = function(object: object, state: boolean)
			setObjectEnabled(object.id, state)
		end,
	} :: EZN_oopMethods,
	--[[
		The DOD methods are just direct access to the engine functions since they return the id and not an object, so they don't use the self parameter.
	]]
	dataOriented = {
		newPacket = function(name: string, enabled: boolean | EZN_PacketData, channel: string, types: { string })
			return constructObject(name, enabled, channel, types).id
		end,
		newChannel = constructChannel,
		setEnabled = setObjectEnabled,
		blockPlayer = blockPlayer,
		unblockPlayer = unblockPlayer,
		bindTo = bindToPacketRecieve,
		bindToOnce = bindToPacketRecieve_Once,
	} :: EZN_VersionDOD,
}
methods.object.__index = methods.object -- This is what sets up the standard OOP __index metamethod for luau

-- [ PARADIGM CONSTS ]
local paragdimConsts = {
	--[[
		OOP constuctor is placed here due to luau quirks.
	]]
	oop = {
		newPacket = function(name: string, enabled: boolean | EZN_PacketData, channel: string, types: { string })
			local object = constructObject(name, enabled, channel, types)
			return setmetatable(object, methods.object)
		end,
		newChannel = function(name: string, unreliable: boolean)
			constructChannel(name, unreliable)
		end,
	},

	--[[
		The DOD constuctor is just direct access to the engine functions since they return the id and not an object, so they don't use the self parameter.
	]]
	dod = methods.dataOriented,
}

-- [ Initial startup fucntions ]
local function InitalizeFramework()
	-- Initialization
	if EZNSettings.debugMode then
		Utils.print("Debug mode is enabled, injecting debug functions into the engine.")
		paragdimConsts[string.lower(EZNSettings.paradigmMode)]["readEngineMemory"] = Utils.readEngineMemory
		paragdimConsts[string.lower(EZNSettings.paradigmMode)]["readSignalMemory"] = Utils.readSignalMemory
	end
	if not ChannelStore then
		Utils.createChannelStore()
	end
	if EZNSettings.checkForUpdates then
		Utils.checkForUpdates()
	end

	-- Variables
	local UtilityRemote = Instance.new("RemoteEvent")
	UtilityRemote.Name = "EZNet_Utlis"
	UtilityRemote.Parent = ReplicatedStorage

	UtilityRemote.OnServerEvent:Connect(function(player: Player, isResync: boolean, Id: number)
		if isResync and GlobalMemory.Packets[Id] then
			local PacketMemoryInfo = GlobalMemory.Packets[Id]
			print(PacketMemoryInfo)
		elseif not isResync then
			table.insert(GlobalMemory._ConnectedPlayers, player.UserId)
			print(player, "Connected!")
		end
	end)
end

--[[
	This is what allows EZNet to support both OOP and DOD by architecture.
]]
if paragdimConsts[string.lower(EZNSettings.paradigmMode)] then
	task.spawn(InitalizeFramework)

	return paragdimConsts[string.lower(EZNSettings.paradigmMode)] :: EZNet_TypeMode & EZN_Debug
end
