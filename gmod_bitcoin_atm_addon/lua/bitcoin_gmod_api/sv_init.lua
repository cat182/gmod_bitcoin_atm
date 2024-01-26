BitcoinGmodAPI.accounts = BitcoinGmodAPI.accounts or {}

function BitcoinGmodAPI:CreateAccount(id, client)
	if BitcoinGmodAPI.accounts[id] then
		return false
	end

	if client then
		BitcoinGmodAPI.accounts[id] = {owner = client:SteamID64(), balance  = 0, pending_charges = {}, pending_withdrawals = {}}
	else
		BitcoinGmodAPI.accounts[id] = {balance  = 0, pending_charges = {}, pending_withdrawals = {}}
	end
end

function BitcoinGmodAPI:CreateCharge(account, amount, description, ttl, onSuccess, onFailure)
	HTTP({
        	url= "https://api.opennode.com/v1/charges", 
        	method= "POST", 
        	headers= { 
	 	   		['accept']= 'application/json',
				['Content-Type']= 'application/json',
	  	  		['Authorization']= BitcoinGmodAPI.InvoiceKey
        	},
        	success= function( code, body, headers )
				local json = util.JSONToTable(body)
				local data = json.data

				if data then
					BitcoinGmodAPI.accounts[account].pending_charges[data.id] = true

					if onSuccess then
						onSuccess(data.lightning_invoice.payreq, data.chain_invoice.address, data.created_at + 600)
					end
				elseif failure then
					onFailure(json.message)
				end
       		end, 
        	failed = function( err ) 
            		print(err)
        	end,
        	body=util.TableToJSON({ amount = amount, description=description, ttl=ttl}),
		type="application/json"
	})
end

local nextTick = 0

hook.Add("Tick", "BitcoinGmodAPI_Tick", function()
	if CurTime() > nextTick then
		nextTick = CurTime() + 10
		for k, v in pairs(BitcoinGmodAPI.accounts) do
			for k2, v2 in pairs(v.pending_charges) do
				if !v2 then
					continue
				end

				HTTP({
        				url= "https://api.opennode.com/v1/charge/"..k2, 
        				method= "GET", 
        				headers= { 
	 	   					['accept']= 'application/json',
         	   				['Content-Type']= 'application/json',
	  	  					['Authorization']= BitcoinGmodAPI.ReadOnlyKey
        				},
        				success= function( code, body, headers )
							local data = util.JSONToTable(body).data
							if data && data.status == "paid" then
								v.balance = v.balance + data.amount
								v.pending_charges[k2] = nil
								hook.Run("BitcoinGmodAPI_ChargePaid", k, player.GetBySteamID64( v.owner ), data.amount)
							elseif data && data.status == "expired" then
								v.pending_charges[k2] = nil
							end
       					end, 
        				failed = function( err )
            					print(err)
        				end,
					type="application/json"
				})
			end
			for k2, v2 in pairs(v.pending_withdrawals) do
				if !v2 then
					continue
				end

				HTTP({
        				url= "https://api.opennode.com/v1/withdrawal/"..k2, 
        				method= "GET", 
        				headers= { 
	 	   					['accept']= 'application/json',
         	   				['Content-Type']= 'application/json',
	  	  					['Authorization']= BitcoinGmodAPI.ReadOnlyKey
        				},
        				success= function( code, body, headers )
							local json = util.JSONToTable(body)

							if json.data && json.data.status == "confirmed" then
								v.pending_withdrawals[k2] = nil
							elseif json.data && json.data.status == "failed" then
								v.balance = v.balance + json.data.amount
								v.pending_withdrawals[k2] = nil
								hook.Run("BitcoinGmodAPI_WithdrawalFailed", k, player.GetBySteamID64( v.owner ), json.data.amount)
							end
       					end, 
        				failed = function( err )
            					print(err)
        				end,
					type="application/json"
				})
			end
		end
	end
end)

function BitcoinGmodAPI:InitiateLightningWithdrawal(account, amount, address, onSuccess, onFailure)
	if BitcoinGmodAPI.accounts[account].balance < amount then
		return
	end

	HTTP({
        	url= "https://api.opennode.com/v2/withdrawals", 
        	method= "POST", 
        	headers= { 
	 	   		['accept']= 'application/json',
         	   	['Content-Type']= 'application/json',
	  	  		['Authorization']= BitcoinGmodAPI.WithdrawalKey
        	},
        	success= function( code, body, headers )
				local json = util.JSONToTable(body)
				local data = json.data

				if data then
					BitcoinGmodAPI.accounts[account].pending_withdrawals[data.id] = true
					BitcoinGmodAPI.accounts[account].balance = BitcoinGmodAPI.accounts[account].balance - data.amount
					if onSuccess then
						onSuccess()
					end
				elseif onFailure then
					onFailure(json.message)
				end
       		end, 
        	failed = function( err ) 
            		print(err)
        	end,
        	body=util.TableToJSON({ type="ln", amount = amount, address=address}),
		type="application/json"
	})
end

local function saveData()
	file.Write("BitcoinGmodAPI.txt", util.TableToJSON(BitcoinGmodAPI.accounts))
end

local function loadData()
	local contents = file.Read("BitcoinGmodAPI.txt", "DATA")

	if (contents and contents ~= "") then
		BitcoinGmodAPI.accounts = util.JSONToTable(contents)
	end
end

hook.Add("InitPostEntity", "BitcoinGmodAPI_InitPostEntity1", loadData)
hook.Add("PostCleanupMap", "BitcoinGmodAPI_PostCleanupMap1", loadData)
hook.Add("ShutDown", "BitcoinGmodAPI_ShutDown1", saveData)
hook.Add("PreCleanupMap", "BitcoinGmodAPI_PreCleanupMap1", saveData)