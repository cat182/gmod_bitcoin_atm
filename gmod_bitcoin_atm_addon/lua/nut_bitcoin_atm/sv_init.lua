util.AddNetworkString("nutBitcoinAtmOpen")
util.AddNetworkString("nutBitcoinAtmDeposit")
util.AddNetworkString("nutBitcoinAtmWithdraw")
util.AddNetworkString("nutBitcoinAtmChargePaid")
util.AddNetworkString("nutBitcoinAtmBalance")
util.AddNetworkString("nutBitcoinAtmConvert")

function NutscriptBitcoinAtm:IsNearATM(client)
	local atm
	
	for k, v in pairs (ents.FindByClass("nut_bitcoin_atm")) do
		if v:GetPos():DistToSqr(client:GetPos()) < 6000 then
			atm = v
		end
	end

	return (atm != nil)
end

net.Receive("nutBitcoinAtmDeposit", function(_, client)
	local amount = net.ReadUInt(32)
	if amount % 1 != 0 then return end
	
	if !IsValid(client) then return end
	if !client:getChar() then return end
	if !NutscriptBitcoinAtm:IsNearATM(client) then return end

	local charID = client:getChar():getID()

	BitcoinGmodAPI:CreateAccount("atm_"..charID, client)
    BitcoinGmodAPI:CreateCharge("atm_"..charID, amount, "Garry's Mod server", 10,
	function(lightningInvoice, onChainInvoice, expiration)
		net.Start("nutBitcoinAtmDeposit")
			net.WriteString(lightningInvoice)
			net.WriteUInt(expiration, 32)
		net.Send(client)
	end)
end)

net.Receive("nutBitcoinAtmWithdraw", function(_, client)
	local amount = net.ReadUInt(32)
	if amount % 1 != 0 then return end

	if !IsValid(client) then return end
	if !client:getChar() then return end
	if !NutscriptBitcoinAtm:IsNearATM(client) then return end	

	local charID = client:getChar():getID()

	BitcoinGmodAPI:InitiateLightningWithdrawal("atm_"..charID, amount, net.ReadString(), nil,
	function(message)
		if message == "Invalid payment request." then
			nut.util.notifyLocalized("bitcoinAtmInvalidPayment", client)

			net.Start("nutBitcoinAtmBalance")
				net.WriteUInt(BitcoinGmodAPI.accounts["atm_"..charID].balance, 32)
			net.Send(client)
		end
	end)
end)

net.Receive("nutBitcoinAtmConvert", function(_, client)
	local amount = net.ReadUInt(32)
	if amount % 1 != 0 or amount < 0 then return end

	if !IsValid(client) then return end
	if !client:getChar() then return end
	if !NutscriptBitcoinAtm:IsNearATM(client) then return end

	local charId = client:getChar():getID()
	local toTokens = net.ReadBool()

	if toTokens then
		local sats = amount
		local tokens = NutscriptBitcoinAtm.ExchangeRate * amount
		if sats % 1 != 0 then return end
		if tokens % 1 != 0 then return end

		if BitcoinGmodAPI.accounts["atm_"..charId].balance < sats then return end

		client:getChar():giveMoney(tokens)
		BitcoinGmodAPI.accounts["atm_"..charId].balance = BitcoinGmodAPI.accounts["atm_"..charId].balance - sats
	elseif NutscriptBitcoinAtm.AllowBuyingBitcoin  then
		local sats = amount / NutscriptBitcoinAtm.ExchangeRate
		local tokens = amount
		if sats % 1 != 0 then return end
		if tokens % 1 != 0 then return end

		if client:getChar():getMoney() < tokens then return end

		client:getChar():takeMoney(tokens)
		BitcoinGmodAPI.accounts["atm_"..charId].balance = BitcoinGmodAPI.accounts["atm_"..charId].balance + sats
	end
end)

hook.Add("BitcoinGmodAPI_ChargePaid", "NutscriptBitcoinAtm_ChargePaid1", function(account, owner, amount)
	if !string.StartsWith(account, "atm_") then return end
	if !IsValid(owner) then return end
	if !owner:getChar() then return end
	if !NutscriptBitcoinAtm:IsNearATM(owner) then return end	

	net.Start("nutBitcoinAtmBalance")
		net.WriteUInt(BitcoinGmodAPI.accounts["atm_"..owner:getChar():getID()].balance, 32)
		net.WriteBool(true)
	net.Send(owner)

	nut.util.notifyLocalized("bitcoinAtmPaymentReceived", owner)
end)

hook.Add("BitcoinGmodAPI_WithdrawalFailed", "NutscriptBitcoinAtm_ChargePaid1", function(account, owner, amount)
	if !string.StartsWith(account, "atm_") then return end
	if !IsValid(owner) then return end
	if !owner:getChar() then return end
	if !NutscriptBitcoinAtm:IsNearATM(owner) then return end	

	net.Start("nutBitcoinAtmBalance")
		net.WriteUInt(BitcoinGmodAPI.accounts["atm_"..owner:getChar():getID()].balance, 32)
		net.WriteBool(true)
	net.Send(owner)

	nut.util.notifyLocalized("bitcoinAtmWithdrawalFailed", owner)
end)

local function saveData()
	if !nut then return end

	-- Get the base path to write to.
	local folder = engine.ActiveGamemode()
	local path = "nutscript/"..(folder.."/")
		..(game.GetMap().."/")

	-- Create the schema folder if the data is not global.
	file.CreateDir("nutscript/"..folder.."/")

	-- If we're not ignoring the map, create a folder for the map.
	file.CreateDir(path)

	local atms = {}

	for k, v in pairs(ents.FindByClass("nut_bitcoin_atm")) do
		table.insert(atms, {v:GetPos(), v:GetAngles()})
	end

	file.Write(path.."BitcoinAtm.txt", util.TableToJSON(atms))
end

local function loadData()
	if !nut then return end

	local folder = engine.ActiveGamemode()
	local path = "nutscript/"..(folder.."/")
		..(game.GetMap().."/")

	local contents = file.Read(path.."BitcoinAtm.txt", "DATA")

	if (contents and contents ~= "") then
		local atms = util.JSONToTable(contents)

		for k, v in pairs(atms) do
			local atm = ents.Create("nut_bitcoin_atm")
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

hook.Add("InitPostEntity", "NutscriptBitcoinAtm_InitPostEntity1", loadData)
hook.Add("PostCleanupMap", "NutscriptBitcoinAtm_PostCleanupMap1", loadData)
hook.Add("ShutDown", "NutscriptBitcoinAtm_ShutDown1", saveData)
hook.Add("PreCleanupMap", "NutscriptBitcoinAtm_PreCleanupMap1", saveData)

hook.Add("CharacterLoaded", "NutscriptBitcoinAtm_CharacterLoaded", function(id)
	local ply = nut.char.loaded[id]:getPlayer()

	if (BitcoinGmodAPI.accounts["atm_"..id]) then
		net.Start("nutBitcoinAtmBalance")
			net.WriteUInt(BitcoinGmodAPI.accounts["atm_"..id].balance, 32)
		net.Send(ply)
	else
		net.Start("nutBitcoinAtmBalance")
			net.WriteUInt(0, 32)
		net.Send(ply)
	end
end)

hook.Add("OnCharacterDelete", "NutscriptBitcoinAtm_CharacterLoaded", function(client, id)
	if (BitcoinGmodAPI.accounts["atm_"..id]) then
		BitcoinGmodAPI.accounts["atm_"..id] = nil
	end
end)