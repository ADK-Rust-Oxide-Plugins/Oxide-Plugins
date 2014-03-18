PLUGIN.Title = "advanced_kits"
PLUGIN.Description = "Advanced Kits"
PLUGIN.Version = "1.16.11"
PLUGIN.Author = "Fox Junior"
print("loading " .. PLUGIN.Title .. " " .. PLUGIN.Version)

function PLUGIN:loadConfiguraion()
	self.Columns = nil
	local _dataFile = util.GetDatafile( "cfg_advanced_kits" )
    local _txt = _dataFile:GetText()
	local _result = nil
	local _default_command = "kit"
	local _default_messages = {
		githelp = "Get your kits! Type /" .. _default_command .. " to get started",
		nokitdefined = "No kit available!",
		redeem = "Kit %kit% redeemed!",
		given = "Kit %kit% given to %user%!",
		received = "Buff! %user% gave you a %kit%!",
		cooldown = "You have to wait %min% minutes and %sec%s seconds for %kit% to be available!",
		exceeded = "Already redeemed %kit% maximum %amount% times!",
		nogiveyourself = "You cannot give %kit% yourself!",
		broadcast = "Get your kits! Type /" .. _default_command .. " to get started"
	}
	local _default_kits = {
		starter = { max = 5, cooldown = 1, description = "Basic things you need! (maximum 5 times)",
			items = { "Stone Hatchet", {item = "Cooked Chicken Breast", amount = 3 } } },
		basic = { max = 2, cooldown = 1, description = "Gives you some comfort (maximum 2 times)!",
			items = { "Wood Shelter", "Cloth Pants", "Wooden Door", "Camp Fire", {item = "Cooked Chicken Breast", amount = 3 } } },
		help = { admin = true, description = "Start building!",
			items = { "Bed", {item = "Wood Wall", amount = 3}, "Wood Doorway", "Metal Door", "Wood Foundation", "Wood Storage Box", "Camp Fire", "Furnace" } }
	}

    if ( _txt ~= "" ) then
        _result = json.decode( _txt )
		if (not(_result)) then
			print (self.Title .. " Configuration file is corrupted!")
			return false
		end
	else
		print (self.Title .. " Configuration file not found!")
	end

	local _doSave = false

	if (not(_result)) then
		_result = {
			command = _default_command,
			messages = _default_messages,
			kits = _default_kits
		}
		_doSave = true
	end
	if (not(_result.messages)) then
		_result.messages = {}
	end

	-- lets optimize messages
	self.Messages = {}
	for _name, _msg in pairs(_default_messages) do
		if (not(_result.messages[_name]) and _name ~= "broadcast" ) then
			_result.messages[_name] = _msg
			_doSave = true
		end
		self.Messages[_name] = _result.messages[_name]
	end

	if (not(_result.command)) then
		_result.command = _default_command
		_doSave = true
	end
	if (not(_result.chatname)) then
		_result.chatname = _result.command .. ' '
		_doSave = true
	end

	if (not(_result.columns)) then
		_result.columns = 0
		_doSave = true
	else
		self.Columns = _result.columns
	end

	if (_doSave) then
		_dataFile:SetText( json.encode( _result, { indent = true } ) )
		_dataFile:Save()
		print (self.Title .. " configuration updated")
	end

	self.Command = _result.command
	self.ChatName = _result.chatname

	self.KitsData = {}

	self.KitCount = { total = 0, player = 0}

	for _name, _kits in pairs(_result.kits) do
		local _newKits = { items = {} }
		self.KitCount.total = self.KitCount.total + 1
		if (_kits.admin) then
			_newKits.admin = _kits.admin
		else
			self.KitCount.player = self.KitCount.player + 1
		end
		if (_kits.flags) then
			 _newKits.flags = _kits.flags
			 if ( type(_newKits.flags) == "string" ) then
			 	_newKits.flags = { get = {_newKits.flags}, give = nil }
			 end
		end
		if (_kits.max) then
			_newKits.max = _kits.max
		end
		if (_kits.cooldown) then
			_newKits.cooldown = _kits.cooldown
		end
		if (_kits.description) then
			_newKits.description = _kits.description
		end
		if (not(_kits.items) or #_kits.items == 0) then
			error("Kit items are missing for kit " .. _name)
			return
		end
		for __, _kit in pairs(_kits.items) do
			local _newKit = { item = "", amount = 1 }
			if (type( _kit ) == "table") then
				if (not(_kit.item)) then
					error("Kit item item is missing for kit " .. _name)
					return
				end
				_newKit.item = _kit.item
				if (_kit.amount) then
					_newKit.amount = _kit.amount
				end
				if (_kit.target) then
					_newKit.target = _kit.target
				end
			else
				_newKit.item = _kit
			end
			table.insert(_newKits.items, _newKit)
		end
		print ("Kit " .. _name .. " loaded")
		self.KitsData[_name] = _newKits
	end

	self.WelcomeKit = {}
	if ( _result.auto_kit ) then
		if (type( _result.auto_kit ) == "table") then
			for _index, _kits in pairs(_result.auto_kit) do
				local _newKits = { disabled_when = nil, items = {}, remove_rock = false, flags = {} }
				if (type( _kits ) == "table") then
					if ( _kits.disabled_when ) then
						_newKits.disabled_when = _kits.disabled_when
					end
					if ( _kits.remove_rock ) then
						_newKits.remove_rock = _kits.remove_rock
					end
					if ( _kits.flags ) then
						if (type(_kits.flags) == "string") then
							_newKits.flags = { get = { _kits.flags }, give = nil }
						else
							_newKits.flags = { get = _kits.flags , give = nil }
						end
					end
					if (not(_kits.items)) then
						error("Kit item item is missing for kit " .. _name)
						return
					end

					for __, _kit in pairs(_kits.items) do
						local _newKit = { item = nil, amount = 1 }
						if (type( _kit ) == "table") then
							if (not(_kit.item)) then
								error("Kit item item is missing for kit " .. _name)
								return
							end
							_newKit.item = _kit.item
							if (_kit.amount) then
								_newKit.amount = _kit.amount
							end
							if (_kit.target) then
								_newKit.target = _kit.target
							end
						else
							_newKit.item = _kit
						end
						table.insert(_newKits.items, _newKit)
					end

				else
					table.insert(_newKits.items, { item = _kits, amount = 1 })
				end
				table.insert(self.WelcomeKit, _newKits )
			end
		else
			table.insert(self.WelcomeKit, { { disabled_when = nil, items = { _result.auto_kit } } })
		end
	end

	self.RemoveRock = nil
	if ( _result.remove_rock ) then
		if (type( _result.remove_rock ) == "table") then
			self.RemoveRock = _result.remove_rock
		else
			self.RemoveRock= { _result.remove_rock }
		end
	end

	if ( not(self.WelcomeKit) or #self.WelcomeKit == 0) then
		print (self.Title .. " No auto kit!")
	else
		print (self.Title .. " loaded: " .. tostring(#self.WelcomeKit))
	end 

	if (self.KitCount.total > 0) then
		print(self.KitCount.total .. " kits and player " .. self.KitCount.player .. " kits loaded")
	else
		print ("Kits not found!")
	end
end


function PLUGIN:Init()
	self:loadConfiguraion()
	self.UserKitsFile = util.GetDatafile( "advanced_kits_data" )
	local _kitsResult = self.UserKitsFile:GetText()
	if ( _kitsResult ~= "" ) then
		self.UserKits = json.decode( _kitsResult )
	else
		self.UserKits = {}
	end

	self:AddChatCommand(self.Command, self.mainCommand)
end

function PLUGIN:PostInit()
	self.flagsPlugin = plugins.Find("flags")
	if( self.flagsPlugin ) then
		print(self.Title .. " Flags plugin implemented")
	else
		print(self.Title .. " Flags plugin not found!")
	end
	self.oxminPlugin = plugins.Find("oxmin")
	if( self.oxminPlugin ) then
		print(self.Title .. " Oxmin plugin implemented")
	else
		print(self.Title .. " Oxmin plugin not found!")
	end

	local _broacastPlugin = nil
	if( api.Exists( "broadcast" )) then
		_broacastPlugin = plugins.Find("broadcast")
		if( _broacastPlugin ) then
			_broacastPlugin:RemoveExternalMessage("advanced_kits")
		end
	end
	if ( self.Messages.broadcast ) then
		if( _broacastPlugin ) then
			_broacastPlugin:AddExternalMessage( "advanced_kits", self.Messages.broadcast  , { chatname = self.ChatName } )
		end
	end
end

function PLUGIN:HasFlag( netuser, flag, user_id )
	if ( not(flag) ) then
		return false
	end
	if ( type( flag ) == "table") then
		if (#flag == 0) then
			return false
		end
		local _user_id = rust.GetUserID( netuser )
		for _, _flag in pairs( flag ) do
			if ( self:HasFlag(netuser, _flag, _user_id) ) then
				return true
			end
		end
		return false
	end
	if ( self.oxminPlugin and self.oxminPlugin:HasFlag(netuser, flag) ) then
		return true
	end
	if ( not (user_id) ) then
		user_id = rust.GetUserID( netuser )
	end
	if ( self.flagsPlugin and self.flagsPlugin:HasFlag( user_id, flag) ) then
		return true
	end
	return false	
end

function PLUGIN:CanRedeem(netuser, kit)
	local _inv = rust.GetInventory(netuser)
	if (kit.disabled_when) then
		for _, _name in pairs (kit.disabled_when) do
			local _db_name = rust.GetDatablockByName(_name)
			if ( not (_db_name) ) then
				print (self.Title .. " Configuration error! " .. _name .. " not found!")
			elseif ( _inv:FindItem(_db_name) ) then
				return false, false
			end
		end
	end
	if ( kit.flags and (( kit.flags.get and #kit.flags.get > 0 ) or ( kit.flags.give and #kit.flags.give > 0 ))) then
		local _get = false
		local _give = false
		if ( kit.flags.get and #kit.flags.get > 0 ) then
			_get = self:HasFlag(netuser, kit.flags.get)
		end
		if ( kit.flags.give ) then
			_give = self:HasFlag(netuser, kit.flags.give)
		end
		return _get, _give
	end
	if ( kit.admin and not(netuser:CanAdmin()) ) then
		return false, false
	end
	return true, false
end

function PLUGIN:DoRemoveRock(netuser, inv)
	local _rock = rust.GetDatablockByName("Rock")
	local _r = inv:FindItem(_rock)
	local _i = 0
	while (_r) do
		inv:RemoveItem(_r)
		_r = inv:FindItem(_rock)
		_i = _i + 1
		if ( _i > 36) then
			print ("Too many rocks!")
			break -- avoid cycle!
		end
	end
end

function PLUGIN:AutoKit(netuser)
	local _inv = rust.GetInventory(netuser)
	local rock_removed = false
	if (self.WelcomeKit) then
		local _redeem = false
		for _index, _kit in pairs(self.WelcomeKit) do
			if ( _redeem ) then
				break
			end
			_redeem = self:CanRedeem( netuser, _kit )
			if (_redeem) then
				if (_kit.remove_rock and not (rock_removed)) then
					self:DoRemoveRock(netuser, _inv)
					rock_removed = true
				end
				self:redeem(netuser, _kit.items, false, _inv )
			end
		end
	end
	if (rock_removed) then
		return
	end
	if ( self.RemoveRock ) then
		local _redeem = false
		for _index, _name in pairs(self.RemoveRock) do
			local _db_name = rust.GetDatablockByName(_name)
			if ( _inv:FindItem(_db_name) ) then
				_redeem = true
				break
			end
		end
		if (_redeem) then
			self:DoRemoveRock(netuser, _inv)
		end
	end
end

function PLUGIN:OnSpawnPlayer(playerclient, usecamp, avatar)
	if (self.WelcomeKit or self.RemoveRock ) then
    	timer.Once(1, function() self:AutoKit(playerclient.netUser) end)
    end
end

function PLUGIN:Save()
	self.UserKitsFile:SetText( json.encode( self.UserKits ) )
	self.UserKitsFile:Save()
end

function PLUGIN:redeem(netuser, items, notice, inventory)
	for __, _kit in pairs(items) do
		local _invPref = nil
		if (_kit.target) then
			if (_kit.target == "belt") then
				_invPref = rust.InventorySlotPreference( InventorySlotKind.Belt, false, InventorySlotKindFlags.Belt )
			elseif (_kit.target == "ammo") then
				_invPref = rust.InventorySlotPreference( InventorySlotKind.Default, false, InventorySlotKindFlags.Belt )
			elseif (_kit.target == "helmet") then
				_invPref = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor )
			elseif (_kit.target == "vest") then
				_invPref = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor )
			elseif (_kit.target == "pants") then
				_invPref = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor )
			elseif (_kit.target == "boots") then
				_invPref = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor )
			end
		end
		if not (_invPref) then
			_invPref = rust.InventorySlotPreference(InventorySlotKind.Default, false, InventorySlotKindFlags.Belt)
		end
		local _item = rust.GetDatablockByName( _kit.item )
		inventory:AddItemAmount( _item, _kit.amount, _invPref )
		if (notice) then
			rust.InventoryNotice(netuser,  _kit.amount .. " x " .. _kit.item )
		end
	end
end

-- rust find user does the same thing but does not work with special symbols
function PLUGIN:FindUserByName( userName )
	local _rv = {}
	local _players = rust.GetAllNetUsers()
	if (not _players) then return false, 0 end
	for _, _player in pairs( _players ) do
		local _name = util.QuoteSafe(_player.displayName)
		if (string.sub(_name, 1, string.len(userName)) == userName) then
			table.insert(_rv, _player)
		end
	end
	if (#_rv == 0) then return false, 0 end
	if (#_rv > 1) then return false, #_rv end
	return true, _rv[1]
end

function PLUGIN:FindUserByNameWithErrors( netuser, userName )
	local b, _found = self:FindUserByName(userName)
	if (not(b)) then
		if ( not(type(_found) ~= "number") and _found == 0 ) then
			rust.Notice( netuser, "User " .. util.QuoteSafe(userName) .. " not found!!" )
		elseif ( not(type(_found) ~= "number") and _found > 0 ) then
			rust.Notice( netuser, "Too many users for " .. util.QuoteSafe(userName) .. " matched!!" )
		else
			rust.Notice( netuser, "Unknown reason why user " .. util.QuoteSafe(userName) .. " not found!!" )
		end
		return
	end
	return _found
end

function PLUGIN:mainCommand( netuser, cmd, args )
	if ((self.KitCount.player == 0 and not(netuser:CanAdmin())) or (self.KitCount.total == 0 and netuser:CanAdmin())) then
		rust.Notice( netuser, self.Messages.nokitdefined )
		return
	end

	if ( args[1] and args[1] == "about" ) then
		rust.SendChatToUser(netuser, self.Title .. " " .. self.Version .. " by " .. self.Author .. ". " .. self.Description)
		return
	end
	if ( args[1] and args[1] == "reload" and netuser:CanAdmin() ) then
		self:loadConfiguraion()

		local _broacastPlugin = nil
		if( api.Exists( "broadcast" )) then
			_broacastPlugin = plugins.Find("broadcast")
			if( _broacastPlugin ) then
				_broacastPlugin:RemoveExternalMessage("advanced_kits")
			end
		end
		if ( self.Messages.broadcast ) then
			if( _broacastPlugin ) then
				_broacastPlugin:AddExternalMessage( "advanced_kits", self.Messages.broadcast  , { chatname = self.ChatName } )
			end
		end
		rust.SendChatToUser( netuser, self.ChatName, "Advanced kits configuration reloaded" )
		return
	end

	local _kit = nil
	local _kit_name = nil
	if (args[1] and self.KitsData[args[1]]) then
		_kit_name = args[1] 
		_kit = self.KitsData[_kit_name]
	end
	local _command = nil
	if (args[2] and (args[2] == "list" or args[2] == "give")) then 
		_command = args[2]
	end

	local _user_id = rust.GetUserID( netuser )
	local _isAdmin = netuser:CanAdmin()


	local _canGet = false
	local _canGive = false
	if ( _kit ) then
		_canGet,  _canGive = self:CanRedeem( netuser, _kit )
	end

	if ( _canGet or  _canGive ) then
		if (_command and _command == "list") then
			rust.SendChatToUser( netuser, self.ChatName, _command )
			for _name, _kit in pairs(_kit.items) do
				rust.SendChatToUser( netuser, self.ChatName, _kit.amount .. "  - " .. _kit.item )
			end
			return
		end

		local _message = self.Messages.redeem
		local _isgiven = false
		local _netuser = nil

		local _userGive = false
		if ( _command and _command == "give") then
			if (netuser:CanAdmin() or _canGive ) then
				_userGive = true
			end
		end

		if (_userGive and args[3]) then
			local _m_netuser = self:FindUserByNameWithErrors(netuser, args[3])
			if (_m_netuser) then
				local _m_user_id = rust.GetUserID( _m_netuser )
				if (_m_user_id == _user_id) then
					local _error_message = string.gsub(self.Messages.nogiveyourself , "%%kit%%", _kit_name)
					rust.Notice( netuser, _error_message )
					return
				end
				_netuser = _m_netuser
				_message = self.Messages.received
				_isgiven = true
			end
		elseif (_canGet and not(_command)) then
			local _error_message = nil

			if (_kit.max and _kit.max > 0) then
				if (not(self.UserKits[_user_id])) then
			 		self.UserKits[_user_id] = {}
			 	end
			 	if (not(self.UserKits[_user_id][_kit_name])) then
			 		 self.UserKits[_user_id][_kit_name] = {amount = 0}
			 	end
			 	if (not(self.UserKits[_user_id][_kit_name].amount)) then
			 		 self.UserKits[_user_id][_kit_name].amount = 0
			 	end
			 	if (self.UserKits[_user_id][_kit_name].amount >= _kit.max) then
			 		_error_message = string.gsub(self.Messages.exceeded , "%%kit%%", _kit_name)
			 		_error_message = string.gsub(_error_message , "%%amount%%", self.UserKits[_user_id][_kit_name].amount)
			 	end
			end
			if (not(_error_message) and _kit.cooldown and _kit.cooldown > 0) then
				if (not(self.UserKits[_user_id])) then
			 		self.UserKits[_user_id] = {}
			 	end
			 	if (not(self.UserKits[_user_id][_kit_name])) then
			 		 self.UserKits[_user_id][_kit_name] = {when = 0}
			 	end
			 	if (not(self.UserKits[_user_id][_kit_name].when)) then
			 		 self.UserKits[_user_id][_kit_name].when = 0
			 	end
			 	local _now = util.GetTime()
				if (_now > 61) then -- bug at oxide
					local _remain = self.UserKits[_user_id][_kit_name].when + (_kit.cooldown * 60) - _now
					if (_remain > 0 ) then
						local _min = math.floor( _remain / 60 )
						local _second = _remain - ( _min * 60 )
						_error_message = string.gsub(self.Messages.cooldown , "%%kit%%", _kit_name)
						_error_message = string.gsub(_error_message , "%%min%%", _min)
						_error_message = string.gsub(_error_message , "%%sec%%", _second)
					end
				end
			end
			if (not(_error_message) and (_kit.cooldown or _kit.max)) then
				if (_kit.max) then
			 		self.UserKits[_user_id][_kit_name].amount = self.UserKits[_user_id][_kit_name].amount + 1
				end
				if (_kit.cooldown) then
			 		self.UserKits[_user_id][_kit_name].when = util.GetTime()
				end
				self:Save()
			end
			if (not(_error_message)) then
				_netuser = netuser
			else
				rust.Notice(netuser, _error_message )
				return
			end
		end

		if (_netuser) then
			_user_name = util.QuoteSafe(_netuser.displayName)
			_message =  string.gsub(_message , "%%kit%%", _kit_name)
			if (_isgiven) then
				_message =  string.gsub(_message , "%%user%%", util.QuoteSafe(netuser.displayName))
			else
				_message =  string.gsub(_message , "%%user%%", _user_name)
			end
			local _inventory = rust.GetInventory(_netuser)

			self:redeem(_netuser, _kit.items, true, _inventory )

			rust.Notice(_netuser, _message )
			if (_isgiven) then
				_message =  string.gsub(self.Messages.given , "%%kit%%", _kit_name)
				_message =  string.gsub(_message , "%%user%%", _user_name)
				rust.Notice(netuser, _message )
			end
			return
		end
	end

	for _name, _kit in pairs(self.KitsData) do
		local _canGet, _canGive = self:CanRedeem( netuser, _kit )
		if ( _isAdmin or _canGet or _canGive ) then
			local _text = "/" .. self.Command .. " " .. _name
			local _permissions = nil
			if (netuser:CanAdmin() or _canGet) then
				_text = _text .. " <list"
			end
			if (netuser:CanAdmin() or _canGive) then
				if ( netuser:CanAdmin() or _canGet ) then
					_text = _text .. " | " 
				end
				_text = _text .. " give \"<user>\""
			end
			if ( netuser:CanAdmin() or  _canGet or _canGive   ) then
				_text = _text .. ">" 
			end
			if (_kit.admin and netuser:CanAdmin()) then
				_text = _text .. " (admin kit)"
			end
			if (_kit.description) then
				_text = _text .. " - " .. _kit.description
			end
			rust.SendChatToUser(netuser, self.ChatName, _text )

			if ( self.Columns and self.Columns > 0 ) then
				local _row = nil
				for _name, _kit in pairs(_kit.items) do
					local _text = _kit.item
					if ( _kit.amount > 1 ) then
						_text = tostring(_kit.amount) .. " x " .. _text
					end
					local _tmpRow = nil
					if ( not (_row) ) then
						_tmpRow = "--  " .. _text
					else
						_tmpRow = _row .. ", " .. _text
					end
					if ( #_tmpRow > self.Columns ) then
						rust.SendChatToUser( netuser, self.ChatName, _row )
						_row = "--  " .. _text
					else
						_row = _tmpRow
					end
				end
				if (_row) then
					rust.SendChatToUser( netuser, self.ChatName, _row )
				end
			end 
		end
	end
end


function PLUGIN:SendHelpText( netuser )
	if ((netuser:CanAdmin() and self.KitCount.total > 0) or (not(netuser:CanAdmin()) and self.KitCount.player > 0)) then
		rust.SendChatToUser( netuser, self.Messages.githelp )
	end
end
