PLUGIN.Title = "Bushy Day"
PLUGIN.Description = "Bushy Day"
PLUGIN.Author = "BuSheeZy"
PLUGIN.Version = "0.2"

function PLUGIN:PostInit()
	self.myTimer = timer.Repeat( 10*60, 0, function() self:tick() end )
end

function PLUGIN:tick()
	rust.RunServerCommand("env.time 8")
end