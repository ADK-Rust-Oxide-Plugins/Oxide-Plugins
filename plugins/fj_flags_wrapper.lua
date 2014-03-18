PLUGIN.Title = "Flags Wrapper"
PLUGIN.Description = "Wrapping common flags plugins for easier programatical use"
PLUGIN.Version = "1.0"
PLUGIN.Author = "Fox Junior"
print("loading " .. PLUGIN.Title .. " " .. PLUGIN.Version)

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

api.Bind( PLUGIN, "fj_flags_wrapper" )
