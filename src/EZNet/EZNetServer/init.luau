--!strict
--!native
--!optimize 2
--[[
	Welcome to EZNet,
	You can customize settings and change how the core engine works here and modify it yourself!

	Built and scripted by @Blueeple on github / RBLX
]]
-- [ SETTINGS ]
local Settings = {
	paradigmMode = "OOP", -- Can only be "OOP" or "DOD" default ["DOD"] not setting this properly WILL cause certain contructors to NOT works
}

-- [ TYPES ]
type object = {
	id: number,
	name: string,
	enabled: boolean,
}
type EZN_oopMethods = object & {
	__index: EZN_oopMethods,
	setEnabled: (_: object, state: boolean) -> (),
}

type EZN_VersionDOD = {
	new: (name: string) -> number,
}
type EZN_VersionOOP = {
	new: (name: string) -> EZN_oopMethods,
}

-- [ TYPE SETTINGS ]
type EZNet_TypeMode = EZN_VersionOOP -- By changing this to either "EZN_VersionDOD" or "EZN_VersionOOP" you can allow type annotations t, Default ["EZN_VersionDOD"]

-- [ Memory ]
local GlobalMemory = {
	Packets = {} :: { [number]: object },
	NameMap = {} :: { [string]: number },
}

-- [ ENGINE ]
local function constructObject(name: string): object
	local object: object = {
		id = #GlobalMemory.Packets + 1,
		name = name,
		enabled = true,
	}

	table.insert(GlobalMemory.Packets, object)
	GlobalMemory.NameMap[name] = object.id
	return object
end

local function setObjectEnabled(identity: number | string, state: boolean)
	if typeof(identity) == "number" and GlobalMemory.Packets[identity] then
		GlobalMemory.Packets[identity].enabled = state
	elseif typeof(identity) == "string" and GlobalMemory.NameMap[identity] then
		local id = GlobalMemory.NameMap[identity]
		GlobalMemory.Packets[id].enabled = state
	end
end

-- [ METHODS ]
local methods = {
	object = {
		setEnabled = function(object: object, state: boolean)
			setObjectEnabled(object.id, state)
		end,
	} :: EZN_oopMethods,
	dataOriented = {
		new = function(name: string)
			return constructObject(name).id
		end,
		setEnabled = function(id: number | string, state: boolean)
			setObjectEnabled(id, state)
		end,
	} :: EZN_VersionDOD,
}
methods.object.__index = methods.object

local paragdimConsts = {
	--[[
		OOP constuctor is placed here due to how luau works
	]]
	oop = {
		new = function(name: string)
			local object = constructObject(name)
			return setmetatable(object, methods.object)
		end,
	},
	dod = methods.dataOriented,
}

--[[
	This is what allows EZNet to support both OOP and DOD by architecture.
]]
if paragdimConsts[string.lower(Settings.paradigmMode)] then
	return paragdimConsts[string.lower(Settings.paradigmMode)] :: EZN_VersionOOP | EZN_VersionDOD
end
