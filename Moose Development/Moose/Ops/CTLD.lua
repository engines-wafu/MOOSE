--- **Ops** -- Combat Troops & Logistics Department.
--
-- ===
-- 
-- **CTLD** - MOOSE based Helicopter CTLD Operations.
-- 
-- ===
-- 
-- ## Missions:
--
-- ### [CTLD - Combat Troop & Logistics Deployment](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20CTLD)
-- 
-- ===
-- 
-- **Main Features:**
--
--    * MOOSE-based Helicopter CTLD Operations for Players.
--
-- ===
--
-- ### Author: **Applevangelist** (Moose Version), ***Ciribob*** (original), Thanks to: Shadowze, Cammel (testing), bbirchnz (additional code!!)
-- @module Ops.CTLD
-- @image OPS_CTLD.jpg

-- Date: Sep 2021

do
------------------------------------------------------
--- **CTLD_ENGINEERING** class, extends Core.Base#BASE
-- @type CTLD_ENGINEERING
-- @field #string ClassName
-- @field #string lid
-- @field #string Name
-- @field Wrapper.Group#GROUP Group
-- @field Wrapper.Unit#UNIT Unit
-- @field Wrapper.Group#GROUP HeliGroup
-- @field Wrapper.Unit#UNIT HeliUnit
-- @field #string State
-- @extends Core.Base#BASE
CTLD_ENGINEERING = {
  ClassName = "CTLD_ENGINEERING",
  lid = "",
  Name = "none",
  Group = nil,
  Unit = nil,
  --C_Ops = nil,
  HeliGroup = nil,
  HeliUnit = nil,
  State = "",
  }
  
  --- CTLD_ENGINEERING class version.
  -- @field #string version
  CTLD_ENGINEERING.Version = "0.0.3"
  
  --- Create a new instance.
  -- @param #CTLD_ENGINEERING self
  -- @param #string Name
  -- @param #string GroupName Name of Engineering #GROUP object
  -- @param Wrapper.Group#GROUP HeliGroup HeliGroup
  -- @param Wrapper.Unit#UNIT HeliUnit HeliUnit
  -- @return #CTLD_ENGINEERING self 
  function CTLD_ENGINEERING:New(Name, GroupName, HeliGroup, HeliUnit)
  
      -- Inherit everything from BASE class.
    local self=BASE:Inherit(self, BASE:New()) -- #CTLD_ENGINEERING
    
   --BASE:I({Name, GroupName})
    
    self.Name = Name or "Engineer Squad" -- #string
    self.Group = GROUP:FindByName(GroupName) -- Wrapper.Group#GROUP
    self.Unit = self.Group:GetUnit(1) -- Wrapper.Unit#UNIT
    --self.C_Ops = C_Ops -- Ops.CTLD#CTLD
    self.HeliGroup = HeliGroup -- Wrapper.Group#GROUP
    self.HeliUnit = HeliUnit -- Wrapper.Unit#UNIT
    --self.distance = Distance or UTILS.NMToMeters(1)
    self.currwpt = nil -- Core.Point#COORDINATE
    self.lid = string.format("%s (%s) | ",self.Name, self.Version)
      -- Start State.
    self.State = "Stopped"
    self.marktimer = 300 -- wait this many secs before trying a crate again
  
    --[[ Add FSM transitions.
    --                 From State  -->   Event        -->      To State
    self:AddTransition("Stopped",       "Start",               "Running")     -- Start FSM.
    self:AddTransition("*",             "Status",              "*")
    self:AddTransition("*",             "Search",              "Searching")
    self:AddTransition("*",             "Move",                "Moving")
    self:AddTransition("*",             "Arrive",              "Arrived")
    self:AddTransition("*",             "Build",               "Building")
    self:AddTransition("*",             "Done",                "Running")
    self:AddTransition("*",             "Stop",                "Stopped")     -- Stop FSM. 
    
    self:__Start(5)
    --]]
    self:Start()
    local parent = self:GetParent(self)
    return self
  end
  
  --- (Internal) Set the status
  -- @param #CTLD_ENGINEERING self
  -- @param #string State
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:SetStatus(State)
    self.State = State
    return self
  end
  
  --- (Internal) Get the status
  -- @param #CTLD_ENGINEERING self
  -- @return #string State
  function CTLD_ENGINEERING:GetStatus()
    return self.State
  end
  
  --- (Internal) Check the status
  -- @param #CTLD_ENGINEERING self
  -- @param #string State
  -- @return #boolean Outcome
  function CTLD_ENGINEERING:IsStatus(State)
    return self.State == State
  end
  
  --- (Internal) Check the negative status
  -- @param #CTLD_ENGINEERING self
  -- @param #string State
  -- @return #boolean Outcome
  function CTLD_ENGINEERING:IsNotStatus(State)
    return self.State ~= State
  end
  
  --- (Internal) Set start status.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Start()
    self:T(self.lid.."Start")
    self:SetStatus("Running")
    return self
  end
  
  --- (Internal) Set stop status.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Stop()
    self:T(self.lid.."Stop")
    self:SetStatus("Stopped")
    return self
  end
  
  --- (Internal) Set build status.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Build()
    self:T(self.lid.."Build")
    self:SetStatus("Building")
    return self
  end
  
  --- (Internal) Set done status.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Done()
    self:T(self.lid.."Done")
    local grp = self.Group -- Wrapper.Group#GROUP
    grp:RelocateGroundRandomInRadius(7,100,false,false,"Diamond")
    self:SetStatus("Running")
    return self
  end
  
  --- (Internal) Search for crates in reach.
  -- @param #CTLD_ENGINEERING self
  -- @param #table crates Table of found crate Ops.CTLD#CTLD_CARGO objects.
  -- @param #number number Number of crates found.
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Search(crates,number)
    self:T(self.lid.."Search")
    self:SetStatus("Searching")
    -- find crates close by
    --local COps = self.C_Ops -- Ops.CTLD#CTLD
    local dist = self.distance -- #number
    local group = self.Group -- Wrapper.Group#GROUP
    --local crates,number = COps:_FindCratesNearby(group,nil, dist) -- #table
    local ctable = {}
    local ind = 0
    if number > 0 then
      -- get set of dropped only
      for _,_cargo in pairs (crates) do
       local cgotype = _cargo:GetType()
       if _cargo:WasDropped() and cgotype ~= CTLD_CARGO.Enum.STATIC then
        local ok = false
        local chalk = _cargo:GetMark()
        if chalk == nil then
          ok = true
        else
         -- have we tried this cargo recently?
         local tag = chalk.tag or "none"
         local timestamp = chalk.timestamp or 0
         --self:I({chalk})
         -- enough time gone?
         local gone = timer.getAbsTime() - timestamp
         --self:I({time=gone})
         if gone >= self.marktimer then
            ok = true
            _cargo:WipeMark()
         end -- end time check
        end -- end chalk
        if ok then
          local chalk = {}
          chalk.tag = "Engineers"
          chalk.timestamp = timer.getAbsTime()
          _cargo:AddMark(chalk)
          ind = ind + 1
          table.insert(ctable,ind,_cargo)
        end     
       end -- end dropped
      end -- end for
    end -- end number
    
    if ind > 0 then
      local crate = ctable[1] -- Ops.CTLD#CTLD_CARGO
      local static = crate:GetPositionable() -- Wrapper.Static#STATIC
      local crate_pos = static:GetCoordinate() -- Core.Point#COORDINATE
      local gpos = group:GetCoordinate() -- Core.Point#COORDINATE
      -- see how far we are from the crate
      local distance = self:_GetDistance(gpos,crate_pos)
      self:T(string.format("%s Distance to crate: %d", self.lid, distance))
      -- move there
      if distance > 30 and distance ~= -1 and self:IsStatus("Searching") then
        group:RouteGroundTo(crate_pos,15,"Line abreast",1)
        self.currwpt = crate_pos -- Core.Point#COORDINATE
        self:Move()
      elseif distance <= 30 and distance ~= -1 then
        -- arrived
        self:Arrive()
      end
    else
      self:T(self.lid.."No crates in reach!")
    end
    return self
  end
  
  --- (Internal) Move towards crates in reach.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Move()
    self:T(self.lid.."Move")
    self:SetStatus("Moving")
    -- check if we arrived on target
    --local COps = self.C_Ops -- Ops.CTLD#CTLD
    local group = self.Group -- Wrapper.Group#GROUP
    local tgtpos = self.currwpt -- Core.Point#COORDINATE
    local gpos = group:GetCoordinate() -- Core.Point#COORDINATE
    -- see how far we are from the crate
    local distance = self:_GetDistance(gpos,tgtpos)
    self:T(string.format("%s Distance remaining: %d", self.lid, distance))
    if distance <= 30 and distance ~= -1 then
        -- arrived
        self:Arrive()
    end
    return self
  end
  
  --- (Internal) Arrived at crates in reach. Stop group.
  -- @param #CTLD_ENGINEERING self
  -- @return #CTLD_ENGINEERING self
  function CTLD_ENGINEERING:Arrive()
    self:T(self.lid.."Arrive")
    self:SetStatus("Arrived")
    self.currwpt = nil
    local Grp = self.Group -- Wrapper.Group#GROUP
    Grp:RouteStop()
    return self
  end
  
  --- (Internal) Return distance in meters between two coordinates.
  -- @param #CTLD_ENGINEERING self
  -- @param Core.Point#COORDINATE _point1 Coordinate one
  -- @param Core.Point#COORDINATE _point2 Coordinate two
  -- @return #number Distance in meters or -1
  function CTLD_ENGINEERING:_GetDistance(_point1, _point2)
    self:T(self.lid .. " _GetDistance")
    if _point1 and _point2 then
      local distance1 = _point1:Get2DDistance(_point2)
      local distance2 = _point1:DistanceFromPointVec2(_point2)
      --self:I({dist1=distance1, dist2=distance2})
      if distance1 and type(distance1) == "number" then
        return distance1
      elseif distance2 and type(distance2) == "number" then
        return distance2
      else
        self:E("*****Cannot calculate distance!")
        self:E({_point1,_point2})
        return -1
      end
    else
      self:E("******Cannot calculate distance!")
      self:E({_point1,_point2})
      return -1
    end
  end
------------------------------------------------------
--- **CTLD_CARGO** class, extends Core.Base#BASE
-- @type CTLD_CARGO
-- @field #number ID ID of this cargo.
-- @field #string Name Name for menu.
-- @field #table Templates Table of #POSITIONABLE objects.
-- @field #CTLD_CARGO.Enum CargoType Enumerator of Type.
-- @field #boolean HasBeenMoved Flag for moving.
-- @field #boolean LoadDirectly Flag for direct loading.
-- @field #number CratesNeeded Crates needed to build.
-- @field Wrapper.Positionable#POSITIONABLE Positionable Representation of cargo in the mission.
-- @field #boolean HasBeenDropped True if dropped from heli.
-- @field #number PerCrateMass Mass in kg
-- @field #number Stock Number of builds available, -1 for unlimited
-- @extends Core.Base#BASE
CTLD_CARGO = {
  ClassName = "CTLD_CARGO",
  ID = 0,
  Name = "none",
  Templates = {},
  CargoType = "none",
  HasBeenMoved = false,
  LoadDirectly = false,
  CratesNeeded = 0,
  Positionable = nil,
  HasBeenDropped = false,
  PerCrateMass = 0,
  Stock = nil,
  Mark = nil,
  }
  
  --- Define cargo types.
  -- @type CTLD_CARGO.Enum
  -- @field #string Type Type of Cargo.
  CTLD_CARGO.Enum = {
    ["VEHICLE"] = "Vehicle", -- #string vehicles
    ["TROOPS"] = "Troops", -- #string troops
    ["FOB"] = "FOB", -- #string FOB
    ["CRATE"] = "Crate", -- #string crate
    ["REPAIR"] = "Repair", -- #string repair
    ["ENGINEERS"] = "Engineers", -- #string engineers
    ["STATIC"] = "Static", -- #string engineers
  }
  
  --- Function to create new CTLD_CARGO object.
  -- @param #CTLD_CARGO self
  -- @param #number ID ID of this #CTLD_CARGO
  -- @param #string Name Name for menu.
  -- @param #table Templates Table of #POSITIONABLE objects.
  -- @param #CTLD_CARGO.Enum Sorte Enumerator of Type.
  -- @param #boolean HasBeenMoved Flag for moving.
  -- @param #boolean LoadDirectly Flag for direct loading.
  -- @param #number CratesNeeded Crates needed to build.
  -- @param Wrapper.Positionable#POSITIONABLE Positionable Representation of cargo in the mission.
  -- @param #boolean Dropped Cargo/Troops have been unloaded from a chopper.
  -- @param #number PerCrateMass Mass in kg
  -- @param #number Stock Number of builds available, nil for unlimited
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:New(ID, Name, Templates, Sorte, HasBeenMoved, LoadDirectly, CratesNeeded, Positionable, Dropped, PerCrateMass, Stock)
    -- Inherit everything from BASE class.
    local self=BASE:Inherit(self, BASE:New()) -- #CTLD
    self:T({ID, Name, Templates, Sorte, HasBeenMoved, LoadDirectly, CratesNeeded, Positionable, Dropped})
    self.ID = ID or math.random(100000,1000000)
    self.Name = Name or "none" -- #string
    self.Templates = Templates or {} -- #table
    self.CargoType = Sorte or "type" -- #CTLD_CARGO.Enum
    self.HasBeenMoved = HasBeenMoved or false -- #boolean
    self.LoadDirectly = LoadDirectly or false -- #boolean
    self.CratesNeeded = CratesNeeded or 0 -- #number
    self.Positionable = Positionable or nil -- Wrapper.Positionable#POSITIONABLE
    self.HasBeenDropped = Dropped or false --#boolean
    self.PerCrateMass = PerCrateMass or 0 -- #number
    self.Stock = Stock or nil --#number
    self.Mark = nil
    return self
  end
  
  --- Query ID.
  -- @param #CTLD_CARGO self
  -- @return #number ID
  function CTLD_CARGO:GetID()
    return self.ID
  end
  
  --- Query Mass.
  -- @param #CTLD_CARGO self
  -- @return #number Mass in kg
  function CTLD_CARGO:GetMass()
    return self.PerCrateMass
  end  
  --- Query Name.
  -- @param #CTLD_CARGO self
  -- @return #string Name
  function CTLD_CARGO:GetName()
    return self.Name
  end
  
  --- Query Templates.
  -- @param #CTLD_CARGO self
  -- @return #table Templates
  function CTLD_CARGO:GetTemplates()
    return self.Templates
  end
  
  --- Query has moved.
  -- @param #CTLD_CARGO self
  -- @return #boolean Has moved
  function CTLD_CARGO:HasMoved()
    return self.HasBeenMoved
  end
  
  --- Query was dropped.
  -- @param #CTLD_CARGO self
  -- @return #boolean Has been dropped.
  function CTLD_CARGO:WasDropped()
    return self.HasBeenDropped
  end
  
  --- Query directly loadable.
  -- @param #CTLD_CARGO self
  -- @return #boolean loadable
  function CTLD_CARGO:CanLoadDirectly()
    return self.LoadDirectly
  end
  
  --- Query number of crates or troopsize.
  -- @param #CTLD_CARGO self
  -- @return #number Crates or size of troops.
  function CTLD_CARGO:GetCratesNeeded()
    return self.CratesNeeded
  end
  
  --- Query type.
  -- @param #CTLD_CARGO self
  -- @return #CTLD_CARGO.Enum Type
  function CTLD_CARGO:GetType()
    return self.CargoType
  end
  
  --- Query type.
  -- @param #CTLD_CARGO self
  -- @return Wrapper.Positionable#POSITIONABLE Positionable
  function CTLD_CARGO:GetPositionable()
    return self.Positionable
  end
  
  --- Set HasMoved.
  -- @param #CTLD_CARGO self
  -- @param #boolean moved
  function CTLD_CARGO:SetHasMoved(moved)
    self.HasBeenMoved = moved or false
  end
  
   --- Query if cargo has been loaded.
  -- @param #CTLD_CARGO self
  -- @param #boolean loaded
  function CTLD_CARGO:Isloaded()
    if self.HasBeenMoved and not self.WasDropped() then
      return true
    else
     return false
    end 
  end
  
  --- Set WasDropped.
  -- @param #CTLD_CARGO self
  -- @param #boolean dropped
  function CTLD_CARGO:SetWasDropped(dropped)
    self.HasBeenDropped = dropped or false
  end
  
  --- Get Stock.
  -- @param #CTLD_CARGO self
  -- @return #number Stock
  function CTLD_CARGO:GetStock()
    if self.Stock then
      return self.Stock
    else
      return -1
    end
  end
  
  --- Add Stock.
  -- @param #CTLD_CARGO self
  -- @param #number Number to add, one if nil.
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:AddStock(Number)
    if self.Stock then -- Stock nil?
      local number = Number or 1
      self.Stock = self.Stock + number
    end
    return self
  end
  
  --- Remove Stock.
  -- @param #CTLD_CARGO self
  -- @param #number Number to reduce, one if nil.
  -- @return #CTLD_CARGO self
  function CTLD_CARGO:RemoveStock(Number)
    if self.Stock then -- Stock nil?
      local number = Number or 1
      self.Stock = self.Stock - number
      if self.Stock < 0 then self.Stock = 0 end
    end
    return self
  end
  
  --- Query crate type for REPAIR
  -- @param #CTLD_CARGO self
  -- @param #boolean 
  function CTLD_CARGO:IsRepair()
   if self.CargoType == "Repair" then
    return true
   else
    return false
   end
  end
  
  --- Query crate type for STATIC
  -- @param #CTLD_CARGO self
  -- @param #boolean 
  function CTLD_CARGO:IsStatic()
   if self.CargoType == "Static" then
    return true
   else
    return false
   end
  end
  
  function CTLD_CARGO:AddMark(Mark)
    self.Mark = Mark
    return self
  end
  
  function CTLD_CARGO:GetMark(Mark)
    return self.Mark
  end
  
  function CTLD_CARGO:WipeMark()
    self.Mark = nil
    return self
  end
   
end

do
-------------------------------------------------------------------------
--- **CTLD** class, extends Core.Base#BASE, Core.Fsm#FSM
-- @type CTLD
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number coalition Coalition side number, e.g. `coalition.side.RED`.
-- @extends Core.Fsm#FSM

--- *Combat Troop & Logistics Deployment (CTLD): Everyone wants to be a POG, until there\'s POG stuff to be done.* (Mil Saying)
--
-- ===
--
-- ![Banner Image](OPS_CTLD.jpg)
--
-- # CTLD Concept
-- 
--  * MOOSE-based CTLD for Players.
--  * Object oriented refactoring of Ciribob\'s fantastic CTLD script.
--  * No need for extra MIST loading. 
--  * Additional events to tailor your mission.
--  * ANY late activated group can serve as cargo, either as troops, crates, which have to be build on-location, or static like ammo chests.
--  * Option to persist (save&load) your dropped troops, crates and vehicles.
-- 
-- ## 0. Prerequisites
-- 
-- You need to load an .ogg soundfile for the pilot\'s beacons into the mission, e.g. "beacon.ogg", use a once trigger, "sound to country" for that.
-- Create the late-activated troops, vehicles (no statics at this point!) that will make up your deployable forces.
-- 
-- ## 1. Basic Setup
-- 
-- ## 1.1 Create and start a CTLD instance
-- 
-- A basic setup example is the following:
--        
--        -- Instantiate and start a CTLD for the blue side, using helicopter groups named "Helicargo" and alias "Lufttransportbrigade I"
--        local my_ctld = CTLD:New(coalition.side.BLUE,{"Helicargo"},"Lufttransportbrigade I")
--        my_ctld:__Start(5)
--
-- ## 1.2 Add cargo types available
--        
-- Add *generic* cargo types that you need for your missions, here infantry units, vehicles and a FOB. These need to be late-activated Wrapper.Group#GROUP objects:
--        
--        -- add infantry unit called "Anti-Tank Small" using template "ATS", of type TROOP with size 3
--        -- infantry units will be loaded directly from LOAD zones into the heli (matching number of free seats needed)
--        my_ctld:AddTroopsCargo("Anti-Tank Small",{"ATS"},CTLD_CARGO.Enum.TROOPS,3)
--        -- if you want to add weight to your Heli, troops can have a weight in kg **per person**. Currently no max weight checked. Fly carefully.
--        my_ctld:AddTroopsCargo("Anti-Tank Small",{"ATS"},CTLD_CARGO.Enum.TROOPS,3,80)
--        
--        -- add infantry unit called "Anti-Tank" using templates "AA" and "AA"", of type TROOP with size 4. No weight. We only have 2 in stock:
--        my_ctld:AddTroopsCargo("Anti-Air",{"AA","AA2"},CTLD_CARGO.Enum.TROOPS,4,nil,2)
--        
--        -- add an engineers unit called "Wrenches" using template "Engineers", of type ENGINEERS with size 2. Engineers can be loaded, dropped,
--        -- and extracted like troops. However, they will seek to build and/or repair crates found in a given radius. Handy if you can\'t stay
--        -- to build or repair or under fire.
--        my_ctld:AddTroopsCargo("Wrenches",{"Engineers"},CTLD_CARGO.Enum.ENGINEERS,4)
--        myctld.EngineerSearch = 2000 -- teams will search for crates in this radius.
--        
--        -- add vehicle called "Humvee" using template "Humvee", of type VEHICLE, size 2, i.e. needs two crates to be build
--        -- vehicles and FOB will be spawned as crates in a LOAD zone first. Once transported to DROP zones, they can be build into the objects
--        my_ctld:AddCratesCargo("Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,2)
--        -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Currently no max weight checked. Fly carefully.
--        my_ctld:AddCratesCargo("Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,2,2775)
--        -- if you want to limit your stock, add a number (here: 10) as parameter after weight. No parameter / nil means unlimited stock.
--        my_ctld:AddCratesCargo("Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,2,2775,10)
--        
--        -- add infantry unit called "Forward Ops Base" using template "FOB", of type FOB, size 4, i.e. needs four crates to be build:
--        my_ctld:AddCratesCargo("Forward Ops Base",{"FOB"},CTLD_CARGO.Enum.FOB,4)
--        
--        -- add crates to repair FOB or VEHICLE type units - the 2nd parameter needs to match the template you want to repair
--        my_ctld:AddCratesRepair("Humvee Repair","Humvee",CTLD_CARGO.Enum.REPAIR,1)
--        my_ctld.repairtime = 300 -- takes 300 seconds to repair something
-- 
--        -- add static cargo objects, e.g ammo chests - the name needs to refer to a STATIC object in the mission editor, 
--        -- here: it\'s the UNIT name (not the GROUP name!), the second parameter is the weight in kg.
--        my_ctld:AddStaticsCargo("Ammunition",500)
--        
-- ## 1.3 Add logistics zones
--  
--  Add zones for loading troops and crates and dropping, building crates
--  
--        -- Add a zone of type LOAD to our setup. Players can load troops and crates.
--        -- "Loadzone" is the name of the zone from the ME. Players can load, if they are inside the zone.
--        -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
--        my_ctld:AddCTLDZone("Loadzone",CTLD.CargoZoneType.LOAD,SMOKECOLOR.Blue,true,true)
--        
--        -- Add a zone of type DROP. Players can drop crates here.
--        -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
--        -- NOTE: Troops can be unloaded anywhere, also when hovering in parameters.
--        my_ctld:AddCTLDZone("Dropzone",CTLD.CargoZoneType.DROP,SMOKECOLOR.Red,true,true)
--        
--        -- Add two zones of type MOVE. Dropped troops and vehicles will move to the nearest one. See options.
--        -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
--        my_ctld:AddCTLDZone("Movezone",CTLD.CargoZoneType.MOVE,SMOKECOLOR.Orange,false,false)
--        
--        my_ctld:AddCTLDZone("Movezone2",CTLD.CargoZoneType.MOVE,SMOKECOLOR.White,true,true)
--        
--        -- Add a zone of type SHIP to our setup. Players can load troops and crates from this ship
--        -- "Tarawa" is the unitname (callsign) of the ship from the ME. Players can load, if they are inside the zone.
--        -- The ship is 240 meters long and 20 meters wide.
--        -- Note that you need to adjust the max hover height to deck height plus 5 meters or so for loading to work.
--        -- When the ship is moving, forcing hoverload might not be a good idea.
--        my_ctld:AddCTLDZone("Tarawa",CTLD.CargoZoneType.SHIP,SMOKECOLOR.Blue,true,true,240,20)
-- 
-- ## 2. Options
-- 
-- The following options are available (with their defaults). Only set the ones you want changed:
--
--          my_ctld.useprefix = true -- (DO NOT SWITCH THIS OFF UNLESS YOU KNOW WHAT YOU ARE DOING!) Adjust **before** starting CTLD. If set to false, *all* choppers of the coalition side will be enabled for CTLD.
--          my_ctld.CrateDistance = 35 -- List and Load crates in this radius only.
--          my_ctld.dropcratesanywhere = false -- Option to allow crates to be dropped anywhere.
--          my_ctld.maximumHoverHeight = 15 -- Hover max this high to load.
--          my_ctld.minimumHoverHeight = 4 -- Hover min this low to load.
--          my_ctld.forcehoverload = true -- Crates (not: troops) can **only** be loaded while hovering.
--          my_ctld.hoverautoloading = true -- Crates in CrateDistance in a LOAD zone will be loaded automatically if space allows.
--          my_ctld.smokedistance = 2000 -- Smoke or flares can be request for zones this far away (in meters).
--          my_ctld.movetroopstowpzone = true -- Troops and vehicles will move to the nearest MOVE zone...
--          my_ctld.movetroopsdistance = 5000 -- .. but only if this far away (in meters)
--          my_ctld.smokedistance = 2000 -- Only smoke or flare zones if requesting player unit is this far away (in meters)
--          my_ctld.suppressmessages = false -- Set to true if you want to script your own messages.
--          my_ctld.repairtime = 300 -- Number of seconds it takes to repair a unit.
--          my_ctld.cratecountry = country.id.GERMANY -- ID of crates. Will default to country.id.RUSSIA for RED coalition setups.
--          my_ctld.allowcratepickupagain = true  -- allow re-pickup crates that were dropped.
--          my_ctld.enableslingload = false -- allow cargos to be slingloaded - might not work for all cargo types
-- 
-- ## 2.1 User functions
-- 
-- ### 2.1.1 Adjust or add chopper unit-type capabilities
--  
-- Use this function to adjust what a heli type can or cannot do:
-- 
--        -- E.g. update unit capabilities for testing. Please stay realistic in your mission design.
--        -- Make a Gazelle into a heavy truck, this type can load both crates and troops and eight of each type:
--        my_ctld:UnitCapabilities("SA342L", true, true, 8, 8, 12)
--        
--        -- Default unit type capabilities are:
--    
--        ["SA342Mistral"] = {type="SA342Mistral", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 12},
--        ["SA342L"] = {type="SA342L", crates=false, troops=true, cratelimit = 0, trooplimit = 2, length = 12},
--        ["SA342M"] = {type="SA342M", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 12},
--        ["SA342Minigun"] = {type="SA342Minigun", crates=false, troops=true, cratelimit = 0, trooplimit = 2, length = 12},
--        ["UH-1H"] = {type="UH-1H", crates=true, troops=true, cratelimit = 1, trooplimit = 8, length = 15},
--        ["Mi-8MT"] = {type="Mi-8MTV2", crates=true, troops=true, cratelimit = 2, trooplimit = 12, length = 15},
--        ["Ka-50"] = {type="Ka-50", crates=false, troops=false, cratelimit = 0, trooplimit = 0, length = 15},
--        ["Mi-24P"] = {type="Mi-24P", crates=true, troops=true, cratelimit = 2, trooplimit = 8, length = 18},
--        ["Mi-24V"] = {type="Mi-24V", crates=true, troops=true, cratelimit = 2, trooplimit = 8, length = 18},
--        ["Hercules"] = {type="Hercules", crates=true, troops=true, cratelimit = 7, trooplimit = 64, length = 25},
--
--        
-- ### 2.1.2 Activate and deactivate zones
-- 
-- Activate a zone:
-- 
--        -- Activate zone called Name of type #CTLD.CargoZoneType ZoneType:
--        my_ctld:ActivateZone(Name,CTLD.CargoZoneType.MOVE)
-- 
-- Deactivate a zone:
-- 
--        -- Deactivate zone called Name of type #CTLD.CargoZoneType ZoneType:
--        my_ctld:DeactivateZone(Name,CTLD.CargoZoneType.DROP)
-- 
-- ## 2.1.3 Limit and manage available resources
--  
--  When adding generic cargo types, you can effectively limit how many units can be dropped/build by the players, e.g.
--  
--              -- if you want to limit your stock, add a number (here: 10) as parameter after weight. No parameter / nil means unlimited stock.
--              my_ctld:AddCratesCargo("Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,2,2775,10)
--  
--  You can manually add or remove the available stock like so:
--            
--              -- Crates
--              my_ctld:AddStockCrates("Humvee", 2)
--              my_ctld:RemoveStockCrates("Humvee", 2)
--              
--              -- Troops
--              my_ctld:AddStockTroops("Anti-Air", 2)
--              my_ctld:RemoveStockTroops("Anti-Air", 2)
--  
--  Notes:
--  Troops dropped back into a LOAD zone will effectively be added to the stock. Crates lost in e.g. a heli crash are just that - lost.
-- 
-- ## 3. Events
--
--  The class comes with a number of FSM-based events that missions designers can use to shape their mission.
--  These are:
-- 
-- ## 3.1 OnAfterTroopsPickedUp
-- 
--   This function is called when a player has loaded Troops:
--
--        function my_ctld:OnAfterTroopsPickedUp(From, Event, To, Group, Unit, Cargo)
--          ... your code here ...
--        end
-- 
-- ## 3.2 OnAfterCratesPickedUp
-- 
--    This function is called when a player has picked up crates:
--
--        function my_ctld:OnAfterCratesPickedUp(From, Event, To, Group, Unit, Cargo)
--          ... your code here ...
--        end
--  
-- ## 3.3 OnAfterTroopsDeployed
--  
--    This function is called when a player has deployed troops into the field:
--
--        function my_ctld:OnAfterTroopsDeployed(From, Event, To, Group, Unit, Troops)
--          ... your code here ...
--        end
--        
-- ## 3.4 OnAfterTroopsExtracted
--  
--    This function is called when a player has re-boarded already deployed troops from the field:
--
--        function my_ctld:OnAfterTroopsExtracted(From, Event, To, Group, Unit, Troops)
--          ... your code here ...
--        end
--  
-- ## 3.5 OnAfterCratesDropped
--  
--    This function is called when a player has deployed crates to a DROP zone:
--
--        function my_ctld:OnAfterCratesDropped(From, Event, To, Group, Unit, Cargotable)
--          ... your code here ...
--        end
--  
-- ## 3.6 OnAfterCratesBuild, OnAfterCratesRepaired
--  
--    This function is called when a player has build a vehicle or FOB:
--
--        function my_ctld:OnAfterCratesBuild(From, Event, To, Group, Unit, Vehicle)
--          ... your code here ...
--        end
--        
--        function my_ctld:OnAfterCratesRepaired(From, Event, To, Group, Unit, Vehicle)
--          ... your code here ...
--        end
 --  
-- ## 3.7 A simple SCORING example:
--  
--    To award player with points, using the SCORING Class (SCORING: my_Scoring, CTLD: CTLD_Cargotransport)
--
--        function CTLD_Cargotransport:OnAfterCratesDropped(From, Event, To, Group, Unit, Cargotable)
--            local points = 10
--            if Unit then
--              local PlayerName = Unit:GetPlayerName()
--              my_scoring:_AddPlayerFromUnit( Unit )
--              my_scoring:AddGoalScore(Unit, "CTLD", string.format("Pilot %s has been awarded %d points for transporting cargo crates!", PlayerName, points), points)
--            end
--        end
--        
--        function CTLD_Cargotransport:OnAfterCratesBuild(From, Event, To, Group, Unit, Vehicle)
--          local points = 5
--          if Unit then
  --          local PlayerName = Unit:GetPlayerName()
  --          my_scoring:_AddPlayerFromUnit( Unit )
  --          my_scoring:AddGoalScore(Unit, "CTLD", string.format("Pilot %s has been awarded %d points for the construction of Units!", PlayerName, points), points)
--          end
--         end
--  
-- ## 4. F10 Menu structure
-- 
-- CTLD management menu is under the F10 top menu and called "CTLD"
-- 
-- ## 4.1 Manage Crates
-- 
-- Use this entry to get, load, list nearby, drop, build and repair crates. Also @see options.
-- 
-- ## 4.2 Manage Troops
-- 
-- Use this entry to load, drop and extract troops. NOTE - with extract you can only load troops from the field that were deployed prior. 
-- Currently limited CTLD_CARGO troops, which are build from **one** template. Also, this will heal/complete your units as they are respawned.
-- 
-- ## 4.3 List boarded cargo
-- 
-- Lists what you have loaded. Shows load capabilities for number of crates and number of seats for troops.
-- 
-- ## 4.4 Smoke & Flare zones nearby
-- 
-- Does what it says.
-- 
-- ## 4.5 List active zone beacons
-- 
-- Lists active radio beacons for all zones, where zones are both active and have a beacon. @see `CTLD:AddCTLDZone()`
-- 
-- ## 4.6 Show hover parameters
-- 
-- Lists hover parameters and indicates if these are curently fulfilled. Also @see options on hover heights.
-- 
-- ## 4.7 List Inventory
-- 
-- Lists invetory of available units to drop or build.
-- 
-- ## 5. Support for Hercules mod by Anubis
-- 
-- Basic support for the Hercules mod By Anubis has been build into CTLD. Currently this does **not** cover objects and troops which can
-- be loaded from the Rearm/Refuel menu, i.e. you can drop them into the field, but you cannot use them in functions scripted with this class.
--
--              local my_ctld = CTLD:New(coalition.side.BLUE,{"Helicargo", "Hercules"},"Lufttransportbrigade I")
-- 
-- Enable these options for Hercules support:
--  
--              my_ctld.enableHercules = true
--              my_ctld.HercMinAngels = 155 -- for troop/cargo drop via chute in meters, ca 470 ft
--              my_ctld.HercMaxAngels = 2000 -- for troop/cargo drop via chute in meters, ca 6000 ft
--              my_ctld.HercMaxSpeed = 77 -- 77mps or 270kph or 150kn
-- 
-- Also, the following options need to be set to `true`:
-- 
--              my_ctld.useprefix = true -- this is true by default and MUST BE ON. 
-- 
-- Standard transport capabilities as per the real Hercules are:
-- 
--               ["Hercules"] = {type="Hercules", crates=true, troops=true, cratelimit = 7, trooplimit = 64}, -- 19t cargo, 64 paratroopers
--  
-- ## 6. Save and load back units - persistance
-- 
-- You can save and later load back units dropped or build to make your mission persistent.
-- For this to work, you need to de-sanitize **io** and **lfs** in your MissionScripting.lua, which is located in your DCS installtion folder under Scripts.
-- There is a risk involved in doing that; if you do not know what that means, this is possibly not for you.
-- 
-- Use the following options to manage your saves:
-- 
--              my_ctld.enableLoadSave = true -- allow auto-saving and loading of files
--              my_ctld.saveinterval = 600 -- save every 10 minutes
--              my_ctld.filename = "missionsave.csv" -- example filename
--              my_ctld.filepath = "C:\\Users\\myname\\Saved Games\\DCS\Missions\\MyMission" -- example path
--              my_ctld.eventoninject = true -- fire OnAfterCratesBuild and OnAfterTroopsDeployed events when loading (uses Inject functions)
--  
--  Then use an initial load at the beginning of your mission:
--  
--            my_ctld:__Load(10)
--            
-- **Caveat:**
-- If you use units build by multiple templates, they will effectively double on loading. Dropped crates are not saved. Current stock is not saved.
--  
-- @field #CTLD
CTLD = {
  ClassName       = "CTLD",
  verbose         =     0,
  lid             =   "",
  coalition       = 1,
  coalitiontxt    = "blue",
  PilotGroups = {}, -- #GROUP_SET of heli pilots
  CtldUnits = {},   -- Table of helicopter #GROUPs
  FreeVHFFrequencies = {}, -- Table of VHF
  FreeUHFFrequencies = {}, -- Table of UHF
  FreeFMFrequencies = {}, -- Table of FM
  CargoCounter = 0,
  wpZones = {},
  Cargo_Troops = {}, -- generic troops objects
  Cargo_Crates = {}, -- generic crate objects
  Loaded_Cargo = {}, -- cargo aboard units
  Spawned_Crates = {}, -- Holds objects for crates spawned generally
  Spawned_Cargo = {}, -- Binds together spawned_crates and their CTLD_CARGO objects
  CrateDistance = 35, -- list crates in this radius
  debug = false,
  wpZones = {},
  dropOffZones = {},
  pickupZones  = {},
}

------------------------------
-- DONE: Zone Checks
-- DONE: TEST Hover load and unload
-- DONE: Crate unload
-- DONE: Hover (auto-)load
-- DONE: (More) Housekeeping
-- DONE: Troops running to WP Zone
-- DONE: Zone Radio Beacons
-- DONE: Stats Running
-- DONE: Added support for Hercules
-- TODO: Possibly - either/or loading crates and troops
-- DONE: Make inject respect existing cargo types
-- TODO: Drop beacons or flares/smoke
-- DONE: Add statics as cargo
-- DONE: List cargo in stock
-- DONE: Limit of troops, crates buildable?
-- DONE: Allow saving of Troops & Vehicles
------------------------------

--- Radio Beacons
-- @type CTLD.ZoneBeacon
-- @field #string name -- Name of zone for the coordinate
-- @field #number frequency -- in mHz
-- @field #number modulation -- i.e.radio.modulation.FM or radio.modulation.AM

--- Zone Info.
-- @type CTLD.CargoZone
-- @field #string name Name of Zone.
-- @field #string color Smoke color for zone, e.g. SMOKECOLOR.Red.
-- @field #boolean active Active or not.
-- @field #string type Type of zone, i.e. load,drop,move,ship
-- @field #boolean hasbeacon Create and run radio beacons if active.
-- @field #table fmbeacon Beacon info as #CTLD.ZoneBeacon
-- @field #table uhfbeacon Beacon info as #CTLD.ZoneBeacon
-- @field #table vhfbeacon Beacon info as #CTLD.ZoneBeacon
-- @field #number shiplength For ships - length of ship
-- @field #number shipwidth For ships - width of ship

--- Zone Type Info.
-- @type CTLD.CargoZoneType
CTLD.CargoZoneType = {
  LOAD = "load",
  DROP = "drop",
  MOVE = "move",
  SHIP = "ship",
}

--- Buildable table info.
-- @type CTLD.Buildable
-- @field #string Name Name of the object.
-- @field #number Required Required crates.
-- @field #number Found Found crates.
-- @field #table Template Template names for this build.
-- @field #boolean CanBuild Is buildable or not.
-- @field #CTLD_CARGO.Enum Type Type enumerator (for moves).

--- Unit capabilities.
-- @type CTLD.UnitCapabilities
-- @field #string type Unit type.
-- @field #boolean crates Can transport crate.
-- @field #boolean troops Can transport troops.
-- @field #number cratelimit Number of crates transportable.
-- @field #number trooplimit Number of troop units transportable.
CTLD.UnitTypes = {
    ["SA342Mistral"] = {type="SA342Mistral", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 12},
    ["SA342L"] = {type="SA342L", crates=false, troops=true, cratelimit = 0, trooplimit = 2, length = 12},
    ["SA342M"] = {type="SA342M", crates=false, troops=true, cratelimit = 0, trooplimit = 4, length = 12},
    ["SA342Minigun"] = {type="SA342Minigun", crates=false, troops=true, cratelimit = 0, trooplimit = 2, length = 12},
    ["UH-1H"] = {type="UH-1H", crates=true, troops=true, cratelimit = 1, trooplimit = 8, length = 15},
    ["Mi-8MTV2"] = {type="Mi-8MTV2", crates=true, troops=true, cratelimit = 2, trooplimit = 12, length = 15},
    ["Mi-8MT"] = {type="Mi-8MTV2", crates=true, troops=true, cratelimit = 2, trooplimit = 12, length = 15},
    ["Ka-50"] = {type="Ka-50", crates=false, troops=false, cratelimit = 0, trooplimit = 0, length = 15},
    ["Mi-24P"] = {type="Mi-24P", crates=true, troops=true, cratelimit = 2, trooplimit = 8, length = 18},
    ["Mi-24V"] = {type="Mi-24V", crates=true, troops=true, cratelimit = 2, trooplimit = 8, length = 18},
    ["Hercules"] = {type="Hercules", crates=true, troops=true, cratelimit = 7, trooplimit = 64, length = 25}, -- 19t cargo, 64 paratroopers. 
    --Actually it's longer, but the center coord is off-center of the model.
}

--- CTLD class version.
-- @field #string version
CTLD.version="0.2.3"

--- Instantiate a new CTLD.
-- @param #CTLD self
-- @param #string Coalition Coalition of this CTLD. I.e. coalition.side.BLUE or coalition.side.RED or coalition.side.NEUTRAL
-- @param #table Prefixes Table of pilot prefixes.
-- @param #string Alias Alias of this CTLD for logging.
-- @return #CTLD self
function CTLD:New(Coalition, Prefixes, Alias)
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #CTLD
  
  BASE:T({Coalition, Prefixes, Alias})
  
  --set Coalition
  if Coalition and type(Coalition)=="string" then
    if Coalition=="blue" then
      self.coalition=coalition.side.BLUE
      self.coalitiontxt = Coalition
    elseif Coalition=="red" then
      self.coalition=coalition.side.RED
      self.coalitiontxt = Coalition
    elseif Coalition=="neutral" then
      self.coalition=coalition.side.NEUTRAL
      self.coalitiontxt = Coalition
    else
      self:E("ERROR: Unknown coalition in CTLD!")
    end
  else
    self.coalition = Coalition
    self.coalitiontxt = string.lower(UTILS.GetCoalitionName(self.coalition))
  end
  
  -- Set alias.
  if Alias then
    self.alias=tostring(Alias)
  else
    self.alias="UNHCR"  
    if self.coalition then
      if self.coalition==coalition.side.RED then
        self.alias="Red CTLD"
      elseif self.coalition==coalition.side.BLUE then
        self.alias="Blue CTLD"
      end
    end
  end
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.alias, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event        -->      To State
  self:AddTransition("Stopped",       "Start",               "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",              "*")           -- CTLD status update.
  self:AddTransition("*",             "TroopsPickedUp",      "*")           -- CTLD pickup  event. 
  self:AddTransition("*",             "TroopsExtracted",     "*")           -- CTLD extract  event. 
  self:AddTransition("*",             "CratesPickedUp",      "*")           -- CTLD pickup  event.  
  self:AddTransition("*",             "TroopsDeployed",      "*")           -- CTLD deploy  event. 
  self:AddTransition("*",             "TroopsRTB",           "*")           -- CTLD deploy  event.   
  self:AddTransition("*",             "CratesDropped",       "*")           -- CTLD deploy  event.  
  self:AddTransition("*",             "CratesBuild",         "*")           -- CTLD build  event.
  self:AddTransition("*",             "CratesRepaired",      "*")           -- CTLD repair  event.
  self:AddTransition("*",             "Load",                "*")           -- CTLD load  event.  
  self:AddTransition("*",             "Save",                "*")           -- CTLD save  event.      
  self:AddTransition("*",             "Stop",                "Stopped")     -- Stop FSM.
  
  -- tables
  self.PilotGroups ={}
  self.CtldUnits = {}
  
  -- Beacons
  self.FreeVHFFrequencies = {}
  self.FreeUHFFrequencies = {}
  self.FreeFMFrequencies = {}
  self.UsedVHFFrequencies = {}
  self.UsedUHFFrequencies = {}
  self.UsedFMFrequencies = {}
  
  -- radio beacons
  self.RadioSound = "beacon.ogg"
  
  -- zones stuff
  self.pickupZones  = {}
  self.dropOffZones = {}
  self.wpZones = {}
  self.shipZones = {}
  
  -- Cargo
  self.Cargo_Crates = {}
  self.Cargo_Troops = {}
  self.Cargo_Statics = {}
  self.Loaded_Cargo = {}
  self.Spawned_Crates = {}
  self.Spawned_Cargo = {}
  self.MenusDone = {}
  self.DroppedTroops = {}
  self.DroppedCrates = {}
  self.CargoCounter = 0
  self.CrateCounter = 0
  self.TroopCounter = 0
  
  -- added engineering
  self.Engineers = 0 -- #number use as counter
  self.EngineersInField = {} -- #table holds #CTLD_ENGINEERING objects
  self.EngineerSearch = 2000 -- #number search distance for crates to build or repair
  
  -- setup
  self.CrateDistance = 35 -- list/load crates in this radius
  self.ExtractFactor = 3.33 -- factor for troops extraction, i.e. CrateDistance * Extractfactor
  self.prefixes = Prefixes or {"Cargoheli"}
  --self.I({prefixes = self.prefixes})
  self.useprefix = true
  
  self.maximumHoverHeight = 15
  self.minimumHoverHeight = 4
  self.forcehoverload = true
  self.hoverautoloading = true
  self.dropcratesanywhere = false -- #1570
  
  self.smokedistance = 2000
  self.movetroopstowpzone = true
  self.movetroopsdistance = 5000
  
  -- added support Hercules Mod
  self.enableHercules = false
  self.HercMinAngels = 165 -- for troop/cargo drop via chute
  self.HercMaxAngels = 2000 -- for troop/cargo drop via chute
  self.HercMaxSpeed = 77 -- 280 kph or 150kn eq 77 mps
  
  -- message suppression
  self.suppressmessages = false
  
  -- time to repair a unit/group
  self.repairtime = 300
  
  -- place spawned crates in front of aircraft
  self.placeCratesAhead = false
  
  -- country of crates spawned
  self.cratecountry = country.id.GERMANY
  
  if self.coalition == coalition.side.RED then
     self.cratecountry = country.id.RUSSIA
  end
  
  -- load and save dropped TROOPS
  self.enableLoadSave = false
  self.filepath = nil
  self.saveinterval = 600
  self.eventoninject = true
  
  local AliaS = string.gsub(self.alias," ","_")
  self.filename = string.format("CTLD_%s_Persist.csv",AliaS)
  
  -- allow re-pickup crates
  self.allowcratepickupagain = true
  
  -- slingload
  self.enableslingload = false
  
  for i=1,100 do
    math.random()
  end
  
  self:_GenerateVHFrequencies()
  self:_GenerateUHFrequencies()
  self:_GenerateFMFrequencies()
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------
  
    --- Triggers the FSM event "Start". Starts the CTLD. Initializes parameters and starts event handlers.
  -- @function [parent=#CTLD] Start
  -- @param #CTLD self

  --- Triggers the FSM event "Start" after a delay. Starts the CTLD. Initializes parameters and starts event handlers.
  -- @function [parent=#CTLD] __Start
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the CTLD and all its event handlers.
  -- @param #CTLD self

  --- Triggers the FSM event "Stop" after a delay. Stops the CTLD and all its event handlers.
  -- @function [parent=#CTLD] __Stop
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#CTLD] Status
  -- @param #CTLD self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#CTLD] __Status
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.
  
  --- Triggers the FSM event "Load".
  -- @function [parent=#CTLD] Load
  -- @param #CTLD self

  --- Triggers the FSM event "Load" after a delay.
  -- @function [parent=#CTLD] __Load
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.
  
  --- Triggers the FSM event "Save".
  -- @function [parent=#CTLD] Load
  -- @param #CTLD self

  --- Triggers the FSM event "Save" after a delay.
  -- @function [parent=#CTLD] __Save
  -- @param #CTLD self
  -- @param #number delay Delay in seconds.
  
  --- FSM Function OnAfterTroopsPickedUp.
  -- @function [parent=#CTLD] OnAfterTroopsPickedUp
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo troops.
  -- @return #CTLD self
  
  --- FSM Function OnAfterTroopsExtracted.
  -- @function [parent=#CTLD] OnAfterTroopsExtracted
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo troops.
  -- @return #CTLD self
    
  --- FSM Function OnAfterCratesPickedUp.
  -- @function [parent=#CTLD] OnAfterCratesPickedUp
  -- @param #CTLD self
  -- @param #string From State .
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate.
  -- @return #CTLD self
  
   --- FSM Function OnAfterTroopsDeployed.
  -- @function [parent=#CTLD] OnAfterTroopsDeployed
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Troops Troops #GROUP Object.
  -- @return #CTLD self
  
  --- FSM Function OnAfterCratesDropped.
  -- @function [parent=#CTLD] OnAfterCratesDropped
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO objects dropped.
  -- @return #CTLD self
  
  --- FSM Function OnAfterCratesBuild.
  -- @function [parent=#CTLD] OnAfterCratesBuild
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Vehicle The #GROUP object of the vehicle or FOB build.
  -- @return #CTLD self

  --- FSM Function OnAfterCratesRepaired.
  -- @function [parent=#CTLD] OnAfterCratesRepaired
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Vehicle The #GROUP object of the vehicle or FOB repaired.
  -- @return #CTLD self
    
  --- FSM Function OnAfterTroopsRTB.
  -- @function [parent=#CTLD] OnAfterTroopsRTB
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  
  --- FSM Function OnAfterLoad.
  -- @function [parent=#CTLD] OnAfterLoad
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is located. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for loading. Default is "CTLD_<alias>_Persist.csv".
  
  --- FSM Function OnAfterSave.
  -- @function [parent=#CTLD] OnAfterSave
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is saved. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for saving. Default is "CTLD_<alias>_Persist.csv".
  
  return self
end

------------------------------------------------------------------- 
-- Helper and User Functions
------------------------------------------------------------------- 

--- (Internal) Function to get capabilities of a chopper
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit The unit
-- @return #table Capabilities Table of caps
function CTLD:_GetUnitCapabilities(Unit)
  self:T(self.lid .. " _GetUnitCapabilities")
  local _unit = Unit -- Wrapper.Unit#UNIT
  local unittype = _unit:GetTypeName()
  local capabilities = self.UnitTypes[unittype] -- #CTLD.UnitCapabilities
  if not capabilities or capabilities == {} then
    -- e.g. ["Ka-50"] = {type="Ka-50", crates=false, troops=false, cratelimit = 0, trooplimit = 0},
    capabilities = {}
    capabilities.troops = false
    capabilities.crates = false
    capabilities.cratelimit = 0
    capabilities.trooplimit = 0
    capabilities.type = "generic"
    capabilities.length = 20
  end
  return capabilities
end


--- (Internal) Function to generate valid UHF Frequencies
-- @param #CTLD self
function CTLD:_GenerateUHFrequencies()
  self:T(self.lid .. " _GenerateUHFrequencies")
    self.FreeUHFFrequencies = {}
    self.FreeUHFFrequencies = UTILS.GenerateUHFrequencies()    
    return self
end

--- (Internal) Function to generate valid FM Frequencies
-- @param #CTLD self
function CTLD:_GenerateFMFrequencies()
  self:T(self.lid .. " _GenerateFMrequencies")
    self.FreeFMFrequencies = {}
    self.FreeFMFrequencies = UTILS.GenerateFMFrequencies()
    return self
end

--- (Internal) Populate table with available VHF beacon frequencies.
-- @param #CTLD self
function CTLD:_GenerateVHFrequencies()
  self:T(self.lid .. " _GenerateVHFrequencies")
  self.FreeVHFFrequencies = {}
  self.UsedVHFFrequencies = {}
  self.FreeVHFFrequencies = UTILS.GenerateVHFrequencies()
  return self
end

--- (Internal) Event handler function
-- @param #CTLD self
-- @param Core.Event#EVENTDATA EventData
function CTLD:_EventHandler(EventData)
  self:T(string.format("%s Event = %d",self.lid, EventData.id))
  local event = EventData -- Core.Event#EVENTDATA
  if event.id == EVENTS.PlayerEnterAircraft or event.id == EVENTS.PlayerEnterUnit then
    local _coalition = event.IniCoalition
    if _coalition ~= self.coalition then
        return --ignore!
    end
    -- check is Helicopter
    local _unit = event.IniUnit
    local _group = event.IniGroup
    if _unit:IsHelicopter() or _group:IsHelicopter() then
      local unitname = event.IniUnitName or "none"
      self.Loaded_Cargo[unitname] = nil
      self:_RefreshF10Menus()
    end
    -- Herc support
    --self:T_unit:GetTypeName())
    if _unit:GetTypeName() == "Hercules" and self.enableHercules then
      self.Loaded_Cargo[unitname] = nil
      self:_RefreshF10Menus()
    end
    return
  elseif event.id == EVENTS.PlayerLeaveUnit then
    -- remove from pilot table
    local unitname = event.IniUnitName or "none"
    self.CtldUnits[unitname] = nil
    self.Loaded_Cargo[unitname] = nil
  end
  return self
end

--- (Internal) Function to message a group.
-- @param #CTLD self
-- @param #string Text The text to display.
-- @param #number Time Number of seconds to display the message.
-- @param #boolean Clearscreen Clear screen or not.
-- @param Wrapper.Group#GROUP Group The group receiving the message.
function CTLD:_SendMessage(Text, Time, Clearscreen, Group)
  self:T(self.lid .. " _SendMessage")
  if not self.suppressmessages then
    local m = MESSAGE:New(Text,Time,"CTLD",Clearscreen):ToGroup(Group)
  end 
  return self
end

--- (Internal) Function to load troops into a heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #CTLD_CARGO Cargotype
function CTLD:_LoadTroops(Group, Unit, Cargotype)
  self:T(self.lid .. " _LoadTroops")
  -- check if we have stock
  local instock = Cargotype:GetStock()
  local cgoname = Cargotype:GetName()
  local cgotype = Cargotype:GetType()
  if type(instock) == "number" and tonumber(instock) <= 0 and tonumber(instock) ~= -1 then
    -- nothing left over
    self:_SendMessage(string.format("Sorry, all %s are gone!", cgoname), 10, false, Group)
    return self
  end
  -- landed or hovering over load zone?
  local grounded = not self:IsUnitInAir(Unit)
  local hoverload = self:CanHoverLoad(Unit)
  -- check if we are in LOAD zone
  local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
  if not inzone then
    inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.SHIP)
  end
  if not inzone then
    self:_SendMessage("You are not close enough to a logistics zone!", 10, false, Group)
    if not self.debug then return self end
  elseif not grounded and not hoverload then
    self:_SendMessage("You need to land or hover in position to load!", 10, false, Group)
    if not self.debug then return self end
  end
  -- load troops into heli
  local group = Group -- Wrapper.Group#GROUP
  local unit = Unit -- Wrapper.Unit#UNIT
  local unitname = unit:GetName()
  local cargotype = Cargotype -- #CTLD_CARGO
  local cratename = cargotype:GetName() -- #string
  -- see if this heli can load troops
  local unittype = unit:GetTypeName()
  local capabilities = self:_GetUnitCapabilities(Unit)
  local cantroops = capabilities.troops -- #boolean
  local trooplimit = capabilities.trooplimit -- #number
  local troopsize = cargotype:GetCratesNeeded() -- #number
  -- have we loaded stuff already?
  local numberonboard = 0
  local loaded = {}
  if self.Loaded_Cargo[unitname] then
    loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
    numberonboard = loaded.Troopsloaded or 0
  else
    loaded = {} -- #CTLD.LoadedCargo
    loaded.Troopsloaded = 0
    loaded.Cratesloaded = 0
    loaded.Cargo = {}
  end
  if troopsize + numberonboard > trooplimit then
    self:_SendMessage("Sorry, we\'re crammed already!", 10, false, Group)
    return
  else
    self.CargoCounter = self.CargoCounter + 1
    local loadcargotype = CTLD_CARGO:New(self.CargoCounter, Cargotype.Name, Cargotype.Templates, cgotype, true, true, Cargotype.CratesNeeded,nil,nil,Cargotype.PerCrateMass)
    self:T({cargotype=loadcargotype})
    loaded.Troopsloaded = loaded.Troopsloaded + troopsize
    table.insert(loaded.Cargo,loadcargotype)
    self.Loaded_Cargo[unitname] = loaded
    self:_SendMessage("Troops boarded!", 10, false, Group)
    self:__TroopsPickedUp(1,Group, Unit, Cargotype)
    self:_UpdateUnitCargoMass(Unit)
    Cargotype:RemoveStock()
  end
  return self
end

function CTLD:_FindRepairNearby(Group, Unit, Repairtype)
    self:T(self.lid .. " _FindRepairNearby")
    local unitcoord = Unit:GetCoordinate()
    
    -- find nearest group of deployed groups
    local nearestGroup = nil
    local nearestGroupIndex = -1
    local nearestDistance = 10000
    for k,v in pairs(self.DroppedTroops) do
      local distance = self:_GetDistance(v:GetCoordinate(),unitcoord)
      local unit = v:GetUnit(1) -- Wrapper.Unit#UNIT
      local desc = unit:GetDesc() or nil
      --self:I({desc = desc.attributes})
      if distance < nearestDistance and distance ~= -1 and not desc.attributes.Infantry then
        nearestGroup = v
        nearestGroupIndex = k
        nearestDistance = distance
      end
    end

    -- found one and matching distance?  
    if nearestGroup == nil or nearestDistance > self.EngineerSearch then
      self:_SendMessage("No unit close enough to repair!", 10, false, Group)
      return nil, nil
    end
    
    local groupname = nearestGroup:GetName()
    
    -- helper to find matching template
    local function matchstring(String,Table)
      local match = false
      if type(Table) == "table" then
        for _,_name in pairs (Table) do
          if string.find(String,_name) then
            match = true
            break
          end
        end
      else
        if type(String) == "string" then
          if string.find(String,Table) then match = true end
        end
      end 
      return match
    end
    
    -- walk through generics and find matching type
    local Cargotype = nil
    for k,v in pairs(self.Cargo_Crates) do
      --self:I({groupname,v.Templates})
      if matchstring(groupname,v.Templates) and matchstring(groupname,Repairtype) then
        Cargotype = v -- #CTLD_CARGO
        break
      end
    end

    if Cargotype == nil then
      --self:_SendMessage("Can't find a matching group for " .. Repairtype, 10, false, Group)
      return nil, nil
    else
      return nearestGroup, Cargotype
    end
    
end

--- (Internal) Function to repair an object.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #table Crates Table of #CTLD_CARGO objects near the unit.
-- @param #CTLD.Buildable Build Table build object.
-- @param #number Number Number of objects in Crates (found) to limit search.
-- @param #boolean Engineering If true it is an Engineering repair.
function CTLD:_RepairObjectFromCrates(Group,Unit,Crates,Build,Number,Engineering)
  self:T(self.lid .. " _RepairObjectFromCrates")
  local build = Build -- -- #CTLD.Buildable
  --self:I({Build=Build})
  local Repairtype = build.Template -- #string
  local NearestGroup, CargoType = self:_FindRepairNearby(Group,Unit,Repairtype) -- Wrapper.Group#GROUP, #CTLD_CARGO
  --self:I({Repairtype=Repairtype, CargoType=CargoType, NearestGroup=NearestGroup})
  if NearestGroup ~= nil then
    if self.repairtime < 2 then self.repairtime = 30 end -- noob catch
    if not Engineering then
      self:_SendMessage(string.format("Repair started using %s taking %d secs", build.Name, self.repairtime), 10, false, Group)
    end
    -- now we can build ....
    --NearestGroup:Destroy(false)
    local name = CargoType:GetName()
    local required = CargoType:GetCratesNeeded()
    local template = CargoType:GetTemplates()
    local ctype = CargoType:GetType()
    local object = {} -- #CTLD.Buildable
    object.Name = CargoType:GetName()
    object.Required = required
    object.Found = required
    object.Template = template
    object.CanBuild = true
    object.Type = ctype -- #CTLD_CARGO.Enum
    self:_CleanUpCrates(Crates,Build,Number)
    local desttimer = TIMER:New(function() NearestGroup:Destroy(false) end, self)
    desttimer:Start(self.repairtime - 1)
    local buildtimer = TIMER:New(self._BuildObjectFromCrates,self,Group,Unit,object,true,NearestGroup:GetCoordinate())
    buildtimer:Start(self.repairtime)
    --self:_BuildObjectFromCrates(Group,Unit,object)
  else
    if not Engineering then
      self:_SendMessage("Can't repair this unit with " .. build.Name, 10, false, Group)
    else
      self:T("Can't repair this unit with " .. build.Name)
    end
  end
  return self
end

  --- (Internal) Function to extract (load from the field) troops into a heli.
  -- @param #CTLD self
  -- @param Wrapper.Group#GROUP Group
  -- @param Wrapper.Unit#UNIT Unit
  function CTLD:_ExtractTroops(Group, Unit) -- #1574 thanks to @bbirchnz!
    self:T(self.lid .. " _ExtractTroops")
    -- landed or hovering over load zone?
    local grounded = not self:IsUnitInAir(Unit)
    local hoverload = self:CanHoverLoad(Unit)
    
    if not grounded and not hoverload then
      self:_SendMessage("You need to land or hover in position to load!", 10, false, Group)
      if not self.debug then return self end
    end
    -- load troops into heli
    local unit = Unit -- Wrapper.Unit#UNIT
    local unitname = unit:GetName()
    -- see if this heli can load troops
    local unittype = unit:GetTypeName()
    local capabilities = self:_GetUnitCapabilities(Unit)
    local cantroops = capabilities.troops -- #boolean
    local trooplimit = capabilities.trooplimit -- #number
    local unitcoord = unit:GetCoordinate()
    
    -- find nearest group of deployed troops
    local nearestGroup = nil
    local nearestGroupIndex = -1
    local nearestDistance = 10000000
    local nearestList = {}
    local distancekeys = {}
    local extractdistance = self.CrateDistance * self.ExtractFactor
    for k,v in pairs(self.DroppedTroops) do
      local distance = self:_GetDistance(v:GetCoordinate(),unitcoord)
      if distance <= extractdistance and distance ~= -1 then
        nearestGroup = v
        nearestGroupIndex = k
        nearestDistance = distance
        table.insert(nearestList, math.floor(distance), v)
        distancekeys[#distancekeys+1] = math.floor(distance)
      end
    end
    
    if nearestGroup == nil or nearestDistance > extractdistance then
      self:_SendMessage("No units close enough to extract!", 10, false, Group)
      return self
    end
    
    -- sort reference keys
    table.sort(distancekeys)
    
    local secondarygroups = {}
    
    for i=1,#distancekeys do
      local nearestGroup = nearestList[distancekeys[i]]
          -- find matching cargo type
      local groupType = string.match(nearestGroup:GetName(), "(.+)-(.+)$")
      local Cargotype = nil
      for k,v in pairs(self.Cargo_Troops) do
        local comparison = ""
        if type(v.Templates) == "string" then comparison = v.Templates else comparison = v.Templates[1] end
        if comparison == groupType then
          Cargotype = v
          break
        end
      end
      if Cargotype == nil then
        self:_SendMessage("Can't onboard " .. groupType, 10, false, Group)
      else
      
        local troopsize = Cargotype:GetCratesNeeded() -- #number
        -- have we loaded stuff already?
        local numberonboard = 0
        local loaded = {}
        if self.Loaded_Cargo[unitname] then
          loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
          numberonboard = loaded.Troopsloaded or 0
        else
          loaded = {} -- #CTLD.LoadedCargo
          loaded.Troopsloaded = 0
          loaded.Cratesloaded = 0
          loaded.Cargo = {}
        end
        if troopsize + numberonboard > trooplimit then
          self:_SendMessage("Sorry, we\'re crammed already!", 10, false, Group)
          --return self
        else
          self.CargoCounter = self.CargoCounter + 1
          local loadcargotype = CTLD_CARGO:New(self.CargoCounter, Cargotype.Name, Cargotype.Templates, Cargotype.CargoType, true, true, Cargotype.CratesNeeded,nil,nil,Cargotype.PerCrateMass)
          self:T({cargotype=loadcargotype})
          loaded.Troopsloaded = loaded.Troopsloaded + troopsize
          table.insert(loaded.Cargo,loadcargotype)
          self.Loaded_Cargo[unitname] = loaded
          self:_SendMessage("Troops boarded!", 10, false, Group)
          self:_UpdateUnitCargoMass(Unit)
          self:__TroopsExtracted(1,Group, Unit, nearestGroup)
      
          -- clean up:
          --table.remove(self.DroppedTroops, nearestGroupIndex)
          if type(Cargotype.Templates) == "table" and  Cargotype.Templates[2] then
            --self:I("*****This CargoType has multiple templates: "..Cargotype.Name)
            for _,_key in pairs (Cargotype.Templates) do
              table.insert(secondarygroups,_key)
            end
          end
          nearestGroup:Destroy(false)
        end
      end
    end
    -- clean up secondary groups
    for _,_name in pairs(secondarygroups) do
      for _,_group in pairs(nearestList) do
        if _group and _group:IsAlive() then
          local groupname = string.match(_group:GetName(), "(.+)-(.+)$")
          if _name == groupname then
            _group:Destroy(false)
          end
        end
      end
    end
    self:CleanDroppedTroops()
    return self
  end
  
--- (Internal) Function to spawn crates in front of the heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #CTLD_CARGO Cargo
-- @param #number number Number of crates to generate (for dropping)
-- @param #boolean drop If true we\'re dropping from heli rather than loading.
function CTLD:_GetCrates(Group, Unit, Cargo, number, drop)
  self:T(self.lid .. " _GetCrates")
  if not drop then
    local cgoname = Cargo:GetName()
    -- check if we have stock
    local instock = Cargo:GetStock()
    if type(instock) == "number" and tonumber(instock) <= 0 and tonumber(instock) ~= -1 then
      -- nothing left over
      self:_SendMessage(string.format("Sorry, we ran out of %s", cgoname), 10, false, Group)
      return self
    end
  end
  -- check if we are in LOAD zone
  local inzone = false 
  local drop = drop or false
  local ship = nil
  local width = 20
  if not drop then 
    inzone = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
    if not inzone then
      inzone, ship, zone, distance, width  = self:IsUnitInZone(Unit,CTLD.CargoZoneType.SHIP)
    end
  else
    if self.dropcratesanywhere then -- #1570
      inzone = true
    else
      inzone = self:IsUnitInZone(Unit,CTLD.CargoZoneType.DROP)
    end
  end
  
  if not inzone then
    self:_SendMessage("You are not close enough to a logistics zone!", 10, false, Group)
    if not self.debug then return self end
  end

  -- avoid crate spam
  local capabilities = self:_GetUnitCapabilities(Unit) -- #CTLD.UnitCapabilities
  local canloadcratesno = capabilities.cratelimit
  local loaddist = self.CrateDistance or 35
  local nearcrates, numbernearby = self:_FindCratesNearby(Group,Unit,loaddist)
  if numbernearby >= canloadcratesno and not drop then
    self:_SendMessage("There are enough crates nearby already! Take care of those first!", 10, false, Group)
    return self
  end
  -- spawn crates in front of helicopter
  local IsHerc = self:IsHercules(Unit) -- Herc
  local cargotype = Cargo -- Ops.CTLD#CTLD_CARGO
  local number = number or cargotype:GetCratesNeeded() --#number
  local cratesneeded = cargotype:GetCratesNeeded() --#number
  local cratename = cargotype:GetName()
  local cratetemplate = "Container"-- #string
  local cgotype = cargotype:GetType()
  local cgomass = cargotype:GetMass()
  local isstatic = false
  if cgotype == CTLD_CARGO.Enum.STATIC then
    cratetemplate = cargotype:GetTemplates()
    isstatic = true
  end
  -- get position and heading of heli
  local position = Unit:GetCoordinate()
  local heading = Unit:GetHeading() + 1
  local height = Unit:GetHeight()
  local droppedcargo = {}
  local cratedistance = 0
  local rheading = 0
  local angleOffNose = 0
  local addon = 0
  if IsHerc then 
    -- spawn behind the Herc
    addon = 180
  end
  -- loop crates needed
  for i=1,number do
    local cratealias = string.format("%s-%d", cratetemplate, math.random(1,100000))
    if not self.placeCratesAhead then
      cratedistance = (i-1)*2.5 + capabilities.length
      if cratedistance > self.CrateDistance then cratedistance = self.CrateDistance end
      -- altered heading logic
      -- DONE: right standard deviation?
      rheading = UTILS.RandomGaussian(0,30,-90,90,100)
      rheading = math.fmod((heading + rheading + addon), 360)
    else
      local initialSpacing = IsHerc and 16 or 12 -- initial spacing of the first crates
      local crateSpacing = 4 -- further spacing of remaining crates
      local lateralSpacing = 4 -- lateral spacing of crates
      local nrSideBySideCrates = 3 -- number of crates that are placed side-by-side

      if cratesneeded == 1 then
        -- single crate needed spawns straight ahead
        cratedistance = initialSpacing
        rheading = heading
      else
        if (i - 1) % nrSideBySideCrates == 0 then
            cratedistance = i == 1 and initialSpacing or cratedistance + crateSpacing
            angleOffNose = math.ceil(math.deg(math.atan(lateralSpacing / cratedistance)))
            rheading = heading - angleOffNose
        else
            rheading = rheading + angleOffNose
        end
      end
    end
    local cratecoord = position:Translate(cratedistance,rheading)
    local cratevec2 = cratecoord:GetVec2()
    self.CrateCounter = self.CrateCounter + 1
    local basetype = "container_cargo"
    if isstatic then
      basetype = cratetemplate
    end
    if type(ship) == "string" then
      self:T("Spawning on ship "..ship)
      local Ship = UNIT:FindByName(ship)
      local shipcoord = Ship:GetCoordinate()
      local unitcoord = Unit:GetCoordinate()
      local dist = shipcoord:Get2DDistance(unitcoord)
      dist = dist - (20 + math.random(1,10))
      local width = width / 2
      local Offy = math.random(-width,width)
      self.Spawned_Crates[self.CrateCounter] = SPAWNSTATIC:NewFromType(basetype,"Cargos",self.cratecountry)
      --:InitCoordinate(cratecoord)
      :InitCargoMass(cgomass)
      :InitCargo(self.enableslingload)
      :InitLinkToUnit(Ship,dist,Offy,0)
      :Spawn(270,cratealias)
    else   
      self.Spawned_Crates[self.CrateCounter] = SPAWNSTATIC:NewFromType(basetype,"Cargos",self.cratecountry)
        :InitCoordinate(cratecoord)
        :InitCargoMass(cgomass)
        :InitCargo(self.enableslingload)
        --:InitLinkToUnit(Unit,OffsetX,OffsetY,OffsetAngle)
        :Spawn(270,cratealias)
    end
    local templ = cargotype:GetTemplates()
    local sorte = cargotype:GetType()
    self.CargoCounter = self.CargoCounter + 1
    local realcargo = nil
    if drop then
      realcargo = CTLD_CARGO:New(self.CargoCounter,cratename,templ,sorte,true,false,cratesneeded,self.Spawned_Crates[self.CrateCounter],true,cargotype.PerCrateMass)
      table.insert(droppedcargo,realcargo)
    else
      realcargo = CTLD_CARGO:New(self.CargoCounter,cratename,templ,sorte,false,false,cratesneeded,self.Spawned_Crates[self.CrateCounter],true,cargotype.PerCrateMass)
      Cargo:RemoveStock()
    end
    table.insert(self.Spawned_Cargo, realcargo)
  end
  local text = string.format("Crates for %s have been positioned near you!",cratename)
  if drop then
    text = string.format("Crates for %s have been dropped!",cratename)
    self:__CratesDropped(1, Group, Unit, droppedcargo)
  end
  self:_SendMessage(text, 10, false, Group) 
  return self
end

--- (Internal) Inject crates and static cargo objects.
-- @param #CTLD self
-- @param Core.Zone#ZONE Zone Zone to spawn in.
-- @param #CTLD_CARGO Cargo The cargo type to spawn.
-- @param #boolean RandomCoord Randomize coordinate.
-- @return #CTLD self
function CTLD:InjectStatics(Zone, Cargo, RandomCoord)
  self:T(self.lid .. " InjectStatics")
  local cratecoord = Zone:GetCoordinate()
  if RandomCoord then
    cratecoord = Zone:GetRandomCoordinate(5,20)
  end
  local surface = cratecoord:GetSurfaceType()
  if surface == land.SurfaceType.WATER then
    return self
  end
  local cargotype = Cargo -- #CTLD_CARGO
  --local number = 1
  local cratesneeded = cargotype:GetCratesNeeded() --#number
  local cratetemplate = "Container"-- #string
  local cratealias = string.format("%s-%d", cratetemplate, math.random(1,100000))
  local cratename = cargotype:GetName()
  local cgotype = cargotype:GetType()
  local cgomass = cargotype:GetMass()
  local isstatic = false
  if cgotype == CTLD_CARGO.Enum.STATIC then
    cratetemplate = cargotype:GetTemplates()
    isstatic = true
  end
  local basetype = "container_cargo"
  if isstatic then
    basetype = cratetemplate
  end
  self.CrateCounter = self.CrateCounter + 1
  self.Spawned_Crates[self.CrateCounter] = SPAWNSTATIC:NewFromType(basetype,"Cargos",self.cratecountry)
    :InitCargoMass(cgomass)
    :InitCargo(self.enableslingload)
    :InitCoordinate(cratecoord)
    :Spawn(270,cratealias)
  local templ = cargotype:GetTemplates()
  local sorte = cargotype:GetType()
  self.CargoCounter = self.CargoCounter + 1
  cargotype.Positionable = self.Spawned_Crates[self.CrateCounter]
  table.insert(self.Spawned_Cargo, cargotype)
  return self
end

--- (User) Inject static cargo objects.
-- @param #CTLD self
-- @param Core.Zone#ZONE Zone Zone to spawn in. Will be a somewhat random coordinate.
-- @param #string Template Unit(!) name of the static cargo object to be used as template.
-- @param #number Mass Mass of the static in kg.
-- @return #CTLD self
function CTLD:InjectStaticFromTemplate(Zone, Template, Mass)
  self:T(self.lid .. " InjectStaticFromTemplate")
  local cargotype = self:GetStaticsCargoFromTemplate(Template,Mass) -- #CTLD_CARGO
  self:InjectStatics(Zone,cargotype,true)
  return self
end

--- (Internal) Function to find and list nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_ListCratesNearby( _group, _unit)
  self:T(self.lid .. " _ListCratesNearby")
  local finddist = self.CrateDistance or 35
  local crates,number = self:_FindCratesNearby(_group,_unit, finddist) -- #table
  if number > 0 then
    local text = REPORT:New("Crates Found Nearby:")
    text:Add("------------------------------------------------------------")
    for _,_entry in pairs (crates) do
      local entry = _entry -- #CTLD_CARGO
      local name = entry:GetName() --#string
      local dropped = entry:WasDropped()
      if dropped then
        text:Add(string.format("Dropped crate for %s, %dkg",name, entry.PerCrateMass))
      else
        text:Add(string.format("Crate for %s, %dkg",name, entry.PerCrateMass))
      end
    end
    if text:GetCount() == 1 then
    text:Add("        N O N E")
    end
    text:Add("------------------------------------------------------------")
    self:_SendMessage(text:Text(), 30, true, _group) 
  else
    self:_SendMessage(string.format("No (loadable) crates within %d meters!",finddist), 10, false, _group) 
  end
  return self
end

--- (Internal) Return distance in meters between two coordinates.
-- @param #CTLD self
-- @param Core.Point#COORDINATE _point1 Coordinate one
-- @param Core.Point#COORDINATE _point2 Coordinate two
-- @return #number Distance in meters
function CTLD:_GetDistance(_point1, _point2)
  self:T(self.lid .. " _GetDistance")
  if _point1 and _point2 then
    local distance1 = _point1:Get2DDistance(_point2)
    local distance2 = _point1:DistanceFromPointVec2(_point2)
    --self:I({dist1=distance1, dist2=distance2})
    if distance1 and type(distance1) == "number" then
      return distance1
    elseif distance2 and type(distance2) == "number" then
      return distance2
    else
      self:E("*****Cannot calculate distance!")
      self:E({_point1,_point2})
      return -1
    end
  else
    self:E("******Cannot calculate distance!")
    self:E({_point1,_point2})
    return -1
  end
end

--- (Internal) Function to find and return nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP _group Group
-- @param Wrapper.Unit#UNIT _unit Unit
-- @param #number _dist Distance
-- @return #table Table of crates
-- @return #number Number Number of crates found
function CTLD:_FindCratesNearby( _group, _unit, _dist)
  self:T(self.lid .. " _FindCratesNearby")
  local finddist = _dist
  local location = _group:GetCoordinate()
  local existingcrates = self.Spawned_Cargo -- #table
  -- cycle
  local index = 0
  local found = {}
  for _,_cargoobject in pairs (existingcrates) do
    local cargo = _cargoobject -- #CTLD_CARGO
    local static = cargo:GetPositionable() -- Wrapper.Static#STATIC -- crates
    local staticid = cargo:GetID()
    if static and static:IsAlive() then
      local staticpos = static:GetCoordinate()
      local distance = self:_GetDistance(location,staticpos)
      if distance <= finddist and static then
        index = index + 1
        table.insert(found, staticid, cargo)
      end
    end
  end
  return found, index
end

--- (Internal) Function to get and load nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_LoadCratesNearby(Group, Unit)
  self:T(self.lid .. " _LoadCratesNearby")
    -- load crates into heli
  local group = Group -- Wrapper.Group#GROUP
  local unit = Unit -- Wrapper.Unit#UNIT
  local unitname = unit:GetName()
  -- see if this heli can load crates
  local unittype = unit:GetTypeName()
  local capabilities = self:_GetUnitCapabilities(Unit) -- #CTLD.UnitCapabilities
  --local capabilities = self.UnitTypes[unittype] -- #CTLD.UnitCapabilities
  local cancrates = capabilities.crates -- #boolean
  local cratelimit = capabilities.cratelimit -- #number
  local grounded = not self:IsUnitInAir(Unit)
  local canhoverload = self:CanHoverLoad(Unit)
  --- cases -------------------------------
  -- Chopper can\'t do crates - bark & return
  -- Chopper can do crates -
  -- --> hover if forcedhover or bark and return
  -- --> hover or land if not forcedhover
  -----------------------------------------
  if not cancrates then
    self:_SendMessage("Sorry this chopper cannot carry crates!", 10, false, Group) 
  elseif self.forcehoverload and not canhoverload then
    self:_SendMessage("Hover over the crates to pick them up!", 10, false, Group) 
  elseif not grounded and not canhoverload then
    self:_SendMessage("Land or hover over the crates to pick them up!", 10, false, Group) 
  else
     -- have we loaded stuff already?
    local numberonboard = 0
    local massonboard = 0
    local loaded = {}
    if self.Loaded_Cargo[unitname] then
      loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
      numberonboard = loaded.Cratesloaded or 0
    else
      loaded = {} -- #CTLD.LoadedCargo
      loaded.Troopsloaded = 0
      loaded.Cratesloaded = 0
      loaded.Cargo = {}
    end
    -- get nearby crates
    local finddist = self.CrateDistance or 35
    local nearcrates,number = self:_FindCratesNearby(Group,Unit,finddist) -- #table
    if number == 0 and self.hoverautoloading then
      return self -- exit
    elseif number == 0 then
      self:_SendMessage("Sorry no loadable crates nearby!", 10, false, Group) 
      return self -- exit
    elseif numberonboard == cratelimit then
      self:_SendMessage("Sorry no fully loaded!", 10, false, Group) 
      return self -- exit
    else
      -- go through crates and load
      local capacity = cratelimit - numberonboard
      local crateidsloaded = {}
      local loops = 0
      while loaded.Cratesloaded < cratelimit and loops < number do
        loops = loops + 1
        local crateind = 0
        -- get crate with largest index
        for _ind,_crate in pairs (nearcrates) do
          if self.allowcratepickupagain then
            if _crate:GetID() > crateind and _crate.Positionable ~= nil then
              crateind = _crate:GetID()
            end
          else
            if not _crate:HasMoved() and _crate:WasDropped() and _crate:GetID() > crateind then
              crateind = _crate:GetID()
            end
          end
        end
        -- load one if we found one
        if crateind > 0 then
          local crate = nearcrates[crateind] -- #CTLD_CARGO
          loaded.Cratesloaded = loaded.Cratesloaded + 1
          crate:SetHasMoved(true)
          crate:SetWasDropped(false)
          table.insert(loaded.Cargo, crate)
          table.insert(crateidsloaded,crate:GetID())
          -- destroy crate
          crate:GetPositionable():Destroy(false)
          crate.Positionable = nil
          self:_SendMessage(string.format("Crate ID %d for %s loaded!",crate:GetID(),crate:GetName()), 10, false, Group)
          table.remove(nearcrates,crate:GetID())
          self:__CratesPickedUp(1, Group, Unit, crate)
        end
      end
      self.Loaded_Cargo[unitname] = loaded
      self:_UpdateUnitCargoMass(Unit) 
      -- clean up real world crates
      local existingcrates = self.Spawned_Cargo -- #table
      local newexcrates = {}
      for _,_crate in pairs(existingcrates) do
        local excrate = _crate -- #CTLD_CARGO
        local ID = excrate:GetID()
        for _,_ID in pairs(crateidsloaded) do
          if ID ~= _ID then
            table.insert(newexcrates,_crate)
          end
        end
      end
      self.Spawned_Cargo = nil
      self.Spawned_Cargo = newexcrates
    end
  end
  return self
end

--- (Internal) Function to get current loaded mass
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit
-- @return #number mass in kgs
function CTLD:_GetUnitCargoMass(Unit) 
  self:T(self.lid .. " _GetUnitCargoMass")
  local unitname = Unit:GetName()
  local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
  local loadedmass = 0 -- #number
  if self.Loaded_Cargo[unitname] then
    local cargotable = loadedcargo.Cargo or {} -- #table
    for _,_cargo in pairs(cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) and not cargo:WasDropped() then
        loadedmass = loadedmass + (cargo.PerCrateMass * cargo:GetCratesNeeded())
      end
      if type ~= CTLD_CARGO.Enum.TROOPS and type ~=  CTLD_CARGO.Enum.ENGINEERS and not cargo:WasDropped() then
        loadedmass = loadedmass + cargo.PerCrateMass
      end
    end
  end
  return loadedmass
end

--- (Internal) Function to calculate and set Unit internal cargo mass
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit
function CTLD:_UpdateUnitCargoMass(Unit)
  self:T(self.lid .. " _UpdateUnitCargoMass")
  local calculatedMass = self:_GetUnitCargoMass(Unit)
  Unit:SetUnitInternalCargo(calculatedMass)
  --local report = REPORT:New("Loadmaster report")
  --report:Add("Carrying " .. calculatedMass .. "Kg")
  --self:_SendMessage(report:Text(),10,false,Unit:GetGroup())
  return self
end

--- (Internal) Function to list loaded cargo.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_ListCargo(Group, Unit)
  self:T(self.lid .. " _ListCargo")
  local unitname = Unit:GetName()
  local unittype = Unit:GetTypeName()
  local capabilities = self:_GetUnitCapabilities(Unit) -- #CTLD.UnitCapabilities
  local trooplimit = capabilities.trooplimit -- #boolean
  local cratelimit = capabilities.cratelimit -- #number
  local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
  local loadedmass = self:_GetUnitCargoMass(Unit) -- #number
  if self.Loaded_Cargo[unitname] then
    local no_troops = loadedcargo.Troopsloaded or 0
    local no_crates = loadedcargo.Cratesloaded or 0
    local cargotable = loadedcargo.Cargo or {} -- #table
    local report = REPORT:New("Transport Checkout Sheet")
    report:Add("------------------------------------------------------------")
    report:Add(string.format("Troops: %d(%d), Crates: %d(%d)",no_troops,trooplimit,no_crates,cratelimit))
    report:Add("------------------------------------------------------------")
    report:Add("        -- TROOPS --")
    for _,_cargo in pairs(cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) and (not cargo:WasDropped() or self.allowcratepickupagain) then
        report:Add(string.format("Troop: %s size %d",cargo:GetName(),cargo:GetCratesNeeded()))
      end
    end
    if report:GetCount() == 4 then
      report:Add("        N O N E")
    end
    report:Add("------------------------------------------------------------")
    report:Add("       -- CRATES --")
    local cratecount = 0
    for _,_cargo in pairs(cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type ~= CTLD_CARGO.Enum.TROOPS and type ~= CTLD_CARGO.Enum.ENGINEERS) and (not cargo:WasDropped() or self.allowcratepickupagain) then
        report:Add(string.format("Crate: %s size 1",cargo:GetName()))
        cratecount = cratecount + 1
      end
    end
    if cratecount == 0 then
      report:Add("        N O N E")
    end
    report:Add("------------------------------------------------------------")
    report:Add("Total Mass: ".. loadedmass .. " kg")
    local text = report:Text()
    self:_SendMessage(text, 30, true, Group) 
  else
    self:_SendMessage(string.format("Nothing loaded!\nTroop limit: %d | Crate limit %d",trooplimit,cratelimit), 10, false, Group) 
  end
  return self
end

--- (Internal) Function to list loaded cargo.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @return #CTLD self
function CTLD:_ListInventory(Group, Unit)
  self:T(self.lid .. " _ListInventory")
  local unitname = Unit:GetName()
  local unittype = Unit:GetTypeName()
  local cgotypes = self.Cargo_Crates
  local trptypes = self.Cargo_Troops
  local stctypes = self.Cargo_Statics
  
  local function countcargo(cgotable)
    local counter = 0
    for _,_cgo in pairs(cgotable) do
      counter = counter + 1
    end
    return counter
  end
  
  local crateno = countcargo(cgotypes)
  local troopno = countcargo(trptypes)
  local staticno = countcargo(stctypes)
  
  if (crateno > 0 or troopno > 0 or staticno > 0) then

    local report = REPORT:New("Inventory Sheet")
    report:Add("------------------------------------------------------------")
    report:Add(string.format("Troops: %d, Cratetypes: %d",troopno,crateno+staticno))
    report:Add("------------------------------------------------------------")
    report:Add("        -- TROOPS --")
    for _,_cargo in pairs(trptypes) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) and not cargo:WasDropped() then
        local stockn = cargo:GetStock()
        local stock = "none"
        if stockn == -1 then 
          stock = "unlimited"
        elseif stockn > 0 then
          stock = tostring(stockn)
        end
        report:Add(string.format("Unit: %s | Soldiers: %d | Stock: %s",cargo:GetName(),cargo:GetCratesNeeded(),stock))
      end
    end
    if report:GetCount() == 4 then
      report:Add("        N O N E")
    end
    report:Add("------------------------------------------------------------")
    report:Add("       -- CRATES --")
    local cratecount = 0
    for _,_cargo in pairs(cgotypes) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type ~= CTLD_CARGO.Enum.TROOPS and type ~= CTLD_CARGO.Enum.ENGINEERS) and not cargo:WasDropped() then
        local stockn = cargo:GetStock()
        local stock = "none"
        if stockn == -1 then 
          stock = "unlimited"
        elseif stockn > 0 then
          stock = tostring(stockn)
        end
        report:Add(string.format("Type: %s | Crates per Set: %d | Stock: %s",cargo:GetName(),cargo:GetCratesNeeded(),stock))
        cratecount = cratecount + 1
      end
    end
    -- Statics
    for _,_cargo in pairs(stctypes) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if (type == CTLD_CARGO.Enum.STATIC) and not cargo:WasDropped() then
        local stockn = cargo:GetStock()
        local stock = "none"
        if stockn == -1 then 
          stock = "unlimited"
        elseif stockn > 0 then
          stock = tostring(stockn)
        end
        report:Add(string.format("Type: %s | Stock: %s",cargo:GetName(),stock))
        cratecount = cratecount + 1
      end
    end
    if cratecount == 0 then
      report:Add("        N O N E")
    end
    local text = report:Text()
    self:_SendMessage(text, 30, true, Group) 
  else
    self:_SendMessage(string.format("Nothing in stock!"), 10, false, Group) 
  end
  return self
end

--- (Internal) Function to check if a unit is a Hercules C-130.
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit
-- @return #boolean Outcome
function CTLD:IsHercules(Unit)
  if Unit:GetTypeName() == "Hercules" then 
    return true
  else
    return false
  end
end

--- (Internal) Function to unload troops from heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
function CTLD:_UnloadTroops(Group, Unit)
  self:T(self.lid .. " _UnloadTroops")
  -- check if we are in LOAD zone
  local droppingatbase = false
  local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD)
  if not inzone then
    inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.SHIP)
  end
  if inzone then
    droppingatbase = true
  end
  -- check for hover unload
  local hoverunload = self:IsCorrectHover(Unit) --if true we\'re hovering in parameters
  local IsHerc = self:IsHercules(Unit) 
  if IsHerc then
    -- no hover but airdrop here
    hoverunload = self:IsCorrectFlightParameters(Unit)
  end
  -- check if we\'re landed
  local grounded = not self:IsUnitInAir(Unit)
  -- Get what we have loaded
  local unitname = Unit:GetName()
  if self.Loaded_Cargo[unitname] and (grounded or hoverunload) then
    if not droppingatbase or self.debug then
      local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
      -- looking for troops
      local cargotable = loadedcargo.Cargo
      for _,_cargo in pairs (cargotable) do
        local cargo = _cargo -- #CTLD_CARGO
        local type = cargo:GetType() -- #CTLD_CARGO.Enum
        if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) and not cargo:WasDropped() then
          -- unload troops
          local name = cargo:GetName() or "none"
          local temptable = cargo:GetTemplates() or {}
          local position = Group:GetCoordinate()
          local zoneradius = 100 -- drop zone radius
          local factor = 1
          if IsHerc then
            factor = cargo:GetCratesNeeded() or 1 -- spread a bit more if airdropping
            zoneradius = Unit:GetVelocityMPS() or 100
          end
          local zone = ZONE_GROUP:New(string.format("Unload zone-%s",unitname),Group,zoneradius*factor)
          local randomcoord = zone:GetRandomCoordinate(10,30*factor):GetVec2()
          for _,_template in pairs(temptable) do
            self.TroopCounter = self.TroopCounter + 1
            local alias = string.format("%s-%d", _template, math.random(1,100000))
            self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
              :InitRandomizeUnits(true,20,2)
              :InitDelayOff()
              :SpawnFromVec2(randomcoord)
            if self.movetroopstowpzone and type ~= CTLD_CARGO.Enum.ENGINEERS then
              self:_MoveGroupToZone(self.DroppedTroops[self.TroopCounter])
            end
          end -- template loop
          cargo:SetWasDropped(true)
          -- engineering group?
          --self:I("Dropped Troop Type: "..type)
          if type == CTLD_CARGO.Enum.ENGINEERS then
            self.Engineers = self.Engineers + 1
            local grpname = self.DroppedTroops[self.TroopCounter]:GetName()
            self.EngineersInField[self.Engineers] = CTLD_ENGINEERING:New(name, grpname)
            self:_SendMessage(string.format("Dropped Engineers %s into action!",name), 10, false, Group)
          else
            self:_SendMessage(string.format("Dropped Troops %s into action!",name), 10, false, Group)
          end
          self:__TroopsDeployed(1, Group, Unit, self.DroppedTroops[self.TroopCounter])
        end -- if type end
      end  -- cargotable loop
    else -- droppingatbase
        self:_SendMessage("Troops have returned to base!", 10, false, Group) 
        self:__TroopsRTB(1, Group, Unit)
    end
    -- cleanup load list
    local    loaded = {} -- #CTLD.LoadedCargo
    loaded.Troopsloaded = 0
    loaded.Cratesloaded = 0
    loaded.Cargo = {}
    local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
    local cargotable = loadedcargo.Cargo or {}
    for _,_cargo in pairs (cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      local dropped = cargo:WasDropped()
      if type ~= CTLD_CARGO.Enum.TROOPS and type ~= CTLD_CARGO.Enum.ENGINEERS and not dropped then
        table.insert(loaded.Cargo,_cargo)
        loaded.Cratesloaded = loaded.Cratesloaded + 1
      else
        -- add troops back to stock
        if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) and droppingatbase then
          -- find right generic type
          local name = cargo:GetName()
          local gentroops = self.Cargo_Troops
          for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
            if _troop.Name == name then
              local stock = _troop:GetStock()
              -- avoid making unlimited stock limited
              if stock and tonumber(stock) >= 0 then _troop:AddStock() end
            end
          end
        end
      end
    end
    self.Loaded_Cargo[unitname] = nil
    self.Loaded_Cargo[unitname] = loaded
    self:_UpdateUnitCargoMass(Unit)
  else
   if IsHerc then
    self:_SendMessage("Nothing loaded or not within airdrop parameters!", 10, false, Group) 
   else
    self:_SendMessage("Nothing loaded or not hovering within parameters!", 10, false, Group) 
   end
  end
  return self
end

--- (Internal) Function to unload crates from heli.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
function CTLD:_UnloadCrates(Group, Unit)
  self:T(self.lid .. " _UnloadCrates")
  
  if not self.dropcratesanywhere then -- #1570
    -- check if we are in DROP zone
    local inzone, zonename, zone, distance = self:IsUnitInZone(Unit,CTLD.CargoZoneType.DROP)
    if not inzone then
      self:_SendMessage("You are not close enough to a drop zone!", 10, false, Group) 
      if not self.debug then 
        return self 
      end
    end
  end
  -- check for hover unload
  local hoverunload = self:IsCorrectHover(Unit) --if true we\'re hovering in parameters
  local IsHerc = self:IsHercules(Unit)
  if IsHerc then
    -- no hover but airdrop here
    hoverunload = self:IsCorrectFlightParameters(Unit)
  end
  -- check if we\'re landed
  local grounded = not self:IsUnitInAir(Unit)
  -- Get what we have loaded
  local unitname = Unit:GetName()
  if self.Loaded_Cargo[unitname] and (grounded or hoverunload) then
    local loadedcargo = self.Loaded_Cargo[unitname] or {} -- #CTLD.LoadedCargo
    -- looking for crate
    local cargotable = loadedcargo.Cargo
    for _,_cargo in pairs (cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      if type ~= CTLD_CARGO.Enum.TROOPS and type ~= CTLD_CARGO.Enum.ENGINEERS and (not cargo:WasDropped() or self.allowcratepickupagain) then
        -- unload crates
        self:_GetCrates(Group, Unit, cargo, 1, true)
        cargo:SetWasDropped(true)
        cargo:SetHasMoved(true)
      end
    end
    -- cleanup load list
    local loaded = {} -- #CTLD.LoadedCargo
    loaded.Troopsloaded = 0
    loaded.Cratesloaded = 0
    loaded.Cargo = {}
    
    for _,_cargo in pairs (cargotable) do
      local cargo = _cargo -- #CTLD_CARGO
      local type = cargo:GetType() -- #CTLD_CARGO.Enum
      local size = cargo:GetCratesNeeded()
      if type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS then
        table.insert(loaded.Cargo,_cargo)
        loaded.Troopsloaded = loaded.Troopsloaded + size
      end
    end
    self.Loaded_Cargo[unitname] = nil
    self.Loaded_Cargo[unitname] = loaded
    
    self:_UpdateUnitCargoMass(Unit)
  else
    if IsHerc then
        self:_SendMessage("Nothing loaded or not within airdrop parameters!", 10, false, Group) 
    else
        self:_SendMessage("Nothing loaded or not hovering within parameters!", 10, false, Group) 
     end
  end
  return self
end

--- (Internal) Function to build nearby crates.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #boolean Engineering If true build is by an engineering team.
function CTLD:_BuildCrates(Group, Unit,Engineering)
  self:T(self.lid .. " _BuildCrates")
  -- avoid users trying to build from flying Hercs
  local type = Unit:GetTypeName()
  if type == "Hercules" and self.enableHercules and not Engineering then
    local speed = Unit:GetVelocityKMH()
    if speed > 1 then
      self:_SendMessage("You need to land / stop to build something, Pilot!", 10, false, Group) 
      return self
    end
  end
  -- get nearby crates
  local finddist = self.CrateDistance or 35
  local crates,number = self:_FindCratesNearby(Group,Unit, finddist) -- #table
  local buildables = {}
  local foundbuilds = false
  local canbuild = false
  if number > 0 then
    -- get dropped crates
    for _,_crate in pairs(crates) do
      local Crate = _crate -- #CTLD_CARGO
      if Crate:WasDropped() and not Crate:IsRepair() and not Crate:IsStatic() then
        -- we can build these - maybe
        local name = Crate:GetName()
        local required = Crate:GetCratesNeeded()
        local template = Crate:GetTemplates()
        local ctype = Crate:GetType()
        if not buildables[name] then
          local object = {} -- #CTLD.Buildable
          object.Name = name
          object.Required = required
          object.Found = 1
          object.Template = template
          object.CanBuild = false
          object.Type = ctype -- #CTLD_CARGO.Enum
          buildables[name] = object
          foundbuilds = true
        else
         buildables[name].Found = buildables[name].Found + 1
         foundbuilds = true
        end
        if buildables[name].Found >= buildables[name].Required then 
           buildables[name].CanBuild = true
           canbuild = true
        end
        self:T({buildables = buildables})
      end -- end dropped
    end -- end crate loop
    -- ok let\'s list what we have
    local report = REPORT:New("Checklist Buildable Crates")
    report:Add("------------------------------------------------------------")
    for _,_build in pairs(buildables) do
      local build = _build -- Object table from above
      local name = build.Name
      local needed = build.Required
      local found = build.Found
      local txtok = "NO"
      if build.CanBuild then 
        txtok = "YES" 
      end
      local text = string.format("Type: %s | Required %d | Found %d | Can Build %s", name, needed, found, txtok)
      report:Add(text)
    end -- end list buildables
    if not foundbuilds then report:Add("     --- None Found ---") end
    report:Add("------------------------------------------------------------")
    local text = report:Text()
    if not Engineering then
      self:_SendMessage(text, 30, true, Group) 
    else
      self:T(text)
    end
    -- let\'s get going
    if canbuild then
      -- loop again
      for _,_build in pairs(buildables) do
        local build = _build -- #CTLD.Buildable
        if build.CanBuild then
          self:_CleanUpCrates(crates,build,number)
          self:_BuildObjectFromCrates(Group,Unit,build)
        end
      end
    end
  else
    if not Engineering then self:_SendMessage(string.format("No crates within %d meters!",finddist), 10, false, Group) end
  end -- number > 0
  return self
end

--- (Internal) Function to repair nearby vehicles / FOBs
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
-- @param #boolean Engineering If true, this is an engineering role
function CTLD:_RepairCrates(Group, Unit, Engineering)
  self:T(self.lid .. " _RepairCrates")
  -- get nearby crates
  local finddist = self.CrateDistance or 35
  local crates,number = self:_FindCratesNearby(Group,Unit,finddist) -- #table
  local buildables = {}
  local foundbuilds = false
  local canbuild = false
  if number > 0 then
    -- get dropped crates
    for _,_crate in pairs(crates) do
      local Crate = _crate -- #CTLD_CARGO
      if Crate:WasDropped() and Crate:IsRepair() and not Crate:IsStatic() then
        -- we can build these - maybe
        local name = Crate:GetName()
        local required = Crate:GetCratesNeeded()
        local template = Crate:GetTemplates()
        local ctype = Crate:GetType()
        if not buildables[name] then
          local object = {} -- #CTLD.Buildable
          object.Name = name
          object.Required = required
          object.Found = 1
          object.Template = template
          object.CanBuild = false
          object.Type = ctype -- #CTLD_CARGO.Enum
          buildables[name] = object
          foundbuilds = true
        else
         buildables[name].Found = buildables[name].Found + 1
         foundbuilds = true
        end
        if buildables[name].Found >= buildables[name].Required then 
           buildables[name].CanBuild = true
           canbuild = true
        end
        self:T({repair = buildables})
      end -- end dropped
    end -- end crate loop
    -- ok let\'s list what we have
    local report = REPORT:New("Checklist Repairs")
    report:Add("------------------------------------------------------------")
    for _,_build in pairs(buildables) do
      local build = _build -- Object table from above
      local name = build.Name
      local needed = build.Required
      local found = build.Found
      local txtok = "NO"
      if build.CanBuild then 
        txtok = "YES" 
      end
      local text = string.format("Type: %s | Required %d | Found %d | Can Repair %s", name, needed, found, txtok)
      report:Add(text)
    end -- end list buildables
    if not foundbuilds then report:Add("     --- None Found ---") end
    report:Add("------------------------------------------------------------")
    local text = report:Text()
    if not Engineering then
      self:_SendMessage(text, 30, true, Group) 
    else
      self:T(text)
    end
    -- let\'s get going
    if canbuild then
      -- loop again
      for _,_build in pairs(buildables) do
        local build = _build -- #CTLD.Buildable
        if build.CanBuild then
          self:_RepairObjectFromCrates(Group,Unit,crates,build,number,Engineering)
        end
      end
    end
  else
    if not Engineering then self:_SendMessage(string.format("No crates within %d meters!",finddist), 10, false, Group) end 
  end -- number > 0
  return self
end

--- (Internal) Function to actually SPAWN buildables in the mission.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Group#UNIT Unit
-- @param #CTLD.Buildable Build
-- @param #boolean Repair If true this is a repair and not a new build
-- @param Core.Point#COORDINATE Coordinate Location for repair (e.g. where the destroyed unit was)
function CTLD:_BuildObjectFromCrates(Group,Unit,Build,Repair,RepairLocation)
  self:T(self.lid .. " _BuildObjectFromCrates")
  -- Spawn-a-crate-content
  if Group and Group:IsAlive() then
    local position = Unit:GetCoordinate() or Group:GetCoordinate()
    local unitname = Unit:GetName() or Group:GetName()
    local name = Build.Name
    local ctype = Build.Type -- #CTLD_CARGO.Enum
    local canmove = false
    if ctype == CTLD_CARGO.Enum.VEHICLE then canmove = true end
    if ctype == CTLD_CARGO.Enum.STATIC then 
      return self 
    end
    local temptable = Build.Template or {}
    if type(temptable) == "string" then 
      temptable = {temptable}
    end
    local zone = ZONE_GROUP:New(string.format("Unload zone-%s",unitname),Group,100)
    local randomcoord = zone:GetRandomCoordinate(35):GetVec2()
    if Repair then
      randomcoord = RepairLocation:GetVec2()
    end
    for _,_template in pairs(temptable) do
      self.TroopCounter = self.TroopCounter + 1
      local alias = string.format("%s-%d", _template, math.random(1,100000))
      if canmove then
        self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
          :InitRandomizeUnits(true,20,2)
          :InitDelayOff()
          :SpawnFromVec2(randomcoord)
      else -- don't random position of e.g. SAM units build as FOB
        self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
          :InitDelayOff()
          :SpawnFromVec2(randomcoord)
      end
      if self.movetroopstowpzone and canmove then
        self:_MoveGroupToZone(self.DroppedTroops[self.TroopCounter])
      end
      if Repair then
        self:__CratesRepaired(1,Group,Unit,self.DroppedTroops[self.TroopCounter])
      else
        self:__CratesBuild(1,Group,Unit,self.DroppedTroops[self.TroopCounter])
      end
    end -- template loop
  else
    self:T(self.lid.."Group KIA while building!")
  end
  return self
end

--- (Internal) Function to move group to WP zone.
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group The Group to move.
function CTLD:_MoveGroupToZone(Group)
  self:T(self.lid .. " _MoveGroupToZone")
  local groupname = Group:GetName() or "none"
  local groupcoord = Group:GetCoordinate()
  -- Get closest zone of type
  local outcome, name, zone, distance  = self:IsUnitInZone(Group,CTLD.CargoZoneType.MOVE)
  --self:Tstring.format("Closest WP zone %s is %d meters",name,distance))
  if (distance <= self.movetroopsdistance) and zone then
    -- yes, we can ;)
    local groupname = Group:GetName()
    local zonecoord = zone:GetRandomCoordinate(20,125) -- Core.Point#COORDINATE
    local coordinate = zonecoord:GetVec2()
    Group:SetAIOn()
    Group:OptionAlarmStateAuto()
    Group:OptionDisperseOnAttack(30)
    Group:OptionROEOpenFirePossible()
    Group:RouteToVec2(coordinate,5)
    end
  return self
end

--- (Internal) Housekeeping - Cleanup crates when build
-- @param #CTLD self
-- @param #table Crates Table of #CTLD_CARGO objects near the unit.
-- @param #CTLD.Buildable Build Table build object.
-- @param #number Number Number of objects in Crates (found) to limit search.
function CTLD:_CleanUpCrates(Crates,Build,Number)
  self:T(self.lid .. " _CleanUpCrates")
  -- clean up real world crates
  local build = Build -- #CTLD.Buildable
  local existingcrates = self.Spawned_Cargo -- #table of exising crates
  local newexcrates = {}
  -- get right number of crates to destroy
  local numberdest = Build.Required
  local nametype = Build.Name
  local found = 0
  local rounds = Number
  local destIDs = {}
  
  -- loop and find matching IDs in the set
  for _,_crate in pairs(Crates) do
    local nowcrate = _crate -- #CTLD_CARGO
    local name = nowcrate:GetName()
    local thisID = nowcrate:GetID()
    if name == nametype then -- matching crate type
      table.insert(destIDs,thisID)
      found = found + 1
      nowcrate:GetPositionable():Destroy(false)
      nowcrate.Positionable = nil
      nowcrate.HasBeenDropped = false
    end
    if found == numberdest then break end -- got enough
  end
  -- loop and remove from real world representation
  for _,_crate in pairs(existingcrates) do
    local excrate = _crate -- #CTLD_CARGO
    local ID = excrate:GetID()
    for _,_ID in pairs(destIDs) do
      if ID ~= _ID then
        table.insert(newexcrates,_crate)
      end
    end
  end
  
  -- reset Spawned_Cargo
  self.Spawned_Cargo = nil
  self.Spawned_Cargo = newexcrates
  return self
end

--- (Internal) Housekeeping - Function to refresh F10 menus.
-- @param #CTLD self
-- @return #CTLD self
function CTLD:_RefreshF10Menus()
  self:T(self.lid .. " _RefreshF10Menus")
  local PlayerSet = self.PilotGroups -- Core.Set#SET_GROUP
  local PlayerTable = PlayerSet:GetSetObjects() -- #table of #GROUP objects
  -- rebuild units table
  local _UnitList = {}
  for _key, _group in pairs (PlayerTable) do  
    local _unit = _group:GetUnit(1) -- Wrapper.Unit#UNIT Asume that there is only one unit in the flight for players
    if _unit then 
      if _unit:IsAlive() and _unit:IsPlayer() then
        if _unit:IsHelicopter() or (_unit:GetTypeName() == "Hercules" and self.enableHercules) then --ensure no stupid unit entries here
          local unitName = _unit:GetName()
          _UnitList[unitName] = unitName
        end    
      end -- end isAlive
    end -- end if _unit
  end -- end for
  self.CtldUnits = _UnitList
  
  -- build unit menus
  local menucount = 0
  local menus = {}  
  for _, _unitName in pairs(self.CtldUnits) do
    if not self.MenusDone[_unitName] then 
      local _unit = UNIT:FindByName(_unitName) -- Wrapper.Unit#UNIT
      if _unit then
        local _group = _unit:GetGroup() -- Wrapper.Group#GROUP
        if _group then
          -- get chopper capabilities
          local unittype = _unit:GetTypeName()
          local capabilities = self:_GetUnitCapabilities(_unit) -- #CTLD.UnitCapabilities
          local cantroops = capabilities.troops
          local cancrates = capabilities.crates
          -- top menu
          local topmenu = MENU_GROUP:New(_group,"CTLD",nil)
          local toptroops = MENU_GROUP:New(_group,"Manage Troops",topmenu)
          local topcrates = MENU_GROUP:New(_group,"Manage Crates",topmenu)
          local listmenu = MENU_GROUP_COMMAND:New(_group,"List boarded cargo",topmenu, self._ListCargo, self, _group, _unit)
          local invtry = MENU_GROUP_COMMAND:New(_group,"Inventory",topmenu, self._ListInventory, self, _group, _unit)
          local rbcns = MENU_GROUP_COMMAND:New(_group,"List active zone beacons",topmenu, self._ListRadioBeacons, self, _group, _unit)
          local smokemenu = MENU_GROUP_COMMAND:New(_group,"Smoke zones nearby",topmenu, self.SmokeZoneNearBy, self, _unit, false)
          local smokemenu = MENU_GROUP_COMMAND:New(_group,"Flare zones nearby",topmenu, self.SmokeZoneNearBy, self, _unit, true):Refresh()
          -- sub menus
          -- sub menu troops management
          if cantroops then 
            local troopsmenu = MENU_GROUP:New(_group,"Load troops",toptroops)
            for _,_entry in pairs(self.Cargo_Troops) do
              local entry = _entry -- #CTLD_CARGO
              menucount = menucount + 1
              menus[menucount] = MENU_GROUP_COMMAND:New(_group,entry.Name,troopsmenu,self._LoadTroops, self, _group, _unit, entry)
            end
            local unloadmenu1 = MENU_GROUP_COMMAND:New(_group,"Drop troops",toptroops, self._UnloadTroops, self, _group, _unit):Refresh()
              local extractMenu1 = MENU_GROUP_COMMAND:New(_group, "Extract troops", toptroops, self._ExtractTroops, self, _group, _unit):Refresh()
          end
          -- sub menu crates management
          if cancrates then 
            local loadmenu = MENU_GROUP_COMMAND:New(_group,"Load crates",topcrates, self._LoadCratesNearby, self, _group, _unit)
            local cratesmenu = MENU_GROUP:New(_group,"Get Crates",topcrates)
            for _,_entry in pairs(self.Cargo_Crates) do
              local entry = _entry -- #CTLD_CARGO
              menucount = menucount + 1
              local menutext = string.format("Crate %s (%dkg)",entry.Name,entry.PerCrateMass or 0)
              menus[menucount] = MENU_GROUP_COMMAND:New(_group,menutext,cratesmenu,self._GetCrates, self, _group, _unit, entry)
            end
            for _,_entry in pairs(self.Cargo_Statics) do
              local entry = _entry -- #CTLD_CARGO
              menucount = menucount + 1
              local menutext = string.format("Crate %s (%dkg)",entry.Name,entry.PerCrateMass or 0)
              menus[menucount] = MENU_GROUP_COMMAND:New(_group,menutext,cratesmenu,self._GetCrates, self, _group, _unit, entry)
            end
            listmenu = MENU_GROUP_COMMAND:New(_group,"List crates nearby",topcrates, self._ListCratesNearby, self, _group, _unit)
            local unloadmenu = MENU_GROUP_COMMAND:New(_group,"Drop crates",topcrates, self._UnloadCrates, self, _group, _unit)
            local buildmenu = MENU_GROUP_COMMAND:New(_group,"Build crates",topcrates, self._BuildCrates, self, _group, _unit)
            local repairmenu = MENU_GROUP_COMMAND:New(_group,"Repair",topcrates, self._RepairCrates, self, _group, _unit):Refresh()
          end
          if unittype == "Hercules" then
            local hoverpars = MENU_GROUP_COMMAND:New(_group,"Show flight parameters",topmenu, self._ShowFlightParams, self, _group, _unit):Refresh()
          else
            local hoverpars = MENU_GROUP_COMMAND:New(_group,"Show hover parameters",topmenu, self._ShowHoverParams, self, _group, _unit):Refresh()
          end
          self.MenusDone[_unitName] = true
        end -- end group
      end -- end unit
    else -- menu build check
      self:T(self.lid .. " Menus already done for this group!")
    end  -- end menu build check
  end  -- end for
  return self
 end

--- User function - Add *generic* troop type loadable as cargo. This type will load directly into the heli without crates.
-- @param #CTLD self
-- @param #string Name Unique name of this type of troop. E.g. "Anti-Air Small".
-- @param #table Templates Table of #string names of late activated Wrapper.Group#GROUP making up this troop.
-- @param #CTLD_CARGO.Enum Type Type of cargo, here TROOPS - these will move to a nearby destination zone when dropped/build.
-- @param #number NoTroops Size of the group in number of Units across combined templates (for loading).
-- @param #number PerTroopMass Mass in kg of each soldier
-- @param #number Stock Number of groups in stock. Nil for unlimited.
function CTLD:AddTroopsCargo(Name,Templates,Type,NoTroops,PerTroopMass,Stock)
  self:T(self.lid .. " AddTroopsCargo")
  self:T({Name,Templates,Type,NoTroops,PerTroopMass,Stock})
  self.CargoCounter = self.CargoCounter + 1
  -- Troops are directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,Templates,Type,false,true,NoTroops,nil,nil,PerTroopMass,Stock)
  table.insert(self.Cargo_Troops,cargo)
  return self
end

--- User function - Add *generic* crate-type loadable as cargo. This type will create crates that need to be loaded, moved, dropped and built.
-- @param #CTLD self
-- @param #string Name Unique name of this type of cargo. E.g. "Humvee".
-- @param #table Templates Table of #string names of late activated Wrapper.Group#GROUP building this cargo.
-- @param #CTLD_CARGO.Enum Type Type of cargo. I.e. VEHICLE or FOB. VEHICLE will move to destination zones when dropped/build, FOB stays put.
-- @param #number NoCrates Number of crates needed to build this cargo.
-- @param #number PerCrateMass Mass in kg of each crate
-- @param #number Stock Number of groups in stock. Nil for unlimited.
function CTLD:AddCratesCargo(Name,Templates,Type,NoCrates,PerCrateMass,Stock)
  self:T(self.lid .. " AddCratesCargo")
  self.CargoCounter = self.CargoCounter + 1
  -- Crates are not directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,Templates,Type,false,false,NoCrates,nil,nil,PerCrateMass,Stock)
  table.insert(self.Cargo_Crates,cargo)
  return self
end

--- User function - Add *generic* static-type loadable as cargo. This type will create cargo that needs to be loaded, moved and dropped.
-- @param #CTLD self
-- @param #string Name Unique name of this type of cargo as set in the mission editor (note: UNIT name!), e.g. "Ammunition-1".
-- @param #number Mass Mass in kg of each static in kg, e.g. 100.
-- @param #number Stock Number of groups in stock. Nil for unlimited.
function CTLD:AddStaticsCargo(Name,Mass,Stock)
  self:T(self.lid .. " AddStaticsCargo")
  self.CargoCounter = self.CargoCounter + 1
  local type = CTLD_CARGO.Enum.STATIC
  local template = STATIC:FindByName(Name,true):GetTypeName()
  -- Crates are not directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,template,type,false,false,1,nil,nil,Mass,Stock)
  table.insert(self.Cargo_Statics,cargo)
  return self
end

--- User function - Get a *generic* static-type loadable as #CTLD_CARGO object.
-- @param #CTLD self
-- @param #string Name Unique Unit(!) name of this type of cargo as set in the mission editor (not: GROUP name!), e.g. "Ammunition-1".
-- @param #number Mass Mass in kg of each static in kg, e.g. 100.
-- @return #CTLD_CARGO Cargo object
function CTLD:GetStaticsCargoFromTemplate(Name,Mass)
  self:T(self.lid .. " GetStaticsCargoFromTemplate")
  self.CargoCounter = self.CargoCounter + 1
  local type = CTLD_CARGO.Enum.STATIC
  local template = STATIC:FindByName(Name,true):GetTypeName()
  -- Crates are not directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,template,type,false,false,1,nil,nil,Mass,1)
  --table.insert(self.Cargo_Statics,cargo)
  return cargo
end

--- User function - Add *generic* repair crates loadable as cargo. This type will create crates that need to be loaded, moved, dropped and built.
-- @param #CTLD self
-- @param #string Name Unique name of this type of cargo. E.g. "Humvee".
-- @param #string Template Template of VEHICLE or FOB cargo that this can repair.
-- @param #CTLD_CARGO.Enum Type Type of cargo, here REPAIR.
-- @param #number NoCrates Number of crates needed to build this cargo.
-- @param #number PerCrateMass Mass in kg of each crate
-- @param #number Stock Number of groups in stock. Nil for unlimited.
function CTLD:AddCratesRepair(Name,Template,Type,NoCrates, PerCrateMass,Stock)
  self:T(self.lid .. " AddCratesRepair")
  self.CargoCounter = self.CargoCounter + 1
  -- Crates are not directly loadable
  local cargo = CTLD_CARGO:New(self.CargoCounter,Name,Template,Type,false,false,NoCrates,nil,nil,PerCrateMass,Stock)
  table.insert(self.Cargo_Crates,cargo)
  return self
end

--- User function - Add a #CTLD.CargoZoneType zone for this CTLD instance.
-- @param #CTLD self
-- @param #CTLD.CargoZone Zone Zone #CTLD.CargoZone describing the zone.
function CTLD:AddZone(Zone)
  self:T(self.lid .. " AddZone")
  local zone = Zone -- #CTLD.CargoZone
  if zone.type == CTLD.CargoZoneType.LOAD then
    table.insert(self.pickupZones,zone)
  elseif zone.type == CTLD.CargoZoneType.DROP then
    table.insert(self.dropOffZones,zone)
  elseif zone.type == CTLD.CargoZoneType.SHIP then
    table.insert(self.shipZones,zone)  
  else
    table.insert(self.wpZones,zone)
  end
  return self
end

--- User function - Activate Name #CTLD.CargoZone.Type ZoneType for this CTLD instance.
-- @param #CTLD self
-- @param #string Name Name of the zone to change in the ME.
-- @param #CTLD.CargoZoneTyp ZoneType Type of zone this belongs to.
-- @param #boolean NewState (Optional) Set to true to activate, false to switch off.
function CTLD:ActivateZone(Name,ZoneType,NewState)
  self:T(self.lid .. " AddZone")
  local newstate = true
  -- set optional in case we\'re deactivating
  if NewState ~= nil then
    newstate = NewState
  end  
  
  -- get correct table
  local table = {}
  if ZoneType == CTLD.CargoZoneType.LOAD then
    table = self.pickupZones
  elseif ZoneType == CTLD.CargoZoneType.DROP then
    table = self.dropOffZones
  elseif ZoneType == CTLD.CargoZoneType.SHIP then
    table = self.shipZones
  else
    table = self.wpZones
  end
  -- loop table
  for _,_zone in pairs(table) do
    local thiszone = _zone --#CTLD.CargoZone
    if thiszone.name == Name then
      thiszone.active = newstate
      break
    end
  end
  return self
end


--- User function - Deactivate Name #CTLD.CargoZoneType ZoneType for this CTLD instance.
-- @param #CTLD self
-- @param #string Name Name of the zone to change in the ME.
-- @param #CTLD.CargoZoneTyp ZoneType Type of zone this belongs to.
function CTLD:DeactivateZone(Name,ZoneType)
  self:T(self.lid .. " AddZone")
  self:ActivateZone(Name,ZoneType,false)
  return self
end

--- (Internal) Function to obtain a valid FM frequency.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @return #CTLD.ZoneBeacon Beacon Beacon table.
function CTLD:_GetFMBeacon(Name)
  self:T(self.lid .. " _GetFMBeacon")
  local beacon = {} -- #CTLD.ZoneBeacon  
  if #self.FreeFMFrequencies <= 1 then
      self.FreeFMFrequencies = self.UsedFMFrequencies
      self.UsedFMFrequencies = {}
  end 
  --random
  local FM = table.remove(self.FreeFMFrequencies, math.random(#self.FreeFMFrequencies))
  table.insert(self.UsedFMFrequencies, FM)  
  beacon.name = Name
  beacon.frequency = FM / 1000000
  beacon.modulation = radio.modulation.FM
  return beacon
end

--- (Internal) Function to obtain a valid UHF frequency.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @return #CTLD.ZoneBeacon Beacon Beacon table.
function CTLD:_GetUHFBeacon(Name)
  self:T(self.lid .. " _GetUHFBeacon")
  local beacon = {} -- #CTLD.ZoneBeacon  
  if #self.FreeUHFFrequencies <= 1 then
      self.FreeUHFFrequencies = self.UsedUHFFrequencies
      self.UsedUHFFrequencies = {}
  end 
  --random
  local UHF = table.remove(self.FreeUHFFrequencies, math.random(#self.FreeUHFFrequencies))
  table.insert(self.UsedUHFFrequencies, UHF)
  beacon.name = Name
  beacon.frequency = UHF / 1000000
  beacon.modulation = radio.modulation.AM

  return beacon
end

--- (Internal) Function to obtain a valid VHF frequency.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @return #CTLD.ZoneBeacon Beacon Beacon table.
function CTLD:_GetVHFBeacon(Name)
  self:T(self.lid .. " _GetVHFBeacon")
  local beacon = {} -- #CTLD.ZoneBeacon
  if #self.FreeVHFFrequencies <= 3 then
      self.FreeVHFFrequencies = self.UsedVHFFrequencies
      self.UsedVHFFrequencies = {}
  end
  --get random
  local VHF = table.remove(self.FreeVHFFrequencies, math.random(#self.FreeVHFFrequencies))
  table.insert(self.UsedVHFFrequencies, VHF)
  beacon.name = Name
  beacon.frequency = VHF / 1000000
  beacon.modulation = radio.modulation.FM
  return beacon
end


--- User function - Crates and adds a #CTLD.CargoZone zone for this CTLD instance.
--  Zones of type LOAD: Players load crates and troops here.  
--  Zones of type DROP: Players can drop crates here. Note that troops can be unloaded anywhere.  
--  Zone of type MOVE: Dropped troops and vehicles will start moving to the nearest zone of this type (also see options).  
-- @param #CTLD self
-- @param #string Name Name of this zone, as in Mission Editor.
-- @param #string Type Type of this zone, #CTLD.CargoZoneType
-- @param #number Color Smoke/Flare color e.g. #SMOKECOLOR.Red
-- @param #string Active Is this zone currently active?
-- @param #string HasBeacon Does this zone have a beacon if it is active?
-- @param #number Shiplength Length of Ship for shipzones
-- @param #number Shipwidth Width of Ship for shipzones
-- @return #CTLD self
function CTLD:AddCTLDZone(Name, Type, Color, Active, HasBeacon, Shiplength, Shipwidth)
  self:T(self.lid .. " AddCTLDZone")

  local ctldzone = {} -- #CTLD.CargoZone
  ctldzone.active = Active or false
  ctldzone.color = Color or SMOKECOLOR.Red
  ctldzone.name = Name or "NONE"
  ctldzone.type = Type or CTLD.CargoZoneType.MOVE -- #CTLD.CargoZoneType
  ctldzone.hasbeacon = HasBeacon or false
   
  if HasBeacon then
    ctldzone.fmbeacon = self:_GetFMBeacon(Name)
    ctldzone.uhfbeacon = self:_GetUHFBeacon(Name)
    ctldzone.vhfbeacon = self:_GetVHFBeacon(Name)
  else
    ctldzone.fmbeacon = nil
    ctldzone.uhfbeacon = nil
    ctldzone.vhfbeacon = nil
  end
  
  if Type == CTLD.CargoZoneType.SHIP then
   ctldzone.shiplength = Shiplength or 100
   ctldzone.shipwidth = Shipwidth or 10
  end
  
  self:AddZone(ctldzone)
  return self
end

--- (Internal) Function to show list of radio beacons
-- @param #CTLD self
-- @param Wrapper.Group#GROUP Group
-- @param Wrapper.Unit#UNIT Unit
function CTLD:_ListRadioBeacons(Group, Unit)
  self:T(self.lid .. " _ListRadioBeacons")
  local report = REPORT:New("Active Zone Beacons")
  report:Add("------------------------------------------------------------")
  local zones = {[1] = self.pickupZones, [2] = self.wpZones, [3] = self.dropOffZones, [4] = self.shipZones}
  for i=1,4 do
    for index,cargozone in pairs(zones[i]) do
      -- Get Beacon object from zone
      local czone = cargozone -- #CTLD.CargoZone
      if czone.active and czone.hasbeacon then
        local FMbeacon = czone.fmbeacon -- #CTLD.ZoneBeacon
        local VHFbeacon = czone.vhfbeacon -- #CTLD.ZoneBeacon
        local UHFbeacon = czone.uhfbeacon -- #CTLD.ZoneBeacon
        local Name = czone.name
        local FM = FMbeacon.frequency  -- MHz
        local VHF = VHFbeacon.frequency * 1000 -- KHz
        local UHF = UHFbeacon.frequency  -- MHz
        report:AddIndent(string.format(" %s | FM %s Mhz | VHF %s KHz | UHF %s Mhz ", Name, FM, VHF, UHF),"|")
      end
    end
  end
  if report:GetCount() == 1 then
    report:Add("        N O N E")
  end
  report:Add("------------------------------------------------------------")
  self:_SendMessage(report:Text(), 30, true, Group) 
  return self
end

--- (Internal) Add radio beacon to zone. Runs 30 secs.
-- @param #CTLD self
-- @param #string Name Name of zone.
-- @param #string Sound Name of soundfile.
-- @param #number Mhz Frequency in Mhz.
-- @param #number Modulation Modulation AM or FM.
-- @param #boolean IsShip If true zone is a ship.
function CTLD:_AddRadioBeacon(Name, Sound, Mhz, Modulation, IsShip)
  self:T(self.lid .. " _AddRadioBeacon")
  local Zone = nil
  if IsShip then
    Zone = UNIT:FindByName(Name)
  else
    Zone = ZONE:FindByName(Name)
  end
  local Sound = Sound or "beacon.ogg"
  if Zone then
    local ZoneCoord = Zone:GetCoordinate()
    local ZoneVec3 = ZoneCoord:GetVec3()
    local Frequency = Mhz * 1000000 -- Freq in Hertz
    local Sound =  "l10n/DEFAULT/"..Sound
    trigger.action.radioTransmission(Sound, ZoneVec3, Modulation, false, Frequency, 1000) -- Beacon in MP only runs for 30secs straight
  end
  return self
end

--- (Internal) Function to refresh radio beacons
-- @param #CTLD self
function CTLD:_RefreshRadioBeacons()
  self:T(self.lid .. " _RefreshRadioBeacons")

  local zones = {[1] = self.pickupZones, [2] = self.wpZones, [3] = self.dropOffZones, [4] = self.shipZones}
  for i=1,4 do
    local IsShip = false
    if i == 4 then IsShip = true end
    for index,cargozone in pairs(zones[i]) do
      -- Get Beacon object from zone
      local czone = cargozone -- #CTLD.CargoZone
      local Sound = self.RadioSound
      if czone.active and czone.hasbeacon then
        local FMbeacon = czone.fmbeacon -- #CTLD.ZoneBeacon
        local VHFbeacon = czone.vhfbeacon -- #CTLD.ZoneBeacon
        local UHFbeacon = czone.uhfbeacon -- #CTLD.ZoneBeacon
        local Name = czone.name
        local FM = FMbeacon.frequency  -- MHz
        local VHF = VHFbeacon.frequency -- KHz
        local UHF = UHFbeacon.frequency  -- MHz      
        self:_AddRadioBeacon(Name,Sound,FM,radio.modulation.FM, IsShip)
        self:_AddRadioBeacon(Name,Sound,VHF,radio.modulation.FM, IsShip)
        self:_AddRadioBeacon(Name,Sound,UHF,radio.modulation.AM, IsShip)
      end
    end
  end
  return self
end

--- (Internal) Function to see if a unit is in a specific zone type.
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit Unit
-- @param #CTLD.CargoZoneType Zonetype Zonetype
-- @return #boolean Outcome Is in zone or not
-- @return #string name Closest zone name
-- @return Core.Zone#ZONE zone Closest Core.Zone#ZONE object
-- @return #number distance Distance to closest zone
-- @return #number width Radius of zone or width of ship
function CTLD:IsUnitInZone(Unit,Zonetype)
  self:T(self.lid .. " IsUnitInZone")
  self:T(Zonetype)
  local unitname = Unit:GetName()
  local zonetable = {}
  local outcome = false
  if Zonetype == CTLD.CargoZoneType.LOAD then
    zonetable = self.pickupZones -- #table
  elseif Zonetype == CTLD.CargoZoneType.DROP then
    zonetable = self.dropOffZones -- #table
  elseif Zonetype == CTLD.CargoZoneType.SHIP then
    zonetable = self.shipZones -- #table
  else 
   zonetable = self.wpZones -- #table
  end
  --- now see if we\'re in
  local zonecoord = nil
  local colorret = nil
  local maxdist = 1000000 -- 100km
  local zoneret = nil
  local zonewret = nil
  local zonenameret = nil
  for _,_cargozone in pairs(zonetable) do
    local czone = _cargozone -- #CTLD.CargoZone
    local unitcoord = Unit:GetCoordinate()
    local zonename = czone.name
    local active = czone.active
    local color = czone.color
    local zone = nil
    local zoneradius = 100
    local zonewidth = 20
    if Zonetype == CTLD.CargoZoneType.SHIP then
      self:T("Checking Type Ship: "..zonename)
      zone = UNIT:FindByName(zonename)
      zonecoord = zone:GetCoordinate()
      zoneradius = czone.shiplength
      zonewidth = czone.shipwidth
    else
      zone = ZONE:FindByName(zonename)
      zonecoord = zone:GetCoordinate()
      zoneradius = zone:GetRadius()
      zonewidth = zoneradius
    end
    local distance = self:_GetDistance(zonecoord,unitcoord)
    if distance <= zoneradius and active then 
      outcome = true
    end
    if maxdist > distance then 
      maxdist = distance
      zoneret = zone 
      zonenameret = zonename
      zonewret = zonewidth
      colorret = color 
    end
  end
  if Zonetype == CTLD.CargoZoneType.SHIP then
    return outcome, zonenameret, zoneret, maxdist, zonewret
  else
    return outcome, zonenameret, zoneret, maxdist
  end
end

--- User function - Start smoke in a zone close to the Unit.
-- @param #CTLD self
-- @param Wrapper.Unit#UNIT Unit The Unit.
-- @param #boolean Flare If true, flare instead.
function CTLD:SmokeZoneNearBy(Unit, Flare)
  self:T(self.lid .. " SmokeZoneNearBy")
  -- table of #CTLD.CargoZone table
  local unitcoord = Unit:GetCoordinate()
  local Group = Unit:GetGroup()
  local smokedistance = self.smokedistance
  local smoked = false
  local zones = {[1] = self.pickupZones, [2] = self.wpZones, [3] = self.dropOffZones, [4] = self.shipZones}
  for i=1,4 do
    for index,cargozone in pairs(zones[i]) do
      local CZone = cargozone --#CTLD.CargoZone
      local zonename = CZone.name
      local zone = nil
      if i == 4 then
        zone = UNIT:FindByName(zonename)
      else
        zone = ZONE:FindByName(zonename)
      end
      local zonecoord = zone:GetCoordinate()
      local active = CZone.active
      local color = CZone.color
      local distance = self:_GetDistance(zonecoord,unitcoord)
      if distance < smokedistance and active then
        -- smoke zone since we\'re nearby
        if not Flare then 
          zonecoord:Smoke(color or SMOKECOLOR.White)
        else
          if color == SMOKECOLOR.Blue then color = FLARECOLOR.White end
          zonecoord:Flare(color or FLARECOLOR.White)
        end
        local txt = "smoking"
        if Flare then txt = "flaring" end
        self:_SendMessage(string.format("Roger, %s zone %s!",txt, zonename), 10, false, Group)
        smoked = true
      end
    end
  end
  if not smoked then
    local distance = UTILS.MetersToNM(self.smokedistance)
    self:_SendMessage(string.format("Negative, need to be closer than %dnm to a zone!",distance), 10, false, Group)
  end
  return self 
end

  --- User - Function to add/adjust unittype capabilities.
  -- @param #CTLD self
  -- @param #string Unittype The unittype to adjust. If passed as Wrapper.Unit#UNIT, it will search for the unit in the mission.
  -- @param #boolean Cancrates Unit can load crates. Default false.
  -- @param #boolean Cantroops Unit can load troops. Default false.
  -- @param #number Cratelimit Unit can carry number of crates. Default 0.
  -- @param #number Trooplimit Unit can carry number of troops. Default 0.
  -- @param #number Length Unit lenght (in mteres) for the load radius. Default 20.
  function CTLD:UnitCapabilities(Unittype, Cancrates, Cantroops, Cratelimit, Trooplimit, Length)
    self:T(self.lid .. " UnitCapabilities")
    local unittype =  nil
    local unit = nil
    if type(Unittype) == "string" then
      unittype = Unittype
    elseif type(Unittype) == "table" then
      unit = UNIT:FindByName(Unittype) -- Wrapper.Unit#UNIT
      unittype = unit:GetTypeName()
    else
      return self
    end
    -- set capabilities
    local capabilities = {} -- #CTLD.UnitCapabilities
    capabilities.type = unittype
    capabilities.crates = Cancrates or false
    capabilities.troops = Cantroops or false
    capabilities.cratelimit = Cratelimit or  0
    capabilities.trooplimit = Trooplimit or 0
    capabilities.length = Length or 20
    self.UnitTypes[unittype] = capabilities
    return self
  end
  
  --- (Internal) Check if a unit is hovering *in parameters*.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD:IsCorrectHover(Unit)
    self:T(self.lid .. " IsCorrectHover")
    local outcome = false
    -- see if we are in air and within parameters.
    if self:IsUnitInAir(Unit) then
      -- get speed and height
      local uspeed = Unit:GetVelocityMPS()
      local uheight = Unit:GetHeight()
      local ucoord = Unit:GetCoordinate()
      local gheight = ucoord:GetLandHeight()
      local aheight = uheight - gheight -- height above ground
      local maxh = self.maximumHoverHeight -- 15
      local minh =  self.minimumHoverHeight -- 5
      local mspeed = 2 -- 2 m/s
      if (uspeed <= mspeed) and (aheight <= maxh) and (aheight >= minh)  then 
        -- yep within parameters
        outcome = true
      end
    end
    return outcome
  end
  
    --- (Internal) Check if a Hercules is flying *in parameters* for air drops.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD:IsCorrectFlightParameters(Unit)
    self:T(self.lid .. " IsCorrectFlightParameters")
    local outcome = false
    -- see if we are in air and within parameters.
    if self:IsUnitInAir(Unit) then
      -- get speed and height
      local uspeed = Unit:GetVelocityMPS()
      local uheight = Unit:GetHeight()
      local ucoord = Unit:GetCoordinate()
      local gheight = ucoord:GetLandHeight()
      local aheight = uheight - gheight -- height above ground
      local maxh = self.HercMinAngels-- 1500m
      local minh =  self.HercMaxAngels -- 5000m
      local maxspeed =  self.HercMaxSpeed -- 77 mps
      -- DONE: TEST - Speed test for Herc, should not be above 280kph/150kn
      local kmspeed = uspeed * 3.6
      local knspeed = kmspeed / 1.86
      self:T(string.format("%s Unit parameters: at %dm AGL with %dmps | %dkph | %dkn",self.lid,aheight,uspeed,kmspeed,knspeed))
      if (aheight <= maxh) and (aheight >= minh) and (uspeed <= maxspeed) then 
        -- yep within parameters
        outcome = true
      end
    end
    return outcome
  end
  
  --- (Internal) List if a unit is hovering *in parameters*.
  -- @param #CTLD self
  -- @param Wrapper.Group#GROUP Group
  -- @param Wrapper.Unit#UNIT Unit
  function CTLD:_ShowHoverParams(Group,Unit)
    local inhover = self:IsCorrectHover(Unit)
    local htxt = "true"
    if not inhover then htxt = "false" end
    local text = ""
    if _SETTINGS:IsMetric() then
      text = string.format("Hover parameters (autoload/drop):\n - Min height %dm \n - Max height %dm \n - Max speed 2mps \n - In parameter: %s", self.minimumHoverHeight, self.maximumHoverHeight, htxt)
    else
      local minheight = UTILS.MetersToFeet(self.minimumHoverHeight)
      local maxheight = UTILS.MetersToFeet(self.maximumHoverHeight)
      text = string.format("Hover parameters (autoload/drop):\n - Min height %dm \n - Max height %dm \n - Max speed 6fts \n - In parameter: %s", minheight, maxheight, htxt)
    end
    self:_SendMessage(text, 10, false, Group)
    return self
  end
  
    --- (Internal) List if a Herc unit is flying *in parameters*.
  -- @param #CTLD self
  -- @param Wrapper.Group#GROUP Group
  -- @param Wrapper.Unit#UNIT Unit
  function CTLD:_ShowFlightParams(Group,Unit)
    local inhover = self:IsCorrectFlightParameters(Unit)
    local htxt = "true"
    if not inhover then htxt = "false" end
    local text = ""
    if _SETTINGS:IsImperial() then
      local minheight = UTILS.MetersToFeet(self.HercMinAngels)
      local maxheight = UTILS.MetersToFeet(self.HercMaxAngels)
      text = string.format("Flight parameters (airdrop):\n - Min height %dft \n - Max height %dft \n - In parameter: %s", minheight, maxheight, htxt)
    else
      local minheight = self.HercMinAngels
      local maxheight = self.HercMaxAngels
      text = string.format("Flight parameters (airdrop):\n - Min height %dm \n - Max height %dm \n - In parameter: %s", minheight, maxheight, htxt)
    end
    self:_SendMessage(text, 10, false, Group)
    return self
  end
  
  
  --- (Internal) Check if a unit is in a load zone and is hovering in parameters.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD:CanHoverLoad(Unit)
    self:T(self.lid .. " CanHoverLoad")
    if self:IsHercules(Unit) then return false end
    local outcome = self:IsUnitInZone(Unit,CTLD.CargoZoneType.LOAD) and self:IsCorrectHover(Unit)
    if not outcome then
      outcome = self:IsUnitInZone(Unit,CTLD.CargoZoneType.SHIP) --and self:IsCorrectHover(Unit)
    end
    return outcome
  end
  
  --- (Internal) Check if a unit is above ground.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #boolean Outcome
  function CTLD:IsUnitInAir(Unit)
    -- get speed and height
    local minheight = self.minimumHoverHeight
    if self.enableHercules and Unit:GetTypeName() == "Hercules" then
      minheight = 5.1 -- herc is 5m AGL on the ground
    end
    local uheight = Unit:GetHeight()
    local ucoord = Unit:GetCoordinate()
    local gheight = ucoord:GetLandHeight()
    local aheight = uheight - gheight -- height above ground
    if aheight >= minheight then
      return true
    else
      return false
    end
  end
  
  --- (Internal) Autoload if we can do crates, have capacity free and are in a load zone.
  -- @param #CTLD self
  -- @param Wrapper.Unit#UNIT Unit
  -- @return #CTLD self
  function CTLD:AutoHoverLoad(Unit)
    self:T(self.lid .. " AutoHoverLoad")
    -- get capabilities and current load
    local unittype = Unit:GetTypeName()
    local unitname = Unit:GetName()
    local Group = Unit:GetGroup()
    local capabilities = self:_GetUnitCapabilities(Unit) -- #CTLD.UnitCapabilities
    local cancrates = capabilities.crates -- #boolean
    local cratelimit = capabilities.cratelimit -- #number
    if cancrates then
      -- get load
      local numberonboard = 0
      local loaded = {}
      if self.Loaded_Cargo[unitname] then
        loaded = self.Loaded_Cargo[unitname] -- #CTLD.LoadedCargo
        numberonboard = loaded.Cratesloaded or 0
      end
      local load = cratelimit - numberonboard
      local canload = self:CanHoverLoad(Unit)
      if canload and load > 0 then
        self:_LoadCratesNearby(Group,Unit)
      end
    end
    return self
  end
  
  --- (Internal) Run through all pilots and see if we autoload.
  -- @param #CTLD self
  -- @return #CTLD self
  function CTLD:CheckAutoHoverload()
    if self.hoverautoloading then
      for _,_pilot in pairs (self.CtldUnits) do
        local Unit = UNIT:FindByName(_pilot)
        if self:CanHoverLoad(Unit) then self:AutoHoverLoad(Unit) end
      end
    end
    return self
  end
  
  --- (Internal) Run through DroppedTroops and capture alive units
  -- @param #CTLD self
  -- @return #CTLD self
  function CTLD:CleanDroppedTroops()
    -- Troops
    local troops = self.DroppedTroops
    local newtable = {}
    for _index, _group in pairs (troops) do
      self:T({_group.ClassName})
      if _group and _group.ClassName == "GROUP" then
        if _group:IsAlive() then
          newtable[_index] = _group
        end
      end
    end
    self.DroppedTroops = newtable
    -- Engineers
    local engineers = self.EngineersInField
    local engtable = {}
    for _index, _group in pairs (engineers) do
      self:T({_group.ClassName})
      if _group and _group:IsNotStatus("Stopped") then
        engtable[_index] = _group
      end
    end
    self.EngineersInField = engtable
    return self
  end

  --- User - function to add stock of a certain troops type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to add.
  -- @return #CTLD self
  function CTLD:AddStockTroops(Name, Number)
    local name = Name or "none"
    local number = Number or 1
    -- find right generic type
    local gentroops = self.Cargo_Troops
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:AddStock(number)
      end
    end
  end
  
  --- User - function to add stock of a certain crates type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to add.
  -- @return #CTLD self
  function CTLD:AddStockCrates(Name, Number)
    local name = Name or "none"
    local number = Number or 1
    -- find right generic type
    local gentroops = self.Cargo_Crates
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:AddStock(number)
      end
    end
  end
  
  --- User - function to remove stock of a certain troops type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to add.
  -- @return #CTLD self
  function CTLD:RemoveStockTroops(Name, Number)
    local name = Name or "none"
    local number = Number or 1
    -- find right generic type
    local gentroops = self.Cargo_Troops
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:RemoveStock(number)
      end
    end
  end
  
  --- User - function to remove stock of a certain crates type
  -- @param #CTLD self
  -- @param #string Name Name as defined in the generic cargo.
  -- @param #number Number Number of units/groups to add.
  -- @return #CTLD self
  function CTLD:RemoveStockCrates(Name, Number)
    local name = Name or "none"
    local number = Number or 1
    -- find right generic type
    local gentroops = self.Cargo_Crates
    for _id,_troop in pairs (gentroops) do -- #number, #CTLD_CARGO
      if _troop.Name == name then
        _troop:RemoveStock(number)
      end
    end
    return self
  end
  
  --- (Internal) Check on engineering teams
  -- @param #CTLD self
  -- @return #CTLD self
  function CTLD:_CheckEngineers()
    self:T(self.lid.." CheckEngineers")
    local engtable = self.EngineersInField
    for _ind,_engineers in pairs (engtable) do
      local engineers = _engineers -- #CTLD_ENGINEERING
      local wrenches = engineers.Group -- Wrapper.Group#GROUP
      self:T(_engineers.lid .. _engineers:GetStatus())
      if wrenches and wrenches:IsAlive() then
        if engineers:IsStatus("Running") or engineers:IsStatus("Searching") then
          local crates,number = self:_FindCratesNearby(wrenches,nil, self.EngineerSearch) -- #table
          engineers:Search(crates,number)
        elseif engineers:IsStatus("Moving") then
          engineers:Move()
        elseif engineers:IsStatus("Arrived") then
          engineers:Build()
          local unit = wrenches:GetUnit(1)
          self:_BuildCrates(wrenches,unit,true)
          self:_RepairCrates(wrenches,unit,true)
          engineers:Done()
        end
      else
        engineers:Stop()
      end
    end
    return self
  end
  
  --- (User) Pre-populate troops in the field.
  -- @param #CTLD self
  -- @param Core.Zone#ZONE Zone The zone where to drop the troops.
  -- @param Ops.CTLD#CTLD_CARGO Cargo The #CTLD_CARGO object to spawn.
  -- @return #CTLD self
  -- @usage Use this function to pre-populate the field with Troops or Engineers at a random coordinate in a zone:
  --            -- create a matching #CTLD_CARGO type
  --            local InjectTroopsType = CTLD_CARGO:New(nil,"Infantry",{"Inf12"},CTLD_CARGO.Enum.TROOPS,true,true,12,nil,false,80)
  --            -- get a #ZONE object
  --            local dropzone = ZONE:New("InjectZone") -- Core.Zone#ZONE
  --            -- and go:
  --            my_ctld:InjectTroops(dropzone,InjectTroopsType)
  function CTLD:InjectTroops(Zone,Cargo)
    self:T(self.lid.." InjectTroops")
    local cargo = Cargo -- #CTLD_CARGO
    
    local function IsTroopsMatch(cargo)
      local match = false
      local cgotbl = self.Cargo_Troops
      local name = cargo:GetName()
      for _,_cgo in pairs (cgotbl) do
        local cname = _cgo:GetName()
        if name == cname then
          match = true
          break
        end
      end
      return match
    end
    
    if not IsTroopsMatch(cargo) then
      self.CargoCounter = self.CargoCounter + 1
      cargo.ID = self.CargoCounter
      cargo.Stock = 1
      table.insert(self.Cargo_Troops,cargo)
    end
    
    local type = cargo:GetType() -- #CTLD_CARGO.Enum
    if (type == CTLD_CARGO.Enum.TROOPS or type == CTLD_CARGO.Enum.ENGINEERS) then
      -- unload 
      local name = cargo:GetName() or "none"
      local temptable = cargo:GetTemplates() or {}
      local factor = 1.5
      local zone = Zone
     
      local randomcoord = zone:GetRandomCoordinate(10,30*factor):GetVec2()
      for _,_template in pairs(temptable) do
        self.TroopCounter = self.TroopCounter + 1
        local alias = string.format("%s-%d", _template, math.random(1,100000))
        self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
          :InitRandomizeUnits(true,20,2)
          :InitDelayOff()
          :SpawnFromVec2(randomcoord)
        if self.movetroopstowpzone and type ~= CTLD_CARGO.Enum.ENGINEERS then
          self:_MoveGroupToZone(self.DroppedTroops[self.TroopCounter])
        end
      end -- template loop
      cargo:SetWasDropped(true)
      -- engineering group?
      if type == CTLD_CARGO.Enum.ENGINEERS then
        self.Engineers = self.Engineers + 1
        local grpname = self.DroppedTroops[self.TroopCounter]:GetName()
        self.EngineersInField[self.Engineers] = CTLD_ENGINEERING:New(name, grpname)
        --self:I(string.format("%s Injected Engineers %s into action!",self.lid, name))
      else
        --self:I(string.format("%s Injected Troops %s into action!",self.lid, name))
      end
      if self.eventoninject then
         self:__TroopsDeployed(1,nil,nil,self.DroppedTroops[self.TroopCounter])
      end
    end -- if type end
    return self
  end
  
    --- (User) Pre-populate vehicles in the field.
  -- @param #CTLD self
  -- @param Core.Zone#ZONE Zone The zone where to drop the troops.
  -- @param Ops.CTLD#CTLD_CARGO Cargo The #CTLD_CARGO object to spawn.
  -- @return #CTLD self
  -- @usage Use this function to pre-populate the field with Vehicles or FOB at a random coordinate in a zone:
  --            -- create a matching #CTLD_CARGO type
  --            local InjectVehicleType = CTLD_CARGO:New(nil,"Humvee",{"Humvee"},CTLD_CARGO.Enum.VEHICLE,true,true,1,nil,false,1000)
  --            -- get a #ZONE object
  --            local dropzone = ZONE:New("InjectZone") -- Core.Zone#ZONE
  --            -- and go:
  --            my_ctld:InjectVehicles(dropzone,InjectVehicleType)
  function CTLD:InjectVehicles(Zone,Cargo)
    self:T(self.lid.." InjectVehicles")
    local cargo = Cargo -- #CTLD_CARGO
    
    local function IsVehicMatch(cargo)
      local match = false
      local cgotbl = self.Cargo_Crates
      local name = cargo:GetName()
      for _,_cgo in pairs (cgotbl) do
        local cname = _cgo:GetName()
        if name == cname then
          match = true
          break
        end
      end
      return match
    end
    
    if not IsVehicMatch(cargo) then
      self.CargoCounter = self.CargoCounter + 1
      cargo.ID = self.CargoCounter
      cargo.Stock = 1
      table.insert(self.Cargo_Crates,cargo)
    end
    
    local type = cargo:GetType() -- #CTLD_CARGO.Enum
    if (type == CTLD_CARGO.Enum.VEHICLE or type == CTLD_CARGO.Enum.FOB) then
      -- unload 
      local name = cargo:GetName() or "none"
      local temptable = cargo:GetTemplates() or {}
      local factor = 1.5
      local zone = Zone
      local randomcoord = zone:GetRandomCoordinate(10,30*factor):GetVec2()
      cargo:SetWasDropped(true)
      local canmove = false
      if type == CTLD_CARGO.Enum.VEHICLE then canmove = true end
      for _,_template in pairs(temptable) do
        self.TroopCounter = self.TroopCounter + 1
        local alias = string.format("%s-%d", _template, math.random(1,100000))
        if canmove then
          self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
            :InitRandomizeUnits(true,20,2)
            :InitDelayOff()
            :SpawnFromVec2(randomcoord)
        else -- don't random position of e.g. SAM units build as FOB
          self.DroppedTroops[self.TroopCounter] = SPAWN:NewWithAlias(_template,alias)
            :InitDelayOff()
            :SpawnFromVec2(randomcoord)
        end
        if self.movetroopstowpzone and canmove then
          self:_MoveGroupToZone(self.DroppedTroops[self.TroopCounter])
        end
        if self.eventoninject then
          self:__CratesBuild(1,nil,nil,self.DroppedTroops[self.TroopCounter])
        end
      end -- end loop
    end -- if type end
    return self
  end
  
------------------------------------------------------------------- 
-- FSM functions
------------------------------------------------------------------- 

  --- (Internal) FSM Function onafterStart.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onafterStart(From, Event, To)
    self:T({From, Event, To})
    self:I(self.lid .. "Started ("..self.version..")")
    if self.useprefix or self.enableHercules then
      local prefix = self.prefixes
      if self.enableHercules then
        self.PilotGroups = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterPrefixes(prefix):FilterStart()
      else
        self.PilotGroups = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterPrefixes(prefix):FilterCategories("helicopter"):FilterStart()
      end
    else
      self.PilotGroups = SET_GROUP:New():FilterCoalitions(self.coalitiontxt):FilterCategories("helicopter"):FilterStart()
    end
    -- Events
    self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
    self:HandleEvent(EVENTS.PlayerEnterUnit, self._EventHandler)
    self:HandleEvent(EVENTS.PlayerLeaveUnit, self._EventHandler)   
    self:__Status(-5)
    
    -- AutoSave
    if self.enableLoadSave then
      local interval = self.saveinterval
      local filename = self.filename
      local filepath = self.filepath
      self:__Save(interval,filepath,filename)
    end
    return self
  end

  --- (Internal) FSM Function onbeforeStatus.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onbeforeStatus(From, Event, To)
    self:T({From, Event, To})
    self:CleanDroppedTroops()
    self:_RefreshF10Menus()
    self:_RefreshRadioBeacons()
    self:CheckAutoHoverload()
    self:_CheckEngineers()
    return self
  end
  
  --- (Internal) FSM Function onafterStatus.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onafterStatus(From, Event, To)
    self:T({From, Event, To})
     -- gather some stats
    -- pilots
    local pilots = 0
    for _,_pilot in pairs (self.CtldUnits) do   
     pilots = pilots + 1
    end
     
    -- spawned cargo boxes curr in field
    local boxes = 0
    for _,_pilot in pairs (self.Spawned_Cargo) do
     boxes = boxes + 1
    end
    
    local cc =  self.CargoCounter
    local tc = self.TroopCounter
    
    if self.debug or self.verbose > 0 then 
      local text = string.format("%s Pilots %d | Live Crates %d |\nCargo Counter %d | Troop Counter %d", self.lid, pilots, boxes, cc, tc)
      local m = MESSAGE:New(text,10,"CTLD"):ToAll()
      if self.verbose > 0 then
        self:I(self.lid.."Cargo and Troops in Stock:")
        for _,_troop in pairs (self.Cargo_Crates) do
          local name = _troop:GetName()
          local stock = _troop:GetStock()
          self:I(string.format("-- %s \t\t\t %d", name, stock))
        end
        for _,_troop in pairs (self.Cargo_Statics) do
          local name = _troop:GetName()
          local stock = _troop:GetStock()
          self:I(string.format("-- %s \t\t\t %d", name, stock))
        end
        for _,_troop in pairs (self.Cargo_Troops) do
          local name = _troop:GetName()
          local stock = _troop:GetStock()
          self:I(string.format("-- %s \t\t %d", name, stock))
        end
      end
    end
    self:__Status(-30)
    return self
  end
  
  --- (Internal) FSM Function onafterStop.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @return #CTLD self
  function CTLD:onafterStop(From, Event, To)
    self:T({From, Event, To})
    self:UnhandleEvent(EVENTS.PlayerEnterAircraft)
    self:UnhandleEvent(EVENTS.PlayerEnterUnit)
    self:UnhandleEvent(EVENTS.PlayerLeaveUnit)
    return self
  end
  
  --- (Internal) FSM Function onbeforeTroopsPickedUp.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate.
  -- @return #CTLD self
  function CTLD:onbeforeTroopsPickedUp(From, Event, To, Group, Unit, Cargo)
    self:T({From, Event, To})
    return self
  end
  
    --- (Internal) FSM Function onbeforeCratesPickedUp.
  -- @param #CTLD self
  -- @param #string From State .
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #CTLD_CARGO Cargo Cargo crate.
  -- @return #CTLD self
  function CTLD:onbeforeCratesPickedUp(From, Event, To, Group, Unit, Cargo)
    self:T({From, Event, To})
    return self
  end
  
      --- (Internal) FSM Function onbeforeTroopsExtracted.
    -- @param #CTLD self
    -- @param #string From State.
    -- @param #string Event Trigger.
    -- @param #string To State.
    -- @param Wrapper.Group#GROUP Group Group Object.
    -- @param Wrapper.Unit#UNIT Unit Unit Object.
    -- @param Wrapper.Group#GROUP Troops Troops #GROUP Object.
    -- @return #CTLD self
    function CTLD:onbeforeTroopsExtracted(From, Event, To, Group, Unit, Troops)
      self:T({From, Event, To})
      return self
    end
    
    
  --- (Internal) FSM Function onbeforeTroopsDeployed.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Troops Troops #GROUP Object.
  -- @return #CTLD self
  function CTLD:onbeforeTroopsDeployed(From, Event, To, Group, Unit, Troops)
    self:T({From, Event, To})
    return self
  end
  
  --- (Internal) FSM Function onbeforeCratesDropped.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param #table Cargotable Table of #CTLD_CARGO objects dropped.
  -- @return #CTLD self
  function CTLD:onbeforeCratesDropped(From, Event, To, Group, Unit, Cargotable)
    self:T({From, Event, To})
    return self
  end
  
  --- (Internal) FSM Function onbeforeCratesBuild.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @param Wrapper.Group#GROUP Vehicle The #GROUP object of the vehicle or FOB build.
  -- @return #CTLD self
  function CTLD:onbeforeCratesBuild(From, Event, To, Group, Unit, Vehicle)
    self:T({From, Event, To})
    return self
  end
  
  --- (Internal) FSM Function onbeforeTroopsRTB.
  -- @param #CTLD self
  -- @param #string From State.
  -- @param #string Event Trigger.
  -- @param #string To State.
  -- @param Wrapper.Group#GROUP Group Group Object.
  -- @param Wrapper.Unit#UNIT Unit Unit Object.
  -- @return #CTLD self
  function CTLD:onbeforeTroopsRTB(From, Event, To, Group, Unit)
    self:T({From, Event, To})
    return self
  end
  
  --- On before "Save" event. Checks if io and lfs are available.
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is saved. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for saving. Default is "CTLD_<alias>_Persist.csv".
  function CTLD:onbeforeSave(From, Event, To, path, filename)
    self:T({From, Event, To, path, filename})
    if not self.enableLoadSave then
      return self
    end
    -- Thanks to @FunkyFranky 
    -- Check io module is available.
    if not io then
      self:E(self.lid.."ERROR: io not desanitized. Can't save current state.")
      return false
    end
  
    -- Check default path.
    if path==nil and not lfs then
      self:E(self.lid.."WARNING: lfs not desanitized. State will be saved in DCS installation root directory rather than your \"Saved Games\\DCS\" folder.")
    end
  
    return true
  end
  
  --- On after "Save" event. Player data is saved to file.
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path Path where the file is saved. If nil, file is saved in the DCS root installtion directory or your "Saved Games" folder if lfs was desanitized.
  -- @param #string filename (Optional) File name for saving. Default is Default is "CTLD_<alias>_Persist.csv".
  function CTLD:onafterSave(From, Event, To, path, filename)
    self:T({From, Event, To, path, filename})
    -- Thanks to @FunkyFranky 
    if not self.enableLoadSave then
      return self
    end
    --- Function that saves data to file
    local function _savefile(filename, data)
      local f = assert(io.open(filename, "wb"))
      f:write(data)
      f:close()
    end
  
    -- Set path or default.
    if lfs then
      path=self.filepath or lfs.writedir()
    end
    
    -- Set file name.
    filename=filename or self.filename
  
    -- Set path.
    if path~=nil then
      filename=path.."\\"..filename
    end
    
    local grouptable = self.DroppedTroops -- #table
    local cgovehic = self.Cargo_Crates
    local cgotable = self.Cargo_Troops
    local stcstable = self.Spawned_Cargo
    
    local statics = nil
    local statics = {}
    self:I(self.lid.."Bulding Statics Table for Saving")
    for _,_cargo in pairs (stcstable) do     
      local cargo = _cargo -- #CTLD_CARGO
      local object = cargo:GetPositionable() -- Wrapper.Static#STATIC
      if object and object:IsAlive() and cargo:WasDropped() then
        self:I({_cargo})
        statics[#statics+1] = cargo
      end
    end
    
    -- find matching cargo
    local function FindCargoType(name,table)
      -- name matching a template in the table
      local match = false
      local cargo = nil
      for _ind,_cargo in pairs (table) do
        local thiscargo = _cargo -- #CTLD_CARGO
        local template = thiscargo:GetTemplates()
        if type(template) == "string" then
          template = { template }
        end
        for _,_name in pairs (template) do
          --self:I(string.format("*** Saving CTLD: Matching %s with %s",name,_name))
          if string.find(name,_name) and _cargo:GetType() ~= CTLD_CARGO.Enum.REPAIR then
            match = true
            cargo = thiscargo
          end
        end
        if match then break end
      end
      return match, cargo
    end
    
      
    --local data = "LoadedData = {\n"
    local data = "Group,x,y,z,CargoName,CargoTemplates,CargoType,CratesNeeded,CrateMass\n"
    local n = 0
    for _,_grp in pairs(grouptable) do
      local group = _grp -- Wrapper.Group#GROUP
      if group and group:IsAlive() then
        -- get template name
        local name = group:GetName()
        local template = string.gsub(name,"-(.+)$","")
        if string.find(template,"#") then
          template = string.gsub(name,"#(%d+)$","")
        end
        
        local match, cargo = FindCargoType(template,cgotable)
        if not match then
          match, cargo = FindCargoType(template,cgovehic)
        end
        if match then
          n = n + 1
          local cargo = cargo -- #CTLD_CARGO
          local cgoname = cargo.Name
          local cgotemp = cargo.Templates
          local cgotype = cargo.CargoType
          local cgoneed = cargo.CratesNeeded
          local cgomass = cargo.PerCrateMass
          
          if type(cgotemp) == "table" then       
            local templates = "{"
            for _,_tmpl in pairs(cgotemp) do
              templates = templates .. _tmpl .. ";"
            end
            templates = templates .. "}"
            cgotemp = templates
          end
          
          local location = group:GetVec3()
          local txt = string.format("%s,%d,%d,%d,%s,%s,%s,%d,%d\n"
              ,template,location.x,location.y,location.z,cgoname,cgotemp,cgotype,cgoneed,cgomass)
          data = data .. txt
        end
      end
    end
    
    for _,_cgo in pairs(statics) do
      local object = _cgo -- #CTLD_CARGO
      local cgoname = object.Name
      local cgotemp = object.Templates
      
      if type(cgotemp) == "table" then       
        local templates = "{"
        for _,_tmpl in pairs(cgotemp) do
          templates = templates .. _tmpl .. ";"
        end
        templates = templates .. "}"
        cgotemp = templates
      end
      
      local cgotype = object.CargoType
      local cgoneed = object.CratesNeeded
      local cgomass = object.PerCrateMass
      local crateobj = object.Positionable
      local location = crateobj:GetVec3()
      local txt = string.format("%s,%d,%d,%d,%s,%s,%s,%d,%d\n"
          ,"STATIC",location.x,location.y,location.z,cgoname,cgotemp,cgotype,cgoneed,cgomass)
      data = data .. txt
    end
    
    _savefile(filename, data)
     
    -- AutoSave
    if self.enableLoadSave then
      local interval = self.saveinterval
      local filename = self.filename
      local filepath = self.filepath
      self:__Save(interval,filepath,filename)
    end
    return self
  end

  --- On before "Load" event. Checks if io and lfs and the file are available.
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is located. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for loading. Default is "CTLD_<alias>_Persist.csv".
  function CTLD:onbeforeLoad(From, Event, To, path, filename)
    self:T({From, Event, To, path, filename})
    if not self.enableLoadSave then
      return self
    end
    --- Function that check if a file exists.
    local function _fileexists(name)
       local f=io.open(name,"r")
       if f~=nil then
        io.close(f)
        return true
      else
        return false
      end
    end
    
    -- Set file name and path
    filename=filename or self.filename
    path = path or self.filepath
    
    -- Check io module is available.
    if not io then
      self:E(self.lid.."WARNING: io not desanitized. Cannot load file.")
      return false
    end
  
    -- Check default path.
    if path==nil and not lfs then
      self:E(self.lid.."WARNING: lfs not desanitized. State will be saved in DCS installation root directory rather than your \"Saved Games\\DCS\" folder.")
    end
  
    -- Set path or default.
    if lfs then
      path=path or lfs.writedir()
    end
  
    -- Set path.
    if path~=nil then
      filename=path.."\\"..filename
    end
  
    -- Check if file exists.
    local exists=_fileexists(filename)
  
    if exists then
      return true
    else
      self:E(self.lid..string.format("WARNING: State file %s might not exist.", filename))
      return false
      --return self
    end
  
  end

  --- On after "Load" event. Loads dropped units from file.
  -- @param #CTLD self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string path (Optional) Path where the file is located. Default is the DCS root installation folder or your "Saved Games\\DCS" folder if the lfs module is desanitized.
  -- @param #string filename (Optional) File name for loading. Default is "CTLD_<alias>_Persist.csv".
  function CTLD:onafterLoad(From, Event, To, path, filename)
    self:T({From, Event, To, path, filename})
    if not self.enableLoadSave then
      return self
    end
    --- Function that loads data from a file.
    local function _loadfile(filename)
      local f=assert(io.open(filename, "rb"))
      local data=f:read("*all")
      f:close()
      return data
    end
    
    -- Set file name and path
    filename=filename or self.filename
    path = path or self.filepath
    
    -- Set path or default.
    if lfs then
      path=path or lfs.writedir()
    end
  
    -- Set path.
    if path~=nil then
      filename=path.."\\"..filename
    end
  
    -- Info message.
    local text=string.format("Loading CTLD state from file %s", filename)
    MESSAGE:New(text,10):ToAllIf(self.Debug)
    self:I(self.lid..text)
    
    local file=assert(io.open(filename, "rb"))
    
    local loadeddata = {}
    for line in file:lines() do
      --self:I({line=type(line)})
        loadeddata[#loadeddata+1] = line
    end
    file:close()
    
    -- remove header
    table.remove(loadeddata, 1)
    
    for _id,_entry in pairs (loadeddata) do
      local dataset = UTILS.Split(_entry,",")     
      -- 1=Group,2=x,3=y,4=z,5=CargoName,6=CargoTemplates,7=CargoType,8=CratesNeeded,9=CrateMass
      local groupname = dataset[1]
      local vec2 = {}
      vec2.x = tonumber(dataset[2])
      vec2.y = tonumber(dataset[4])
      local cargoname = dataset[5]
      local cargotype = dataset[7]
      if type(groupname) == "string" and groupname ~= "STATIC" then
        local cargotemplates = dataset[6]
        cargotemplates = string.gsub(cargotemplates,"{","")
        cargotemplates = string.gsub(cargotemplates,"}","")
        cargotemplates = UTILS.Split(cargotemplates,";")
        local size = tonumber(dataset[8])
        local mass = tonumber(dataset[9])
        --self:I({groupname,vec3,cargoname,cargotemplates,cargotype,size,mass})
        -- inject at Vec2
        local dropzone = ZONE_RADIUS:New("DropZone",vec2,20)
        if cargotype == CTLD_CARGO.Enum.VEHICLE or cargotype == CTLD_CARGO.Enum.FOB then
          local injectvehicle = CTLD_CARGO:New(nil,cargoname,cargotemplates,cargotype,true,true,size,nil,true,mass)      
          self:InjectVehicles(dropzone,injectvehicle)
        elseif cargotype == CTLD_CARGO.Enum.TROOPS or cargotype == CTLD_CARGO.Enum.ENGINEERS then
          local injecttroops = CTLD_CARGO:New(nil,cargoname,cargotemplates,cargotype,true,true,size,nil,true,mass)      
          self:InjectTroops(dropzone,injecttroops)
        end
      elseif (type(groupname) == "string" and groupname == "STATIC") or cargotype == CTLD_CARGO.Enum.REPAIR then
        local cargotemplates = dataset[6]
        local size = tonumber(dataset[8])
        local mass = tonumber(dataset[9])
        local dropzone = ZONE_RADIUS:New("DropZone",vec2,20)
        -- STATIC,-84037,154,834021,Humvee,{Humvee;},Vehicle,1,100
        -- STATIC,-84036,154,834018,Ammunition-1,ammo_cargo,Static,1,500
        local injectstatic = nil
        if cargotype == CTLD_CARGO.Enum.VEHICLE or cargotype == CTLD_CARGO.Enum.FOB then
          cargotemplates = string.gsub(cargotemplates,"{","")
          cargotemplates = string.gsub(cargotemplates,"}","")
          cargotemplates = UTILS.Split(cargotemplates,";")
          injectstatic = CTLD_CARGO:New(nil,cargoname,cargotemplates,cargotype,true,true,size,nil,true,mass)      
        elseif cargotype == CTLD_CARGO.Enum.STATIC or cargotype == CTLD_CARGO.Enum.REPAIR then
          injectstatic = CTLD_CARGO:New(nil,cargoname,cargotemplates,cargotype,true,true,size,nil,true,mass) 
        end
        if injectstatic then
          self:InjectStatics(dropzone,injectstatic)
        end
      end    
    end
    
    return self
  end
end -- end do
-------------------------------------------------------------------
-- End Ops.CTLD.lua
-------------------------------------------------------------------