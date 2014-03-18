PLUGIN.Title = "Remover Tool"
PLUGIN.Description = "Remove Building"
PLUGIN.Author = "Guewen and Thx Rexas"
PLUGIN.Version = "1.7.1"

function PLUGIN:Init()

	print("Remover Load")
	
	local b, res = config.Read( "remover" )
	self.Config = res or {}
	if (not b) then
		self:LoadDefaultConfig()
		if (res) then config.Save( "remover" ) end
	else
		self:LoadUpdateConfig()
	end	
	
	local b, res = config.Read( "removereconomy" )
	self.economy = res or {}
	self:LoadRemoverEconomy()
	
	local b, res = config.Read( "removerallowconfig" )
	self.AllowConfig = res or {}
	self:LoadRemoverAllowConfig()
	
	oxmin_Plugin = plugins.Find("oxmin")
    if oxmin_Plugin or oxmin then
        self.FLAG_REMOVER = oxmin.AddFlag( "remover" )
    end
	
	group_Plugin = plugins.Find("groups")
    if group_Plugin then
		print("Remover Groups Loaded")
    end
	
	
	if( self.Config.Economy) then

		if( api.Exists( "economy" )) then
			_b, self.GS = api.Call( "economy", "GetSymbol" )
			self.Economy = true
			print("Remover Economy Loaded")
		end
	
	end
	
	self:AddChatCommand("load", self.loadfiles)
	-- self:AddChatCommand("loada", self.loadfiles2)

	self:AddChatCommand("removerreload", self.ReloadConfig)
	
	self:AddChatCommand("removeactiveplayer", self.RemoveActivePlayer)
	self:AddChatCommand("removerestoresitems", self.RemoveRestoreItems)
	
	self:AddChatCommand("RemoveAll", self.ActiveRemoveAdminAll)
	self:AddChatCommand("removeall", self.ActiveRemoveAdminAll)
	
	self:AddChatCommand("removesteam", self.RemoveSteamId)
	self:AddChatCommand("RemoveSteam", self.RemoveSteamId)
	
    self:AddChatCommand("RemoveAdmin", self.ActiveRemoveAdmin)
    self:AddChatCommand("removeadmin", self.ActiveRemoveAdmin)

	
    self:AddChatCommand("Remove", self.ActiveRemove)
    self:AddChatCommand("remove", self.ActiveRemove)
    -- self:AddChatCommand("undo", self.undo)
    -- self:AddChatCommand("restor", self.restor)
	
    self:AddChatCommand("removestatus", self.removestatus)
    self:AddChatCommand("rstatus", self.removestatus)
	
	self.commandgive = "give-" .. tostring(math.random(1,2000))
	self:AddCommand("remover", self.commandgive , self.give)

end

function PLUGIN:LoadDefaultConfig()
	self.Config.AllowPlayer = true -- edited me to enable or disable this command to players.  ->  true or false
	self.Config.AllowPlayerGiveItems = true -- edited me to enable or disable restores items.  ->  true or false
	self.Config.UseGroups = false -- edited me to enable or disable remove by groups (plugin http://forum.rustoxide.com/resources/groups.13 )  ->  true or false
	self.Config.Economy = false -- edited me to enable or disable Economy (plugin http://forum.rustoxide.com/resources/basic-economy.16/ )  ->  true or false
end

function PLUGIN:LoadUpdateConfig()

	if not self.Config.UseGroups then self.Config.UseGroups = false end
	if not self.Config.Economy then self.Config.Economy = false end
	config.Save( "remover" )
	
end


function PLUGIN:ReloadConfig(netuser)

	if self:GetAdmin(netuser) then
		local b, res = config.Read( "remover" )
		self.Config = res or {}
	end
	
end

function PLUGIN:loadfiles( netuser, cmd, args )
	cs.reloadplugin("0-remover")
end

function PLUGIN:GetAdmin(netuser)

	if oxmin_Plugin or oxmin then
		if  oxmin_Plugin:HasFlag( netuser, self.FLAG_REMOVER, false ) then
			return true
		end
    end

	if netuser:CanAdmin() then
		return true
	end	

	return false
end

TableActivedRemove = {}
function PLUGIN:ActiveRemove( netuser, cmd, args )

	if not self.Config.AllowPlayer then 
		rust.Notice(netuser, "Remove De-Actived for player")
		return
	end
	
	local steamID = rust.CommunityIDToSteamID(  tonumber(rust.GetUserID(netuser )))

	if TableActivedRemove[steamID] then
		TableActivedRemove[steamID] = false
		rust.Notice(netuser, "Remove De-Actived")
	else
		TableActivedRemove[steamID] = true
		rust.Notice(netuser, "Remove Actived")
	end
	
end

function PLUGIN:removestatus( netuser, cmd, args )

	rust.SendChatToUser( netuser, "Remover Status" , "Command Actived:" )
	local steamID = rust.CommunityIDToSteamID(  tonumber(rust.GetUserID(netuser )))

	if TableActivedRemove[steamID] then
		rust.SendChatToUser( netuser, "/remove" , "Actived" )
	else
		rust.SendChatToUser( netuser, "/remove" , "De-Actived" )
	end
	
	if self:GetAdmin(netuser) then
		if TableActivedRemoveAmin[steamID] then
			rust.SendChatToUser( netuser, "/removeadmin" , "Actived" )
		else
			rust.SendChatToUser( netuser, "/removeadmin" , "De-Actived" )
		end
		
		if TableActivedRemoveAminAll[steamID] then
			rust.SendChatToUser( netuser, "/removeall" , "Actived" )
		else
			rust.SendChatToUser( netuser, "/removeall" , "De-Actived" )
		end
	end	
end

TableActivedRemoveAmin = {}
function PLUGIN:ActiveRemoveAdmin( netuser, cmd, args )
    if self:GetAdmin(netuser) then
		local steamID = rust.CommunityIDToSteamID(  tonumber(rust.GetUserID(netuser )))

		if TableActivedRemoveAmin[steamID] then
			TableActivedRemoveAmin[steamID] = false
			rust.Notice(netuser, "Remove De-Actived")
		else
			TableActivedRemoveAmin[steamID] = true
			rust.Notice(netuser, "Remove Actived")
		end
	end	
end

TableActivedRemoveAminAll = {}
function PLUGIN:ActiveRemoveAdminAll( netuser, cmd, args )
    if self:GetAdmin(netuser) then
		local steamID = rust.CommunityIDToSteamID(  tonumber(rust.GetUserID(netuser )))

		if TableActivedRemoveAminAll[steamID] then
			TableActivedRemoveAminAll[steamID] = false
			rust.Notice(netuser, "Remove All De-Actived")
			if not varplayer[steamID] then varplayer[steamID] = {} end
			varplayer[steamID].RemoveAllactived = false
			varplayer[steamID].netuser = netuser
		else
			TableActivedRemoveAminAll[steamID] = true
			rust.Notice(netuser, "Remove All Actived ! ! !")
			if not varplayer[steamID] then varplayer[steamID] = {} end
			varplayer[steamID].RemoveAllactived = true
			varplayer[steamID].netuser = netuser
		end
	end	
end

-- for reload
if RemoveTimer then
RemoveTimer:Destroy()
end
RemoveTimer = timer.Repeat( 15, 0, function()

	for k,v in pairs(varplayer) do
		
		if v.RemoveAllactived then
			rust.Notice(v.netuser, "Remove All Is Actived ! ! !")	
		end
		
	end
	
end)


function PLUGIN:RemoveActivePlayer( netuser, cmd, args )
    if self:GetAdmin(netuser) then

		if not self.Config.AllowPlayer then
			
			rust.Notice(netuser, "Remove Actived for player")
			self.Config.AllowPlayer = true
			
		else
		
			rust.Notice(netuser, "Remove Disable for player")
			self.Config.AllowPlayer = false
		
		end

		config.Save( "remover" )
		
	end	
end

function PLUGIN:RemoveRestoreItems( netuser, cmd, args )
    if self:GetAdmin(netuser) then

		if not self.Config.AllowPlayerGiveItems then
		
			rust.Notice(netuser, "Remove restores items Actived")
			self.Config.AllowPlayerGiveItems = true
			
		else
		
			rust.Notice(netuser, "Remove restores items Desable")
			self.Config.AllowPlayerGiveItems = false
			
			
		end
		
		config.Save( "remover" )
		
	end	
end

local GetComponents, SetComponents = typesystem.GetField( Rust.StructureMaster, "_structureComponents", bf.private_instance )
local function GetConnectedComponents( master )
    local hashset = GetComponents( master )
    local tbl = {}
    local it = hashset:GetEnumerator()
    while (it:MoveNext()) do
        tbl[ #tbl + 1 ] = it.Current
    end
    return tbl
end

local ItemTable ={}

-- Base
ItemTable["Wood_Shelter(Clone)"] = {item = "Wood Shelter", prefab = ";deploy_wood_shelter" }
ItemTable["Campfire(Clone)"] = {item = "Camp Fire", prefab = ";deploy_camp_bonfire" }
ItemTable["Furnace(Clone)"] = {item = "Furnace", prefab = ";deploy_furnace" }
ItemTable["Workbench(Clone)"] = {item = "Workbench", prefab = ";deploy_workbench" }
ItemTable["SleepingBagA(Clone)"] = {item = "Sleeping Bag", prefab = ";deploy_camp_sleepingbag" }
ItemTable["SingleBed(Clone)"] = {item = "Bed", prefab = ";deploy_singlebed" }
ItemTable["RepairBench(Clone)"] = {item = "Repair Bench", prefab = ";deploy_repairbench" }


-- Attack and protect
ItemTable["LargeWoodSpikeWall(Clone)"] = {item = "Large Spike Wall", prefab = ";deploy_largewoodspikewall" }
ItemTable["WoodSpikeWall(Clone)"] = {item = "Spike Wall", prefab = ";deploy_woodspikewall" }
ItemTable["Barricade_Fence_Deployable(Clone)"] = {item = "Wood Barricade", prefab = ";deploy_wood_barricade" }
ItemTable["WoodGateway(Clone)"] = {item = "Wood Gateway", prefab = ";deploy_woodgateway" }
ItemTable["WoodGate(Clone)"] = {item = "Wood Gate", prefab = ";deploy_woodgate" }

-- Storage
ItemTable["WoodBoxLarge(Clone)"] = {item = "Large Wood Storage", prefab = ";deploy_wood_storage_large" }
ItemTable["WoodBox(Clone)"] = {item = "Wood Storage Box", prefab = ";deploy_wood_box" }
ItemTable["SmallStash(Clone)"] = {item = "Small Stash", prefab = ";deploy_small_stash" }

-- Structure Wood
ItemTable["WoodFoundation(Clone)"] = {item = "Wood Foundation", prefab = ";struct_wood_foundation" }
ItemTable["WoodWindowFrame(Clone)"] = {item = "Wood Window", prefab = ";struct_wood_windowframe" }
ItemTable["WoodDoorFrame(Clone)"] = {item = "Wood Doorway", prefab = ";struct_wood_doorway" }
ItemTable["WoodWall(Clone)"] = {item = "Wood Wall", prefab = ";struct_wood_wall" }
ItemTable["WoodenDoor(Clone)"] = {item = "Wooden Door", prefab = ";deploy_wood_door" }
ItemTable["WoodCeiling(Clone)"] = {item = "Wood Ceiling", prefab = ";struct_wood_ceiling" }
ItemTable["WoodRamp(Clone)"] = {item = "Wood Ramp", prefab = ";struct_wood_ramp" }
ItemTable["WoodStairs(Clone)"] = {item = "Wood Stairs", prefab = ";struct_wood_stairs" }
ItemTable["WoodPillar(Clone)"] = {item = "Wood Pillar", prefab = ";struct_wood_pillar" }

-- Structure Metal
ItemTable["MetalFoundation(Clone)"] = {item = "Metal Foundation", prefab = ";struct_metal_foundation" }
ItemTable["MetalWall(Clone)"] = {item = "Metal Wall", prefab = ";struct_metal_wall" }
ItemTable["MetalDoorFrame(Clone)"] = {item = "Metal Doorway", prefab = ";struct_metal_doorframe" }
ItemTable["MetalDoor(Clone)"] = {item = "Metal Door", prefab = ";deploy_metal_door" }
ItemTable["MetalCeiling(Clone)"] = {item = "Metal Ceiling", prefab = ";struct_metal_ceiling" }
ItemTable["MetalStairs(Clone)"] = {item = "Metal Stairs", prefab = ";struct_metal_stairs" }
ItemTable["MetalRamp(Clone)"] = {item = "Metal Ramp", prefab = ";struct_metal_ramp" }
ItemTable["MetalBarsWindow(Clone)"] = {item = "Metal Window Bars", prefab = ";deploy_metalwindowbars" }
ItemTable["MetalWindowFrame(Clone)"] = {item = "Metal Window", prefab = ";struct_metal_windowframe" }
ItemTable["MetalPillar(Clone)"] = {item = "Metal Pillar", prefab = ";struct_metal_pillar" }

function PLUGIN:LoadRemoverEconomy()

	if not self.economy.Economy then self.economy.Economy = {} end
	
	for k,v in pairs(ItemTable) do
	
		if not self.economy.Economy[v] then self.economy.Economy[v.item] = 10 end
		
	end
	
	config.Save( "removereconomy" )
	
end

function PLUGIN:LoadRemoverAllowConfig()

	if not self.AllowConfig.conf then self.AllowConfig.conf = {} end
	
	for k,v in pairs(ItemTable) do

		if type(self.AllowConfig.conf[v]) == "nil" then self.AllowConfig.conf[v.item] = true end
		
	end
	
	config.Save( "removerallowconfig" )
	
end

entsremover = {}
entsremover.FindByClass = util.GetStaticMethod( UnityEngine.Resources._type, "FindObjectsOfTypeAll")

function entsremover.GetAll()
 
	local tab = {}
	
	local allStructureComponent = entsremover.FindByClass(Rust.StructureComponent._type)
	for i = 0, tonumber(allStructureComponent.Length-1)
	do
		local component = allStructureComponent[i];
		
		table.insert(tab, component)
	end
	
	local allStructureComponent = entsremover.FindByClass(Rust.DeployableObject._type)
	for i = 0, tonumber(allStructureComponent.Length-1)
	do
		local component = allStructureComponent[i];
		
		table.insert(tab, component)
	end
	
	return tab
	
end

function PLUGIN:OnProcessDamageEvent( takedamage, damage )

	MyHostIsNoMultiplay = true
	
	if takedamage then

		if takedamage.gameObject then

			if takedamage.GetComponent == "GetComponent" then

				if ItemTable[takedamage.idMain.Name] then
					local name = ItemTable[takedamage.idMain.Name].item
					plugins.Call( "OnEntityTakeDamage", takedamage.idMain, name)
					return
				end	
			end 

			if takedamage.gameObject == "gameObject" then return end
			
			if takedamage.gameObject.Name then

				if ItemTable[takedamage.gameObject.Name] then

					local name = ItemTable[takedamage.gameObject.Name].item

					plugins.Call( "OnEntityTakeDamage", takedamage, damage, name )
				end
			end
		end	
	end
end

function PLUGIN:OnHurt( takedamage, damage )

	if MyHostIsNoMultiplay then return end

	if takedamage then

		if takedamage.gameObject then

			if takedamage.GetComponent == "GetComponent" then

				plugins.Call( "OnEntityTakeDamage", takedamage.idMain, damage, takedamage.idMain.name)
				return
			end 

			if takedamage.gameObject == "gameObject" then return end
			
			if takedamage.gameObject.Name then

				if ItemTable[takedamage.gameObject.Name] then

					local name = ItemTable[takedamage.gameObject.Name].item

					plugins.Call( "OnEntityTakeDamage", takedamage, damage, name )
				end
			end
		end	
	end
end

varplayer = {}
local GetStructureComponentownerID = util.GetFieldGetter( Rust.StructureMaster, "ownerID", true )
local GetDeployableObjectownerID = util.GetFieldGetter( Rust.DeployableObject, "ownerID", true )
local GetDeployableObjectcreatorID = util.GetFieldGetter( Rust.DeployableObject, "creatorID", true )
local GetDeployableObjectownerName = util.GetFieldGetter( Rust.DeployableObject, "ownerName", true )
NetCullRemove = util.FindOverloadedMethod( Rust.NetCull._type, "Destroy", bf.public_static, { UnityEngine.GameObject} )

if not HistoriqueStructure then  HistoriqueStructure = {} end
if not HistoriqueRemovedStructure then  HistoriqueRemovedStructure = {} end

-- function PLUGIN:OnPlaceStructure(structure, pos)

	-- timer.Once(0.2, function() 
		
		-- for k,v in pairs(entsremover.GetAll()) do
			-- ent = v.Transform.position
			-- print(pos)
			-- print(v.Transform.position)
			-- print(v.Transform.position)
			-- print(pos == v.Transform.position)
			-- print(v.Transform.position == v.Transform.position)
			-- print(ent == ent)
	
		
			-- if v.Transform.position.x == pos.x then
				-- if v.Transform.position.y == pos.y then
					-- if v.Transform.position.z == pos.z then
	
						-- local userID = GetStructureComponentownerID(v._master)
						-- local SteamIdEntity = rust.CommunityIDToSteamID( userID )

						-- HistoriqueStructure[SteamIdEntity] = v
					-- end
				-- end		
				
			-- end
		
		-- end

	-- end)

-- end

local Getowner, Setowner = typesystem.GetField( Rust.StructureMaster, "ownerID", bf.public_instance )
local GetcreatorID, SetcreatorID = typesystem.GetField( Rust.StructureMaster, "creatorID", bf.public_instance )

function PLUGIN:undo( netuser, cmd, args )

	steamID = rust.CommunityIDToSteamID( tonumber(rust.GetUserID(netuser )))

	if HistoriqueStructure[steamID] then
		local ent = HistoriqueStructure[steamID]
		local name = ItemTable[ent.Name].item
		local stucturemaster = false
		
		if ent._master then
			stucturemaster = ent._master
		end
			
		self:AddIdems(netuser, name, 1)
		rust.InventoryNotice( netuser, 1 .. " x " .. name )
		HistoriqueRemovedStructure[steamID] = {owner = netuser, item = name, pos =  ent.Transform.position, angle =  ent.Transform.rotation, stucturemaster = stucturemaster}
		Remove(ent.GameObject)
		HistoriqueStructure[steamID] = nil
	end	
end

entsremover.create = util.FindOverloadedMethod( Rust.NetCull._type, "InstantiateStatic", bf.public_static, { System.String, UnityEngine.Vector3,UnityEngine.Quaternion } )

function PLUGIN:restor( netuser, cmd, args )

	steamID = rust.CommunityIDToSteamID( tonumber(rust.GetUserID(netuser )))
	local prefab = false
	
	if HistoriqueRemovedStructure[steamID] then
		local ent = HistoriqueStructure[steamID]
		
		for k,v in pairs(ItemTable) do
	
			if HistoriqueRemovedStructure[steamID].item == v.item then
				prefab = v.prefab
			end
		end
		
	end	
	
	local pos =  HistoriqueRemovedStructure[steamID].pos
	local angle =  HistoriqueRemovedStructure[steamID].angle
	local StructureMaster = HistoriqueRemovedStructure[steamID].stucturemaster
	if prefab then
		print(prefab)
		print("merdeeeeee")
		print(StructureMaster)
		
		arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { prefab, pos, angle  } )  ;
		
		cs.convertandsetonarray( arr, 0, prefab, System.String._type )
		cs.convertandsetonarray( arr, 1, pos, UnityEngine.Vector3._type )
		cs.convertandsetonarray( arr, 2, angle, UnityEngine.Quaternion._type )
		
		local xgameObject = entsremover.create:Invoke( nil, arr )
		
		if StructureMaster then
			local StructureComponent = xgameObject:GetComponent("StructureComponent")
		
			StructureMaster:AddStructureComponent(StructureComponent)
			print("master added")
			
			-- owner
			
			
		end
		
		print(xgameObject)
	end
end

IsRemoved= {}
function Remove(object)

	if IsRemoved[object] then return end
	IsRemoved[object] = true
	if object.name == "name" then return end
	if object == "GameObject" then return end
	
	arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { object } )  ;
	cs.convertandsetonarray( arr, 0, object , UnityEngine.GameObject._type )
	NetCullRemove:Invoke( nil, arr )
	
end
function PLUGIN:RemoveSteamId(netuser, cmd, args )
   
	if self:GetAdmin(netuser) then

		if not args[1] then rust.SendChatToUser( netuser, "Error Remove SteamID" , "Use /removesteam \"SteamID\" " ) return end
	
		local steamid = util.QuoteSafe(args[1])
		
		
		for k,v in pairs(entsremover.GetAll()) do
		
			if (v:GetComponent("StructureComponent")) then
				
				local master = v._master
				
				if master == "_master" then return end
				if type(master) == "string" then return end
				
				if master then 
				
					userID = GetStructureComponentownerID(master)
					SteamIdEntity = rust.CommunityIDToSteamID( userID )
					
				end	
			end

			if (v:GetComponent("DeployableObject")) then
				
				userID = GetDeployableObjectownerID(v)
				SteamIdEntity = rust.CommunityIDToSteamID( userID )
				
			end
			
			if SteamIdEntity == steamid then
				Remove(v.GameObject)
			end	
			
		end
		
	end
	
end

function PLUGIN:OnEntityTakeDamage( takedamage, damage , name)

	local netuser = nil
	local steamID = nil
	local userID = nil
	
	if damage then
	
		if damage.attacker then
			
			if damage.attacker.client then
		
				if damage.attacker.client.netUser then
			
					netuser = damage.attacker.client.netUser
				
					if self:GetAdmin(netuser) then
						allow = true
					end
				
					steamID = rust.CommunityIDToSteamID( tonumber(rust.GetUserID(netuser )))
				else
					return
				end
			else
				return
			end
			
			if damage.attacker.idMain then
				
				if damage.attacker.idMain.GetComponent == "GetComponent" then
					
					if not damage.attacker.client.netUser then
						netuser = nil
					end
				
				else
				
					if type(damage.attacker.idMain:GetComponent("PlayerInventory")) == "nil" then
						netuser = nil
					
					else
						
					end
				
				end
			end
		end
	end

	if not netuser then return end

	if TableActivedRemoveAminAll[steamID] then
		if allow then

			if takedamage.GameObject:GetComponent("StructureComponent") then
				local entity = takedamage.GameObject:GetComponent("StructureComponent")
				if not entity then return end
				for k,v in pairs (GetConnectedComponents(entity._master) ) do
			
					timer.Once(0.5, function()  Remove(v.GameObject) end)
				
				end
			end	
			
		end  
	end 

	if TableActivedRemoveAmin[steamID] then
		if allow then
		
			timer.Once(0.5, function()  Remove(takedamage.GameObject) end)
			return
	
		end  
	end  
	
	if (takedamage.GameObject:GetComponent("StructureComponent")) then
		entity = takedamage.GameObject:GetComponent("StructureComponent")
		local master = entity._master
		
		if master == "_master" then return end
		if type(master) == "string" then return end
		
		if master then 
		
			userID = GetStructureComponentownerID(master)
			SteamIdEntity = rust.CommunityIDToSteamID( userID )
			
		end	
	end

	if (takedamage.GameObject:GetComponent("DeployableObject")) then
		entity = takedamage.GameObject:GetComponent("DeployableObject")
	
		if entity.GetComponent == "GetComponent" then
			return
		end
		
		if type(entity.GetComponent) == "string" then return end
		
		userID = GetDeployableObjectownerID(entity)
		SteamIdEntity = rust.CommunityIDToSteamID( userID )
	end
	
	if self.Config.AllowPlayer then
	
		if TableActivedRemove[steamID] then
			
			if self.Economy then
			
				local b, balance = api.Call( "economy", "getMoney", netuser)
				
				if balance < self.economy.Economy[name] then
					rust.Notice(netuser,"You don't have " .. self.GS .. self.economy.Economy[name] .. " to remove ".. name .."!" )
					return
				else
					api.Call( "economy", "takeMoneyFrom", netuser, self.economy.Economy[name])
				end
				
			end
			print(name)
			if not self.AllowConfig.conf[name] then
				rust.Notice(netuser,"You don't have permission to delete ".. name .."!" )
				return
			end
			
			local AllowGroup = false
			
			local userID2 = rust.GetUserID( netuser )
			if self.Config.UseGroups then
				if group_Plugin then
				
					local id1 = group_Plugin:checkPlayerGroup(userID2)
					local id2 = group_Plugin:checkPlayerGroup(tostring(userID))
			
					if id1 == id2 then
						AllowGroup = true
					end
					
				end
			end
	
			if (SteamIdEntity == steamID) or AllowGroup then
			
				if self.Config.AllowPlayerGiveItems then
					if not varplayer[steamID] then varplayer[steamID] = {} end
					if not varplayer[steamID].OldRemove then varplayer[steamID].OldRemove = {} end
					
					-- Fix duplication shootgun
					local dup = false
					for a,b in pairs(varplayer[steamID].OldRemove) do

						if b == entity then
							dup = true
						end
					end
				
					if not dup then
						
						local nodrop = false
						
						if takedamage.gameObject.Name == "Campfire(Clone)" then
							local wood = rust.GetDatablockByName( "Wood" )


							inv = entity:GetComponent( "Inventory" )
							local item1 = inv:FindItem(wood)
							if item1 then
								
								
								if item1.uses >= 5 then
								
									if item1.uses > 5 then
										local num = item1.uses - 5
										timer.Once(0.05, function()  
											rusself:AddIdems(netuser, "Wood", num)
											rust.InventoryNotice( netuser, num .. " x Wood" )
										end)
									end
								else
									nodrop = true
									timer.Once(0.05, function()  
										self:AddIdems(netuser, "Wood", item1.uses)
										rust.InventoryNotice( netuser, item1.uses .. " x Wood" )
									end)
								end
							else
								nodrop = true
							end	
						end
						
						if not nodrop then
							
							timer.Once(0.05, function()  
								self:AddIdems(netuser, name, 1)
								rust.InventoryNotice( netuser, 1 .. " x " .. name )
							end)
							
						end	
						
					end	
				end
				
				if not varplayer[steamID] then varplayer[steamID] = {} end
				if not varplayer[steamID].OldRemove then varplayer[steamID].OldRemove = {} end
				
				table.insert(varplayer[steamID].OldRemove, entity)
	
				timer.Once(0.5, function()  Remove(takedamage.GameObject) end)
				return
				
			end
		end
	end
end

function printtable(table, indent)

  indent = indent or 0;

  local keys = {};

  for k in pairs(table) do
    keys[#keys+1] = k;
    -- table.sort(keys, function(a, b)
      -- local ta, tb = type(a), type(b);
      -- if (ta ~= tb) then
        -- return ta < tb;
      -- else
        -- return a < b;
      -- end
    -- end);
  end

  print(string.rep('  ', indent)..'{');
  indent = indent + 1;
  for k, v in pairs(table) do

    local key = k;
    if (type(key) == 'string') then
      if not (string.match(key, '^[A-Za-z_][0-9A-Za-z_]*$')) then
        key = "['"..key.."']";
      end
    elseif (type(key) == 'number') then
      key = "["..key.."]";
    end

    if (type(v) == 'table') then
      if (next(v)) then
        print("%s%s =", string.rep('  ', indent), tostring(key));
        printtable(v, indent);
      else
        print("%s%s = {},", string.rep('  ', indent), tostring(key));
      end 
    elseif (type(v) == 'string') then
      print("%s%s = %s,", string.rep('  ', indent), tostring(key), "'"..v.."'");
    else
      print("%s%s = %s,", string.rep('  ', indent), tostring(key), tostring(v));
    end
  end
  indent = indent - 1;
  print(string.rep('  ', indent)..'}');
end


function PLUGIN:give(arg)

	if self.Config.AllowPlayerGiveItems then
		local PlayerClientAll = rust.GetAllNetUsers()

		user = false
		
		for key,netuser in pairs(PlayerClientAll) do
			if arg:GetString( 2 ) == rust.GetUserID(netuser ) then
				user = netuser
			end
		end	
		
		if user then

			local steamID = rust.CommunityIDToSteamID( tonumber(rust.GetUserID(user )))

			if varplayer[steamID].Recoveritem == arg:GetString( 0 ) then
				
				if tostring(varplayer[steamID].Recoveritemnum) == arg:GetString( 1 ) then
					varplayer[steamID].Recoveritemnum = 0
					varplayer[steamID].Recoveritem = nil
					arg:SetUser(user)
					Rust.inv.give(arg)
				end
			end
		end
	end
end

function PLUGIN:AddIdems(netuser, item, num)
	
	local steamID = rust.CommunityIDToSteamID( tonumber(rust.GetUserID(netuser )))
	if not varplayer[steamID] then varplayer[steamID] = {} end
	varplayer[steamID].Recoveritem = item
	varplayer[steamID].Recoveritemnum = num

	rust.RunServerCommand("remover."..self.commandgive.." \"" .. util.QuoteSafe( item ) .. "\" ".. tostring(num) .." " .. rust.GetUserID(netuser ) ) 

end

api.Bind( PLUGIN, "removertool" )
