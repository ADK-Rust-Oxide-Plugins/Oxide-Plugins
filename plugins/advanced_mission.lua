PLUGIN.Author="Fox Junior"
PLUGIN.Title="Advanced Missions"
PLUGIN.Version="1.16.3"
PLUGIN.Description="Manage missions"

print("Loading " .. PLUGIN.Title .. " " .. PLUGIN.Version)


function PLUGIN:OnKilled (takedamage, damage)
	if (not(damage.attacker.client)) then -- fix client error
		return
	end
	if (self.MissionCount == 0) then
		return
	end
	local _type = nil
	local _component = nil
	if (takedamage:GetComponent( "ZombieController" )) then
		_type = "zombie" -- obsolete. Zombies are gone!
	elseif (takedamage:GetComponent( "BearAI" )) then
		_component = takedamage:GetComponent( "BearAI" )
		_type = "bear"
	elseif (takedamage:GetComponent( "WolfAI" )) then
		_component = takedamage:GetComponent( "WolfAI" )
		_type = "wolf"
	elseif (takedamage:GetComponent( "StagAI" )) then
		_component = takedamage:GetComponent( "StagAI" )
		_type = "deer"
	elseif (takedamage:GetComponent( "ChickenAI" )) then
		_component = takedamage:GetComponent( "ChickenAI" )
		_type = "chicken"
	elseif (takedamage:GetComponent( "RabbitAI" )) then
		_component = takedamage:GetComponent( "RabbitAI" )
		_type = "rabbit"
	elseif (takedamage:GetComponent( "BoarAI" )) then
		_component = takedamage:GetComponent( "BoarAI" )
		_type = "boar"
	else
		return
	end

	local _netUser = damage.attacker.client.netUser
	local _userID = rust.GetUserID( _netUser )

	if (not(self.MissionStatus[_userID]) or not(self.MissionStatus[_userID][_type])) then
		return
	end

	local _userMissions = {}
	for _name, _data in pairs(self.MissionStatus[_userID][_type]) do
		self.MissionStatus[_userID][_type][_name].kills = _data.kills + 1
		if (not(_userMissions[_type])) then
			_userMissions[_type] = { amount = 0, complete = {} }
		end
		-- check if mission exists. Perhaps was removed
		if (self.SupportedTypes[_type].missions[_name] and self.Missions[_type][self.SupportedTypes[_type].missions[_name]]) then
			local _mission = self.Missions[_type][self.SupportedTypes[_type].missions[_name]]
			if ( _mission.kills <= self.MissionStatus[_userID][_type][_name].kills ) then
				if (_mission.money and self.economy) then
					self.economy.callback(_netUser, _mission.money)
				else
					print ("inv.giveplayer \"" .. util.QuoteSafe(_netUser.displayName) .. "\" \"" .. _mission.item .. "\" " .. _mission.amount)
					rust.RunServerCommand("inv.giveplayer \"" .. util.QuoteSafe(_netUser.displayName) .. "\" \"" .. _mission.item .. "\" " .. _mission.amount )
					rust.InventoryNotice( _netUser,  _mission.amount .. " x " .. _mission.item)
				end
				rust.SendChatToUser( _netUser, self.Config.chatname, _type .. " " ..  self.Config.text.single .. " " .. util.QuoteSafe(_name) .. " completed!" )
				table.insert(_userMissions[_type].complete, _name)
			else
				_userMissions[_type].amount = _userMissions[_type].amount + 1
			end
		else
			table.insert(_userMissions[_type].complete, _name)
			print ("Seems like " .. _type .. " " .. _name .. " is removed from mission list!")
		end
	end

	for _type, _data in pairs(_userMissions) do
		for _, _name in pairs(_data.complete) do
			self.MissionStatus[_userID][_type][_name] = nil
		end
		if (_data.amount == 0) then
			self.MissionStatus[_userID][_type] = nil
		end
	end

	local _hasMissions = false
	for _type, _data in pairs(self.MissionStatus[_userID]) do
		_hasMissions = true
		break
	end
	if (not(_hasMissions)) then
		self.MissionStatus[_userID] = nil
	end
	self:Save()
	-- below is some debug info for me. Just investigating why i cannot get info about killing with a bow
	-- if(damage.extraData and damage.extraData.dataBlock and damage.extraData.dataBlock.name	) then
	-- 	local _weapon = damage.extraData.dataBlock.name
	-- 		print(util.QuoteSafe(_netUser.displayName) .. " weapon:" .. _weapon)
	-- 		print ( damage.extraData.dataBlock  )
	-- 		print ( damage.extraData  )
	-- 	elseif (damage.extraData and damage.extraData.dataBlock ) then
	-- 		print ( damage.extraData.dataBlock  )
	-- 	elseif (damage.extraData ) then
	-- 		print ( damage.extraData  )
	-- 	else
	-- 		print ( util.QuoteSafe(_netUser.displayName) .. " no weapon found")
	-- 	end
end

function PLUGIN:LoadConfiguraion()
	local _dataFile = util.GetDatafile( "cfg_advanced_mission" )
    local _txt = _dataFile:GetText()
	local _result = nil
    if ( _txt ~= "" ) then
        _result = json.decode( _txt )
		if (not(_result)) then
			print ("Configuration file is corrupted!")
			return false
		end
	else
		print ("Configuration file not found!")
	end
	local _doSave = false

	if (not(_result)) then
		_result = self:GetDefaultConfiguration()
	end
	if (not(_result.conf)) then
		_result.conf = {}
	end
	if (not(_result.missions)) then
		_result.missions = {}
	end
	if (not(_result.conf.version) or _result.conf.version == "") then
		_result.conf.version = "1.0"
		_doSave = true
	end
	if (not(_result.conf.command) or _result.conf.command == "") then
		_result.conf.command = "mission"
		_doSave = true
	end
	if (not(_result.conf.chatname) or _result.conf.chatname == "") then
		_result.conf.chatname = _result.conf.command .. ' '
		_doSave = true
	end

	if (not(_result.conf.text) or _result.conf.text == "") then
		_result.conf.text = {}
		_doSave = true
	end
	if (not(_result.conf.text.single) or _result.conf.text.single == "") then
		_result.conf.text.single = _result.conf.command
		_doSave = true
	end
	if (not(_result.conf.text.plural) or _result.conf.text.plural == "") then
		_result.conf.text.plural = _result.conf.text.single .. "s"
		_doSave = true
	end
	
	if (_doSave) then
		_dataFile:SetText( json.encode( _result, { indent = true } ) )
		_dataFile:Save()
		print ("Advanced mission configuration updated")
	end

	self:SetMissions(_result.missions)
	self.Config = _result.conf

	return true
end

function PLUGIN:GetDefaultConfiguration()
	return {
		missions = {
			wolf = {
				{ kills = 1, amount = 2, item = "Can of Tuna", name = "tuna" },
				{ kills = 2, amount = 4, item = "Arrow", name = "ammo" }
			},
			bear = {
				{ kills = 1, amount = 2, item = "Can of Tuna", name = "tuna" },
				{ kills = 1, amount = 4, item = "Arrow", name = "ammo" }
			},
			deer = {
				{ kills = 1, amount = 2, item = "Can of Tuna", name = "tuna" },
				{ kills = 2, amount = 4, item = "Arrow", name = "ammo" }
			},
			chicken = {
				{ kills = 1, amount = 2, item = "Can of Tuna", name = "tuna" },
				{ kills = 2, amount = 4, item = "Shotgun Shells", name = "ammo" }
			},
			rabbit = {
				{ kills = 1, amount = 2, item = "Can of Tuna", name = "tuna" },
				{ kills = 2, amount = 4, item = "9mm Ammo", name = "ammo" }
			},
		},
		conf = {
			version = "1.0",
			command = "mission",
			text = {
				bear = { plural = "bears", single = "bear" },
				wolf = { plural = "wolves", single = "wolf" },
				deer = { plural = "deer", single = "deer" },
				chicken = { plural = "chickens", single = "chicken" },
				rabbit = { plural = "rabbits", single = "rabbit" }
			},
			messages = {
				broadcast = "Try out our missions! Type /mission to show commands available"
			}
		}
	}
end

function PLUGIN:SendHelpText( netuser )
	rust.SendChatToUser( netuser, "Type /" .. self.Config.command .. " to show commands available" )
end

function PLUGIN:Init()
	self.SupportedTypes = {}
	for _, _n in pairs({ "wolf", "bear", "deer", "chicken", "rabbit", "boar" }) do
		self.SupportedTypes[_n] = { amount = 0, missions = {} }
	end
	self.MissionCount = 0
	
	self.MissionStatusFile = util.GetDatafile( "advanced_mission_data" )
	self.MissionStatus = {}
	local _result = self.MissionStatusFile:GetText()
	if ( _result ~= "" ) then
		_result = json.decode( _result )
		-- lets convert older mission configuration
		for _userId, _missionsTypes in pairs(_result) do
			if (not(self.MissionStatus[_userId])) then
				self.MissionStatus[_userId] = {}
			end
			for _type, _missions in pairs(_missionsTypes) do
				if (not(self.MissionStatus[_userId][_type])) then
					self.MissionStatus[_userId][_type] = {}
				end
				for _mission, _amount in pairs(_missions) do
					if (not(self.MissionStatus[_userId][_type][_mission])) then
						if (type(_amount) == "table") then
							self.MissionStatus[_userId][_type][_mission] = _amount
						else
							self.MissionStatus[_userId][_type][_mission] = { kills = _amount }
						end
					else
						error("Somehow self.MissionStatus." .. _userId .. "." .. _type .. "." .. _mission .. " already exists! ")
					end
				end
			end
		end
		self:Save()
	end
end

function PLUGIN:MainCommand( netuser, cmd, args )
	if (args[1] and args[1] == "reload" and self:ReloadConfiguraion(netuser)) then
		rust.SendChatToUser( netuser, self.Config.chatname, "Configuration reloaded" )
		return
	end
	if (args[1] and args[1] == "about" ) then
		rust.SendChatToUser(netuser, self.Title .. " " .. self.Version .. " by " .. self.Author .. ". " .. self.Description)
		return
	end

	local _type = nil

	local _inx = {t = 1, m = 2}
	if (args[1] == "joinall") then
		_inx = {t = 2, m = 3}
	end

	if (args[_inx.t] and self.SupportedTypes[args[_inx.t]]) then
		_type = args[_inx.t]
	end

	local _mission = nil
	if (_type and args[_inx.m] and self.SupportedTypes[_type].missions[args[_inx.m]]) then
		_mission = args[_inx.m]
	end

	if (_type and _mission) then
		if (self:StartMission(netuser, _type, _mission)) then
			rust.SendChatToUser( netuser, self.Config.chatname, "Started " .. _type .. " " ..  self.Config.text.single .. " " .. util.QuoteSafe(_mission) )
			self:Save()
			return
		end
	end

	if (_inx.t == 2 and _type and self.Missions[_type]) then
		for _,v in pairs(self.Missions[_type]) do
			if (self:StartMission(netuser, _type, v.name)) then
				rust.SendChatToUser( netuser, self.Config.chatname, "Started " .. _type .. " " ..  self.Config.text.single .. " " .. util.QuoteSafe(v.name) )
			end
		end
		self:Save()
		return
	end
	
	local userID = rust.GetUserID( netuser )
	if (_type and self.Missions[_type]) then
		local _plural = _type
		local _single = _type
		if self.SupportedTypes[_type].plural then
			_plural = self.SupportedTypes[_type].plural
		end
		if self.SupportedTypes[_type].single then
			_single = self.SupportedTypes[_type].single
		end
		local _found = false
		for _,v in pairs(self.Missions[_type]) do
			if ((v.money and self.economy) or (not(v.money) and v.item)) then
				local _text = util.QuoteSafe(v.name) .. " - " .. "kill " .. v.kills .. " "
				if (v.kills == 1) then -- single
					_text = _text .. _single
				else -- multiple kills
					_text = _text .. _plural
				end
				_text = _text .. " to get "
				if (v.money and self.economy) then -- economy plugin
					_text = _text .. self.economy.symbol .. v.money
				else -- just some items
					_text = _text .. v.amount .. " " .. v.item
				end
				if (self.MissionStatus[userID] and self.MissionStatus[userID][_type] and self.MissionStatus[userID][_type][util.QuoteSafe(v.name)]) then
					_text = "(progress: " .. self.MissionStatus[userID][_type][util.QuoteSafe(v.name)].kills .. ") " .. _text
				else
					_text = "/" .. self.Config.command .. " " ..  util.QuoteSafe(_type) .. " " .. _text
				end
				rust.SendChatToUser( netuser, self.Config.chatname, _text )
				if (not(_found)) then
					_found = true
				end
			end
		end
		if (_found) then
			return
		end
	end
	for _type, _typeData in pairs(self.SupportedTypes) do
		local _description = _type .. " - "

		if (_typeData.single and not(_typeData.single == _type)) then -- this is all because they named zombie to red animals
			_description = _description .. "(" .. _typeData.single .. ") "
		end

		local _text = "/" .. self.Config.command .. " " .. _description
		local _count = 0
		if (self.MissionStatus[userID] and self.MissionStatus[userID][_type]) then
			for _, _ in pairs(self.MissionStatus[userID][_type]) do
				_count = _count + 1
			end
		end
		if (self.SupportedTypes[_type].amount == 1) then
			_text = _text .. " one " .. self.Config.text.single
		else
			_text = _text .. " " .. self.SupportedTypes[_type].amount .. " " .. self.Config.text.plural
		end
		if (_count == 1) then
			_text = _text .. " (joined one)"
		elseif(_count > 1) then
			_text = _text .. " (joined " .. _count .. ")"
		end
		rust.SendChatToUser(netuser, self.Config.chatname, _text )
	end
	rust.SendChatToUser(netuser, self.Config.chatname, "/" .. self.Config.command .. " joinall <target> to join all targeted missions" )
	if ( netuser:CanAdmin() ) then
		rust.SendChatToUser(netuser, self.Config.chatname, "/" .. self.Config.command .. " reload to reload configuration" )
    end
end

-- if is money based mission then itemName is nil
function PLUGIN:AddMission(missionType, missionName, kilsCount, itemAmount, itemName)
	if ( not(itemName) or itemName == "" ) then
		-- test for economy plugin
		if (not(api.Exists("fj_economy_wrapper"))) then
			error( "Cannot define mission type:" .. missionType .. ", name: " .. missionName .. " it requires economy plugin. Find Economy wrapper plugin")
			return
		end
		local _call, _msg =  api.Call("fj_economy_wrapper", "HasEconomy")
		if ( not(_call) ) then
			error( "Cannot define mission type:" .. missionType .. ", name: " .. missionName .. " it requires economy plugin. Economy wrapper has no economy plugin defined")
			return
		end
	end

	if (not(self.SupportedTypes[missionType])) then
		error( "Cannot define mission name: " .. missionName .. " unknown type: " .. missionType)
		return
	end
	if (self.SupportedTypes[missionType].missions[missionName]) then
		error( "Cannot define mission type:" .. missionType .. ", name: " .. missionName .. " already exists!")
		return
	end
	if (not(type(kilsCount) == "number")) then
		kilsCount = tonumber(kilsCount)
	end
	if (kilsCount <= 0) then
		error("Kills count must be larger than 0, found " .. kilsCount)
		return
	end
	if (not(type(itemAmount) == "number")) then
		itemAmount = tonumber(itemAmount)
	end
	if (itemAmount <= 0) then
		error("Amount must be larger than 0, found " .. itemAmount)
		return
	end
	if (not(self.Missions)) then
		self.Missions = {}
	end
	if (not(self.Missions[missionType])) then
		self.Missions[missionType] = {}
	end
	if (itemName) then
		table.insert(self.Missions[missionType], { name = missionName, kills = kilsCount, item = itemName, amount = itemAmount})
	else
		table.insert(self.Missions[missionType], { name = missionName, kills = kilsCount, money = itemAmount})
	end
	self.MissionCount = self.MissionCount + 1
	self.SupportedTypes[missionType].amount = self.SupportedTypes[missionType].amount + 1
	self.SupportedTypes[missionType].missions[missionName] = #self.Missions[missionType]
end

function PLUGIN:StartMission(netuser, missionType, mission)
	if (not(self.SupportedTypes[missionType]) or self.SupportedTypes[missionType].amount == 0) then
		--- this actually must never happen!
		rust.Notice( netuser, "Unknown " ..  self.Config.text.single .. " type " .. missionType .. "!" )
		return false
	end
	if (not(self.SupportedTypes[missionType].missions[util.QuoteSafe(mission)])) then
		rust.Notice( netuser, missionType .. " " ..  self.Config.text.single .. " " .. mission .. " not found!" )
		return false
	end

	local userID = rust.GetUserID( netuser )
	if (not(self.MissionStatus[userID])) then
		self.MissionStatus[userID] = {}
	end
	if (not(self.MissionStatus[userID][missionType])) then
		self.MissionStatus[userID][missionType] = {}
	end
	if (self.MissionStatus[userID][missionType][util.QuoteSafe(mission)]) then
		rust.Notice( netuser, "Already on " .. missionType .. " " ..  self.Config.text.single .. " " .. mission .. "!" )
		return false
	end
	self.MissionStatus[userID][missionType][util.QuoteSafe(mission)] = { kills = 0 }
	return true
end

function PLUGIN:SetMissions(missions)
	if (not(missions)) then
		print ("Missions are not defined!")
		return
	end
	for _type, _missions in pairs(missions) do
		if (self.SupportedTypes[_type]) then 
			self.SupportedTypes[_type].amount = 0 -- clean up old stuff
			self.SupportedTypes[_type].missions = {} -- clean up old stuff
			for _, _mission in pairs(_missions) do
				if (_mission.money and not(_mission.item)) then
					if (self.economy) then -- if economy is not defined there is no reason to activate this
						self:AddMission(_type, _mission.name, _mission.kills, _mission.money, nil)
					end
				elseif (not(_mission.money) and _mission.item) then
					self:AddMission(_type, _mission.name, _mission.kills, _mission.amount, _mission.item)
				else
					error( "Cannot define mission type " .. _type .. " mission " .. _mission.name)
				end
			end
		else
			print (_type .. " mission is not supported. Sorry!")
		end
	end
end

function PLUGIN:Save()
	self.MissionStatusFile:SetText( json.encode( self.MissionStatus ) )
	self.MissionStatusFile:Save()
end

function PLUGIN:ReloadConfiguraion(netuser)
	if ( not(netuser:CanAdmin()) ) then
        return false
    end

	local _dataFile = util.GetDatafile( "cfg_advanced_mission" )
    local _txt = _dataFile:GetText()
	local _result = nil
    if ( _txt ~= "" ) then
        _result = json.decode( _txt )
		if (not(_result)) then
			print ("Configuration file is corrupted!")
			return false
		end
	else
		print ("Configuration file not found!")
	end
	if (not(_result)) then
		_result = self:GetDefaultConfiguration()
		_dataFile:SetText( json.encode( _result, { indent = true } ) )
		_dataFile:Save()
	end
	self.Missions = {}
	self:SetMissions(_result.missions)
	if (_result.conf.text) then
		for _type, __ in pairs(self.SupportedTypes) do
			if (_result.conf.text[_type] and _result.conf.text[_type].plural) then
				self.SupportedTypes[_type].plural =  _result.conf.text[_type].plural
			end
			if (_result.conf.text[_type] and _result.conf.text[_type].single) then
				self.SupportedTypes[_type].single =  _result.conf.text[_type].single
			end
		end
	end
	self.Config = _result.conf

	api.Call("broadcast", "RemoveExternalMessage", "advanced_mission")
	
	if ( self.Config.messages and self.Config.messages.broadcast ) then
		api.Call("broadcast", "AddExternalMessage", "advanced_mission", self.Config.messages.broadcast  , { chatname = self.ChatName })
	end
end

-- read configuration
function PLUGIN:PostInit()
	if (not(self:LoadConfiguraion())) then
		error( "Configuration file is corrupted! Advanced mission is not initialized")
		return
	end
	print ("advanced missions: loaded " .. self.MissionCount .. " missions!")
	
	api.Call("broadcast", "RemoveExternalMessage", "advanced_mission")
	
	if ( self.Config.messages and self.Config.messages.broadcast ) then
		api.Call("broadcast", "AddExternalMessage", "advanced_mission", self.Config.messages.broadcast  , { chatname = self.ChatName })
	end
	
	-- prefill missions end
	self:AddChatCommand(self.Config.command, self.MainCommand)
end

print("Loaded " .. PLUGIN.Title .. " " .. PLUGIN.Version)
