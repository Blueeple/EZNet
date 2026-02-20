--!strict
-- Variables
local Internal = {
	_Messagers = {} :: {
		[string]: {
			Messages: { string },
			LatestMessage: string,
			Callbacks: {
				Once: { [number]: (Message: string) -> () },
				Connect: { [number]: (Message: string) -> () },
			},
			Functions: {
				SendMessage: (...any) -> (),
				OnMessage: (Callback: (Message: string) -> ()) -> (),
				OnMessageOnce: (Callback: (Message: string) -> ()) -> (),
				GetName: () -> string,
			},
		},
	},
	_MessagerPointer = {} :: { string },
	_Configs = {
		YeildTime = 3,
		MaxMessages = 64,
		AutoCleanUp = true,
	},
}

--[=[
	Generates a UID
]=]
local function GenerateUID(Count: number)
	local Chars = {}

	for _ = 0, Count or 64 do
		if math.random(1, 2) > 1 then
			local CharId = math.random(1, 26)
			local Char = string.char(64 + CharId)

			table.insert(Chars, Char)
		else
			local CharId = math.random(1, 9)
			local Char = string.char(47 + CharId)

			table.insert(Chars, Char)
		end
	end

	return table.concat(Chars)
end

local MessagerModule = {}

--[=[
    Registers a new lisiener.

	@param CustomName: string?
]=]
function MessagerModule.CreateListener(Name: string?)
	if Name and Internal._Messagers[Name] then
		warn(`[LuauMessager]  - Messager of [{Name}] already exists, returning existing`)
		return Internal._Messagers[Name].Functions
	end

	local MessagerUID = Name or GenerateUID(24)

	table.insert(Internal._MessagerPointer, MessagerUID)
	Internal._Messagers[MessagerUID] = {
		Messages = {},
		LatestMessage = "",
		Callbacks = {
			Connect = {},
			Once = {},
		},
		Functions = {} :: any,
	}
	local MessagerObject = Internal._Messagers[MessagerUID]

	MessagerObject.Functions = {
		SendMessage = function(...)
			local Text = table.concat(table.pack(...))

			if Internal._Configs.AutoCleanUp and #MessagerObject.Messages >= Internal._Configs.MaxMessages then
				table.clear(MessagerObject.Messages)
			end

			MessagerObject.LatestMessage = Text
			table.insert(MessagerObject.Messages, Text)

			for _, Callback in MessagerObject.Callbacks.Once do
				task.spawn(Callback, Text)
			end

			for _, Callback in MessagerObject.Callbacks.Connect do
				task.spawn(Callback, Text)
			end

			table.clear(MessagerObject.Callbacks.Once)
		end,
		OnMessage = function(Callback: (Message: string) -> ())
			table.insert(MessagerObject.Callbacks.Connect, Callback)
		end,
		OnMessageOnce = function(Callback: (Message: string) -> ())
			table.insert(MessagerObject.Callbacks.Connect, Callback)
		end,
		GetName = function()
			return MessagerUID
		end,
	}

	return MessagerObject.Functions
end

--[=[
    Gets the messager by id.

    @param MessagerId: number
]=]
function MessagerModule.GetMessagerById(MessagerId: number)
	local MessagerUID = Internal._MessagerPointer[MessagerId]

	if MessagerUID then
		return MessagerUID
	else
		return ""
	end
end

function MessagerModule.SendMessage(MessagerName: string, ...)
	if MessagerName and not Internal._Messagers[MessagerName] then
		warn(`[LuauMessager]  - Messager of [{MessagerName}] does not exist!`)
		return
	end
	local MessagerObject = Internal._Messagers[MessagerName]
	local Text = table.concat(table.pack(...))

	MessagerObject.LatestMessage = Text
	table.insert(MessagerObject.Messages, Text)

	for _, Callback in MessagerObject.Callbacks.Once do
		task.spawn(Callback, Text)
	end

	for _, Callback in MessagerObject.Callbacks.Connect do
		task.spawn(Callback, Text)
	end

	table.clear(MessagerObject.Callbacks.Once)
end

function MessagerModule.SendMessageAsync(MessagerName: string, ...)
	local CurrentYeildTime = 0

	if MessagerName and not Internal._Messagers[MessagerName] then
		repeat
			if CurrentYeildTime >= Internal._Configs.YeildTime then
				warn(`[LuauMessager]  - Messager of [{MessagerName}] does not exist!`)
				return
			else
				task.wait(0.01)
				CurrentYeildTime += 0.01
			end

		until Internal._Messagers[MessagerName]
	end

	local MessagerObject = Internal._Messagers[MessagerName]
	local Text = table.concat(table.pack(...))

	MessagerObject.LatestMessage = Text
	table.insert(MessagerObject.Messages, Text)

	for _, Callback in MessagerObject.Callbacks.Once do
		task.spawn(Callback, Text)
	end

	for _, Callback in MessagerObject.Callbacks.Connect do
		task.spawn(Callback, Text)
	end

	table.clear(MessagerObject.Callbacks.Once)
end

function MessagerModule.OnMessage(MessagerName: string, Callback: (Message: string) -> ())
	if MessagerName and not Internal._Messagers[MessagerName] then
		warn(`[LuauMessager]  - Messager of [{MessagerName}] does not exist!`)
		return
	end
	local MessagerObject = Internal._Messagers[MessagerName]

	table.insert(MessagerObject.Callbacks.Connect, Callback)
end

function MessagerModule.OnMessageAsync(MessagerName: string, Callback: (Message: string) -> ())
	local CurrentYeildTime = 0

	if MessagerName and not Internal._Messagers[MessagerName] then
		repeat
			if CurrentYeildTime >= Internal._Configs.YeildTime then
				warn(`[LuauMessager]  - Messager of [{MessagerName}] does not exist!`)
				return
			else
				task.wait(0.01)
				CurrentYeildTime += 0.01
			end

		until Internal._Messagers[MessagerName]
	end
	local MessagerObject = Internal._Messagers[MessagerName]

	table.insert(MessagerObject.Callbacks.Connect, Callback)
end

function MessagerModule.OnMessageOnce(MessagerName: string, Callback: (Message: string) -> ())
	if MessagerName and not Internal._Messagers[MessagerName] then
		warn(`[LuauMessager]  - Messager of [{MessagerName}] does not exist!`)
		return
	end
	local MessagerObject = Internal._Messagers[MessagerName]

	table.insert(MessagerObject.Callbacks.Once, Callback)
end

function MessagerModule.OnMessageOnceAync(MessagerName: string, Callback: (Message: string) -> ())
	local CurrentYeildTime = 0

	if MessagerName and not Internal._Messagers[MessagerName] then
		repeat
			if CurrentYeildTime >= Internal._Configs.YeildTime then
				warn(`[LuauMessager]  - Messager of [{MessagerName}] does not exist!`)
				return
			else
				task.wait(0.01)
				CurrentYeildTime += 0.01
			end

		until Internal._Messagers[MessagerName]
	end
	local MessagerObject = Internal._Messagers[MessagerName]

	table.insert(MessagerObject.Callbacks.Once, Callback)
end

return MessagerModule
