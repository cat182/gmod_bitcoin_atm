function DarkrpBitcoinAtm:Notify(str)
    net.Start("darkrpBitcoinAtmNotify")
        net.WriteString(str)
    net.SendToServer()
end

function DarkrpBitcoinAtm:CloseRightFrame()
    if IsValid(self.DepositFrame) then
        self.DepositFrame:Close()
    end
    if IsValid(self.LightningDepositFrame) then
        self.LightningDepositFrame:Close()
    end
    if IsValid(self.LightningWithdrawFrame) then
        self.LightningWithdrawFrame:Close()
    end
    if IsValid(self.ConvertToBitcoinFrame) then
        self.ConvertToBitcoinFrame:Close()
    end
    if IsValid(self.ConvertToTokensFrame) then
        self.ConvertToTokensFrame:Close()
    end
end

function DarkrpBitcoinAtm:OpenDepositFrame()
    if !IsValid(DarkrpBitcoinAtm.AtmFrame) then return end

    local ok, tab_or_message = BitcoinGmodAPI:QrCode(DarkrpBitcoinAtm.DepositUrl)

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Send "..DarkrpBitcoinAtm.DepositAmount.." sats")
    frame:SetSize(math.max((#tab_or_message+2)*2+60, 63*2 + 60), 300)
    frame:MoveRightOf(frame, 4)
    frame:CenterVertical()
    frame:MakePopup()
    frame:SetDraggable(false)

    local qrCode = frame:Add("Panel")
    qrCode:SetSize((#tab_or_message+2)*2, (#tab_or_message+2)*2)
    qrCode:MoveRightOf(frame, 4)
    qrCode:SetY(30)
    qrCode:CenterHorizontal()

    local address = frame:Add("DButton")
    address:SetText(DarkrpBitcoinAtm.lang.copyToClipboard)
    address:SetWide(100)
    address:MoveBelow(qrCode, 4)
    address:CenterHorizontal()
    address.DoClick = function()
        SetClipboardText(DarkrpBitcoinAtm.DepositUrl)
    end

    cancel = frame:Add("DButton")
    cancel:SetText(DarkrpBitcoinAtm.lang.cancelDeposit)
    cancel:SetWide(100)
    cancel:MoveBelow(address, 4)
    cancel:CenterHorizontal()
    cancel.DoClick = function(panel)
        frame:Close()
        DarkrpBitcoinAtm.DepositUrl = nil
        DarkrpBitcoinAtm.DepositAmount = nil
        DarkrpBitcoinAtm.DepositExpiration = nil
    end

    local timeRemaining = frame:Add("DLabel")
    timeRemaining:SetWide(math.max((#tab_or_message+2)*2+60, 63*2 + 60))
    timeRemaining:MoveBelow(cancel, 4)
    timeRemaining:SetContentAlignment( 5 )

    function timeRemaining:Paint()
        timeRemaining:SetText(tostring(math.floor((DarkrpBitcoinAtm.DepositExpiration - os.time()) / 60))..DarkrpBitcoinAtm.lang.minRemaining)

        if DarkrpBitcoinAtm.DepositExpiration - os.time() <= 0 then
            DarkrpBitcoinAtm.DepositFrame:Close()
            DarkrpBitcoinAtm.DepositUrl = nil
            DarkrpBitcoinAtm.DepositAmount = nil
            DarkrpBitcoinAtm.DepositExpiration = nil
        end
    end

    function qrCode:Paint(w, h)
        surface.SetDrawColor(255,255,255,255)
        surface.DrawRect( 0, 0, w, h )
    end

    function qrCode:PaintOver(w, h)
        for x=1,#tab_or_message do
            for y=1,#tab_or_message do
                if tab_or_message[x][y] > 0 then
                    surface.SetDrawColor(0,0,0,255)
                    surface.DrawRect( x*2, y*2, 2, 2 )
                elseif tab_or_message[x][y] < 0 then
                    surface.SetDrawColor(255,255,255,255)
                    surface.DrawRect( x*2, y*2, 2, 2 )
                else
                    surface.SetDrawColor(0,0,0,255)
                    surface.DrawRect( x*2, y*2, 2, 2 )
                end
            end
        end
    end

    frame:MoveRightOf(DarkrpBitcoinAtm.AtmFrame, 4)
    DarkrpBitcoinAtm.DepositFrame = frame
end

net.Receive("darkrpBitcoinAtmDeposit", function()
    DarkrpBitcoinAtm.DepositUrl = net.ReadString()
    DarkrpBitcoinAtm.DepositExpiration = net.ReadUInt(32)
    DarkrpBitcoinAtm:OpenDepositFrame()
end)

function DarkrpBitcoinAtm:BitcoinAtmOpen()
    if IsValid(self.AtmFrame) then
        self.AtmFrame:Close()
    end

    self.AtmFrame = vgui.Create("DFrame") -- The name of the panel we don't have to parent it.
    self.AtmFrame:SetTitle(DarkrpBitcoinAtm.lang.bitcoinAtm)
    self.AtmFrame:SetPos(100, 100) -- Set the position to 100x by 100y. 
    self.AtmFrame:SetSize(160, 300) -- Set the size to 300x by 200y.
    self.AtmFrame:Center()
    self.AtmFrame:MakePopup()
    self.AtmFrame:SetDraggable(false)
    self.AtmFrame.OnClose = function(pnl)
        DarkrpBitcoinAtm:CloseRightFrame()
    end 

    self.AtmFrame.LightningDepositButton = self.AtmFrame:Add("DButton")
    self.AtmFrame.LightningDepositButton:SetText(DarkrpBitcoinAtm.lang.lightningDeposit)
    self.AtmFrame.LightningDepositButton:Dock(TOP)
    self.AtmFrame.LightningDepositButton:DockMargin( 0, 4, 0, 0 ) 
    self.AtmFrame.LightningDepositButton.DoClick = function(pnl)
        DarkrpBitcoinAtm:CloseRightFrame()

        if DarkrpBitcoinAtm.DepositUrl then
            DarkrpBitcoinAtm:OpenDepositFrame()
            return
        end

        self.LightningDepositFrame = vgui.Create("DFrame")
        self.LightningDepositFrame:SetTitle(DarkrpBitcoinAtm.lang.lightningDeposit)
        self.LightningDepositFrame:SetSize(200, 200)
        self.LightningDepositFrame:MoveRightOf(self.AtmFrame, 4)
        self.LightningDepositFrame:CenterVertical()
        self.LightningDepositFrame:MakePopup()
        self.LightningDepositFrame:SetDraggable(false)

        self.LightningDepositFrame.Entry = self.LightningDepositFrame:Add("DTextEntry")
        self.LightningDepositFrame.Entry:SetWide(150)
        self.LightningDepositFrame.Entry:Center()
        self.LightningDepositFrame.Entry:SetNumeric(true)
        self.LightningDepositFrame.Entry:SetValue(0)
        self.LightningDepositFrame.Entry.OnEnter = function(pnl)
        end

        self.LightningDepositFrame.Button = self.LightningDepositFrame:Add("DButton")
        self.LightningDepositFrame.Button:SetText(DarkrpBitcoinAtm.lang.depositSats)
        self.LightningDepositFrame.Button:SetWide(100)
        self.LightningDepositFrame.Button:MoveBelow(self.LightningDepositFrame.Entry, 4)
        self.LightningDepositFrame.Button:CenterHorizontal()
        self.LightningDepositFrame.Button.DoClick = function(panel)
            local amount = tonumber(self.LightningDepositFrame.Entry:GetValue())

            if !isnumber(amount) or amount < 1 or amount > DarkrpBitcoinAtm.MaximumTransfer or amount % 1 != 0 then
                DarkrpBitcoinAtm:Notify("invalidNumber")
                return
            end

            self.LightningDepositFrame:Close()

            net.Start("darkrpBitcoinAtmDeposit")
                net.WriteUInt(amount, 32)
            net.SendToServer()

            DarkrpBitcoinAtm.DepositAmount = amount
        end
    end

    self.AtmFrame.LightningWithdrawButton = self.AtmFrame:Add("DButton")
    self.AtmFrame.LightningWithdrawButton:SetText(DarkrpBitcoinAtm.lang.lightningWithdrawal)
    self.AtmFrame.LightningWithdrawButton:Dock(TOP)
    self.AtmFrame.LightningWithdrawButton:DockMargin( 0, 4, 0, 0 ) 
    self.AtmFrame.LightningWithdrawButton.DoClick = function(panel)
        DarkrpBitcoinAtm:CloseRightFrame()

        self.LightningWithdrawFrame = vgui.Create("DFrame")
        self.LightningWithdrawFrame:SetTitle(DarkrpBitcoinAtm.lang.lightningWithdrawal)
        self.LightningWithdrawFrame:SetSize(200, 200)
        self.LightningWithdrawFrame:MoveRightOf(self.AtmFrame, 4)
        self.LightningWithdrawFrame:CenterVertical()
        self.LightningWithdrawFrame:MakePopup()
        self.LightningWithdrawFrame:SetDraggable(false)

        self.LightningWithdrawFrame.InvoiceEntry = self.LightningWithdrawFrame:Add("DTextEntry")
        self.LightningWithdrawFrame.InvoiceEntry:SetWide(150)
        self.LightningWithdrawFrame.InvoiceEntry:SetY(75)
        self.LightningWithdrawFrame.InvoiceEntry:CenterHorizontal()
        self.LightningWithdrawFrame.InvoiceEntry:SetPlaceholderText(DarkrpBitcoinAtm.lang.lightningInvoice)
        self.LightningWithdrawFrame.InvoiceEntry.OnEnter = function(panel)
        end

        self.LightningWithdrawFrame.AmountEntry = self.LightningWithdrawFrame:Add("DTextEntry")
        self.LightningWithdrawFrame.AmountEntry:MoveBelow(self.LightningWithdrawFrame.InvoiceEntry, 4)
        self.LightningWithdrawFrame.AmountEntry:SetWide(150)
        self.LightningWithdrawFrame.AmountEntry:CenterHorizontal()
        self.LightningWithdrawFrame.AmountEntry:SetNumeric(true)
        self.LightningWithdrawFrame.AmountEntry:SetValue(0)
        self.LightningWithdrawFrame.AmountEntry.OnEnter = function(panel)
            
        end

        self.LightningWithdrawFrame.Button = self.LightningWithdrawFrame:Add("DButton")
        self.LightningWithdrawFrame.Button:SetText(DarkrpBitcoinAtm.lang.withdrawSats)
        self.LightningWithdrawFrame.Button:SetWide(100)
        self.LightningWithdrawFrame.Button:MoveBelow(self.LightningWithdrawFrame.AmountEntry, 4)
        self.LightningWithdrawFrame.Button:CenterHorizontal()
        self.LightningWithdrawFrame.Button.DoClick = function(panel)
            local amount = tonumber(self.LightningWithdrawFrame.AmountEntry:GetValue())

            if !isnumber(amount) or amount < 1 or amount > DarkrpBitcoinAtm.MaximumTransfer or amount % 1 != 0 then
                DarkrpBitcoinAtm:Notify("invalidNumber")
                return
            end

            if (amount > DarkrpBitcoinAtm.Balance) then
                DarkrpBitcoinAtm:Notify("insufficientFunds")
                return
            end

            self.LightningWithdrawFrame:Close()

            net.Start("darkrpBitcoinAtmWithdraw")
                net.WriteUInt(amount, 32)
                net.WriteString(self.LightningWithdrawFrame.InvoiceEntry:GetValue())
            net.SendToServer()

            DarkrpBitcoinAtm.Balance = DarkrpBitcoinAtm.Balance - amount
        end
    end

    if (DarkrpBitcoinAtm.AllowBuyingBitcoin) then
        self.AtmFrame.ConvertToBitcoinButton = self.AtmFrame:Add("DButton")
        self.AtmFrame.ConvertToBitcoinButton:SetText(DarkrpBitcoinAtm.lang.buyBitcoin)
        self.AtmFrame.ConvertToBitcoinButton:Dock(TOP)
        self.AtmFrame.ConvertToBitcoinButton:DockMargin( 0, 4, 0, 0 ) 
        self.AtmFrame.ConvertToBitcoinButton.DoClick = function(pnl)
            DarkrpBitcoinAtm:CloseRightFrame()

            self.ConvertToBitcoinFrame = vgui.Create("DFrame")
            self.ConvertToBitcoinFrame:SetTitle(DarkrpBitcoinAtm.lang.buyBitcoin)
            self.ConvertToBitcoinFrame:SetSize(200, 200)
            self.ConvertToBitcoinFrame:MoveRightOf(self.AtmFrame, 4)
            self.ConvertToBitcoinFrame:CenterVertical()
            self.ConvertToBitcoinFrame:MakePopup()
            self.ConvertToBitcoinFrame:SetDraggable(false)

            self.ConvertToBitcoinFrame.Entry = self.ConvertToBitcoinFrame:Add("DTextEntry")
            self.ConvertToBitcoinFrame.Entry:SetWide(150)
            self.ConvertToBitcoinFrame.Entry:Center()
            self.ConvertToBitcoinFrame.Entry:SetNumeric(true)
            self.ConvertToBitcoinFrame.Entry:SetValue(0)
            self.ConvertToBitcoinFrame.Entry.OnEnter = function(pnl)
            end

            self.ConvertToBitcoinFrame.Button = self.ConvertToBitcoinFrame:Add("DButton")
            self.ConvertToBitcoinFrame.Button:SetText(DarkrpBitcoinAtm.lang.buy)
            self.ConvertToBitcoinFrame.Button:SetWide(100)
            self.ConvertToBitcoinFrame.Button:MoveBelow(self.ConvertToBitcoinFrame.Entry, 4)
            self.ConvertToBitcoinFrame.Button:CenterHorizontal()
            self.ConvertToBitcoinFrame.Button.DoClick = function(panel)
                local amount = tonumber(self.ConvertToBitcoinFrame.Entry:GetValue())
                local sats = math.floor(amount / DarkrpBitcoinAtm.ExchangeRate)
		        local tokens = sats * DarkrpBitcoinAtm.ExchangeRate

                if !isnumber(tokens) or tokens < 1 or tokens % 1 != 0 then
                    DarkrpBitcoinAtm:Notify("invalidNumber")
                    return
                end

                if (tokens > LocalPlayer():getDarkRPVar("money")) then
                    DarkrpBitcoinAtm:Notify("insufficientFunds")
                    return
                end

                net.Start("darkrpBitcoinAtmConvert")
                    net.WriteUInt(tokens, 32)
                    net.WriteBool(false)
                net.SendToServer()

                DarkrpBitcoinAtm.Balance = DarkrpBitcoinAtm.Balance + sats
            end
        end
    end

    self.AtmFrame.ConvertToTokensButton = self.AtmFrame:Add("DButton")
    self.AtmFrame.ConvertToTokensButton:SetText(DarkrpBitcoinAtm.lang.sellBitcoin)
    self.AtmFrame.ConvertToTokensButton:Dock(TOP)
    self.AtmFrame.ConvertToTokensButton:DockMargin( 0, 4, 0, 0 ) 
    self.AtmFrame.ConvertToTokensButton.DoClick = function(pnl)
        DarkrpBitcoinAtm:CloseRightFrame()

        self.ConvertToTokensFrame = vgui.Create("DFrame")
        self.ConvertToTokensFrame:SetTitle(DarkrpBitcoinAtm.lang.sellBitcoin)
        self.ConvertToTokensFrame:SetSize(200, 200)
        self.ConvertToTokensFrame:MoveRightOf(self.AtmFrame, 4)
        self.ConvertToTokensFrame:CenterVertical()
        self.ConvertToTokensFrame:MakePopup()
        self.ConvertToTokensFrame:SetDraggable(false)

        self.ConvertToTokensFrame.Entry = self.ConvertToTokensFrame:Add("DTextEntry")
        self.ConvertToTokensFrame.Entry:SetWide(150)
        self.ConvertToTokensFrame.Entry:Center()
        self.ConvertToTokensFrame.Entry:SetNumeric(true)
        self.ConvertToTokensFrame.Entry:SetValue(0)
        self.ConvertToTokensFrame.Entry.OnEnter = function(pnl)
        end

        self.ConvertToTokensFrame.Button = self.ConvertToTokensFrame:Add("DButton")
        self.ConvertToTokensFrame.Button:SetText(DarkrpBitcoinAtm.lang.sell)
        self.ConvertToTokensFrame.Button:SetWide(100)
        self.ConvertToTokensFrame.Button:MoveBelow(self.ConvertToTokensFrame.Entry, 4)
        self.ConvertToTokensFrame.Button:CenterHorizontal()
        self.ConvertToTokensFrame.Button.DoClick = function(panel)
            local amount = tonumber(self.ConvertToTokensFrame.Entry:GetValue())
            local sats = math.floor(DarkrpBitcoinAtm.ExchangeRate * amount) / DarkrpBitcoinAtm.ExchangeRate

            if !isnumber(sats) or sats < 1 or sats % 1 != 0 then
                DarkrpBitcoinAtm:Notify("invalidNumber")
                return
            end

            if (sats > DarkrpBitcoinAtm.Balance) then
                DarkrpBitcoinAtm:Notify("insufficientFunds")
                return
            end

            net.Start("darkrpBitcoinAtmConvert")
                net.WriteUInt(sats, 32)
                net.WriteBool(true)
            net.SendToServer()

            DarkrpBitcoinAtm.Balance = DarkrpBitcoinAtm.Balance - sats
        end
    end

    DarkrpBitcoinAtm.AtmFrame.TokenBalance = DarkrpBitcoinAtm.AtmFrame:Add("DLabel")
    DarkrpBitcoinAtm.AtmFrame.TokenBalance:SetTextColor( Color( 255, 255, 255 ) )
    DarkrpBitcoinAtm.AtmFrame.TokenBalance:SetText((LocalPlayer():getDarkRPVar("money") or 0)..DarkrpBitcoinAtm.lang.currency)
    DarkrpBitcoinAtm.AtmFrame.TokenBalance:SetContentAlignment(5)
    DarkrpBitcoinAtm.AtmFrame.TokenBalance:Dock(BOTTOM)
    DarkrpBitcoinAtm.AtmFrame.TokenBalance.Paint = function(pnl)
        DarkrpBitcoinAtm.AtmFrame.TokenBalance:SetText((LocalPlayer():getDarkRPVar("money") or 0)..DarkrpBitcoinAtm.lang.currency)
    end

    DarkrpBitcoinAtm.AtmFrame.BitcoinBalance = DarkrpBitcoinAtm.AtmFrame:Add("DLabel")
    DarkrpBitcoinAtm.AtmFrame.BitcoinBalance:SetTextColor( Color( 255, 255, 255 ) )
    DarkrpBitcoinAtm.AtmFrame.BitcoinBalance:SetText((DarkrpBitcoinAtm.Balance or 0).." sats")
    DarkrpBitcoinAtm.AtmFrame.BitcoinBalance:SetContentAlignment(5)
    DarkrpBitcoinAtm.AtmFrame.BitcoinBalance:Dock(BOTTOM)
    DarkrpBitcoinAtm.AtmFrame.BitcoinBalance.Paint = function(pnl)
        DarkrpBitcoinAtm.AtmFrame.BitcoinBalance:SetText((DarkrpBitcoinAtm.Balance or 0).." sats")
    end
end

net.Receive("darkrpBitcoinAtmOpen", function()
    DarkrpBitcoinAtm:BitcoinAtmOpen()
end)

net.Receive("darkrpBitcoinAtmBalance", function()
    DarkrpBitcoinAtm.Balance = net.ReadUInt(32)

    if net.ReadBool() && IsValid(DarkrpBitcoinAtm.DepositFrame) then
        DarkrpBitcoinAtm.DepositFrame:Close()
        DarkrpBitcoinAtm.DepositUrl = nil
        DarkrpBitcoinAtm.DepositAmount = nil
        DarkrpBitcoinAtm.DepositExpiration = nil
    end
end)