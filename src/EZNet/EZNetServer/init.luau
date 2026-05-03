--!strict
--!native
--!optimize 2
--[[
	Welcome to EZNet,
	You can customize settings and change how the core engine works here and modify it yourself!

	Built and scripted by @Blueeple on github / RBLX
]]
-- [ SERVICES ]
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- [ TYPES ]
type object = {
	id: number,
	name: string,
	enabled: boolean,
}
type EZN_oopMethods = object & {
	__index: EZN_oopMethods,
	--[[
		Enables or disables the object by id or name.

		@param identity: number | string
		@param state: boolean
	]]
	setEnabled: (_: object, state: boolean) -> (),
}

type EZN_VersionDOD = {
	--[[
		Creates a new packet object.
	]]
	new: (name: string) -> number,
	--[[
		Enables or disables the object by id or name.

		@param identity: number | string
		@param state: boolean
	]]
	setEnabled: (id: number | string, state: boolean) -> (),
}
type EZN_VersionOOP = {
	--[[
		Creates a new packet object.
	]]
	new: (name: string) -> EZN_oopMethods,
}

-- [ SETTINGS ]
local EZNSettings = {
	checkForUpdates = true, -- Checks for updates on the github repo and warns if there is an update available and only works when in studio. Default [true]
	debugMode = RunService:IsStudio(), -- Prints debug information about the engine, such as when objects are created, enabled, disabled, and when updates are checked for. Default [RunService:IsStudio()]
	githubRepository = "https://github.com/Blueeple/EZNet", -- The github repository URL for the engine, or your specific engine fork. Default ["https://github.com/Blueeple/EZNet"]
	paradigmMode = "dod", -- Can only be "OOP" or "DOD" default ["DOD"] not setting this properly WILL cause certain contructors to NOT works. default ["DOD"]
	updateRetryTime = 2, -- Time in seconds between update checks when an update is available, default [2]
	updateMaxRetries = 5, -- Maximum number of retries for update checks when an update is available, default [5]
	versionChannel = "alpha", -- The version channel of the engine, used for update checking. Default ["alpha"]
}
type EZNet_TypeMode = EZN_VersionDOD -- By changing this to either "EZN_VersionDOD" or "EZN_VersionOOP" you can allow type annotations t, Default ["EZN_VersionDOD"]

-- [ Memory ]
local currentVersion = "0.1.0a" -- The current version of the engine, used for update checking.
local GlobalMemory = {
	Packets = {} :: { [number]: object },
	NameMap = {} :: { [string]: number },
}

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
				local success, result = pcall(function()
					return HttpService:GetAsync(EZNSettings.githubRepository .. "/raw/main/version.txt", true)
				end)

				if success then
					local latestVersion = result

					if latestVersion ~= currentVersion then
						warn(`[EZNet][Update] - Update available! Current version: ${currentVersion}, Latest version: ${latestVersion}. Please update at ${EZNSettings.githubRepository}`)
					else
						print(`[EZNet][Update] - You are using the latest version: ${currentVersion}.`)
					end

					break
				else
					warn(`[EZNet][Update] - Failed to check for updates. Attempt ${i} of ${EZNSettings.updateMaxRetries}. Error: ${result}`)
					task.wait(EZNSettings.updateRetryTime)
				end
			end
		else
			warn("[EZNet][Update] - Cannot check for updates when httpservice is disabled!")
		end
	end,
}

-- [ ENGINE ]
--[=[
	Constructs the object and stores it in memory, returns the data object.

	Not even the OOP wrapper uses the data object, just the id.

	@param name: string
]=]
local function constructObject(name: string): object
	local object: object = {
		id = #GlobalMemory.Packets + 1,
		name = name,
		enabled = true,
	}

	table.insert(GlobalMemory.Packets, object)
	GlobalMemory.NameMap[name] = object.id
	Utils.print("Constructed object with name: " .. name .. " and id: " .. object.id)

	return object
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
		new = function(name: string)
			return constructObject(name).id
		end,
		setEnabled = function(id: number | string, state: boolean)
			setObjectEnabled(id, state)
		end,
	} :: EZN_VersionDOD,
}
methods.object.__index = methods.object -- This is what sets up the standard OOP __index metamethod for luau

-- [ PARADIGM CONSTS ]
local paragdimConsts = {
	--[[
		OOP constuctor is placed here due to luau quirks.
	]]
	oop = {
		new = function(name: string)
			local object = constructObject(name)
			return setmetatable(object, methods.object)
		end,
	},

	--[[
		The DOD constuctor is just direct access to the engine functions since they return the id and not an object, so they don't use the self parameter.
	]]
	dod = methods.dataOriented,
}

--[[
	This is what allows EZNet to support both OOP and DOD by architecture.
]]
if paragdimConsts[string.lower(EZNSettings.paradigmMode)] then
	return paragdimConsts[string.lower(EZNSettings.paradigmMode)] :: EZNet_TypeMode
end
