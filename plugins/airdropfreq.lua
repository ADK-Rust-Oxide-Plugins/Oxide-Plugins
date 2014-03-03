PLUGIN.Title = "Airdrop Frequency Controller"
PLUGIN.Description = "Control the frequencies of aidrops."
PLUGIN.Author = "Chief Tiger"
PLUGIN.Version = "2.65"

local PlayerClientAll = util.GetStaticPropertyGetter( Rust.PlayerClient, "All" )
function PLUGIN:Init()
	self:LoadConfig()
	self:AddChatCommand("afc", self.cmdAFC)
	
	timer.Once( 25, function()
		self.Env = util.GetStaticFieldGetter( Rust.EnvironmentControlCenter, "Singleton" )
	end )
	
	if self.Config.realtimedrop > 0 then
		local count = 1
		timer.Repeat(math.max(self.Config.realtimedrop*60*60, 25), function()
			if self.Env == nil then
				self.Env = util.GetStaticFieldGetter( Rust.EnvironmentControlCenter, "Singleton" )
			end
		
			if self.Env ~= nil then
				pclist = PlayerClientAll()
				local floortime = math.floor(tonumber(self.Env():GetTime()))
				
				if type(self.Config.minplayers) == "number" and pclist.Count < self.Config.minplayers then
					return
				elseif type(self.Config.minplayers) == "table" and pclist.Count < self.Config.minplayers[1] then
					return
				end
				
				if self.Config.dropmessage ~= "" then
					rust.BroadcastChat(self.Config.dropmessage)
				end
				rust.RunServerCommand("airdrop.drop")
				print("[airdropfreq(realtime)] Airdrop delivered at " .. floortime .. " in-game time. " .. (count*self.Config.realtimedrop*60*60) .. " hours after server start.")
				count = count + 1
			end
		end)
		return
	end
	
	-- Double check that amount of drops is less or equal to hours provided or else infinite loop happens.
	local hours
	if self.Config.lasthour > self.Config.firsthour then
		hours = (self.Config.lasthour - self.Config.firsthour) + 1
	else
		hours = (23 - self.Config.firsthour) + self.Config.lasthour + 2
	end
	
	if hours < self.Config.drops then
		local olddrops = self.Config.drops
		self.Config.drops = hours
		config.Save("airdropfreq")
		print("[airdropfreq] The amount of drops was configured to be " .. olddrops .. " which is too much for the hours given. It has been changed to " .. hours .. ".")
	end
	
	self.RandomTime = {}
	self:Randomize()

	local hasdropped = {}
	local pclist
	local daydelay = self.Config.daydelay
	local waitone = -1
	timer.Repeat(30, function()
		if self.Env == nil then
			self.Env = util.GetStaticFieldGetter( Rust.EnvironmentControlCenter, "Singleton" )
		end
		
		if self.Env ~= nil then
			pclist = PlayerClientAll()
			local floortime = math.floor(tonumber(self.Env():GetTime()))
			
			if type(self.Config.minplayers) == "number" and pclist.Count < self.Config.minplayers then
				return
			elseif type(self.Config.minplayers) == "table" and pclist.Count < self.Config.minplayers[1] then
				return
			elseif daydelay > 0 then
				if floortime == self.Config.lasthour then
					daydelay = daydelay - 1
					if daydelay == 0 then
						waitone = floortime
					end
				end
				return
			end
			
			if floortime == self.Config.firsthour then
				waitone = -1
			end

			if hasdropped[floortime] == nil and waitone < floortime then
				if self.RandomTime[floortime] then
					rust.RunServerCommand("airdrop.drop")
					hasdropped[floortime] = true
					if self.Config.dropmessage ~= "" then
						rust.BroadcastChat(self.Config.dropmessage)
					end
					print("[airdropfreq] Airdrop delivered at " .. floortime .. ".")
				end
			end
			
			local count = 0
			for _ in pairs(hasdropped) do count = count + 1 end
			
			if ((floortime > self.Config.lasthour and self.Config.lasthour ~= 23) or (floortime == 0 and self.Config.lasthour == 23)) and count > 0 then
				daydelay = self.Config.daydelay
				hasdropped = {}
				self:Randomize()
			end
		end
	end)
end

function PLUGIN:LoadConfig()
	local b, res = config.Read("airdropfreq")
	self.Config = res or {}
	if (not b) then
		self:LoadDefaultConfig()
		if (res) then config.Save("airdropfreq") end
	end
	
	-- Everything below this line is to allow older version of config files to be compatible with newer version of the plugin.
	if self.Config.dropmessage == nil then
		self.Config.dropmessage = ""
	end
	if type(self.Config.minplayers) == "table" then
		table.sort(self.Config.minplayers)
	end
	if self.Config.realtimedrop == nil then
		self.Config.realtimedrop = 0
	end
	if self.Config.daydelay == nil then
		self.Config.daydelay = 0
	end
	if self.Config.tierdrop == nil then
		self.Config.tierdrop = 1
	end
end

function PLUGIN:cmdAFC(netuser, cmd, args)
	if not netuser:CanAdmin() then
		rust.SendChatToUser(netuser, "This command is for admins only.")
		return
	elseif #args == 1 then
		if args[1] == "reload" then
			self:LoadConfig()
		elseif args[1] == "help" then
			rust.SendChatToUser(netuser, "'/afc reload' to reload the plugin settings.")

			rust.SendChatToUser(netuser, "'/afc firsthour <time(0 - 23)>' to set what hour drops possibly start.")
			rust.SendChatToUser(netuser, "'/afc lasthour <time(0 - 23)>' to set what hour drops will end.")
			rust.SendChatToUser(netuser, "'/afc drops <amount>' to set amount of drops that can happen between the")
			rust.SendChatToUser(netuser, "\t\t            specified hours. Must be less than total hours available.")
			rust.SendChatToUser(netuser, "'/afc tierdrop <amount>' to set number of additional drops added when moving up a player tier.")
			rust.SendChatToUser(netuser, "'/afc minplayers <amount> OR <amount1,amount2,...>' to set minimum players needed to start drops.")
			rust.SendChatToUser(netuser, "'/afc dropmessage <message>' to display a message when an airdrop is called.")
			rust.SendChatToUser(netuser, "'/afc daydelay <amount> to set amount of days delayed between dropping.")
			rust.SendChatToUser(netuser, "'/afc realtimedrop <hours>' to switch plugin to real-time drops every <hours> hours.")
			rust.SendChatToUser(netuser, "\t\t\t      Won't take effect until server is restarted.")
			rust.SendChatToUser(netuser, "'/afc settings' to see the current settings values.")
		elseif args[1] == "settings" then
			rust.SendChatToUser(netuser, "firsthour: " .. self.Config.firsthour)
			rust.SendChatToUser(netuser, "lasthour: " .. self.Config.lasthour)
			rust.SendChatToUser(netuser, "drops: " .. self.Config.drops)
			rust.SendChatToUser(netuser, "tierdrop: " .. self.Config.tierdrop)
			if type(self.Config.minplayers) == "number" then
				rust.SendChatToUser(netuser, "minplayers: " .. self.Config.minplayers)
			else
				local minpls = "{"
				for k, v in pairs( self.Config.minplayers ) do
					minpls = minpls .. v .. ", "
				end
				rust.SendChatToUser(netuser, "minplayers: " .. string.sub(minpls, 1, -3) .. "}")
			end
			rust.SendChatToUser(netuser, "daydelay: " .. self.Config.daydelay)
			rust.SendChatToUser(netuser, "realtimedrop: " .. self.Config.realtimedrop)
			rust.SendChatToUser(netuser, "dropmessage: " .. self.Config.dropmessage)
		elseif args[1] == "dropmessage" then
			rust.SendChatToUser(netuser, "Drop message has been disabled.")
			self.Config.dropmessage = ""
			config.Save("airdropfreq")
		else
			rust.SendChatToUser(netuser, "Incorrect syntax. Type '/afc help' for detailed instructions.")
			return
		end
	elseif #args == 2 then
		if args[1] == "dropmessage" then
			local message = util.QuoteSafe(string.sub(table.concat(args, " "), 13))
			
			self.Config.dropmessage = message
			config.Save("airdropfreq")
			
			rust.SendChatToUser(netuser, "Drop message has been set to:")
			rust.SendChatToUser(netuser, message)
			return
		elseif args[1] == "realtimedrop" then
			local num = tonumber(args[2])
			if num == nil then
				rust.SendChatToUser(netuser, "An invalid number was entered. Please try again.")
				return
			end
			
			self.Config.realtimedrop = num
			config.Save("airdropfreq")
			rust.SendChatToUser(netuser, "Real time drop has been set to " .. num .. ". A server restart is required for this to take effect.")
			return
		end
		
		local nums = {}
		local num = tonumber(args[2])
		if num == nil or math.floor(num) < 0 then
			if args[1] == "minplayers" then
				local used = {}
				for token in string.gmatch(args[2], "[^,]+") do
					if tonumber(token) ~= nil and not used[token] then
						used[token] = true
						table.insert(nums, tonumber(token))
					end
				end
					
				if #nums == 0 then
					rust.SendChatToUser(netuser, "An invalid number or number sequence was entered. Please try again.")
					return
				elseif #nums == 1 then
					self.Config.minplayers = nums[1]
					config.Save("airdropfreq")
					rust.SendChatToUser(netuser, "'minplayers' has been set to '" .. nums[1] .. "'.")
					return
				else
					self.Config.minplayers = nums
					
					config.Save("airdropfreq")
					local minpls = "{"
					for k, v in pairs( self.Config.minplayers ) do
						minpls = minpls .. v .. ", "
					end
					rust.SendChatToUser(netuser, "'minplayers' has been set to '" .. string.sub(minpls, 1, -3) .. "}'.")
					return
				end
			else
				rust.SendChatToUser(netuser, "An invalid number was entered. Please try again.")
				return
			end
		end

		num = math.floor(num)
		
		if args[1] == "firsthour" then
			if num ~= self.Config.lasthour then
				self.Config.firsthour = num
			else
				rust.SendChatToUser(netuser, "First hour cannot be the same as last hour.")
				return
			end
		elseif args[1] == "lasthour" then
			if num ~= self.Config.firsthour then
				self.Config.lasthour = num
			else
				rust.SendChatToUser(netuser, "Last hour cannot be the same as first hour.")
				return
			end
		elseif args[1] == "drops" then
			local hours
			if self.Config.lasthour > self.Config.firsthour then
				hours = (self.Config.lasthour - self.Config.firsthour) + 1
			else
				hours = (23 - self.Config.firsthour) + self.Config.lasthour + 2
			end
			
			if hours < num then
				rust.SendChatToUser(netuser, "Too many drops for amount of hours available to drop.")
				return
			else
				self.Config.drops = num
			end
		elseif args[1] == "tierdrop" then
			self.Config.tierdrop = num
		elseif args[1] == "minplayers" then
			self.Config.minplayers = num
		elseif args[1] == "daydelay" then
			self.Config.daydelay = num
		else
			rust.SendChatToUser(netuser, "That is an invalid setting. Use '/afc help' for more information.")
			return
		end
			
		
		config.Save("airdropfreq")
		rust.SendChatToUser(netuser, "'" .. args[1] .. "' has been set to '" .. num .. "'.")
	else
		rust.SendChatToUser(netuser, "Incorrect syntax. Type '/afc help' for detailed instructions.")
		return
	end
end

function PLUGIN:GenerateRandomNumber()
	if self.Config.lasthour > self.Config.firsthour then
		return math.random(self.Config.firsthour, self.Config.lasthour) -- return 4; // chosen by fair dice roll.
	else																--			 // guaranteed to be random.
		local randy = math.random(self.Config.firsthour, 23 + self.Config.lasthour)
		if randy > 23 then
			return randy - 23
		else
			return randy
		end
	end
end		

local function clamp(num, minimum, maximum)
	if num > maximum then
		return maximum
	elseif num < minimum then
		return minimum
	else
		return num
	end
end

function PLUGIN:Randomize()
	self.RandomTime = {}
	
	local randomNum
	local drops = self.Config.drops
	
	if type(self.Config.minplayers) == "table" then
		local pclist = PlayerClientAll()
		local tier = 1
		
		for k, v in pairs(self.Config.minplayers) do
			if pclist.Count >= v and k > tier then -- minplayer table should be ordered, but we'll throw in this failsafe just in case.
				tier = k
			end
		end
		
		local hours
		if self.Config.lasthour > self.Config.firsthour then
			hours = (self.Config.lasthour - self.Config.firsthour) + 1
		else
			hours = (23 - self.Config.firsthour) + self.Config.lasthour + 2
		end
		
		drops = clamp(drops + self.Config.tierdrop * (tier-1), 1, hours)
	end

	for i = 0, drops - 1 do
		randomNum = self:GenerateRandomNumber()
		while self.RandomTime[randomNum] do
			randomNum = self:GenerateRandomNumber()
		end
		print(randomNum)
		self.RandomTime[randomNum] = true
	end
end

function PLUGIN:LoadDefaultConfig()
	self.Config.realtimedrop = 0
	self.Config.firsthour = 8
	self.Config.lasthour = 16
	self.Config.drops = 1
	self.Config.tierdrop = 1
	self.Config.minplayers = 20
	self.Config.daydelay = 0
	self.Config.dropmessage = ""
end