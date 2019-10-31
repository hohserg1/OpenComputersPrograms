local component = require("component")
local shell = require("shell")
local fs = require("filesystem")
local modem = component.modem

local args, options = shell.parse(...)

local filename = args[1]
local device_address = args[2] or io.lines("last_device_address.cfg")()
local cfg = io.open("last_device_address.cfg","w")
cfg:write(device_address):close()

if #args < 1 then
  io.write("Usage: wireless_flash [<bios.lua>] [<device address>]\n")
  return
end

local file = assert(io.open(args[1], "rb"))
local bios = file:read("*a")
file:close()

io.write("Sending to "..device_address)

modem.send(device_address,1,"eeprom_update",bios)
