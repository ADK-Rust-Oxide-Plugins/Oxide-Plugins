 
PLUGIN.Title = "/Location and Auto Tracker"
PLUGIN.Description = "Allows Players get their location Coords and see in realtime their position on rustnuts.com"
PLUGIN.Author = "Purely Luck (Rustnuts.com)"
PLUGIN.Version = "6.0.3"

print(PLUGIN.Title .. " (" .. PLUGIN.Version .. ") plugin loaded")

--Server initialization of the plugin
function PLUGIN:Init()
	self.X = 0;
	self.Y = 0;
	self.Z = 0;

	 -- Load the config file
	local b, res = config.Read( "playerLocationV2Config" )
		self.Config = res or {}
	if (not b) then
		self:LoadDefaultConfig()
	if (res) then config.Save( "playerLocationV2Config" ) end
 end
	--Create/retrieve datastore
	self.JsonDataDataFile = util.GetDatafile( "locationDataV" )
	local txt = self.JsonDataDataFile:GetText()
	if (txt ~= "") then
		self.JsonData = json.decode( txt )
	else
		self.JsonData = {}
		self:Save();
	end
	
	--Add chat commands
	self:AddChatCommands();
	self:ServerStart();
	if(self.Config.preformWebRequests) then
		timer.Repeat(30, self.PreformWebRequest );
	end
end
function PLUGIN:LoadDefaultConfig()
 self.Config.preformWebRequests = true;
 self.Config.serverAdminSteamId = "STEAM_0:X:XXXXXX";
end
function PLUGIN:ServerStart()

	for k,v in pairs(self.JsonData) do
		v.LoggedOn = 0;
	end
	self:Save();
end

function PLUGIN:OnUserConnect(networkplayer)
    local netuser = networkplayer:GetLocalData()
    if (not netuser or netuser:GetType().Name ~= "NetUser") then return end
    self:updateUserLocation(netuser);
end
function PLUGIN:OnUserDisconnect(networkplayer)
    local netuser = networkplayer:GetLocalData()
    if (not netuser or netuser:GetType().Name ~= "NetUser") then return end
    self:updateUserLocation(netuser);
    local playerID = rust.GetUserID( netuser );
    if(playerID) then
        self.JsonData[playerID].LoggedOn = 0;
        self:Save();
    end
end


--Adds chat commands to the server
function PLUGIN:AddChatCommands()
	self:AddChatCommand( "Location", self.cmdLocation );
	self:AddChatCommand( "location", self.cmdLocation );
	self:AddChatCommand( "register", self.cmdRegisterServer );
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
	local b = webrequest.Send(( "http://api.rustnuts.com/registerServer?&serverIP=" .. ipAddrStr .. ":" .. Port .. "&adminId="..playerID.."&serverName="..name), function( code, response )
						-- Do something with the result here! Or, you could forward it into the plugin like so
						--self:callbackWebrequest( code, response )
			end )
	rust.SendChatToUser( netuser, "You have registered your server at rustnuts.com under your current steam id");
	else
	rust.SendChatToUser( netuser, "You have to be logged in as admin to register");
	end
end
--Timed track all available players
function PLUGIN:TrackAllAvailablePlayers()
	local userTable = rust.GetAllNetUsers();
	local i = 1;
    while userTable[i] do
	local netuser = userTable[i];
	if(netuser) then
		self:updateUserLocation(netuser);
	end
	i = i + 1;
    end
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
--Gets user data from datastore
function PLUGIN:GetUserData( netuser )
	local userID = rust.GetUserID( netuser );
	return self:GetUserDataFromID(netuser, userID, netuser.displayName );
end

--Gets user data from datastore using userid and name
function PLUGIN:GetUserDataFromID(netuser, userID, name )
	local userentry = self.JsonData[ userID ];
	--Create user if user is not present in datastore
	if (not userentry) then
		userentry = {};
		userentry.LoggedOn=1;
		userentry.ID = userID;
		userentry.Name = name;
		userentry.X = self.X;
		userentry.Y = self.Y;
		userentry.Z = self.Z;
		self.JsonData[ userID ] = userentry;
        self:Save();
	end
	return userentry;
end
--updates player location (call as much as possible)
function PLUGIN:updateUserLocation(netuser)
	self:getUserX(netuser);
	self:getUserZ(netuser);
	local playerID = rust.GetUserID( netuser );
	if(playerID) then
		self.JsonData[playerID].LoggedOn = 1;
		self:Save();
	end
end

function PLUGIN:getUserX(netuser)
	self:GetUserData( netuser );
	local coords = netuser.playerClient.lastKnownPosition;
	local playerID = rust.GetUserID( netuser );
	local X = 0;
	if (coords ~= nil) then
		if (coords.x ~= nil) then
			if(type(coords.x)=='number') then	
				X = math.floor(coords.x);
			end
		end
	end
	if(playerID) then
		self.JsonData[playerID].X = X;
		self:Save();
	end
	return X;
end
function PLUGIN:getUserY(netuser)
	self:GetUserData( netuser );
	local coords = netuser.playerClient.lastKnownPosition;
	local Y = 0;
	if (coords ~= nil) then
		if (coords.y ~= nil) then
			if(type(coords.y)=='number') then	
				Y = math.floor(coords.y);
			end
		end
	end
	if(playerID) then
		self.JsonData[playerID].Y = Y;
		self:Save();
	end
	return Y;
end
function PLUGIN:getUserZ(netuser)
	self:GetUserData( netuser );
	local coords = netuser.playerClient.lastKnownPosition;
	local playerID = rust.GetUserID( netuser ) ; 
	local Z = 0;
	if (coords ~= nil) then
		if (coords.z ~= nil) then	
			if(type(coords.z)=='number') then	
				Z = math.floor(coords.z);
			end
		end
	end
	if(playerID) then
		self.JsonData[playerID].Z = Z;
		self:Save();
	end
	return Z;
end

--Saves datastore
function PLUGIN:Save()
	self.JsonDataDataFile:SetText( json.encode( self.JsonData ) );
	self.JsonDataDataFile:Save();
end

function PLUGIN:SendHelpText( netuser )
	rust.SendChatToUser( netuser, "/location   (Shows your location)");
end
function PLUGIN:OnUserConnect( netuser )
    local data = self:GetUserData( netuser );
	--self:TrackAllAvailablePlayers();
end
function PLUGIN:OnUserChat( netuser, name, msg )
	--self:TrackAllAvailablePlayers();
	self:updateUserLocation(netuser);
end

--Preform WebRequest

function PLUGIN:PreformWebRequest()
local tempJsonDatatDataFile = util.GetDatafile( "locationDataV" )
local txt = tempJsonDatatDataFile:GetText()
local tempJsonData = {}
if (txt ~= "") then
	tempJsonData = json.decode( txt )			
end	
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
					if(tempJsonData[playerID]) then
						tempJsonData[playerID].X = X;
						tempJsonData[playerID].Y = Y;
						tempJsonData[playerID].Z = Z;
						tempJsonData[playerID].LoggedOn = 1;
					end
				end
			end
		i = i + 1;
    end
	
	tempJsonDatatDataFile:SetText( json.encode(tempJsonData) );
	tempJsonDatatDataFile:Save();

	local tempJsonDatatDataFile = util.GetDatafile( "locationDataV" )
	local txt = tempJsonDatatDataFile:GetText()
	local PubIP = Rust.Rust.Steam.Server.SteamServer_GetPublicIP()
    local Quad1 = math.floor(  PubIP/(256*256*256) - (                                                0) )
    local Quad2 = math.floor(  PubIP/(256*256    ) - (                                        Quad1*256) )
    local Quad3 = math.floor(  PubIP/(256        ) - (                      Quad2*256  +  Quad1*256*256) )
    local Quad4 = math.floor(  PubIP/(1          ) - (Quad3*256  +  Quad2*256*256  +  Quad1*256*256*256) )
    local ipAddrStr = Quad1 .. "." .. Quad2 .. "." .. Quad3 .. "." .. Quad4
   
    NetCullListenPort = util.FindOverloadedMethod( Rust.NetCull._type, "get_listenPort", bf.public_static, { } )   
    local Port = NetCullListenPort:Invoke( nil, nil );
	local BASEURL = "http://api.rustnuts.com/?&serverIP="..ipAddrStr .. ":" .. Port;
	local URLSTRING = "";
	local onlinePersonCount = 0;
	if (txt ~= "") then
		local tempJsonData = json.decode( txt )
			
		local arrayCount = #tempJsonData
		--Used to randomize players that are sent to location server incase we are under heavy load (Random lottery of data updates)
		for i = arrayCount, 2, -1 do
			local j = math.random(1, i)
			tempJsonData[i], tempJsonData[j] = tempJsonData[j], tempJsonData[i]
		end
		for k,v in pairs(tempJsonData) do
				if(v.LoggedOn == 1 and v.X ~= 0 and v.Z ~= 0) then
					if(onlinePersonCount<70) then
						onlinePersonCount = onlinePersonCount+1;
						local id = tonumber(v.ID)
						local idClean = math.floor( id / 2 )
							if( idClean % 2 == 0) then
								id = 1
							else
								id = 0
							end
						--end
						--URLSTRING = URLSTRING .. "&x=" .. v.X .. "&z=".. v.Z .. "&ID=".. "STEAM_0:" .. id ..":" .. idClean;
						URLSTRING = URLSTRING .. ",".. v.ID.. "," .. v.X .. ",".. v.Z;
					end
				end
		end
		
		if(onlinePersonCount>0) then
			local b = webrequest.Send(( BASEURL .. URLSTRING), function( code, response )
						-- Do something with the result here! Or, you could forward it into the plugin like so
						--self:callbackWebrequest( code, response )
			end )
		end
	end
end