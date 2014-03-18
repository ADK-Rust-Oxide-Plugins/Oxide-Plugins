PLUGIN.Title = "Anti-Rock"
PLUGIN.Version = "0.1.6"
PLUGIN.Description = "Removes the starter rock from player's inventory/hotbar on connect."
PLUGIN.Author = "Luke Spragg - Wulfspider"
PLUGIN.Credits = "Shadowdemonx9 (Rock Removal plugin)"
PLUGIN.Url = "http://forum.rustoxide.com/resources/260/"
PLUGIN.ConfigFile = "antirock"
PLUGIN.ResourceId = "260"

local debug = false -- Used to enable debug messages

-- Plugin initialization
function PLUGIN:Init()
    -- Log that plugin is loading
    print(self.Title .. " v" .. self.Version .. " loading...")

    -- Load configuration
    self:LoadConfiguration()

    -- Log that plugin has loaded
    print(self.Title .. " v" .. self.Version .. " loaded!")
end

-- Preload the better item list
function PLUGIN:OnDatablocksLoaded()
    self.dataBlocks = {}
    for i = 1, #self.Config.BetterItems do
        local blockName = self.Config.BetterItems[i]
        self.dataBlocks[blockName] = rust.GetDatablockByName(blockName)
    end
end

-- Perform on player spawn
function PLUGIN:OnSpawnPlayer(playerclient, usecamp, avatar)
    -- Run rock removal check
    timer.Once(1, function() self:AntiRock(playerclient.netUser) end)
end

-- Rock check/removal function
function PLUGIN:AntiRock(netuser)
    local inv = rust.GetInventory(netuser)
    local rockBlock = rust.GetDatablockByName("Rock")
    local rock = inv:FindItem(rockBlock)
    local betterItem = false

    -- Check inventory for better items
    for i = 1, #self.Config.BetterItems do
        local betterBlock = self.dataBlocks[self.Config.BetterItems[i]]
        local item = inv:FindItem(betterBlock)
        -- If better item found...
        if (item) then
            -- Set better item found
            betterItem = true
            -- Debug messages
            if (debug) then
                error("Found better item(s) on " .. util.QuoteSafe(netuser.displayName))
                rust.BroadcastChat("Debug", "Found better item(s) on " .. util.QuoteSafe(netuser.displayName))
            end
        end
    end

    -- Remove rock if not allowed or better item found
    if ((self.Config.StarterRock == "false") or (betterItem == true)) then
        -- Debug messages
        if (debug) then
            error("Starter rock: " .. tostring(self.Config.StarterRock))
            rust.BroadcastChat("Debug", "Starter rock: " .. tostring(self.Config.StarterRock))
        end
        -- Check for all rocks
        while (rock) do
            -- Remove found rock
            inv:RemoveItem(rock)
            -- Check for other rocks
            rock = inv:FindItem(rockBlock)
            -- Debug messages
            if (debug) then
                error("Remove rock from " .. util.QuoteSafe(netuser.displayName))
                rust.BroadcastChat("Debug", "Remove rock from " .. util.QuoteSafe(netuser.displayName))
            end
        end
    end
end

-- Load the configuration
function PLUGIN:LoadConfiguration()
    -- Read/create configuration file
    local b, res = config.Read(self.ConfigFile)
    self.Config = res or {}

    -- General settings
    self.Config.StarterRock = self.Config.StarterRock or self.Config.StarerRock or self.Config.starterrock or "true"
    self.Config.BetterItems = self.Config.BetterItems or self.Config.betteritems or { "Hatchet", "Pick Axe", "Stone Hatchet" }

    -- Remove old settings
    self.Config.configversion = nil -- Removed in 0.1.4
    self.Config.StarerRock = nil -- Removed in 0.1.5 (silly typo)
    self.Config.starterrock = nil -- Removed in 0.1.6
    self.Config.betteritems = nil -- Removed in 0.1.6

    -- Save configuration
    config.Save(self.ConfigFile)
end
