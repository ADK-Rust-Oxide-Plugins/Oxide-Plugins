PLUGIN.Title = "WelcomeKit"
PLUGIN.Version = "2.05"
PLUGIN.Description = "Automatically hand over a customizable WelcomeKit to new players!"
PLUGIN.Author = "FeuerSturm91"

function PLUGIN:Init()
	self:SetupDatabase()
	self:AddCommand( "welcomekit", "reload", self.ccmdReload )
	self:AddCommand( "welcomekit", "cleardatabase", self.ccmdClearDatabase )
	print( self.Title .. " v" .. self.Version .. ": successfully initialized! Enjoy!" )
end

function PLUGIN:PostInit()
	flags_plugin = plugins.Find( "flags" )
	if(flags_plugin) then print(self.Title .. ": Flags support activated - Admins are recognized by flag 'kick'!") end
	oxminplugin = plugins.Find( "oxmin" )
	if(oxminplugin) then print(self.Title .. ": Oxmin support activated - Admins are recognized by flag 'FLAG_CANKICK'!") end
end

function PLUGIN:SetupDatabase()
	self.PlayerData = util.GetDatafile( "db_welcomekit" )
	if (self.PlayerData:GetText() == "") then
		self.PData = {}
	else
		self.PData = json.decode( self.PlayerData:GetText() )
		if (not self.PData) then
			error( "json decode error in db_welcomekit.txt" )
			self.PData = {}
		end
	end
end

function PLUGIN:ccmdClearDatabase( arg )
	local user = arg.argUser
	if (user and not user:CanAdmin()) then return end
	if (util.GetDatafile( "db_welcomekit" )) then
		util.RemoveDatafile( "db_welcomekit" )
	end
	self:SetupDatabase()
	arg:ReplyWith( "WelcomeKit Database has been cleared." )
	return true
end

function PLUGIN:OnDatablocksLoaded()
	self:LoadKits()
end

function PLUGIN:LoadKits()
	local b, res = config.Read( "welcomekit" )
	self.Kits = res or {}
	if (not b) then
		self:LoadDefaultConfig()
		if (res) then
			config.Save( "welcomekit" )
		end
	end
	
	if (not self.Kits.plugin_options.enable_playerkit and not self.Kits.plugin_options.enable_adminkit and not self.Kits.plugin_options.enable_vipkit) then
		print( "WelcomeKit: WARNING! ALL Kits are disabled! Please check your config file!" )
		return
	end
	local cnt = 0
	for name, kit in pairs( self.Kits ) do
		cnt = cnt + 1
		kit.datablocks = {}
		if (not kit.items) then
			kit.items = {}
		else
			for _, v in pairs( kit.items ) do
				local itemname = v
				local quantity = 1
				local belt = false
				local blockonrespawn = false
				local blockonsuicide = false
				local blockoninitialkit = false
				local blockatcamp = false
				local blockonreconnect = false
				local stack = false
				if (type( v ) == "table") then
					itemname = v.name or ""
					quantity = v.amount or 1
					belt = v.inbelt or false
					blockonrespawn = v.blockonrespawn or false
					blockonsuicide = v.blockonsuicide or false
					blockoninitialkit = v.blockoninitialkit or false
					blockatcamp = v.blockatcamp or false
					blockonreconnect = v.blockonreconnect or false
					stack = v.nostacking or false
				end

				local datablock = rust.GetDatablockByName( itemname )
				if (not datablock) then
					print( "WelcomeKit: WARNING! Unknown item " .. itemname .. " in Kit!" )
				else
					if (stack) then stack = false else stack = true end
					local location = rust.InventorySlotPreference( InventorySlotKind.Default, stack, InventorySlotKindFlags.Belt )
					if (belt) then location = rust.InventorySlotPreference( InventorySlotKind.Belt, stack, InventorySlotKindFlags.Belt ) end
					if ((string.find(itemname, "Helmet") or string.find(itemname, "Vest") or string.find(itemname, "Pants") or string.find(itemname, "Boots")) and not string.find(itemname, "BP")) then
						location = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor )
					end
					kit.datablocks[ #kit.datablocks + 1 ] = { Datablock = datablock, Quantity = quantity, Location = location, BlockOnRespawn = blockonrespawn, BlockOnSuicide = blockonsuicide, BlockOnInitialKit = blockoninitialkit, BlockAtCamp = blockatcamp, BlockOnReconnect = blockonreconnect }
				end
			end
		end
	end
end

function PLUGIN:ccmdReload( arg )
	local user = arg.argUser
	if (user and not user:CanAdmin()) then return end
	self:LoadKits()
	arg:ReplyWith( "WelcomeKit Config has been reloaded." )
	return true
end

function PLUGIN:LoadDefaultConfig()
	self.Kits.plugin_options = {}
	self.Kits.plugin_options.enable_playerkit = false
	self.Kits.plugin_options.enable_adminkit = false
	self.Kits.plugin_options.enable_vipkit = false
	print("WelcomeKit: WARNING! cfg_welcomekit.txt is missing ... creating dummy file! Be sure to upload a valid config file!")
end

function PLUGIN:OnSpawnPlayer ( playerclient, usecamp, avatar )
	if (not playerclient) then return end
	local netuser = playerclient.netuser
	local userid = rust.GetUserID( netuser )
	local data = self.PData[ userid ]
	if (not data) then
		data = {}
		self.PData[ userid ] = data
	end
	local suicide = "suicide"
	local respawn = "respawn"
	local plugincfg = "plugin_options"
	local options = self.Kits[ plugincfg ]
	local userSuicide = data[ suicide ] or 0
	local userRespawn = data[ respawn ] or 0
	local userReconnect = false
	if (options.enable_playerkit or options.enable_adminkit or options.enable_vipkit) then
		local givekit = true
		local kitname = "playerkit"
		local vipflag = false
		local vip = false
		if(flags_plugin) then
			if (options.enable_vipkit) then
				vipflag = self.Kits[ "vipkit" ].required_flag
				local steamID = flags_plugin:CommunityIDToSteamIDFix(tonumber(userid))
				if (flags_plugin:HasFlag(steamID, vipflag)) then vip = true end
			end
		end
		local admin = self:isAdmin(netuser)
		if (options.enable_playerkit or (admin and options.enable_adminkit) or (vip and options.enable_vipkit)) then
			if (vip and options.enable_vipkit) then kitname = "vipkit" end
			if (admin and options.enable_adminkit) then kitname = "adminkit" end
			local kitCount = data[ kitname ] or 0
			if (userRespawn == 0 and kitCount ~= 0) then userReconnect = true end
			kitname = kitname:lower()
			local kit = self.Kits[ kitname ]
			if (data and kitCount ~= 0 and not kit.respawn_equipagain) then givekit = false end
			if (data and kitCount ~= 0 and kit.respawn_equipagain and ((userRespawn == 0 and not kit.respawn_kitonreconnect) or (not kit.respawn_kitatcamp and usecamp) or (kit.respawn_limitkits and kitCount >= kit.respawn_kitmaxlimit))) then givekit = false end
			if (givekit) then
				if (not userSuicide or userSuicide == 0 or (userSuicide == 1 and kit.respawn_kitonsuicide)) then
					timer.NextFrame( function() self:GiveKit( playerclient, kit, kitCount, userSuicide, userRespawn, usecamp, userReconnect ) end )
					data[ kitname ] = kitCount + 1
					if ( options.displaymessages ) then
						if ( kit.message ) then rust.Notice( netuser, kit.message ) end
						if (kit.respawn_equipagain and kit.respawn_limitkits and data[ kitname ] < kit.respawn_kitmaxlimit) then
							rust.SendChatToUser( netuser, "[WelcomeKit]", "You just received Kit " .. tostring( data[ kitname ] ) .. " of " .. tostring( kit.respawn_kitmaxlimit ) .. "!")
						end
						if (kit.respawn_equipagain and kit.respawn_limitkits and data[ kitname ] >= kit.respawn_kitmaxlimit) then
							rust.SendChatToUser( netuser, "[WelcomeKit]", "You just received your last Kit!")
						end
					end
				else
					if ( options.displaymessages ) then rust.SendChatToUser( netuser, "[WelcomeKit]", "Sorry, you just commited suicide! NO Kit for you!") end
				end
			end
		end
	end
	data[ suicide ] = 0
	data[ respawn ] = 0
	self.PlayerData:SetText( json.encode( self.PData ) )
	self.PlayerData:Save()
end

function PLUGIN:OnKilled(takedamage, damage)
	if (not damage.victim.client) then return end
	local userid = rust.GetUserID( damage.victim.client.netUser )
	local data = self.PData[ userid ]
	if (not data) then
		data = {}
		self.PData[ userid ] = data
	end
	if (damage.victim.client == damage.attacker.client) then
		local suicide = "suicide"
		data[ suicide ] = 1
	end
	local respawn = "respawn"
	data[ respawn ] = 1
	self.PlayerData:SetText( json.encode( self.PData ) )
	self.PlayerData:Save()
end

function PLUGIN:GiveKit( playerclient, kit, kitCount, userSuicide, userRespawn, usecamp, userReconnect )
	local inv = playerclient.rootControllable.idMain:GetComponent( "Inventory" )
	if (kit.removerock) then
		local rock = inv:FindItem(rust.GetDatablockByName( "Rock" ))
		inv:RemoveItem( rock )
	end
	if (kit.removebandage) then
		local bandage = inv:FindItem(rust.GetDatablockByName( "Bandage" ))
		inv:RemoveItem( bandage )
	end
	if (kit.removetorch) then
		local torch = inv:FindItem(rust.GetDatablockByName( "Torch" ))
		inv:RemoveItem( torch )
	end
	for i=1, #kit.datablocks do
		repeat
			local item = kit.datablocks[i]
			if (kitCount == 0 and item.BlockOnInitialKit) then break end
			if (kitCount ~= 0 and item.BlockOnRespawn) then break end
			if (userSuicide == 1 and item.BlockOnSuicide) then break end
			if (usecamp and item.BlockAtCamp) then break end
			if (userReconnect and item.BlockOnReconnect) then break end
			inv:AddItemAmount( item.Datablock, item.Quantity, item.Location )
		until true
	end
end

function PLUGIN:isAdmin(netuser)
	if (netuser:CanAdmin()) then return true end
	if(oxminplugin) then
		local FLAG_CANKICK = 3
		if (oxminplugin:HasFlag(netuser, FLAG_CANKICK)) then return true end
	end
	if(flags_plugin) then
		local steamID = rust.CommunityIDToSteamID(tonumber(rust.GetUserID(netuser)))
		if (flags_plugin:HasFlag(steamID, "kick")) then return true end
	end
	return false
end
