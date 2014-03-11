PLUGIN.Title = "PlayersWebService"
PLUGIN.Description = "Publishes player list to a website"
PLUGIN.Author = "NONE"
PLUGIN.Version = "0.0.0"
 
local alternate = true
 
function PLUGIN:Init()
    oxmin_mod = cs.findplugin("oxmin")
    oxmin_mod:AddExternalOxminChatCommand(self, "online", {}, cmdList)
end
 
 
function cmdList()
    local pclist = rust.GetAllNetUsers()
    
    local count = 0
    local names = ""
 
    for key,value in pairs(pclist) do
        count = count + 1
    end
 
    for i=1, count do
        names = names .. "," .. util.QuoteSafe(pclist[i].displayName)
    end
    webrequest.Send("http://toprustservers.com/api/put?plugin=playerlist&key=20522b0185539d8c1b81f9207060ce24&list=" .. names, function(code, content) if(code == 200) then print(content) end end)
 
end
 
function PLUGIN:OnUserDisconnect()	
    timer.Once(3,cmdList);
end
 
function PLUGIN:OnUserConnect()	
    cmdList();
end