PLUGIN.Title = "C4 Location Logging - LogR Extension"
PLUGIN.Description = "A extension for LogR to Log C4 Locations"
PLUGIN.Version = "1.0"
PLUGIN.Author = "Big Wig"

function PLUGIN:Init()
	logr_plugin = plugins.Find( "logr" )
	if ( not logr_plugin ) then 
		print( "RCON Command Logging couldn't be enabled. Plugin: LogR is missing." )
	end
end


typesystem.LoadEnum( Rust.DamageTypeFlags, "DamageType" )
function PLUGIN:OnHurt(takedamage, damage)
    if(tostring(damage.damageTypes)== tostring(DamageType.damage_explosion)) then
	if ( damage.attacker.client.netUser.playerClient.lastKnownPosition ) then
		local coords =  damage.attacker.client.netUser.playerClient.lastKnownPosition;
		local exp = 0 and 10^0 or 1
		coords.x = coords.x - 0
		coords.y = coords.y - 0
		coords.z = coords.z - 0
		local coordx = math.ceil( coords.x * exp - 0.5) / exp
		local coordy = math.ceil( coords.y * exp - 0.5) / exp
		local coordz = math.ceil( coords.z * exp - 0.5) / exp
                local LogrString = damage.attacker.client.netUser.displayName.." Used C4 At: "..coordx..", "..coordy..", "..coordz
                rust.Notice( damage.attacker.client.netUser, LogrString )
                self:LogPosition(LogrString)
	end				
				
				
			
    end
	
end
local oldLogString ="a"
function PLUGIN:LogPosition(LogString)
    if oldLogString == LogString then
       -- print("This Is Different Objects Getting Damage From Single C4")
        return
    end
    -- LogString Is Different From Previous Call
    --print(""..LogString)
    logr.log( LogString, "C4-LOGGER")
    oldLogString=LogString
end
