-- API
include("bitcoin_gmod_api/sh_config.lua")

if SERVER then
    AddCSLuaFile("bitcoin_gmod_api/sh_config.lua")
    AddCSLuaFile("bitcoin_gmod_api/cl_qrencode.lua")
    include("bitcoin_gmod_api/sv_init.lua")
end

if CLIENT then
    include("bitcoin_gmod_api/cl_qrencode.lua")
end

-- NutScript
include("nut_bitcoin_atm/sh_config.lua")

if SERVER then
    AddCSLuaFile("nut_bitcoin_atm/sh_config.lua")
    AddCSLuaFile("nut_bitcoin_atm/cl_init.lua")
    include("nut_bitcoin_atm/sv_init.lua")
end

if CLIENT then
    include("nut_bitcoin_atm/cl_init.lua")
end


-- DarkRP
include("darkrp_bitcoin_atm/sh_config.lua")

if SERVER then
    AddCSLuaFile("darkrp_bitcoin_atm/sh_config.lua")
    AddCSLuaFile("darkrp_bitcoin_atm/cl_init.lua")
    include("darkrp_bitcoin_atm/sv_init.lua")
end

if CLIENT then
    include("darkrp_bitcoin_atm/cl_init.lua")
end