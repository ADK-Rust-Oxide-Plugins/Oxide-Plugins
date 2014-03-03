PLUGIN.Title = "Rank and List"
PLUGIN.Description = "Allow Admins to Put Users in Ranks"
PLUGIN.Author = "The Big Wig"
PLUGIN.Version = "1.2.2"

print(PLUGIN.Title .. " (" .. PLUGIN.Version .. ") plugin loaded")

--Things To Add Later:
--ADD STEAM IDS (ADMIN CANT REMOVE USERS AFTER NAME CHANGE UNLESS USING OLD NAME)
--Add time and date stamp reading to stop users from causing errors
--If group the group is deleted, delete all users with that group

-- Called when oxide loads or user types oxide.reload example at F1 console
function PLUGIN:Init()
    self:AddChatCommand("createrankname", self.cmdcreaterank)
    self:AddChatCommand("removerankname", self.cmdremoverank)
    self:AddChatCommand("addrank", self.cmdaddrank)
    self:AddChatCommand("removerank", self.cmdremoverank1)
    self:AddChatCommand("rankhelp", self.cmdrankhelp)
    self:AddChatCommand("ranks", self.cmdviewrank)
    
    
    self:LoadConfig()
    

    --RANKS LOAD
	self.DataFile = util.GetDatafile("Ranks")
	local txt = self.DataFile:GetText();
	if (txt ~= "") then
		self.Ranks = json.decode(txt);
	else
	self.Ranks ={}
    end
    
    --LOADS User Ranks
    self.UserRankNameFile = util.GetDatafile("UserRanksNames")
    local txt = self.UserRankNameFile:GetText();
    if (txt ~= "") then
	self.UserRanksNames= json.decode(txt);
    else
	self.UserRanksNames ={}

    end
    
    --LOADS USER RANKS
    self.UserRankFile = util.GetDatafile("UserRanks")
	local txt = self.UserRankFile:GetText();
	if (txt ~= "") then
		self.UserRanks = json.decode(txt);
	else
	self.UserRanks ={}      
	end
    
end


-- Called when user types /createrankname
function PLUGIN:cmdcreaterank( netuser, cmd, args )
    --TESTING CODE BELOW
    --Working
    --rust.SendChatToUser( netuser, "Using create rank name" )
    --TESTING CODE Above
    if not netuser:CanAdmin() then
		rust.Notice( netuser, "You are not an admin!" )
		return
    end
    
    
    
    if not args[1] then
	rust.SendChatToUser( netuser, "Syntax /createrankname Name")
	return
    end
    
    local rankName = args[1]
    rankName = util.QuoteSafe(rankName)
    
    
    if self.Ranks == nil then
	local arraySize = 0
    else
    	 arraySize = #self.Ranks
    end
    --Checks To See if Rank Name Already Exists
    for i=1,arraySize do
	    if rankName == self.Ranks[i] then
		rust.SendChatToUser( netuser, "There Already is a Rank Name Called "..rankName)
		return
	    end
    end
    arraySize =arraySize +1
    self.Ranks[arraySize] = rankName
    self:saveRanks()
    
    rust.SendChatToUser( netuser, "You Have Added Rank Named "..self.Ranks[arraySize])
    
end

-- Called when user types /removerankname
function PLUGIN:cmdremoverank( netuser, cmd, args )
    --TESTING CODE BELOW
    --Working
    --rust.SendChatToUser( netuser, "Using Remove Rank Name" )
    --TESTING CODE Above
    if not netuser:CanAdmin() then
		rust.Notice( netuser, "You are not an admin!" )
		return
    end
    
    if not args[1] then
	rust.SendChatToUser( netuser, "Syntax /removerankname Name")
	return
    end
    local rankName = args[1]
    rankName = util.QuoteSafe(rankName)
    
    local arraySize = #self.Ranks
    if arraySize == nil then
	arraySize = 0
	rust.SendChatToUser( netuser, "There Are No Ranks To Remove!" )
	return
    end
 
    local isThere = false
     for i=1,arraySize do
	    if rankName == self.Ranks[i] then
		 isThere = true
	    end
    end
    if isThere == false then
	rust.SendChatToUser( netuser, "Cannont Not Find Rank Name "..rankName)
	return
    end
    
    --Array Contains Some Rank At the Point
    for i=1, arraySize do
	local scannedRankName = self.Ranks[i]
	if scannedRankName == rankName then
	    --Remove This Rank Name
	  table.remove(self.Ranks,i)
	  self:saveRanks()
	end
    end
    rust.SendChatToUser( netuser, "You Have Removed Rank: "..rankName )
   
end



-- Called when user types /addrank
function PLUGIN:cmdaddrank( netuser, cmd, args )
    --TESTING CODE BELOW
    --working
    --rust.SendChatToUser( netuser, "You Are Running Add Rank" )
    --TESTING CODE ABOVE
   if not netuser:CanAdmin() then
		rust.Notice( netuser, "You are not an admin!" )
		return
    end 
    
   if not args[1] then
	rust.SendChatToUser( netuser, "Syntax /addrank Name Rank")
	return
    end
    if not args[2] then
	rust.SendChatToUser( netuser, "Syntax /addrank Name Rank")
	return
    end
   local addToRank = args[2]
   addToRank = util.QuoteSafe(addToRank)
   
    --Checks To See if the User is a Valid User
    local b, targetuser = rust.FindNetUsersByName( args[1] )
    if (not b) then
	if (targetuser == 0) then
	    rust.Notice( netuser, "No players found with that name!" )
	else
	    rust.Notice( netuser, "Multiple players found with that name!" )
	end
	return
    end
    
    local arraySizeRanks = #self.Ranks
    if arraySizeRanks == nil or arraySizeRanks==0  then
	rust.SendChatToUser( netuser, "You Must Create A Rank Before Adding a User To It!" )
	return
    end
    --Checks To See If The Inputed Value is A Valid Rank Name
    for g=1,arraySizeRanks do
	if addToRank == self.Ranks[g] then
	    break 
	 end
	if g == arraySizeRanks then
	  rust.SendChatToUser( netuser, "Can Not Find That Rank Name!" )  
	end
    end
    
    --Checks To See If Either Of The Arrays Is Nil. This Stops Throwing an Error To The User
	
    
	local arraySizeUserRanksNames  = #self.UserRanksNames
	if arraySizeUserRanksNames == nil then
	    arraySizeUserRanksNames = 0
	end
	
	 local arraySizeUserRanks  = #self.UserRanks
	 if arraySizeUserRanks == nil then
	     arraySizeUserRanks = 0
	 end
	 
    --ADDS USER TO THE ARRAY BASED ON THEIR STEAM NAME	    
    --local targetuserID = rust.GetUserID(targetuser)	    
    --Inserts Users into User Rank Table
    self.UserRanks[arraySizeUserRanks+1]= addToRank
    self.UserRanksNames[arraySizeUserRanksNames+1] =targetuser.displayName
    self:saveUserRankNames()
    self:saveUserRanks()
    
    
     rust.SendChatToUser( netuser, "You Have Added "..self.UserRanksNames[arraySizeUserRanksNames+1].." To Rank ".. self.UserRanks[arraySizeUserRanks+1])

    
end



-- Called when user types /removerank
function PLUGIN:cmdremoverank1( netuser, cmd, args )
    --TESTING CODE BELOW
    --working
    --rust.SendChatToUser( netuser, "You are Now Running Remove Rank" )
    --TESTING CODE ABOVE
    if not netuser:CanAdmin() then
		rust.Notice( netuser, "You are not an admin!" )
		return
    end
    
     if not args[1] then
	rust.SendChatToUser( netuser, "Syntax /removerank Name Rank")
	return
    end
    if not args[2] then
	rust.SendChatToUser( netuser, "Syntax /removerank Name Rank")
	return
    end
    
    local b, targetuser = rust.FindNetUsersByName( args[1] )
    if (not b) then
	if (targetuser == 0) then
	    rust.Notice( netuser, "No players found with that name!" )
	else
	    rust.Notice( netuser, "Multiple players found with that name!" )
	end
	return
    end
    local arraySizeRanksNames = #self.UserRanksNames 
    local arraySizeUserRanks = #self.UserRanks
    
    
    --Makes Sure That We Dont Do any Processing On nil or 0 valued Arrays Which Would Cause Errors
     if arraySizeRanksNames == nil or arraySizeRanksNames==0  then
	rust.SendChatToUser( netuser, "You Must Add a User To a Rank Before You Can Remove Them!" )
	return
    end
    
     if arraySizeUserRanks == nil or arraySizeUserRanks==0  then
	rust.SendChatToUser( netuser, "You Must Add a User To a Rank Before You Can Remove Them!" )
	return
    end
    local someVar = args[2]
    someVar = util.QuoteSafe(someVar)
    
    for p=1, arraySizeRanksNames do
	if self.UserRanksNames[p] == targetuser.displayName and self.UserRanks[p] == someVar  then 
	  table.remove(self.UserRanksNames,p)
	  table.remove(self.UserRanks,p)
	  self:saveUserRankNames()
	  self:saveUserRanks()
	end

    end
  
    rust.SendChatToUser( netuser, "You Have Removed "..targetuser.displayName.." From ".. someVar)
   


end


-- Called when user types /viewrank
function PLUGIN:cmdviewrank( netuser, cmd, args )
    --TESTING CODE BELOW
    --Working
    --rust.SendChatToUser( netuser, "NOW Running View Rank" )
    --TESTING CODE ABOVE
    
    
    local rankArray ={}
     local arraySub =""
	 local arraySub2=""
   
    local arraySizeRanks = #self.Ranks
    local arraySizeRanksNames = #self.UserRanksNames 
    local arraySizeUserRanks = #self.UserRanks
    if arraySizeRanks ==nil or arraySizeRanks == 0 then
	 rust.SendChatToUser( netuser, "There Are Currently No Ranks")
	 return
    end
    --ADD Checks Here
    rust.SendChatToUser( netuser, "Current Server Ranks:" )
    --Array Contains Some Rank At the Point
    for i=1, arraySizeRanks do
	--^ This For Loops Cycles Through All Possible Ranks
	--Adds Rank To Position 1 in the Array
	--rust.SendChatToUser( netuser, ""..self.Ranks[i])
	rankArray[1] = self.Ranks[i]
	for p=1, arraySizeUserRanks do
		if self.UserRanks[p] == self.Ranks[i] then
		    --local targetUser =rust.NetUserFromNetPlayer(key)
		    local userName =self.UserRanksNames[p]
		    --Adds The UserName To The Array To Be Print Later
		    --rust.SendChatToUser( netuser, "-"..userName)
		    rankArray[1+#rankArray] =userName
		end
	end
	--At the end of each rank the plguin prints out each rank and users
	

	for y=1, #rankArray do
	arraySub =rankArray[y]
	if y==1 or y== #rankArray then
		if y==1 then
			arraySub2 =arraySub2..""..arraySub..": "
		else			
			arraySub2 =arraySub2..""..arraySub.." "  
		end
		
	else
	arraySub2 =arraySub2..""..arraySub..", "
	end
	
	end
	rust.SendChatToUser( netuser, ""..arraySub2)
	
	for n=1, #rankArray do
	 rankArray[n]=nil
	end
	arraySub2 =""
	arraySub=""
	
    end
    
    
    
    
    
end

--Allows Admin To Add Group Names To The Chat As Well.
function PLUGIN:OnUserChat(netuser, name, msg)
    if (msg:sub(1, 1) == "/") then
        return
    end
    
    if self.Config.ShowNameinChat == false then
	print("Not Showing Name in Chat!")
	return 
    end
    
    --Find NetUser Tag
   print("Trying To Find User Tag!")
   
   local UserFound = false
   local UserIndex = 0
   
    for j=1, #self.UserRanksNames do
	if  self.UserRanksNames[j] == netuser.displayName then
	  UserFound = true
	  UserIndex = j
	  print(j)
	 break
	end
    end
    
    --If No Tag Is Found Then Display The Message Normally
    if UserFound == false then
	print("Can't Find UserName")
	return
    end
    --print("User Found: "..UserFound)
    --print("User Found: "..toString(UserFound).." User Index: "..toString(UserIndex))
    --Takes Index From UserRanksNames and Gets That Users Rank
    local ownerTag =  self.UserRanks[UserIndex]
    
    
    
    
    -- If Show in Front Is True Then the Chat Shows The Rank In Front of The Name
    if (self.Config.ShowinFront == true) then
	
	--Makes The Rank Easier To See In The Chat
	 if self.Config.UseBrackets then
	  print("Adding Brackets" )
	  ownerTag = "["..ownerTag.."] "
	 else
	     ownerTag = ""..ownerTag.." "
	 end
	 
	rust.BroadcastChat( ownerTag .. netuser.displayName, msg )
	--rust.Notice( netuser, "Show In Front is True" )
	return false
    else
	--Makes The Rank Easier To See In The Chat
	 if self.Config.UseBrackets then
	  print("Adding Brackets" )
	  ownerTag = " ["..ownerTag.."]"
	  else
	     ownerTag = " "..ownerTag..""
	 end
	rust.BroadcastChat( netuser.displayName .. ownerTag, msg )
	--rust.Notice( netuser, "Show in Front is False" )
	return false
    end
	
end






-- Called when user types /rankhelp
function PLUGIN:cmdrankhelp( netuser, cmd, args )
    --Working
    if not netuser:CanAdmin() then
	rust.SendChatToUser( netuser, "User Commands: /ranks" )	
    else
	rust.SendChatToUser( netuser, "User Commands: /ranks" )
	rust.SendChatToUser( netuser, "Admin Commands: /createrankname, /removerankname, /addrank, /removerank, /rankhelp" )
    end    
end

-- Automated Oxide help function (added to /help list)
function PLUGIN:SendHelpText( netuser )
    --Working
	rust.SendChatToUser( netuser, "Use /rankhelp to view all available commands!" )
end


function PLUGIN:saveRanks()
	--Saves All Data Files
	self.DataFile:SetText(json.encode(self.Ranks));
	self.DataFile:Save();
	print("Saved: " .. json.encode(self.Ranks));
	

end

function PLUGIN:saveUserRankNames()
	
	self.UserRankNameFile:SetText(json.encode(self.UserRanksNames));
	self.UserRankNameFile:Save();
	print("Saved: " .. json.encode(self.UserRanksNames));
	
	
	
end

function PLUGIN:saveUserRanks()

	self.UserRankFile:SetText(json.encode(self.UserRanks));
	self.UserRankFile:Save();
	print("Saved: " .. json.encode(self.UserRanks));
	
	
end

function PLUGIN:LoadDefaultConfig()
   
       self.Config.ShowNameinChat = false
       self.Config.ShowinFront = true
       self.Config.UseBrackets = true
end

function PLUGIN:LoadConfig()
	local b, res = config.Read("RankandList")
	self.Config = res or {}
	if (not b) then
		self:LoadDefaultConfig()
		if (res) then config.Save("RankandList") end
	end
    
	
end


