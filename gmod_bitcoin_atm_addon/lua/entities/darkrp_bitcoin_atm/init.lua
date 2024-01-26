include("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:Initialize()
	self:SetModel("models/oldbill/bitcoin atm new.mdl")
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	
	if (isfunction(self.PostInitialize)) then
		self:PostInitialize()
	end

	self:PhysicsInit(SOLID_VPHYSICS)
	local physObj = self:GetPhysicsObject()

	if (IsValid(physObj)) then
		physObj:EnableMotion(true)
		physObj:Wake()
	end
end

function ENT:Use(activator)
	if self:GetPos():DistToSqr(activator:GetPos()) < 6000 then
		net.Start("darkrpBitcoinAtmOpen")
			net.WriteEntity(self)
		net.Send(activator)
	end
end
