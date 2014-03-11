PLUGIN.Title = "deathmessages"
PLUGIN.Description = "Send global message on player death."
PLUGIN.Version = "0.7"
PLUGIN.Author = "Erekel"

print(PLUGIN.Title .. " (" .. PLUGIN.Version .. ") plugin loaded")

function PLUGIN:Init()
	self.aDataFile = util.GetDatafile("deathmessages")
	local txt = self.aDataFile:GetText()
	if (txt ~= "") then
		self.aData = json.decode(txt)
	else
		self.aData =
		{
			["AdminOnly"] = false,
			["SendAllChat"] = true,
			["SendNotice"] = false,
			["ShowWeapon"] = true,
			["ShowSuicide"] = false,
			["ChatName"] = "Oxide"
		}
		
		self:Save()
	end
	
	self:AddCommand("deathmessages", "reload", self.Reload)

	oxmin_Plugin = plugins.Find("oxmin")

    if not oxmin_Plugin or not oxmin then
        print("Flag deathmessages not added! Requires Oxmin")
        self.oxminInstalled = false
        return
    end

    self.FLAG_DEATHMESSAGES = oxmin.AddFlag("deathmessages")
    self.oxminInstalled = true

	print("Flag deathmessages successfully added to Oxmin")
end

function PLUGIN:Save()
	self.aDataFile:SetText(json.encode(self.aData))
	self.aDataFile:Save()
end

function PLUGIN:Reload(arg)
	local user = arg.argUser
	if (user and not user:CanAdmin()) then
		rust.Notice(arg.argUser, "Login to rcon and try again.")
		return
	end
	cs.reloadplugin(self.Name)
	rust.Notice(arg.argUser, "Deathmessages reloaded.")
end

function PLUGIN:OnKilled(takedamage, damage)
	local message
	local weapon
	local suicide

	suicide = (damage.victim.client == damage.attacker.client)

	if (damage.extraData) then
		weapon = damage.extraData.dataBlock.name
	end

	if (takedamage:GetComponent("HumanController")) then
		if (damage.attacker.client and damage.victim.client) then
			if ((self.aData["ShowSuicide"]) and (suicide)) then
				message = damage.victim.client.netUser.displayName .. " has commited suicide"
			else
				if (not suicide) then
					message = damage.victim.client.netUser.displayName .. " was killed by " .. damage.attacker.client.netUser.displayName

					if (self.aData["ShowWeapon"]) then
						if ((weapon == "M4") or (weapon == "MP5A4")) then
							message = message .. " (using an " .. weapon .. ")"
						else
							message = message .. " (using a " .. weapon .. ")"
						end
					end
				else
					return
				end
			end
			if (self.aData["AdminOnly"]) then
				self.BroadcastAdmin(self.aData["ChatName"], message)
			else
				if (self.aData["SendAllChat"]) then
					rust.BroadcastChat(self.aData["ChatName"], message)
				end

				if (self.aData["SendNotice"]) then
					self:BroadcastNotice(message)
				end
			end
		end
	end
end

function PLUGIN:BroadcastNotice(message)
	local netUsers = rust.GetAllNetUsers()
	
	for key, netUser in pairs(netUsers)
	do
		rust.Notice(netUser, message)
	end
end

function PLUGIN:BroadcastAdmin(chatname, message)
	local netUsers = rust.GetAllNetUsers()

	if (self.oxminInstalled) then
		for key, netUser in pairs(netUsers)
		do
			if ((netUser:CanAdmin()) or (oxmin_Plugin:HasFlag(netuser, self.FLAG_DEATHMESSAGES, false))) then
				rust.SendChatToUser(netUser, chatname, message)
			end
		end
	else
		for key, netUser in pairs(netUsers)
		do
			if (netUser:CanAdmin()) then
				rust.SendChatToUser(netUser, chatname, message)
			end
		end
	end
end