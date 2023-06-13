# BILLING SYSTEM FOR ESX/QBCORE

| If you are intested in recieving github updates join the community on **[Discord](https://discord.gg/tebex)**! |



**[PREVIEW](https://youtu.be/Jhl08LUMK44)**




# Dependencies


**[ox_lib](https://github.com/overextended/ox_lib)**




# For ESX Users  
 > esx_society > server.lua
  ```lua
RegisterServerEvent('esx_society:depositMoney:src-billing')
AddEventHandler('esx_society:depositMoney:src-billing', function(societyName, amount)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local society = GetSociety(societyName)
	if not society then
		print(('[^3WARNING^7] Player ^5%s^7 attempted to deposit to non-existing society - ^5%s^7!'):format(source, societyName))
		return
	end
	amount = ESX.Math.Round(tonumber(amount))

	TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
		account.addMoney(amount)
	end)
end)
```
