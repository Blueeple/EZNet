--!strict
-- Variables
local TypeCache = {} :: { string }

-- Functions
local function CacheTypes(Typeslist: { string })
	for i = 1, #Typeslist do
		local Type = Typeslist[i]
		local TypeBuffer = buffer.create(1)

		if not table.find(TypeCache, Type) then
			table.insert(TypeCache, Type)
		end

		local TypeIndex = table.find(TypeCache, Type) :: number
		buffer.writeu16(TypeBuffer, 0, TypeIndex)
	end

	return TypeCache
end

local Codec = {}

--[=[]=]
function Codec.Encode(Table: { [string]: {
	PacketId: number,
	Typeslist: { string },
	Replicator: string,
} }): buffer
	local Encoded = buffer.create(1)

	for _PacketName, PacketInfo: { PacketId: number, Typeslist: { string }, Replicator: string } in Table do
		local _PacketId = PacketInfo.PacketId
		local Typeslist = PacketInfo.Typeslist
		local _Replicator = PacketInfo.Replicator

		local Cache = CacheTypes(Typeslist)

        print(Cache)
	end

	return Encoded
end

return Codec
