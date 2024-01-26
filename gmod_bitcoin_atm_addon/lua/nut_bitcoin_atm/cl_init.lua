function NutscriptBitcoinAtm:CloseRightFrame()
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

function NutscriptBitcoinAtm:OpenDepositFrame()
    if !IsValid(NutscriptBitcoinAtm.AtmFrame) then return end

    local ok, tab_or_message = BitcoinGmodAPI:QrCode(NutscriptBitcoinAtm.DepositUrl)

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Send "..NutscriptBitcoinAtm.DepositAmount.." sats")
    frame:SetSize(math.max((#tab_or_message+2)*2+20, 63*2 + 20), 300)
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
    address:SetText(L"bitcoinAtmCopy")
    address:SetTextColor( Color( 255, 255, 255 ) )
    address:SetWide(100)
    address:MoveBelow(qrCode, 4)
    address:CenterHorizontal()
    address.DoClick = function()
        SetClipboardText(NutscriptBitcoinAtm.DepositUrl)
    end

    cancel = frame:Add("DButton")
    cancel:SetText(L"bitcoinAtmCancel")
    cancel:SetTextColor( Color( 255, 255, 255 ) )
    cancel:SetWide(100)
    cancel:MoveBelow(address, 4)
    cancel:CenterHorizontal()
    cancel.DoClick = function(panel)
        frame:Close()
        NutscriptBitcoinAtm.DepositUrl = nil
        NutscriptBitcoinAtm.DepositAmount = nil
        NutscriptBitcoinAtm.DepositExpiration = nil
    end

    local timeRemaining = frame:Add("DLabel")
    timeRemaining:SetWide(math.max((#tab_or_message+2)*2+20, 63*2 + 20))
    timeRemaining:MoveBelow(cancel, 4)
    timeRemaining:SetContentAlignment( 5 )

    function timeRemaining:Paint()
        timeRemaining:SetText(tostring(math.floor((NutscriptBitcoinAtm.DepositExpiration - os.time()) / 60)).." min remaining")

        if NutscriptBitcoinAtm.DepositExpiration - os.time() <= 0 then
            NutscriptBitcoinAtm.DepositFrame:Close()
            NutscriptBitcoinAtm.DepositUrl = nil
            NutscriptBitcoinAtm.DepositAmount = nil
            NutscriptBitcoinAtm.DepositExpiration = nil
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

    frame:MoveRightOf(NutscriptBitcoinAtm.AtmFrame, 4)
    NutscriptBitcoinAtm.DepositFrame = frame
end

net.Receive("nutBitcoinAtmDeposit", function()
    NutscriptBitcoinAtm.DepositUrl = net.ReadString()
    NutscriptBitcoinAtm.DepositExpiration = net.ReadUInt(32)
    NutscriptBitcoinAtm:OpenDepositFrame()
end)

function NutscriptBitcoinAtm:BitcoinAtmOpen()
    if IsValid(self.AtmFrame) then
        self.AtmFrame:Close()
    end

    self.AtmFrame = vgui.Create("DFrame") -- The name of the panel we don't have to parent it.
    self.AtmFrame:SetTitle(L"bitcoinAtm")
    self.AtmFrame:SetPos(100, 100) -- Set the position to 100x by 100y. 
    self.AtmFrame:SetSize(150, 300) -- Set the size to 300x by 200y.
    self.AtmFrame:Center()
    self.AtmFrame:MakePopup()
    self.AtmFrame:SetDraggable(false)
    self.AtmFrame.OnClose = function(panel)
        NutscriptBitcoinAtm:CloseRightFrame()
    end

    self.AtmFrame.LightningDepositButton = self.AtmFrame:Add("DButton")
    self.AtmFrame.LightningDepositButton:SetText(L"bitcoinAtmLightningDeposit")
    self.AtmFrame.LightningDepositButton:Dock(TOP)
    self.AtmFrame.LightningDepositButton:DockMargin( 0, 4, 0, 0 ) 
    self.AtmFrame.LightningDepositButton:SetTextColor( Color( 255, 255, 255 ) )
    self.AtmFrame.LightningDepositButton.DoClick = function(pnl)
        NutscriptBitcoinAtm:CloseRightFrame()

        if NutscriptBitcoinAtm.DepositUrl then
            NutscriptBitcoinAtm:OpenDepositFrame()
            return
        end

        self.LightningDepositFrame = vgui.Create("DFrame")
        self.LightningDepositFrame:SetTitle(L"bitcoinAtmLightningDeposit")
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
        self.LightningDepositFrame.Button:SetText(L"bitcoinAtmDepositSats")
        self.LightningDepositFrame.Button:SetTextColor( Color( 255, 255, 255 ) )
        self.LightningDepositFrame.Button:SetWide(100)
        self.LightningDepositFrame.Button:MoveBelow(self.LightningDepositFrame.Entry, 4)
        self.LightningDepositFrame.Button:CenterHorizontal()
        self.LightningDepositFrame.Button.DoClick = function(panel)
            local amount = tonumber(self.LightningDepositFrame.Entry:GetValue())

            if !isnumber(amount) or amount < 1 or amount > NutscriptBitcoinAtm.MaximumTransfer or amount % 1 != 0  then
                nut.util.notify(L"bitcoinAtmInvalidNumber")
                return
            end

            self.LightningDepositFrame:Close()

            net.Start("nutBitcoinAtmDeposit")
                net.WriteUInt(amount, 32)
            net.SendToServer()

            NutscriptBitcoinAtm.DepositAmount = amount
        end
    end

    self.AtmFrame.LightningWithdrawButton = self.AtmFrame:Add("DButton")
    self.AtmFrame.LightningWithdrawButton:SetText(L"bitcoinAtmLightningWithdrawal")
    self.AtmFrame.LightningWithdrawButton:Dock(TOP)
    self.AtmFrame.LightningWithdrawButton:DockMargin( 0, 4, 0, 0 ) 
    self.AtmFrame.LightningWithdrawButton:SetTextColor( Color( 255, 255, 255 ) )
    self.AtmFrame.LightningWithdrawButton.DoClick = function(panel)
        NutscriptBitcoinAtm:CloseRightFrame()

        self.LightningWithdrawFrame = vgui.Create("DFrame")
        self.LightningWithdrawFrame:SetTitle(L"bitcoinAtmLightningWithdrawal")
        self.LightningWithdrawFrame:SetSize(200, 200)
        self.LightningWithdrawFrame:MoveRightOf(self.AtmFrame, 4)
        self.LightningWithdrawFrame:CenterVertical()
        self.LightningWithdrawFrame:MakePopup()
        self.LightningWithdrawFrame:SetDraggable(false)

        self.LightningWithdrawFrame.InvoiceEntry = self.LightningWithdrawFrame:Add("DTextEntry")
        self.LightningWithdrawFrame.InvoiceEntry:SetWide(150)
        self.LightningWithdrawFrame.InvoiceEntry:SetY(75)
        self.LightningWithdrawFrame.InvoiceEntry:CenterHorizontal()
        self.LightningWithdrawFrame.InvoiceEntry:SetPlaceholderText(L"bitcoinAtmLightningInvoice")
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
        self.LightningWithdrawFrame.Button:SetText(L"bitcoinAtmWithdrawSats")
        self.LightningWithdrawFrame.Button:SetTextColor( Color( 255, 255, 255 ) )
        self.LightningWithdrawFrame.Button:SetWide(100)
        self.LightningWithdrawFrame.Button:MoveBelow(self.LightningWithdrawFrame.AmountEntry, 4)
        self.LightningWithdrawFrame.Button:CenterHorizontal()
        self.LightningWithdrawFrame.Button.DoClick = function(panel)
            local amount = tonumber(self.LightningWithdrawFrame.AmountEntry:GetValue())

            if !isnumber(amount) or amount < 1 or amount > NutscriptBitcoinAtm.MaximumTransfer or amount % 1 != 0  then
                nut.util.notify(L"bitcoinAtmInvalidNumber")
                return
            end

            if (amount > NutscriptBitcoinAtm.Balance) then
                nut.util.notify(L"bitcoinAtmInsufficientFunds")
                return
            end

            self.LightningWithdrawFrame:Close()

            net.Start("nutBitcoinAtmWithdraw")
                net.WriteUInt(amount, 32)
                net.WriteString(self.LightningWithdrawFrame.InvoiceEntry:GetValue())
            net.SendToServer()

            NutscriptBitcoinAtm.Balance = NutscriptBitcoinAtm.Balance - amount
        end
    end

    if NutscriptBitcoinAtm.AllowBuyingBitcoin then
        self.AtmFrame.ConvertToBitcoinButton = self.AtmFrame:Add("DButton")
        self.AtmFrame.ConvertToBitcoinButton:SetText(L"bitcoinAtmBuyBitcoin")
        self.AtmFrame.ConvertToBitcoinButton:Dock(TOP)
        self.AtmFrame.ConvertToBitcoinButton:DockMargin( 0, 4, 0, 0 ) 
        self.AtmFrame.ConvertToBitcoinButton:SetTextColor( Color( 255, 255, 255 ) )
        self.AtmFrame.ConvertToBitcoinButton.DoClick = function(pnl)
            NutscriptBitcoinAtm:CloseRightFrame()

            self.ConvertToBitcoinFrame = vgui.Create("DFrame")
            self.ConvertToBitcoinFrame:SetTitle(L"bitcoinAtmBuyBitcoin")
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
            self.ConvertToBitcoinFrame.Button:SetText(L"bitcoinAtmBuy")
            self.ConvertToBitcoinFrame.Button:SetTextColor( Color( 255, 255, 255 ) )
            self.ConvertToBitcoinFrame.Button:SetWide(100)
            self.ConvertToBitcoinFrame.Button:MoveBelow(self.ConvertToBitcoinFrame.Entry, 4)
            self.ConvertToBitcoinFrame.Button:CenterHorizontal()
            self.ConvertToBitcoinFrame.Button.DoClick = function(panel)
                local amount = tonumber(self.ConvertToBitcoinFrame.Entry:GetValue())
                local sats = math.floor(amount / NutscriptBitcoinAtm.ExchangeRate)
		        local tokens = sats * NutscriptBitcoinAtm.ExchangeRate

                if !isnumber(tokens) or tokens < 1 or tokens % 1 != 0  then
                    nut.util.notify(L"bitcoinAtmInvalidNumber")
                    return
                end

                if (tokens > LocalPlayer():getChar():getMoney()) then
                    nut.util.notify(L"bitcoinAtmInsufficientFunds")
                    return
                end

                net.Start("nutBitcoinAtmConvert")
                    net.WriteUInt(tokens, 32)
                    net.WriteBool(false)
                net.SendToServer()

                NutscriptBitcoinAtm.Balance = NutscriptBitcoinAtm.Balance + sats
            end
        end
    end

    self.AtmFrame.ConvertToTokensButton = self.AtmFrame:Add("DButton")
    self.AtmFrame.ConvertToTokensButton:SetText(L"bitcoinAtmSellBitcoin")
    self.AtmFrame.ConvertToTokensButton:Dock(TOP)
    self.AtmFrame.ConvertToTokensButton:DockMargin( 0, 4, 0, 0 ) 
    self.AtmFrame.ConvertToTokensButton:SetTextColor( Color( 255, 255, 255 ) )
    self.AtmFrame.ConvertToTokensButton.DoClick = function(pnl)
        NutscriptBitcoinAtm:CloseRightFrame()

        self.ConvertToTokensFrame = vgui.Create("DFrame")
        self.ConvertToTokensFrame:SetTitle(L"bitcoinAtmSellBitcoin")
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
        self.ConvertToTokensFrame.Button:SetText(L"bitcoinAtmSell")
        self.ConvertToTokensFrame.Button:SetTextColor( Color( 255, 255, 255 ) )
        self.ConvertToTokensFrame.Button:SetWide(100)
        self.ConvertToTokensFrame.Button:MoveBelow(self.ConvertToTokensFrame.Entry, 4)
        self.ConvertToTokensFrame.Button:CenterHorizontal()
        self.ConvertToTokensFrame.Button.DoClick = function(panel)
            local amount = tonumber(self.ConvertToTokensFrame.Entry:GetValue())
            local sats = math.floor(NutscriptBitcoinAtm.ExchangeRate * amount) / NutscriptBitcoinAtm.ExchangeRate

            if !isnumber(sats) or sats < 1 or sats % 1 != 0  then
                nut.util.notify(L"bitcoinAtmInvalidNumber")
                return
            end

            if (sats > NutscriptBitcoinAtm.Balance) then
                nut.util.notify(L"bitcoinAtmInsufficientFunds")
                return
            end

            net.Start("nutBitcoinAtmConvert")
                net.WriteUInt(sats, 32)
                net.WriteBool(true)
            net.SendToServer()

            NutscriptBitcoinAtm.Balance = NutscriptBitcoinAtm.Balance - sats
        end
    end

    NutscriptBitcoinAtm.AtmFrame.TokenBalance = NutscriptBitcoinAtm.AtmFrame:Add("DLabel")
    NutscriptBitcoinAtm.AtmFrame.TokenBalance:SetTextColor( Color( 255, 255, 255 ) )
    NutscriptBitcoinAtm.AtmFrame.TokenBalance:SetText(nut.currency.get(LocalPlayer():getChar():getMoney() or 0))
    NutscriptBitcoinAtm.AtmFrame.TokenBalance:SetContentAlignment(5)
    NutscriptBitcoinAtm.AtmFrame.TokenBalance:Dock(BOTTOM)
    NutscriptBitcoinAtm.AtmFrame.TokenBalance.Paint = function(pnl)
        NutscriptBitcoinAtm.AtmFrame.TokenBalance:SetText(nut.currency.get(LocalPlayer():getChar():getMoney() or 0))
    end

    NutscriptBitcoinAtm.AtmFrame.BitcoinBalance = NutscriptBitcoinAtm.AtmFrame:Add("DLabel")
    NutscriptBitcoinAtm.AtmFrame.BitcoinBalance:SetTextColor( Color( 255, 255, 255 ) )
    NutscriptBitcoinAtm.AtmFrame.BitcoinBalance:SetText((NutscriptBitcoinAtm.Balance or 0).." sats")
    NutscriptBitcoinAtm.AtmFrame.BitcoinBalance:SetContentAlignment(5)
    NutscriptBitcoinAtm.AtmFrame.BitcoinBalance:Dock(BOTTOM)
    NutscriptBitcoinAtm.AtmFrame.BitcoinBalance.Paint = function(pnl)
        NutscriptBitcoinAtm.AtmFrame.BitcoinBalance:SetText((NutscriptBitcoinAtm.Balance or 0).." sats")
    end
end

net.Receive("nutBitcoinAtmOpen", function()
    NutscriptBitcoinAtm:BitcoinAtmOpen()
end)

net.Receive("nutBitcoinAtmBalance", function()
    NutscriptBitcoinAtm.Balance = net.ReadUInt(32)

    if net.ReadBool() && IsValid(NutscriptBitcoinAtm.DepositFrame) then
        NutscriptBitcoinAtm.DepositFrame:Close()
        NutscriptBitcoinAtm.DepositUrl = nil
        NutscriptBitcoinAtm.DepositAmount = nil
        NutscriptBitcoinAtm.DepositExpiration = nil
    end
end)