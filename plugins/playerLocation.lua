PLUGIN.Title = "/Location and Autotracker"
PLUGIN.Description = "Allows Players get their location Coords and see in realtime their position on rustnuts.com"
PLUGIN.Author = "Purely Luck (Rustnuts.com)"
PLUGIN.Version = "6.1.2"
PLUGIN.Url = "http://forum.rustoxide.com/resources/52/"
PLUGIN.ResourceID = "52"
--Server initialization of the plugin
function PLUGIN:Init()
	--Add chat commands
	self:AddChatCommands();
	timer.Repeat(30, self.PreformWebRequest );
	
end



--Adds chat commands to the server
function PLUGIN:AddChatCommands()
	self:AddChatCommand( "Location", self.cmdLocation );
	self:AddChatCommand( "location", self.cmdLocation );
	self:AddChatCommand( "register", self.cmdRegisterServer );
end
--Shows user location
function PLUGIN:cmdLocation(netuser, cmd, args)
        local controllable = netuser.playerClient.controllable
        local char = controllable:GetComponent( "Character" )
        local yaw = char.eyesYaw -- You can use angles if you'd prefer
		local direction = 0;
		local directionText = "N/A";
		if(type(yaw)=='number') then
			direction = (yaw+90)%360;
			if(direction>337.5 or direction<22.5) then
				directionText = "North";
			end
			if(22.5<direction and direction<67.5) then
				directionText = "North-East";
			end
			if(67.5<direction and direction<112.5) then
				directionText = "East";
			end
			if(112.5<direction and direction<157.5) then
				directionText = "South-East";
			end
			if(157.5<direction and direction<202.5) then
				directionText = "South";
			end
			if(202.5<direction and direction<247.5) then
				directionText = "South-West";
			end
			if(247.5<direction and direction<292.5) then
				directionText = "West";
			end
			if(292.5<direction and direction<337.5) then
				directionText = "North-West";
			end			

		end
	rust.SendChatToUser( netuser, "Put your coordinates in at RustNuts.com");
	rust.SendChatToUser( netuser, "You are at x" .. self:getUserX(netuser) ..  "  y" .. self:getUserY(netuser) .. " z" .. self:getUserZ(netuser) .. " facing " .. directionText);
end


function PLUGIN:getUserX(netuser)
	local coords = netuser.playerClient.lastKnownPosition;
	local X = 0;
	if (coords ~= nil) then
		if (coords.x ~= nil) then
			if(type(coords.x)=='number') then	
				X = math.floor(coords.x);
			end
		end
	end
	return X;
end
function PLUGIN:getUserY(netuser)
	local coords = netuser.playerClient.lastKnownPosition;
	local Y = 0;
	if (coords ~= nil) then
		if (coords.y ~= nil) then
			if(type(coords.y)=='number') then	
				Y = math.floor(coords.y);
			end
		end
	end
	return Y;
end
function PLUGIN:getUserZ(netuser)
	local coords = netuser.playerClient.lastKnownPosition;
	local Z = 0;
	if (coords ~= nil) then
		if (coords.z ~= nil) then	
			if(type(coords.z)=='number') then	
				Z = math.floor(coords.z);
			end
		end
	end
	return Z;
end
function PLUGIN:SendHelpText( netuser )
	rust.SendChatToUser( netuser, "/location   (Shows your location)");
end
--registers server with rustnuts.com for Autolocation Servers Page (And admin population tracking)
function PLUGIN:cmdRegisterServer(netuser, cmd, args)
if netuser:CanAdmin() then
	local PubIP = Rust.Rust.Steam.Server.SteamServer_GetPublicIP()
    local Quad1 = math.floor(  PubIP/(256*256*256) - (                                                0) )
    local Quad2 = math.floor(  PubIP/(256*256    ) - (                                        Quad1*256) )
    local Quad3 = math.floor(  PubIP/(256        ) - (                      Quad2*256  +  Quad1*256*256) )
    local Quad4 = math.floor(  PubIP/(1          ) - (Quad3*256  +  Quad2*256*256  +  Quad1*256*256*256) )
    local ipAddrStr = Quad1 .. "." .. Quad2 .. "." .. Quad3 .. "." .. Quad4
   
    NetCullListenPort = util.FindOverloadedMethod( Rust.NetCull._type, "get_listenPort", bf.public_static, { } )   
    local Port = NetCullListenPort:Invoke( nil, nil );
	local name  = Rust.server.hostname
	local playerID = rust.GetUserID( netuser );
	rust.SendChatToUser( netuser, "Handshaking with rustnuts.com...");
	local b = webrequest.Send(( "http://api.rustnuts.com/handshake?&serverIP=" .. ipAddrStr .. ":" .. Port .. "&adminId="..playerID.."&serverName="..name), function( code, response )						
						self:RegisterServer(code, response, ipAddrStr, Port, playerID, name, netuser);
			end )
	else
	rust.SendChatToUser( netuser, "You have to be logged in as admin to register");
	end
end

function PLUGIN:RegisterServer(code, response, ipAddrStr, Port, playerID, name, netuser)
	local handshakeCode = json.decode(response);
	if (handshakeCode ~= "") then
	rust.SendChatToUser( netuser, "Handshaking complete. Sending server info...");
	local b = webrequest.Send(( "http://api.rustnuts.com/registerServer?&handshake=".. handshakeCode .."&serverIP=" .. ipAddrStr .. ":" .. Port .. "&adminId="..playerID.."&serverName="..name), function( code, response )
				rust.SendChatToUser( netuser, "Server registered with rustnuts.com under your current steam id.");		
			end )
	else
	rust.SendChatToUser( netuser, "Handshaking failed");
	end
	
end

--Preform WebRequest

function PLUGIN:PreformWebRequest()
local tempJsonData = {}
local userTable = rust.GetAllNetUsers();
local i = 1;
    while userTable[i] do
		local netuser = userTable[i];
			if(netuser) then
				local coords = netuser.playerClient.lastKnownPosition;
				local playerID = rust.GetUserID( netuser );
				local X = 0;
				local Y = 0;
				local Z = 0;
				if (coords ~= nil) then
					if (coords.x ~= nil) then
						if(type(coords.x)=='number') then	
							X = math.floor(coords.x);
						end
					end
				end
				if (coords ~= nil) then
					if (coords.y ~= nil) then
						if(type(coords.y)=='number') then	
							Y = math.floor(coords.y);
						end
					end
				end
				if (coords ~= nil) then
					if (coords.z ~= nil) then
						if(type(coords.z)=='number') then	
							Z = math.floor(coords.z);
						end
					end
				end
				if(playerID) then
				local name = netuser.displayName;
				name = string.gsub(name, ' ', '_');				
				name = string.gsub(name, '"', '_');
				name = string.gsub(name, "'", '_');
				name = string.gsub(name, "`", '_');
				name = string.gsub(name, "´", '_');
				name = string.gsub(name, "+", '_');
				name = string.gsub(name, "&", '_');
				name = string.gsub(name, "=", '_');				
				name = string.gsub(name, ",", '_');
				userentry = {};
				userentry.LoggedOn=1;
				userentry.ID = playerID;
				userentry.X = X;
				userentry.Y = Y;
				userentry.Z = Z;
				tempJsonData[playerID] = userentry;
				userentry.Name = name;
				
				end
			end
		i = i + 1;
    end
	local PubIP = Rust.Rust.Steam.Server.SteamServer_GetPublicIP()
    local Quad1 = math.floor(  PubIP/(256*256*256) - (                                                0) )
    local Quad2 = math.floor(  PubIP/(256*256    ) - (                                        Quad1*256) )
    local Quad3 = math.floor(  PubIP/(256        ) - (                      Quad2*256  +  Quad1*256*256) )
    local Quad4 = math.floor(  PubIP/(1          ) - (Quad3*256  +  Quad2*256*256  +  Quad1*256*256*256) )
    local ipAddrStr = Quad1 .. "." .. Quad2 .. "." .. Quad3 .. "." .. Quad4
   
    NetCullListenPort = util.FindOverloadedMethod( Rust.NetCull._type, "get_listenPort", bf.public_static, { } )   
    local Port = NetCullListenPort:Invoke( nil, nil );
	local BASEURL = "http://api.rustnuts.com/postLocationData/index.php";
	local URLSTRING = "serverIP="..ipAddrStr .. ":" .. Port;
	local onlinePersonCount = 0;
	for k,v in pairs(tempJsonData) do
		if(v.LoggedOn == 1 and v.X ~= 0 and v.Z ~= 0) then
					
			onlinePersonCount = onlinePersonCount+1;
			local id = tonumber(v.ID)
			local idClean = math.floor( id / 2 )
			if( idClean % 2 == 0) then
				id = 1
			else
				id = 0
			end
						--end
						
			URLSTRING = URLSTRING .. ",".. v.ID.. "," .. v.X .. ",".. v.Name .. "," .. v.Z;
					
		end
	end
	if(onlinePersonCount>0) then
			local b = webrequest.Post(BASEURL, URLSTRING, function( code, response )
			end )
	end
end

