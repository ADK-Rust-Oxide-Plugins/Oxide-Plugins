PLUGIN.Title = "Voter"
PLUGIN.Description = "Verifies that someone voted on the site"
PLUGIN.Author = "Jwerd"
PLUGIN.Version = "1.0"
-- Set Your Items Here
-- These will be delivered when a user initiates the /voted command
local default_items = {}
default_items["Wood"] = 64
default_items["Metal Door"] = 1
local items = {}
-- Called when oxide loads or user types oxide.reload example at F1 console
function PLUGIN:Init()
    self:AddChatCommand("voted", self.cmdVoted)
    self:AddChatCommand("vote", self.cmdVote)
    self:LoadConfig()
end

function PLUGIN:LoadConfig()
    local b, res = config.Read( "voter" )
    self.Config = res or {}
    items = self.Config.items

    if (not b) then
        print("Voter Config is missing so creating one...")
        self:LoadDefaultConfig()
        if (res) then config.Save( "voter" ) end
    end
end

function PLUGIN:LoadDefaultConfig()
 self.Config.apikey = "_APIKEY_HERE_"
 self.Config.vote_site = "http://toprustservers.com/server/1234"
 self.Config.items = default_items;
 items = default_items;
end

-- Our own give wrapper
local function trsGive (netuser, item, amount)
	local datablock = rust.GetDatablockByName( item )
	local inv = rust.GetInventory( netuser )
	local pref = rust.InventorySlotPreference( InventorySlotKind.Default, false, InventorySlotKindFlags.Belt )
	
	if (not datablock) then
		rust.Notice( netuser, "No such item!" )
		return
	end
	
	inv:AddItemAmount( datablock, amount, pref )
	rust.InventoryNotice( netuser, tostring( amount ) .. " x " .. datablock.name )
    return true
end

local function sendGoods ( netuser, content, steamuid, apikey )
	local give = false
    for key, value in pairs(items) do 
		give = trsGive ( netuser, key, value )
	end

    if(give) then
	    local b = webrequest.Send("http://toprustservers.com/api/put?plugin=voter&key=" .. apikey .. "&uid=" .. steamuid, function(code, content) 
        	if(code == 200) then 
        		if(tostring(content) == "1") then
        			rust.SendChatToUser( netuser, "Thanks for voting!" )
        		else
        			rust.SendChatToUser( netuser, "Sorry, that didn't work.  Try again." )
        		end
        	end
        end )
	end
end

-- Called when user types /voted
function PLUGIN:cmdVoted( netuser, cmd, args )
    rust.SendChatToUser( netuser, "Checking if you voted..." )
    local steamuid = tonumber( rust.GetUserID( netuser ) )
    local apikey = self.Config.apikey
    local b = webrequest.Send("http://toprustservers.com/api/get?plugin=voter&key=" .. apikey .. "&uid=" .. steamuid, function(code, content) 
    	if(code == 200) then
    		if(tostring(content) == "1") then
    			sendGoods( netuser, content, steamuid, apikey ) 
    		elseif(tostring(content) == "invalid_api") then
                print ( "Voter: Invalid API key.  Please double check your key." )
                rust.SendChatToUser( netuser, "An error occured.  Tell the admin to check logs please." )
            else
    			rust.SendChatToUser( netuser, "You already got your goods or haven't voted" )
    		end
    	end
    end )
    if (not b) then print( "Webrequest send failed!" ) end
end

-- Called when user types /vote
function PLUGIN:cmdVote( netuser, cmd, args )
    rust.SendChatToUser( netuser, "You can vote for us at " .. self.Config.vote_site )
end
 
-- Automated Oxide help function (added to /help list)
function PLUGIN:SendHelpText( netuser )
	rust.SendChatToUser( netuser, "Use /vote to find out where to vote for us" )
	rust.SendChatToUser( netuser, "Use /voted to get your goods for voting for us on toprustservers.com" )
end