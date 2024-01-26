util.AddNetworkString("darkrpBitcoinAtmOpen")
util.AddNetworkString("darkrpBitcoinAtmDeposit")
util.AddNetworkString("darkrpBitcoinAtmWithdraw")
util.AddNetworkString("darkrpBitcoinAtmChargePaid")
util.AddNetworkString("darkrpBitcoinAtmBalance")
util.AddNetworkString("darkrpBitcoinAtmConvert")
util.AddNetworkString("darkrpBitcoinAtmNotify")

function DarkrpBitcoinAtm:IsNearATM(client)
	local atm
	
	for k, v in pairs (ents.FindByClass("darkrp_bitcoin_atm")) do
		if v:GetPos():DistToSqr(client:GetPos()) < 6000 then
			atm = v
		end
	end

	return (atm != nil)
end

net.Receive("darkrpBitcoinAtmNotify", function(_, client)
	if !IsValid(client) then return end

	DarkRP.notify(client, 1, 5, DarkrpBitcoinAtm.lang[net.ReadString()])
end)

net.Receive("darkrpBitcoinAtmDeposit", function(_, client)	
	if !IsValid(client) then return end
	if !DarkrpBitcoinAtm:IsNearATM(client) then return end

	BitcoinGmodAPI:CreateAccount("darkrpAtm_"..client:SteamID64(), client)
    BitcoinGmodAPI:CreateCharge("darkrpAtm_"..client:SteamID64(), net.ReadUInt(32), "Garry's Mod server", 10,
	function(lightningInvoice, onChainInvoice, expiration)
		net.Start("darkrpBitcoinAtmDeposit")
			net.WriteString(lightningInvoice)
			net.WriteUInt(expiration, 32)
		net.Send(client)
	end)
end)

net.Receive("darkrpBitcoinAtmWithdraw", function(_, client)
	if !IsValid(client) then return end
	if !DarkrpBitcoinAtm:IsNearATM(client) then return end	

	local id = client:SteamID64()
	local amount = net.ReadUInt(32)

	BitcoinGmodAPI:InitiateLightningWithdrawal("darkrpAtm_"..id, amount, net.ReadString(), nil,
	function(message)
		if message == "Invalid payment request." then
			DarkRP.notify(client, 0, 5, DarkrpBitcoinAtm.lang.invalidPayment)

			net.Start("darkrpBitcoinAtmBalance")
				net.WriteUInt(BitcoinGmodAPI.accounts["darkrpAtm_"..id].balance, 32)
			net.Send(client)
		end
	end)
end)

net.Receive("darkrpBitcoinAtmConvert", function(_, client)
	local amount = net.ReadUInt(32)
	if amount % 1 != 0 or amount < 0 then return end

	if !IsValid(client) then return end
	if !DarkrpBitcoinAtm:IsNearATM(client) then return end	

	local id = client:SteamID64()
	local toTokens = net.ReadBool()

	if toTokens then
		local sats = amount
		local tokens = DarkrpBitcoinAtm.ExchangeRate * amount
		if sats % 1 != 0 then return end
		if tokens % 1 != 0 then return end

		if BitcoinGmodAPI.accounts["darkrpAtm_"..id].balance < sats then return end

		client:addMoney(tokens)
		BitcoinGmodAPI.accounts["darkrpAtm_"..id].balance = BitcoinGmodAPI.accounts["darkrpAtm_"..id].balance - sats
	elseif DarkrpBitcoinAtm.AllowBuyingBitcoin then
		local sats = amount / DarkrpBitcoinAtm.ExchangeRate
		local tokens = amount
		if sats % 1 != 0 then return end
		if tokens % 1 != 0 then return end

		if client:getDarkRPVar("money") < tokens then return end

		client:addMoney(tokens * (-1))
		BitcoinGmodAPI.accounts["darkrpAtm_"..id].balance = BitcoinGmodAPI.accounts["darkrpAtm_"..id].balance + sats
	end
end)

hook.Add("BitcoinGmodAPI_ChargePaid", "DarkrpBitcoinAtm_ChargePaid1", function(account, owner, amount)
	if !string.StartsWith(account, "darkrpAtm_") then return end
	if !IsValid(owner) then return end
	if !DarkrpBitcoinAtm:IsNearATM(owner) then return end	

	net.Start("darkrpBitcoinAtmBalance")
		net.WriteUInt(BitcoinGmodAPI.accounts["darkrpAtm_"..owner:SteamID64()].balance, 32)
		net.WriteBool(true)
	net.Send(owner)

	DarkRP.notify(owner, 0, 5, DarkrpBitcoinAtm.lang.paymentReceived)
end)

hook.Add("BitcoinGmodAPI_WithdrawalFailed", "DarkrpBitcoinAtm_ChargePaid1", function(account, owner, amount)
	if !string.StartsWith(account, "darkrpAtm_") then return end	
	if !IsValid(owner) then return end
	if !DarkrpBitcoinAtm:IsNearATM(owner) then return end

	net.Start("darkrpBitcoinAtmBalance")
		net.WriteUInt(BitcoinGmodAPI.accounts["darkrpAtm_"..owner:SteamID64()].balance, 32)
		net.WriteBool(true)
	net.Send(owner)

	DarkRP.notify(client, 0, 5, DarkrpBitcoinAtm.lang.withdrawalFailed)
end)

local function saveData()
	if !DarkRP then return end

	-- Get the base path to write to.
	local folder = engine.ActiveGamemode()
	local path = "darkrp/"..(folder.."/")
		..(game.GetMap().."/")

	-- Create the schema folder if the data is not global.
	file.CreateDir("darkrp/"..folder.."/")

	-- If we're not ignoring the map, create a folder for the map.
	file.CreateDir(path)

	local atms = {}

	for k, v in pairs(ents.FindByClass("darkrp_bitcoin_atm")) do
		table.insert(atms, {v:GetPos(), v:GetAngles()})
	end

	file.Write(path.."BitcoinAtm.txt", util.TableToJSON(atms))
end

local function loadData()
	if !DarkRP then return end

	local folder = engine.ActiveGamemode()
	local path = "darkrp/"..(folder.."/")
		..(game.GetMap().."/")

	local contents = file.Read(path.."BitcoinAtm.txt", "DATA")

	if (contents and contents ~= "") then
		local atms = util.JSONToTable(contents)

		for k, v in pairs(atms) do
			local atm = ents.Create("darkrp_bitcoin_atm")
			atm:SetPos(v[1])
			atm:SetAngles(v[2])
			atm:Spawn()
			atm:SetSolid(SOLID_VPHYSICS)
			atm:PhysicsInit(SOLID_VPHYSICS)

			local physObject = atm:GetPhysicsObject()

			if (physObject) then
				physObject:EnableMotion()
			end
		end
	end
end

hook.Add("InitPostEntity", "DarkrpBitcoinAtm_InitPostEntity1", loadData)
hook.Add("PostCleanupMap", "DarkrpBitcoinAtm_PostCleanupMap1", loadData)
hook.Add("ShutDown", "DarkrpBitcoinAtm_ShutDown1", saveData)
hook.Add("PreCleanupMap", "DarkrpBitcoinAtm_PreCleanupMap1", saveData)

hook.Add("PlayerInitialSpawn", "DarkrpBitcoinAtm_PlayerInitialSpawn", function(ply)
	local id = ply:SteamID64()
	if !id then return end

	if (BitcoinGmodAPI.accounts["darkrpAtm_"..id]) then
		net.Start("darkrpBitcoinAtmBalance")
			net.WriteUInt(BitcoinGmodAPI.accounts["darkrpAtm_"..id].balance, 32)
		net.Send(ply)
	else
		net.Start("darkrpBitcoinAtmBalance")
			net.WriteUInt(0, 32)
		net.Send(ply)
	end
end)