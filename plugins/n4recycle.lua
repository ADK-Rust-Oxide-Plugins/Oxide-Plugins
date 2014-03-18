PLUGIN.Title = "N4Recycle"
PLUGIN.Description = "Recycle Items"
PLUGIN.Author = "Razztak"
PLUGIN.Version = "0.1"
-- Based on Recyle from L.E.S. | Level / Skill / Playerlist / Groups / Recycler 
-- Thanks to 00Fant

PLUGIN.GetTime = util.GetStaticPropertyGetter( UnityEngine.Time, "realtimeSinceStartup" )

function PLUGIN:Init()
	self.Env = util.GetStaticFieldGetter( Rust.EnvironmentControlCenter, "Singleton" )
	
	--Player cmds:
		self:AddChatCommand("recycle", self.cmdrecycle)
	
	if true then-- dev need	
    self.RecycleList = {}
    --Weapons
	self.RecycleList["Shotgun"] = { "Metal Fragments", 180, true }
	self.RecycleList["Bolt Action Rifle"] = { "Metal Fragments", 450, true }
	self.RecycleList["MP5A4"] = { "Metal Fragments", 300, true }
	self.RecycleList["P250"] = { "Metal Fragments", 180, true }
	self.RecycleList["M4"] = { "Metal Fragments", 450, true }
	self.RecycleList["Revolver"] = { "Metal Fragments", 80, true }
	self.RecycleList["HandCannon"] = { "Metal Fragments", 10, true }
	self.RecycleList["9mm Pistol"] = { "Metal Fragments", 150, true }
	self.RecycleList["Pipe Shotgun"] = { "Metal Fragments", 40, true }
	self.RecycleList["Hunting Bow"] = { "Wood", 35, true }
	
	--Ammo
	self.RecycleList["Arrow"] = { "Wood", 4 }
	self.RecycleList["9mm Ammo"] = { "Gunpowder", 3 }
	self.RecycleList["556 Ammo"] = { "Gunpowder", 5 }
	self.RecycleList["Handmade Shell"] = { "Gunpowder", 5 }
	self.RecycleList["Shotgun Shells"] = { "Gunpowder", 5 }
		
	-- Weapon Mods
	self.RecycleList["Flashlight Mod"] = { "Metal Fragments", 75, true }
	self.RecycleList["Holosight"] = { "Metal Fragments", 75, true }
	self.RecycleList["Silencer"] = { "Metal Fragments", 120, true }
	self.RecycleList["Laser Sight"] = { "Metal Fragments", 75, true }
	
	--Misc
	self.RecycleList["Large Wood Storage"] = { "Wood", 60 }
	self.RecycleList["Wood Storage Box"] = { "Wood", 30 }
	--Tools
	self.RecycleList["Stone Hatchet"] = { "Wood", 10, true }
	self.RecycleList["Hatchet"] = { "Wood", 20, true }
	self.RecycleList["Pick Axe"] = { "Metal Fragments", 15, true }
	--Armor
	self.RecycleList["Cloth Vest"] = { "Cloth", 10 }
	self.RecycleList["Cloth Boots"] = { "Cloth", 3 }
	self.RecycleList["Cloth Helmet"] = { "Cloth", 5 }
	self.RecycleList["Cloth Pants"] = { "Cloth", 8 }
	
	self.RecycleList["Kevlar Vest"] = { "Metal Fragments", 100 }
	self.RecycleList["Kevlar Boots"] = { "Metal Fragments", 30 }
	self.RecycleList["Kevlar Helmet"] = { "Metal Fragments", 50 }
	self.RecycleList["Kevlar Pants"] = { "Metal Fragments", 80 }
	
	self.RecycleList["Rad Suit Vest"] = { "Metal Fragments", 50 }
	self.RecycleList["Rad Suit Boots"] = { "Metal Fragments", 30 }
	self.RecycleList["Rad Suit Helmet"] = { "Metal Fragments", 30 }
	self.RecycleList["Rad Suit Pants"] = { "Metal Fragments", 40 }
	
	self.RecycleList["Leather Vest"] = { "Leather", 50 }
	self.RecycleList["Leather Boots"] = { "Leather", 30 }
	self.RecycleList["Leather Helmet"] = { "Leather", 30 }
	self.RecycleList["Leather Pants"] = { "Leather", 40 }
	
	--Objects
	self.RecycleList["Wooden Door"] = { "Wood", 30 }
	self.RecycleList["Wood Shelter"] = { "Wood", 50 }
	self.RecycleList["Metal Door"] = { "Metal Fragments", 200 }
		
	--Structures
	self.RecycleList["Wood Wall"] = { "Wood", 40 }
	self.RecycleList["Wood Window"] = { "Wood", 40 }
	self.RecycleList["Wood Pillar"] = { "Wood", 20 }
	self.RecycleList["Wood Foundation"] = { "Wood", 80 }
	self.RecycleList["Wood Ceiling"] = { "Wood", 60 }
	self.RecycleList["Wood Doorway"] = { "Wood", 40 }
	self.RecycleList["Wood Stairs"] = { "Wood", 50 }
	self.RecycleList["Wood Ramp"] = { "Wood", 50 }
	
	self.RecycleList["Metal Wall"] = { "Metal Fragments", 60 }
	self.RecycleList["Metal Window"] = { "Metal Fragments", 60 }
	self.RecycleList["Metal Pillar"] = { "Metal Fragments", 30 }
	self.RecycleList["Metal Ceiling"] = { "Metal Fragments", 90 }
	self.RecycleList["Metal Doorway"] = { "Metal Fragments", 60 }
	self.RecycleList["Metal Stairs"] = { "Metal Fragments", 75 }
	self.RecycleList["Metal Foundation"] = { "Metal Fragments", 120 }
	self.RecycleList["Metal Ramp"] = { "Metal Fragments", 75 }
	self.RecycleList["Metal Window Bars"] = { "Metal Fragments", 100 }
	
	end
end

function PLUGIN:SendHelpText( netuser )
	rust.SendChatToUser( netuser, "Use /recycle Item Amount to recycle a item." )
end

function PLUGIN:cmdrecycle( netuser, cmd, args )
	if not args[1] or not netuser then return end
	local RecycleName = tostring( args[1] )
	local inv = rust.GetInventory( netuser )
	local RecycleDelItemData = rust.GetDatablockByName( RecycleName )
	if not RecycleDelItemData then	return	end
	local RecycleDelItem = inv:FindItem( RecycleDelItemData )
	if not RecycleDelItem then	
		rust.SendChatToUser( netuser, "Do not have "..RecycleName.." in your inventory")	
		return	
	end
			
	for ListItemName, value in pairs( self.RecycleList ) do
	    
		if ListItemName == RecycleName then
			local RecycleItemAnz = math.floor(((tonumber( value[2] )) *.5) + .5)
			local cangiveitem = false
			local giveit = false
			local recmulti = 1
			if RecycleDelItem.uses > 1 and not value[3] and giveit == false then
				if args[2] then
					local cmdRecycleAnz = tonumber (args[2] )
					if cmdRecycleAnz > RecycleDelItem.uses then
						cmdRecycleAnz = RecycleDelItem.uses
					end
					local DelGive = RecycleDelItem.uses - cmdRecycleAnz
					inv:RemoveItem( RecycleDelItem )
					recmulti = cmdRecycleAnz
					if DelGive > 0 then
						self:giveItem( netuser, RecycleName, DelGive )
					end
					cangiveitem = true
					giveit = true
				else
					local DelGive = RecycleDelItem.uses - 1
					inv:RemoveItem( RecycleDelItem )
					self:giveItem( netuser, RecycleName, DelGive )
					cangiveitem = true
					giveit = true
				end
			end
			if RecycleDelItem.uses and giveit == false then
				inv:RemoveItem( RecycleDelItem )
				cangiveitem = true
				giveit = true
			end
			if cangiveitem then
				self:giveItem( netuser, value[1], (RecycleItemAnz * recmulti))
				rust.SendChatToUser( netuser, "You Recycle "..RecycleName.." and get "..tostring( RecycleItemAnz * recmulti ).." x "..tostring( value[1] ) )
			end
		
		end	
	end
end

function PLUGIN:giveItem( netuser, itemName, amount )
	if amount then
		local datablock = rust.GetDatablockByName( itemName )
		local inv = rust.GetInventory( netuser )
		local item = inv:FindItem(datablock)
		local i = 0
		local itemDel = 0
		local itemDel250 = 0
		
		if (item) then
			while item.uses < 250 and i < amount do 
				i = i + 1
				item:SetUses( item.uses + 1 )
			end
		end
		if i < amount then
			local i2 = amount - i
			local pref = rust.InventorySlotPreference( InventorySlotKind.Default, false, InventorySlotKindFlags.Belt )
			local arr = util.ArrayFromTable( System.Object, { datablock, i2, pref } )
			util.ArraySet( arr, 1, System.Int32, i2 )
			inv:AddItemAmount( datablock, i2, pref )
		end
	end
end