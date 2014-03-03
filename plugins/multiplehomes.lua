
PLUGIN.Title = "MultipleHomes"
PLUGIN.Description = "Set multiple homes. Economy support."
PLUGIN.Version = "1.1.1"
PLUGIN.Author = "D4K1NG"

function PLUGIN:Init()
	-- Init plugin loaded message
	local load_msg = "MultipleHomes loaded"
	
	-- Load MultipleHomes Datafile
	self.HomesFile = util.GetDatafile( "multiplehomes" )
	
	local txt = self.HomesFile:GetText()
	if ( txt ~= "" ) then
		self.Homes = json.decode( txt )
	else
		self.Homes = {}
	end
	
	-- Load/Create config file
    local b, res = config.Read( "multiplehomes" )
    self.Config = res or {}
    if (not b) then
        self.Config.HomesAllowed = 3
        self.Config.HomesTimer = 10
        self.Config.TPHomesPrice = 250
        self.Config.SetHomesPrice = 500
        if ( res ) then 
        	config.Save( "multiplehomes" )
        end
    end

	-- Check if economy is available
    economy = plugins.Find( "econ" )
    if ( not economy ) then
		load_msg = load_msg .. " without Economy support"	
    else
        load_msg = load_msg .. " with Economy support"
    end

	-- Check if flags is available
    flags = plugins.Find( "flags" )
    if ( not flags ) then
    	load_msg = load_msg .. " and without Flags support!"
    else
    	load_msg = load_msg .. " and with Flags support!"
    end
    
    -- Print plugin loaded message
    print( load_msg )

	-- Add chat commands
    self:AddChatCommand( "sethomes", self.setHomes )
    self:AddChatCommand( "homes", self.tpHomes )
    self:AddChatCommand( "hsettings", self.homesSettings )
    -- Add aliases
    self:AddChatCommand( "sethome", self.setHomes )
    self:AddChatCommand( "home", self.tpHomes )
end
function PLUGIN:setHomes( netuser, cmd, args )
	if ( not args[1] ) then
		rust.Notice( netuser, "Syntax: /sethomes 1-" .. tostring( self.Config.HomesAllowed ) )
		return
	end
	if ( tonumber( args[1] ) < 1 or tonumber( args[1] ) > self.Config.HomesAllowed ) then
		rust.Notice( netuser, "Syntax: /sethomes 1-" .. tostring( self.Config.HomesAllowed ) )
		return
	end
	local userID = rust.GetUserID( netuser )
	if ( economy ) then
	    if ( economy.Data[ userID ].Money < self.Config.SetHomesPrice ) then
	    	rust.Notice( netuser, "You don't have enough money to set your home! You need: " .. self.Config.SetHomesPrice .. economy.CurrencySymbol )
	        return
	    end
    end
	if ( self.Homes[ userID ] == nil ) then
		self.Homes[ userID ] = {}
	end
	if ( netuser.playerClient.lastKnownPosition ) then
		local coords = netuser.playerClient.lastKnownPosition
		local exp = 0 and 10^0 or 1
		coords.x = coords.x - 0
		coords.y = coords.y - 0
		coords.z = coords.z - 0
		local coordx = math.ceil( coords.x * exp - 0.5 ) / exp
		local coordy = math.ceil( coords.y * exp - 0.5 ) / exp
		local coordz = math.ceil( coords.z * exp - 0.5 ) / exp
		if ( self.Homes[ userID ][ args[1] ] == nil ) then
			self.Homes[ userID ][ args[1] ] = {}
		end
		self.Homes[ userID ][ args[1] ]["x"] = coordx
		self.Homes[ userID ][ args[1] ]["y"] = coordy
		self.Homes[ userID ][ args[1] ]["z"] = coordz
		self:Save()
		if ( economy ) then
			economy.Data[ userID ].Money = economy.Data[ userID ].Money - self.Config.SetHomesPrice
			rust.Notice( netuser, "Home " .. tostring( args[1] ) .. " set successfully for " .. self.Config.SetHomesPrice .. economy.CurrencySymbol .. "!" )
		else
			rust.Notice( netuser, "Home " .. tostring( args[1] ) .. " set successfully!" )
		end
		return
	else
		rust.Notice( netuser, "Cant set this home location!" )
		return						
	end	
	return 
end
function PLUGIN:tpHomes( netuser, cmd, args )
	if ( not args[1] ) then
		rust.Notice( netuser, "Syntax: /homes 1-" .. tostring( self.Config.HomesAllowed ) )
		return
	end
	if ( tonumber( args[1] ) < 1 or tonumber( args[1] ) > self.Config.HomesAllowed ) then
		rust.Notice( netuser, "Syntax: /homes 1-" .. tostring( self.Config.HomesAllowed ) )
		return
	end
	local userID = rust.GetUserID( netuser )
	if ( economy ) then
	    if ( economy.Data[ userID ].Money < self.Config.TPHomesPrice ) then
	    	rust.Notice( netuser, "You don't have enough money to teleport to your home! You need: " .. self.Config.TPHomesPrice .. economy.CurrencySymbol )
	        return
	    end
    end
	if ( self.Homes[ userID ] == nil ) then
		rust.Notice( netuser, "You have no homes!" )
		return
	end
	if ( self.Homes[ userID ][ args[1] ] == nil ) then
		rust.Notice( netuser, "You have no Home " .. tostring( args[1] ) .. "!" )
		return
	end
	if ( netuser.playerClient.lastKnownPosition ) then
		local coords = netuser.playerClient.lastKnownPosition
		coords.x = self.Homes[ userID ][ args[1] ]["x"]
		coords.y = self.Homes[ userID ][ args[1] ]["y"]
		coords.z = self.Homes[ userID ][ args[1] ]["z"]
		rust.Notice( netuser, "You will be teleported to your Home " .. tostring( args[1] ) .. " in " .. tostring( self.Config.HomesTimer ) .. " seconds!" )
		timer.Once( self.Config.HomesTimer, function()
            rust.ServerManagement():TeleportPlayer( netuser.playerClient.netPlayer, coords)
            if ( economy ) then
				economy.Data[ userID ].Money = economy.Data[ userID ].Money - self.Config.TPHomesPrice
				rust.Notice( netuser, "Successfully teleported to Home " .. tostring( args[1] ) .. " for " .. self.Config.TPHomesPrice .. economy.CurrencySymbol .. "!" )
			else
				rust.Notice( netuser, "Successfully teleported to Home " .. tostring( args[1] ) .. "!" )
			end
        end )
		return
	else
		rust.Notice( netuser, "Cant teleport to this home location!" )
		return						
	end	
	return
end
function PLUGIN:homesSettings( netuser, cmd, args )
	if ( not self:homesCheckPermission( netuser, "mhsettings" ) ) then
		rust.Notice( netuser, "You dont have the permission to do that!" )
		return
	end
	if ( not args[1] ) then
		rust.Notice( netuser, "Syntax: /hsettings allowed|timer|price|setprice [value]" )
		return
	end
	if ( args[1] ~= "allowed" and args[1] ~= "timer" and args[1] ~= "price" and args[1] ~= "setprice" ) then
		rust.Notice( netuser, "Syntax: /hsettings allowed|timer|price|setprice [value]" )
		return
	end
	if ( not args[2] ) then
		if ( args[1] == "allowed" ) then
			rust.Notice( netuser, "Number of homes that are allowed: " .. tostring( self.Config.HomesAllowed ) )
		elseif ( args[1] == "timer" ) then
			rust.Notice( netuser, "Seconds before the user get teleported: " .. tostring( self.Config.HomesTimer ) )
		elseif ( args[1] == "price" ) then
			rust.Notice( netuser, "Price for teleporting to home: " .. tostring( self.Config.TPHomesPrice ) ) 
		elseif ( args[1] == "setprice" ) then
			rust.Notice( netuser, "Price for set a home point: " .. tostring( self.Config.SetHomesPrice ) ) 
		else
			rust.Notice( netuser, "Setting not found!" )
		end
		return
	else
		if ( args[1] == "allowed" ) then
			self.Config.HomesAllowed = tonumber( args[2] )
			config.Save( "multiplehomes" )
			rust.Notice( netuser, "Number of homes that are allowed set to: " .. tostring( args[2] ) )
		elseif ( args[1] == "timer" ) then
			self.Config.HomesTimer = tonumber( args[2] )
			config.Save( "multiplehomes" )
			rust.Notice( netuser, "Seconds before the user get teleported set to: " .. tostring( args[2] ) )
		elseif ( args[1] == "price" ) then
			self.Config.TPHomesPrice = tonumber( args[2] )
			config.Save( "multiplehomes" )
			rust.Notice( netuser, "Price for teleporting to home set to: " .. tostring( args[2] ) ) 
		elseif ( args[1] == "setprice" ) then
			self.Config.SetHomesPrice = tonumber( args[2] )
			config.Save( "multiplehomes" )
			rust.Notice( netuser, "Price for set a home point set to: " .. tostring( args[2] ) ) 
		else
			rust.Notice( netuser, "Setting not found!" )
		end
		return
	end
end
function PLUGIN:homesCheckPermission( netuser, permission )
	if ( not flags ) then
		if ( netuser:CanAdmin() ) then
			return true
		end
	else
		if ( flags:HasFlag( netuser, permission ) ) then
			return true
		end
	end
	return false
end
function PLUGIN:Save()
    self.HomesFile:SetText( json.encode( self.Homes ) )
    self.HomesFile:Save()
end
function PLUGIN:SendHelpText( netuser )
	rust.SendChatToUser( netuser, "Use /sethomes 1-" .. tostring( self.Config.HomesAllowed ) .. " to set a home location!" )
	rust.SendChatToUser( netuser, "Use /homes 1-" .. tostring( self.Config.HomesAllowed ) .. " to teleport to one of your home locations!" )
	if ( self:homesCheckPermission( netuser, "mhsettings" ) ) then
		rust.SendChatToUser( netuser, "Use /hsettings allowed|timer|price|setprice [value] to set new settings or see actual settings!" )
	end
end