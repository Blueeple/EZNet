--!strict
--!native
--[[
	S8		Minimum: -128			Maximum: 127
	S16		Minimum: -32768			Maximum: 32767
	S24		Minimum: -8388608		Maximum: 8388607
	S32		Minimum: -2147483648	Maximum: 2147483647

	U8		Minimum: 0				Maximum: 255
	U16		Minimum: 0				Maximum: 65535
	U24		Minimum: 0				Maximum: 16777215
	U32		Minimum: 0				Maximum: 4294967295

	F16		±2048					[65520]
	F24		±262144					[4294959104]
	F32		±16777216				[170141183460469231731687303715884105728]
	F64		±9007199254740992		[huge]
]]
-- Objects
local buffer = buffer

-- [[ Types ]]
type AllocatableBuffer = {
	Buffer: buffer,
	BufferOffset: number,
}

export type CameraECFD = {
	Pos: Vector3,
	Rot: Vector2,
}

export type WeaponSendData = {
	WeaponId: number,
	CameraECFD: CameraECFD,
	Walkspeed: number,
	CharacterRotPos: Vector3,
	MouseRayPosition: Vector3,
}

-- [[ Buffer Allocator Engine ]]
local BufferEngine = {}
BufferEngine.__index = BufferEngine

--[=[
	Creates a buffer that initializes with 8bits.
]=]
function BufferEngine.create(Buffer: buffer?)
	local self = setmetatable({
		Buffer = Buffer or buffer.create(1),
		BufferOffset = 0,
	}, BufferEngine)

	return self
end

--[=[
	Allocate bytes to an buffer.

	**Note**: 
	Each buffer is initialized with 8 bits so if your using more than 8bits there is no need for allocation.

	@param Amount: number
]=]
function BufferEngine:AllocateBytes(Amount: number)
	-- Variables
	local AllocatableBuffer = self
	local OldBuffSize = buffer.len(AllocatableBuffer.Buffer)
	local TempBuffer = buffer.create(OldBuffSize + Amount)

	buffer.copy(TempBuffer, 0, AllocatableBuffer.Buffer)

	AllocatableBuffer.Buffer = TempBuffer
end

-- [[ Buffer write functions ]]
-- [[ Unsigned functions ]]
function BufferEngine:WriteU8(Value: number)
	local BufferData = self :: AllocatableBuffer
	buffer.writeu8(BufferData.Buffer, BufferData.BufferOffset, Value)
	BufferData.BufferOffset += 1
end

function BufferEngine:WriteU16(Value: number)
	local BufferData = self :: AllocatableBuffer
	buffer.writeu16(BufferData.Buffer, BufferData.BufferOffset, Value)
	BufferData.BufferOffset += 2
end

function BufferEngine:WriteU24(Value: number)
	local BufferData = self :: AllocatableBuffer
	buffer.writebits(BufferData.Buffer, BufferData.BufferOffset * 8, 24, Value)
	BufferData.BufferOffset += 3
end

function BufferEngine:WriteU32(Value: number)
	local BufferData = self :: AllocatableBuffer
	buffer.writeu32(BufferData.Buffer, BufferData.BufferOffset, Value)
	BufferData.BufferOffset += 4
end

-- [[ Signed integer functions ]]
function BufferEngine:WriteS8(Value: number)
	local BufferData = self :: AllocatableBuffer
	buffer.writei8(BufferData.Buffer, BufferData.BufferOffset, Value)
	BufferData.BufferOffset += 1
end

function BufferEngine:WriteS16(Value: number)
	local BufferData = self :: AllocatableBuffer
	buffer.writei16(BufferData.Buffer, BufferData.BufferOffset, Value)
	BufferData.BufferOffset += 2
end

function BufferEngine:WriteS24(Value: number)
	local BufferData = self :: AllocatableBuffer
	buffer.writebits(BufferData.Buffer, BufferData.BufferOffset * 8, 24, Value + 8388608)
	BufferData.BufferOffset += 3
end

function BufferEngine:WriteS32(Value: number)
	local BufferData = self :: AllocatableBuffer
	buffer.writei32(BufferData.Buffer, BufferData.BufferOffset, Value)
	BufferData.BufferOffset += 4
end

-- [[ Float number functions ]]
function BufferEngine:WriteF16(Value: number)
	local BufferData = self :: AllocatableBuffer
	local bitOffset = BufferData.BufferOffset * 8
	BufferData.BufferOffset += 2
	if Value == 0 then
		buffer.writebits(BufferData.Buffer, bitOffset, 16, 0b0_00000_0000000000)
	elseif Value >= 65520 then
		buffer.writebits(BufferData.Buffer, bitOffset, 16, 0b0_11111_0000000000)
	elseif Value <= -65520 then
		buffer.writebits(BufferData.Buffer, bitOffset, 16, 0b1_11111_0000000000)
	elseif Value ~= Value then
		buffer.writebits(BufferData.Buffer, bitOffset, 16, 0b0_11111_0000000001)
	else
		local sign = 0
		if Value < 0 then
			sign = 1
			Value = -Value
		end
		local mantissa, exponent = math.frexp(Value)
		buffer.writebits(BufferData.Buffer, bitOffset + 0, 10, mantissa * 2048 - 1023.5)
		buffer.writebits(BufferData.Buffer, bitOffset + 10, 5, exponent + 14)
		buffer.writebits(BufferData.Buffer, bitOffset + 15, 1, sign)
	end
end

function BufferEngine:WriteF24(Value: number)
	local BufferData = self :: AllocatableBuffer
	local bitOffset = BufferData.BufferOffset * 8
	BufferData.BufferOffset += 3
	if Value == 0 then
		buffer.writebits(BufferData.Buffer, bitOffset, 24, 0b0_000000_00000000000000000)
	elseif Value >= 4294959104 then
		buffer.writebits(BufferData.Buffer, bitOffset, 24, 0b0_111111_00000000000000000)
	elseif Value <= -4294959104 then
		buffer.writebits(BufferData.Buffer, bitOffset, 24, 0b1_111111_00000000000000000)
	elseif Value ~= Value then
		buffer.writebits(BufferData.Buffer, bitOffset, 24, 0b0_111111_00000000000000001)
	else
		local sign = 0
		if Value < 0 then
			sign = 1
			Value = -Value
		end
		local mantissa, exponent = math.frexp(Value)
		buffer.writebits(BufferData.Buffer, bitOffset + 0, 17, mantissa * 262144 - 131071.5)
		buffer.writebits(BufferData.Buffer, bitOffset + 17, 6, exponent + 30)
		buffer.writebits(BufferData.Buffer, bitOffset + 23, 1, sign)
	end
end

function BufferEngine:WriteF32(Value: number)
	local BufferData = self :: AllocatableBuffer
	buffer.writef32(BufferData.Buffer, BufferData.BufferOffset, Value)
	BufferData.BufferOffset += 4
end

function BufferEngine:WriteF64(Value: number)
	local BufferData = self :: AllocatableBuffer
	buffer.writef64(BufferData.Buffer, BufferData.BufferOffset, Value)
	BufferData.BufferOffset += 8
end

-- [[ Buffer object functions ]]
function BufferEngine:WriteBuffer(Value: buffer)
	local BufferData = self :: AllocatableBuffer
	buffer.copy(BufferData.Buffer, BufferData.BufferOffset, Value)
	BufferData.BufferOffset += buffer.len(Value)
end

-- [[ String object functions ]]
function BufferEngine:WriteString(Value: string)
	local BufferData = self :: AllocatableBuffer
	buffer.writestring(BufferData.Buffer, BufferData.BufferOffset, Value)
	BufferData.BufferOffset += #Value
end

-- [[ Buffer read functions ]]
-- [[ Unsigned integer functions ]]
function BufferEngine:ReadU8(): number
	local BufferData = self :: AllocatableBuffer
	local Value = buffer.readu8(BufferData.Buffer, BufferData.BufferOffset)
	BufferData.BufferOffset += 1
	return Value
end

function BufferEngine:ReadU16(): number
	local BufferData = self :: AllocatableBuffer
	local Value = buffer.readu16(BufferData.Buffer, BufferData.BufferOffset)
	BufferData.BufferOffset += 2
	return Value
end

function BufferEngine:ReadU24(): number
	local BufferData = self :: AllocatableBuffer
	local Value = buffer.readbits(BufferData.Buffer, BufferData.BufferOffset * 8, 24)
	BufferData.BufferOffset += 3
	return Value
end

function BufferEngine:ReadU32(): number
	local BufferData = self :: AllocatableBuffer
	local Value = buffer.readu32(BufferData.Buffer, BufferData.BufferOffset)
	BufferData.BufferOffset += 4
	return Value
end

-- [[ Singed integer functions ]]
function BufferEngine:ReadS8(): number
	local BufferData = self :: AllocatableBuffer
	local Value = buffer.readi8(BufferData.Buffer, BufferData.BufferOffset)
	BufferData.BufferOffset += 1
	return Value
end

function BufferEngine:ReadS16(): number
	local BufferData = self :: AllocatableBuffer
	local Value = buffer.readi16(BufferData.Buffer, BufferData.BufferOffset)
	BufferData.BufferOffset += 2
	return Value
end

function BufferEngine:ReadS24(): number
	local BufferData = self :: AllocatableBuffer
	local Value = buffer.readbits(BufferData.Buffer, BufferData.BufferOffset * 8, 24) - 8388608
	BufferData.BufferOffset += 3
	return Value
end

function BufferEngine:ReadS32(): number
	local BufferData = self :: AllocatableBuffer
	local Value = buffer.readi32(BufferData.Buffer, BufferData.BufferOffset)
	BufferData.BufferOffset += 4
	return Value
end

-- [[ Float number functions ]]
function BufferEngine:ReadF16(): number
	local BufferData = self :: AllocatableBuffer
	local bitOffset = BufferData.BufferOffset * 8
	BufferData.BufferOffset += 2
	local mantissa = buffer.readbits(BufferData.Buffer, bitOffset + 0, 10)
	local exponent = buffer.readbits(BufferData.Buffer, bitOffset + 10, 5)
	local sign = buffer.readbits(BufferData.Buffer, bitOffset + 15, 1)
	if mantissa == 0b0000000000 then
		if exponent == 0b00000 then
			return 0
		end
		if exponent == 0b11111 then
			return if sign == 0 then math.huge else -math.huge
		end
	elseif exponent == 0b11111 then
		return 0 / 0
	end
	if sign == 0 then
		return (mantissa / 1024 + 1) * 2 ^ (exponent - 15)
	else
		return -(mantissa / 1024 + 1) * 2 ^ (exponent - 15)
	end
end

function BufferEngine:ReadF24(): number
	local BufferData = self :: AllocatableBuffer
	local bitOffset = BufferData.BufferOffset * 8
	BufferData.BufferOffset += 3
	local mantissa = buffer.readbits(BufferData.Buffer, bitOffset + 0, 17)
	local exponent = buffer.readbits(BufferData.Buffer, bitOffset + 17, 6)
	local sign = buffer.readbits(BufferData.Buffer, bitOffset + 23, 1)
	if mantissa == 0b00000000000000000 then
		if exponent == 0b000000 then
			return 0
		end
		if exponent == 0b111111 then
			return if sign == 0 then math.huge else -math.huge
		end
	elseif exponent == 0b111111 then
		return 0 / 0
	end
	if sign == 0 then
		return (mantissa / 131072 + 1) * 2 ^ (exponent - 31)
	else
		return -(mantissa / 131072 + 1) * 2 ^ (exponent - 31)
	end
end

function BufferEngine:ReadF32()
	local BufferData = self :: AllocatableBuffer
	local Value = buffer.readf32(BufferData.Buffer, BufferData.BufferOffset)
	BufferData.BufferOffset += 4
	return Value
end

function BufferEngine:ReadF64()
	local BufferData = self :: AllocatableBuffer
	local Value = buffer.readf64(BufferData.Buffer, BufferData.BufferOffset)
	BufferData.BufferOffset += 8
	return Value
end

-- [[ Buffer object functions ]]
function BufferEngine:ReadBuffer(length: number)
	local BufferData = self :: AllocatableBuffer
	local value = buffer.create(length)
	buffer.copy(value, 0, BufferData.Buffer, BufferData.BufferOffset, length)
	BufferData.BufferOffset += length
	return value
end

-- [[ String object functions ]]
function BufferEngine:ReadString(length: number)
	local BufferData = self :: AllocatableBuffer
	local value = buffer.readstring(BufferData.Buffer, BufferData.BufferOffset, length)
	BufferData.BufferOffset += length
	return value
end

--[=[ Data Type Engine ]=]
local Types = {}
local Reads = {}
local Writes = {}
local Settings = {}

--[=[
	This is the u8 Integer type.

	Max length 0 -> 255 (256)
]=]
Types.IntU8 = "IntU8" :: string
Writes.IntU8 = function(Value: number)
	local Pointer = BufferEngine.create()
	Pointer:WriteU8(Value)

	return Pointer.Buffer
end
Reads.IntU8 = function(Value: buffer)
	local Pointer = BufferEngine.create(Value)
	return Pointer:ReadU8()
end

--[=[
	Weapon Fire type.

	@param Value: WeaponSendData
]=]
Types.FireWeapon = "FireWeapon"
Writes.FireWeapon = function(Value: WeaponSendData)
	local Pointer = BufferEngine.create()
	local CharRotPosVec = Writes.Vector3_F24(Value.CharacterRotPos)
	local MouseRayPosVec = Writes.Vector3_F24(Value.MouseRayPosition)
	local CameraECFD = Writes.CameraECFD(Value.CameraECFD)

	Pointer:AllocateBytes(34)

	Pointer:WriteU8(Value.Walkspeed)
	Pointer:WriteU16(Value.WeaponId)

	Pointer:WriteBuffer(CharRotPosVec)
	Pointer:WriteBuffer(MouseRayPosVec)
	Pointer:WriteBuffer(CameraECFD)

	return Pointer.Buffer
end
Reads.FireWeapon = function(Value: buffer): WeaponSendData
	local Pointer = BufferEngine.create(Value)

	local WalkSpeed = Pointer:ReadU8()
	local WeaponId = Pointer:ReadU16()

	local CharRotPosVec_Buffer = Pointer:ReadBuffer(9)
	local MouseRayPosVec_Buffer = Pointer:ReadBuffer(9)
	local CameraECFD_Buffer = Pointer:ReadBuffer(13)

	local CharRotPosVec = Reads.Vector3_F24(CharRotPosVec_Buffer)
	local MouseRayPosVec = Reads.Vector3_F24(MouseRayPosVec_Buffer)
	local CameraECFD = Reads.CameraECFD(CameraECFD_Buffer)

	local WeaponSendData = {
		Walkspeed = WalkSpeed,
		WeaponId = WeaponId,
		CharacterRotPos = CharRotPosVec,
		MouseRayPosition = MouseRayPosVec,
		CameraECFD = CameraECFD,
	} :: WeaponSendData

	return WeaponSendData
end

--[=[
	Weapon configurations type.
]=]
Types.WeaponConfig = "WeaponConfig"
Writes.WeaponConfig = function(_Value: { WeaponId: number })
	local Pointer = BufferEngine.create()

	Pointer:AllocateBytes(1)

	return Pointer.Buffer
end
Reads.WeaponConfig = function(Value: buffer)
	local Pointer = BufferEngine.create(Value)

	return buffer.readi8(Pointer.Buffer, 0)
end

--[[
	Float24 Vector3 type.
]]
Types.Vector3_F24 = "Vector3_F24"
Writes.Vector3_F24 = function(Value: Vector3)
	local Pointer = BufferEngine.create()

	Pointer:AllocateBytes(8)

	Pointer:WriteF24(Value.X)
	Pointer:WriteF24(Value.Y)
	Pointer:WriteF24(Value.Z)

	return Pointer.Buffer
end
Reads.Vector3_F24 = function(Value: buffer): Vector3
	local Pointer = BufferEngine.create(Value)

	local X = Pointer:ReadF24()
	local Y = Pointer:ReadF24()
	local Z = Pointer:ReadF24()

	return Vector3.new(X, Y, Z)
end

Types.CameraECFD = "CameraECFD"
Writes.CameraECFD = function(Value: CameraECFD)
	local Pointer = BufferEngine.create()
	local CameraPosVec = Writes.Vector3_F24(Value.Pos)

	Pointer:AllocateBytes(12)

	Pointer:WriteF16(Value.Rot.X)
	Pointer:WriteF16(Value.Rot.Y)
	Pointer:WriteBuffer(CameraPosVec)

	return Pointer.Buffer
end
Reads.CameraECFD = function(Value: buffer): CameraECFD
	local Pointer = BufferEngine.create(Value)
	local Rotation = Vector2.new(Pointer:ReadF16(), Pointer:ReadF16())
	local Position = Reads.Vector3_F24(Pointer:ReadBuffer(9))

	local CameraECFD = {
		Pos = Position,
		Rot = Rotation,
	} :: CameraECFD

	return CameraECFD
end

--[[
	Boolean type built using u8
]]
Types.Boolean = "Boolean"
Writes.Boolean = function(Value: boolean)
	local Pointer = BufferEngine.create()

	if Value then
		Pointer:WriteU8(1)
	else
		Pointer:WriteU8(0)
	end

	return Pointer.Buffer
end
Reads.Boolean = function(Value: buffer)
	local Pointer = BufferEngine.create(Value)
	local Bool = Pointer:ReadU8()
	local BoolValue = nil

	if Bool >= 1 then
		BoolValue = true
	elseif Bool == 0 then
		BoolValue = false
	end

	return BoolValue
end

--[=[
	WeaponController EquipWeapon type.
]=]
Types.EquipWeapon = "EquipWeapon"
Writes.EquipWeapon = function(Value: { WeaponId: number, Equip: boolean })
	local Pointer = BufferEngine.create()
	Pointer:AllocateBytes(2)

	Pointer:WriteU16(Value.WeaponId)
	if Value.Equip then
		Pointer:WriteU8(1)
	else
		Pointer:WriteU8(0)
	end

	return Pointer.Buffer
end
Reads.EquipWeapon = function(Value: buffer)
	local Pointer = BufferEngine.create(Value)
	local WeaponId = Pointer:ReadU16()
	local Bool = Pointer:ReadU8()
	local BoolValue = nil

	if Bool >= 1 then
		BoolValue = true
	elseif Bool == 0 then
		BoolValue = false
	end

	return { WeaponId = WeaponId, Equip = BoolValue }
end

return {
	Types = Types,
	Reads = Reads :: { [string]: (Value: buffer) -> ...any },
	Writes = Writes :: { [string]: (Value: any) -> ...any },
	Settings = Settings,
}
