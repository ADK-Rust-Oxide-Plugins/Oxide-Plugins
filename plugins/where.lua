PLUGIN.Title = "Where Mod"
PLUGIN.Description = "Allows players to get their location and direction"
 
--Server initialization of the plugin
function PLUGIN:Init()
        --Add chat commands
        self:AddChatCommands();
end
 
--Adds chat commands to the server
function PLUGIN:AddChatCommands()
        self:AddChatCommand( "where", self.cmdWhere );
end
 
--Shows user location and direction
function PLUGIN:cmdWhere(netuser, cmd, args)
    if (not args[1]) then
        rust.SendChatToUser( netuser, "Current location: " .. self:findNearestPoint(netuser) .. " " .. self:getUserLocation(netuser) );
        rust.SendChatToUser( netuser, "You are currently facing " .. self:getUserDirection(netuser) );
        rust.SendChatToUser( netuser, "You can see yourself on the map at http://rustmap.net/" );
        return
    end

    if (not netuser:CanAdmin()) then
        return
    end

    -- Get the target user
    local b, targetuser = rust.FindNetUsersByName( args[1] )
    if (not b) then
        if (targetuser == 0) then
            rust.Notice( netuser, "No players found with that name!" )
        else
            rust.Notice( netuser, "Multiple players found with that name!" )
        end
        return
    end

    rust.SendChatToUser( netuser, targetuser.displayName .. "'s current location: " .. self:findNearestPoint(targetuser) .. " " .. self:getUserLocation(targetuser) );
    rust.SendChatToUser( netuser, "They are currently facing " .. self:getUserDirection(targetuser) );
end

function PLUGIN:compassLetter(dir)
        if (dir > 337.5) or (dir < 22.5) then
                return "North"
        elseif (dir >= 22.5) and (dir <= 67.5) then
                return "Northeast"
        elseif (dir > 67.5) and (dir < 112.5) then
                return "East"
        elseif (dir >= 112.5) and (dir <= 157.5) then
                return "Southeast"
        elseif (dir > 157.5) and (dir < 202.5) then
                return "South"
        elseif (dir >= 202.5) and (dir <= 247.5) then
                return "Southwest"
        elseif (dir > 247.5) and (dir < 292.5) then
                return "West"
        elseif (dir >= 292.5) and (dir <= 337.5) then
                return "Northwest"
        end
end
 
function PLUGIN:getUserDirection(netuser)
        local controllable = netuser.playerClient.controllable
        local char = controllable:GetComponent( "Character" )
 
        -- Convert unit circle angle to compass angle. 
        -- Known error: char.eyesYaw randomly returns a String value and breaks output
        local direction = (char.eyesYaw+90)%360
 
        return self:compassLetter(direction)
end

function PLUGIN:getUserLocation(netuser)
        local coords = netuser.playerClient.lastKnownPosition

        return "(x : " .. math.floor(coords.x) .. ", y : " .. math.floor(coords.y) .. ", z : " .. math.floor(coords.z) .. ")"
end

function PLUGIN:findNearestPoint(netuser)
        local coords = netuser.playerClient.lastKnownPosition
        local points = {
            { name = "Hacker Valley South", x = 5907, z = -1848 },
            { name = "Hacker Mountain South", x = 5268, z = -1961 },
            { name = "Hacker Valley Middle", x = 5268, z = -2700 },
            { name = "Hacker Mountain North", x = 4529, z = -2274 },
            { name = "Hacker Valley North", x = 4416, z = -2813 },
            { name = "Wasteland North", x = 3208, z = -4191 },
            { name = "Wasteland South", x = 6433, z = -2374 },
            { name = "Wasteland East", x = 4942, z = -2061 },
            { name = "Wasteland West", x = 3827, z = -5682 },
            { name = "Sweden", x = 3677, z = -4617 },
            { name = "Everust Mountain", x = 5005, z = -3226 },
            { name = "North Everust Mountain", x = 4316, z = -3439 },
            { name = "South Everust Mountain", x = 5907, z = -2700 },
            { name = "Metal Valley", x = 6825, z = -3038 },
            { name = "Metal Mountain", x = 7185, z = -3339 },
            { name = "Metal Hill", x = 5055, z = -5256 },
            { name = "Resource Mountain", x = 5268, z = -3665 },
            { name = "Resource Valley", x = 5531, z = -3552 },
            { name = "Resource Hole", x = 6942, z = -3502 },
            { name = "Resource Road", x = 6659, z = -3527 },
            { name = "Beach", x = 5494, z = -5770 },
            { name = "Beach Mountain", x = 5108, z = -5875 },
            { name = "Coast Valley", x = 5501, z = -5286 },
            { name = "Coast Mountain", x = 5750, z = -4677 },
            { name = "Coast Resource", x = 6120, z = -4930 },
            { name = "Secret Mountain", x = 6709, z = -4730 },
            { name = "Secret Valley", x = 7085, z = -4617 },
            { name = "Factory Radtown", x = 6446, z = -4667 },
            { name = "Small Radtown", x = 6120, z = -3452 },
            { name = "Big Radtown", x = 5218, z = -4800 },
            { name = "Hangar", x = 6809, z = -4304 },
            { name = "Tanks", x = 6859, z = -3865 },
            { name = "Civilian Forest", x = 6659, z = -4028 },
            { name = "Civilian Mountain", x = 6346, z = -4028 },
            { name = "Civilian Road", x = 6120, z = -4404 },
            { name = "Ballzack Mountain", x =4316, z = -5682 },
            { name = "Ballzack Valley", x = 4720, z = -5660 },
            { name = "Spain Valley", x = 4742, z = -5143 },
            { name = "Portugal Mountain", x = 4203, z = -4570 },
            { name = "Portugal", x = 4579, z = -4637 },
            { name = "Lone Tree Mountain", x = 4842, z = -4354 },
            { name = "Forest", x = 5368, z = -4434 },
            { name = "Rad-Town Valley", x = 5907, z = -3400 },
            { name = "Next Valley", x = 4955, z = -3900 },
            { name = "Silk Valley", x = 5674, z = -4048 },
            { name = "French Valley", x = 5995, z = -3978 },
            { name = "Ecko Valley", x = 7085, z = -3815 },
            { name = "Ecko Mountain", x = 7348, z = -4100 },
            { name = "Middle Mountain", x = 6346, z = -4028 },
            { name = "Zombie Hill", x = 6396, z = -3428 }
        }

        local min = -1
        local minIndex = -1
        for i = 1, #points do
           if (minIndex==-1) then
                min = (points[i].x-coords.x)^2+(points[i].z-coords.z)^2
                minIndex = i
           else
                local dist = (points[i].x-coords.x)^2+(points[i].z-coords.z)^2
                if (dist<min) then
                    min = dist
                    minIndex = i
                end
           end
        end

        return points[minIndex].name
end
 
function PLUGIN:SendHelpText(netuser)
                rust.SendChatToUser( netuser, "Use /where to find your location and direction");
end