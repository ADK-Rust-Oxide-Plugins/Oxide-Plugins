PLUGIN.Title = "AutoCommands"
PLUGIN.Version = "0.1.0"
PLUGIN.Description = "Automatically executes configured commands on server startup."
PLUGIN.Author = "Luke Spragg - Wulfspider"
PLUGIN.Url = "http://forum.rustoxide.com/resources/337/"

local debug = false -- Used to enable debug messages

-- Plugin initialization
function PLUGIN:Init()
    -- Log that plugin is loading
    print(self.Title .. " v" .. self.Version .. " loading...")

    -- Load configuration
    self:LoadConfiguration()

    -- Run update check
    local updater = plugins.Find("updater")
    if (updater ~= nil) then
        updater:UpdateCheck(self.Title, self.Version, "337")
    end

    -- Log that plugin has loaded
    print(self.Title .. " v" .. self.Version .. " loaded!")
end

-- Perform on server start
function PLUGIN:OnServerInitialized()
    -- Run configured commands
    for i = 1, #self.Config.Commands do
        rust.RunServerCommand(self.Config.Commands[i])
        print(self.Title .. " ran server command: " .. self.Config.Commands[i])
    end
end

-- Load the configuration
PLUGIN.ConfigFile = "autocommands"
PLUGIN.ConfigVersion = "0.1.0"
function PLUGIN:LoadConfiguration()
    -- Check for configuration file
    local b, res = config.Read(self.ConfigFile)
    self.Config = res or {}

    -- If no configuration file exists, create it
    if (not b) then
        self:DefaultConfiguration()
        if (res) then
            config.Save(self.ConfigFile)
        end

        -- Log that the default configuration has loaded
        print(self.Title .. " default configuration loaded!")
    end

    -- Check for newer configuration
    if (self.Config.ConfigVersion ~= self.ConfigVersion) then
        print(self.Title .. " configuration is outdated! Creating new file; be sure to update the settings!")
        self:DefaultConfiguration()
        config.Save(self.ConfigFile)
    end
end

-- Set default configuration settings
function PLUGIN:DefaultConfiguration()
    self.Config.ConfigVersion = self.ConfigVersion
    -- General settings
    self.Config.Commands = { "env.time 8", "airdrop.min_players 10" }
end
