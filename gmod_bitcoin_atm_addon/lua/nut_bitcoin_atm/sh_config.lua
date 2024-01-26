NutscriptBitcoinAtm = NutscriptBitcoinAtm or {}

NutscriptBitcoinAtm.AllowBuyingBitcoin = true

NutscriptBitcoinAtm.MaximumTransfer = 499999999

-- How many tokens for one satoshi
NutscriptBitcoinAtm.ExchangeRate = 5

hook.Add("InitializedSchema", "NutscriptBitcoinAtm_InitializedSchema1", function()
    nut.lang.stored.english.bitcoinAtm = "Bitcoin ATM"
    nut.lang.stored.english.bitcoinAtmLightningDeposit = "Lightning Deposit"
    nut.lang.stored.english.bitcoinAtmDepositSats = "Deposit (sats)"
    nut.lang.stored.english.bitcoinAtmInvalidNumber = "Invalid amount"
    nut.lang.stored.english.bitcoinAtmMaximum = "Maximum amount is 499 999 999 sats"
    nut.lang.stored.english.bitcoinAtmLightningWithdrawal = "Lightning Withdrawal"
    nut.lang.stored.english.bitcoinAtmLightningInvoice = "Lightning Invoice"
    nut.lang.stored.english.bitcoinAtmWithdrawSats = "Withdraw (sats)"
    nut.lang.stored.english.bitcoinAtmInsufficientFunds = "You don't have sufficient funds"
    nut.lang.stored.english.bitcoinAtmBuyBitcoin = "Buy Bitcoin"
    nut.lang.stored.english.bitcoinAtmSellBitcoin = "Sell Bitcoin"
    nut.lang.stored.english.bitcoinAtmBuy = "Buy"
    nut.lang.stored.english.bitcoinAtmSell = "Sell"
    nut.lang.stored.english.bitcoinAtmPaymentReceived = "Payment received !"
    nut.lang.stored.english.bitcoinAtmInvalidPayment = "Invalid payment request."
    nut.lang.stored.english.bitcoinAtmWithdrawalFailed = "Withdrawal failed."
    nut.lang.stored.english.bitcoinAtmCopy = "Copy to clipboard"
    nut.lang.stored.english.bitcoinAtmCancel = "Cancel deposit"

    nut.lang.stored.french.bitcoinAtm = "ATM Bitcoin"
    nut.lang.stored.french.bitcoinAtmLightningDeposit = "Dépôt Lightning"
    nut.lang.stored.french.bitcoinAtmDepositSats = "Dépôt (sats)"
    nut.lang.stored.french.bitcoinAtmInvalidNumber = "Montant invalide"
    nut.lang.stored.french.bitcoinAtmMaximum = "Le montant maximal est 499 999 999 sats"
    nut.lang.stored.french.bitcoinAtmLightningWithdrawal = "Retrait Lightning"
    nut.lang.stored.french.bitcoinAtmLightningInvoice = "Facture Lightning"
    nut.lang.stored.french.bitcoinAtmWithdrawSats = "Retrait (sats)"
    nut.lang.stored.french.bitcoinAtmInsufficientFunds = "Fonds insuffisants"
    nut.lang.stored.french.bitcoinAtmBuyBitcoin = "Acheter Bitcoin"
    nut.lang.stored.french.bitcoinAtmSellBitcoin = "Vendre Bitcoin"
    nut.lang.stored.french.bitcoinAtmBuy = "Acheter"
    nut.lang.stored.french.bitcoinAtmSell = "Vendre"
    nut.lang.stored.french.bitcoinAtmPaymentReceived = "Paiement reçu !"
    nut.lang.stored.french.bitcoinAtmInvalidPayment = "Facture invalide."
    nut.lang.stored.french.bitcoinAtmWithdrawalFailed = "Le retrait a echoué."
    nut.lang.stored.french.bitcoinAtmCopy = "Copier dans le presse-papiers"
    nut.lang.stored.french.bitcoinAtmCancel = "Annuler le dépôt"
end)