
PLUGIN.Title = "logr"
PLUGIN.Description = "Logs a lot of stuff"
PLUGIN.Author = "none"
PLUGIN.Version = "0.0.0"

if not logr then
	
	logr = {}
	logr.CONSOLELOG_ENABLED = true
	logr.FILELOG_ENABLED = false
	logr.ADMIN_CONSOLELOG_ENABLED = true
	
end

local func_dateTime = util.GetStaticPropertyGetter( System.DateTime, 'Now' )

local function stringExplode( sep, str )
	
	local t = {}
	for word in string.gmatch( str, "[^"..sep.."]+" ) do 
	
		table.insert( t, word )
		
	end	
	
	return t
	
end


local function getTime( mode )
	
	local dateTime = stringExplode( " ", tostring( func_dateTime() ) )
	local date = dateTime[1]
	local time = dateTime[2]
	local ampm = dateTime[3]
	
	local dateParts = stringExplode( "/", date )
	date = table.concat( { dateParts[2], dateParts[1], dateParts[3] }, "-" )
	
	local timeParts = stringExplode( ":", time )
	if ampm == "PM:" then timeParts[1] = tonumber( timeParts[1] ) + 12 end
	time = table.concat( timeParts, ":" )
	
	if mode == "date" then
		
		return "[" .. date .. "]"
		
	end
	
	return "[" .. date .. " " .. time .. "]"

end


function logr.log( str, tag )
	
	if not tag then 
		
		tag = "" 
	
	else 
		
		tag = "[" .. tag .. "]" 
		
	end
	
	local time = getTime()
	
	if logr.CONSOLELOG_ENABLED then
	
		print( time .. tag .. " " .. str )
		
	end
	
	if logr.ADMIN_CONSOLELOG_ENABLED then
		
		for _, netuser in pairs( rust.GetAllNetUsers() ) do
			
			if netuser:CanAdmin() then
				
				rust.RunClientCommand( netuser, "echo " .. time .. tag .. " " .. str )
				
			end
			
		end
		
	end
	
	if logr.FILELOG_ENABLED then
		
		table.insert( logr.logText, time .. tag .. " " .. str )
		logr.save()
		
	end

end


function logr.save()
	
	
	logr.logFile:SetText( table.concat( logr.logText, "\r\n" ) )
	logr.logFile:Save()

end


function PLUGIN:Init()
	
	if logr.FILELOG_ENABLED then
		
		logr.logFile = util.GetDatafile( string.gsub( getTime( "date" ), "([)(])", "" ) )
		local logText = logr.logFile:GetText()
		if (logText ~= "") then
		
			logr.logText = stringExplode( "\r\n", logText )
			
		else
			
			logr.logText = {}
		
		end
		
	end

end


-- Expect this to work in the next LogR Version ;)
-- function PLUGIN:OnTakeDamage( dmg )
-- print("Attacker", dmg.attacker.client.netUser)
-- print("Victim", dmg.victim.client.netUser)
-- local attacker, victim
-- local attacker_cl = dmg.attacker.client
-- if attacker_cl then attacker = attacker_cl.netUser end
-- local victim_cl = dmg.victim.client
-- if victim_cl then victim = victim_cl.netUser end
-- if ( not attacker_cl ) and victim_cl then
-- local victim_coords = victim_cl.lastKnownPosition
-- logr.log( rust.QuoteSafe( victim.displayName ) .. " (@ X:" .. victim_coords.x .. " Y:" .. victim_coords.y .. " Z:" .. victim_coords.z .. ") took damage from world.", "DAMAGE" )
-- end
-- if attacker_cl and victim_cl then
-- local victim_coords = victim_cl.lastKnownPosition
-- local attacker_coords = victim_cl.lastKnownPosition
-- logr.log( rust.QuoteSafe( victim.displayName ) .. " (@ X:" .. victim_coords.x .. " Y:" .. victim_coords.y .. " Z:" .. victim_coords.z .. ") took damage from " .. rust.QuoteSafe( attacker.displayName ) .. " (@ X:" .. attacker_coords.x .. " Y:" .. attacker_coords.y .. " Z:" .. attacker_coords.z .. ").", "DAMAGE" )
-- end

-- 1.8 hotfix
-- function PLUGIN:OnZombieKilled( _, dmg )
	
	-- local attacker
	-- local attacker_cl = dmg.attacker.client
	-- if attacker_cl then attacker = attacker_cl.netUser end
	
	-- if attacker_cl and attacker then
		
		-- local attacker_coords = attacker_cl.lastKnownPosition
		-- logr.log( rust.QuoteSafe( attacker.displayName ) .. " (@ X:" .. attacker_coords.x .. " Y:" .. attacker_coords.y .. " Z:" .. attacker_coords.z .. ") killed a zombie.", "KILL" )
	
	-- end

-- end


function PLUGIN:OnUserChat( netuser, name, msg  )
	
	logr.log( name .. ": " .. msg, "CHAT" )

end