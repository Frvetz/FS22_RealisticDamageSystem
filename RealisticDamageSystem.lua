-- by Frvetz
-- Contact: RealisticDamageSystem@gmail.com
-- THANKS TO W33ZL (POWER TOOLS MOD) FOR LETTING ME USE HIS MENU!
-- THANKS TO MECHMOXER FOR LETTING ME USE THE IDEA OF THE ENGINE DIE FUNCTION
-- THANKS TO [SbSh] SEBATIAN MODASTIAN FOR MULTIPLAYER TESTING
-- Date 02.12.2021


--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--load event file for multiplayer sync and file for maintenance GUI
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
source(g_currentModDirectory.."events/SyncClientServerEvent.lua") --multiplayer event file
source(g_currentModDirectory .. "src/GUI/RealisticDamageSystemGUI.lua") --maintenance GUI

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--main script
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
RealisticDamageSystem = {};
RealisticDamageSystem.l10nEnv = "FS22_RealisticDamageSystem"; --need this to prevent localization error
RealisticDamageSystem.modDirectory = g_currentModDirectory; --need modDirectory for help menu

RealisticDamageSystem.wartungsEvent = nil; --whole button event itself
RealisticDamageSystem.ShowButton = false; --set to true if in range of a maintenance pallet

RealisticDamageSystem.ResetDamagesCommand = false; --set to true if console command for resetting the damages is called
RealisticDamageSystem.RemoveDamagesCommand = 0; --set how many damages should be removed
RealisticDamageSystem.FindDamagesCommand = false; --set to true if hidden damages should be uncovered
RealisticDamageSystem.ResetTimeUntilInspectionCommand = false; --set to true if console command for resetting the inspection is called
RealisticDamageSystem.StopActiveRepairCommand = false; --set to true if console command for stoping an active repair is called
RealisticDamageSystem.DebugCommand = false; --set to true if console command for DebugCommand is called
RealisticDamageSystem.DebugCommandOnce = false; --set to true if console command for DebugCommandOnce is called
RealisticDamageSystem.ResetTimeUntilNextDamageCommand = false; --set to true if console command for resetting the time until the next damage occurs is called
RealisticDamageSystem.ResetEverythingCommand = false; --set to true if console command for resetting everything is called
RealisticDamageSystem.TimeUntilInspectionCommand = 0; --set the time until the next inspection is needed

RealisticDamageSystem.UsersHadTutorialDialog = {} --users who had the chance to start the tutorial
RealisticDamageSystem.MaintenancePallets = {};	--create table where every maintenance pallet is stored

function RealisticDamageSystem.prerequisitesPresent(specializations)
	return true;
end;

function RealisticDamageSystem.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", RealisticDamageSystem);
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", RealisticDamageSystem);
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", RealisticDamageSystem);
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", RealisticDamageSystem);
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", RealisticDamageSystem);
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", RealisticDamageSystem);
    SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", RealisticDamageSystem);
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", RealisticDamageSystem);
end;

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--overwrite getCanMotorRun function to disable the motor start when maintenance active
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanMotorRun", RealisticDamageSystem.getCanMotorRun);
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--set button event
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:onRegisterActionEvents()
    if self.getIsEntered ~= nil and self:getIsEntered() then
		RealisticDamageSystem.actionEvents = {}
		_, RealisticDamageSystem.wartungsEvent = self:addActionEvent(RealisticDamageSystem.actionEvents, 'VEHICLE_MAINTENANCE', self, RealisticDamageSystem.DIALOG_MAINTENANCE, false, true, false, true, nil)
		g_inputBinding:setActionEventTextPriority(RealisticDamageSystem.wartungsEvent, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventTextVisibility(RealisticDamageSystem.wartungsEvent, false)
		g_inputBinding:setActionEventActive(RealisticDamageSystem.wartungsEvent, false)
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--create variables when starting savegame
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:onLoad(savegame)
	local spec = self.spec_RealisticDamageSystem

	if spec ~= nil then

		-- First savegame load ever with the mod
		
		spec.FirstLoadNumbersSet = false; --don't reset the numbers that are saved at the first start ever

		-- Motor false start

		spec.MotorDieTimer = -1; --motor false start timer for double ignition sound
		spec.NumberMotorDieTimer = 0; --motor false start timer for double ignition sound
		spec.RandomNumber = 0; --random number to decide whether the motor false start or not
		spec.TimesSoundPlayed = 4; --number goes up when second motor start sound played
		spec.DontStopMotor = false; --need this for motor false start
		spec.LoadTooHigh = false; --engine died because load was too high
		spec.BlinkingWarningTimer = -1; --timer for blinking warning visibility
		spec.NumberBlinkingWarningTimer = 0; --timer for blinking warning visibility
		
		-- Damages

		spec.NextKnownDamageOperatingHour = 0; --next operating hour when a known damage occurs --float --need /10 to get a decimal number
		spec.NextKnownDamageAge = 0; --next age when a known damage occurs
		spec.NextUnknownDamageOperatingHour = 0; --next operating hour when an unknown damage occurs --float --need /10 to get a decimal number
		spec.NextUnknownDamageAge = 0; --next age when an unknown damage occurs
		spec.TotalNumberOfDamages = 0; --hidden damages + visible damages + found damages by inspection
		spec.forDBL_TotalNumberOfDamagesPlayerKnows = 0; --visible damages + found damages by inspection
		spec.TotalNumberOfDamagesPlayerDoesntKnow = 0; --visible damages + found damages by inspection
		spec.AllDamagesTable = {}; --all damages in one table (with length - price - costs)
		spec.LengthForDamages = {}; --length for every damage in one table
		spec.forDBL_NextInspectionMonths = 12; --number of months until the next inspection is needed
		spec.NextInspectionAge = 0; --vehicle age when the next inspection is needed
		spec.VehiclePrice = self:getPrice(); --vehicle price needed for damage price calculation in file RealisticDamageSystemGUI
		spec.DamagesThatAddedWear = 0; --needed to check if a new damaged was created and the vanilla damage amount of the vehicle needs to be updated
		spec.DialogSelectedOptionCallback = 0; --set when starting a repair how many damages will be repaired to remove the vehicle damage afterwards
		spec.DamagesMultiplier = 1; --need to compare to global damages multiplier to reset the next damage time if changed
		spec.forDBL_EngineLight = false; --set to true if engine is in critial condition

		-- Variables for maintenance and inspection active
		
		spec.MaintenanceActive = false; --maintenance is active
		spec.InspectionActive = false; --inspection is active
		spec.FinishDay = 0; --day when the maintenance or inspection or CVT-repair is finished
		spec.FinishHour = 0; --hour when the maintenance or inspection or CVT-repair is finished
		spec.FinishMinute = 0; --minute when the maintenance or inspection or CVT-repair is finished

		-- External mod CVT_Addon

		spec.CVTRepairActive = false; --CVT-repair active
		spec.CVTlength = 0; --CVT-repair length
		spec.CVTcosts = 0; --CVT-repair costs
		
		-- Tutorial

		spec.TutorialStarted = false; --Tutorial is started
		spec.TutorialUpdateFinishedTime = false; --Example in tutorial for when the maintenance needs to be paused
		spec.InsertDamagesInTable = 0; --when tutorial started, only one example damage is shown in the maintenance menu
		
		-- Multiplayer

		spec.dirtyFlag = self:getNextDirtyFlag() --multiplayer sync
		spec.MultiplayerCosts = 0;

		-- maintenance menu
		
		spec.menuIsOpen = false
	end

	-- create new "spec" for CVTAddon to let CVT ask separately if this script is active

	self.spec_RealisticDamageSystemEngineDied = {}
	self.spec_RealisticDamageSystemEngineDied.EngineDied = false

	-- insert every pallet on the map into a table to find location later

	if self.typeName == "FS22_RealisticDamageSystem.palletMaintencance" then --searches for the Pallet
		RealisticDamageSystem.MaintenancePallets[self.rootNode] = {} --insert pallets in table
	end;

	-- set damage multiplier from Configure Maintenance mod
	if FS22_Configure_Maintenance ~= nil and FS22_Configure_Maintenance.ReduceMaintenanceSettings ~= nil then
		RealisticDamageSystem.DamagesMultiplier = FS22_Configure_Maintenance.g_r_maintenance.maintenanceDuration
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--load multiplayer XML (saved for every player if he had the option to start the tutorial)
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem.loadedMission(mission, node)
    if mission:getIsServer() then
        if mission.missionInfo.savegameDirectory ~= nil and fileExists(mission.missionInfo.savegameDirectory .. "/RealisticDamageSystemMultiplayer.xml") then
            local xmlFile = XMLFile.load("RealisticDamageSystemMultiplayer", mission.missionInfo.savegameDirectory .. "/RealisticDamageSystemMultiplayer.xml")
            if xmlFile ~= nil then
				if xmlFile:getString("RealisticDamageSystemMultiplayer.PlayerHadTutorialQuestion#playerIDs") ~= nil then
					RealisticDamageSystem.UsersHadTutorialDialog = RealisticDamageSystem:MPStringToTable(xmlFile:getString("RealisticDamageSystemMultiplayer.PlayerHadTutorialQuestion#playerIDs"))
				end
                xmlFile:delete()
            end
        end
    end
    if mission.cancelLoading then
        return
    end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--save multiplayer XML (saved for every player if he had the option to start the tutorial)
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem.saveToEXTRAXMLFile(missionInfo)
	if missionInfo.isValid then
        local xmlFile = XMLFile.create("RealisticDamageSystemMultiplayer", missionInfo.savegameDirectory .. "/RealisticDamageSystemMultiplayer.xml", "RealisticDamageSystemMultiplayer")
        if xmlFile ~= nil then
			if RealisticDamageSystem.UsersHadTutorialDialog ~= nil then
				xmlFile:setString("RealisticDamageSystemMultiplayer.PlayerHadTutorialQuestion#playerIDs", RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog))
			end
            xmlFile:save()
            xmlFile:delete()
        end
    end
end


--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--create values in XML for every vehicle
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem.initSpecialization()
	local schemaSavegame = Vehicle.xmlSchemaSavegame
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).RealisticDamageSystem#NextInspectionAge")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).RealisticDamageSystem#DamagesThatAddedWear")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).RealisticDamageSystem#FinishDay")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).RealisticDamageSystem#FinishHour")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).RealisticDamageSystem#FinishMinute")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).RealisticDamageSystem#DialogSelectedOptionCallback")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).RealisticDamageSystem#NextKnownDamageAge")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).RealisticDamageSystem#NextUnknownDamageAge")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).RealisticDamageSystem#TotalNumberOfDamagesPlayerKnows")
    schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).RealisticDamageSystem#TotalNumberOfDamagesPlayerDoesntKnow")
	
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).RealisticDamageSystem#NextKnownDamageOperatingHour")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).RealisticDamageSystem#NextUnknownDamageOperatingHour")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).RealisticDamageSystem#DamagesMultiplier")

	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).RealisticDamageSystem#FirstLoadNumbersSet")
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).RealisticDamageSystem#MaintenanceActive")
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).RealisticDamageSystem#InspectionActive")
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).RealisticDamageSystem#CVTRepairActive")
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).RealisticDamageSystem#EngineDied")

	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).RealisticDamageSystem#LengthForDamages")
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--load values in XML for every vehicle
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:onPostLoad(savegame)
	local spec = self.spec_RealisticDamageSystem

	if spec ~= nil then
		if savegame ~= nil then
			local xmlFile = savegame.xmlFile
			local key = savegame.key .. ".RealisticDamageSystem"
			
			spec.NextInspectionAge = xmlFile:getValue(key.."#NextInspectionAge", spec.NextInspectionAge)
			spec.DamagesThatAddedWear = xmlFile:getValue(key.."#DamagesThatAddedWear", spec.DamagesThatAddedWear)
			spec.FinishDay = xmlFile:getValue(key.."#FinishDay", spec.FinishDay)
			spec.FinishHour = xmlFile:getValue(key.."#FinishHour", spec.FinishHour)
			spec.FinishMinute = xmlFile:getValue(key.."#FinishMinute", spec.FinishMinute)
			spec.DialogSelectedOptionCallback = xmlFile:getValue(key.."#DialogSelectedOptionCallback", spec.DialogSelectedOptionCallback)
			spec.NextKnownDamageAge = xmlFile:getValue(key.."#NextKnownDamageAge", spec.NextKnownDamageAge)
			spec.NextUnknownDamageAge = xmlFile:getValue(key.."#NextUnknownDamageAge", spec.NextUnknownDamageAge)
			spec.forDBL_TotalNumberOfDamagesPlayerKnows = xmlFile:getValue(key.."#TotalNumberOfDamagesPlayerKnows", spec.forDBL_TotalNumberOfDamagesPlayerKnows)
			spec.TotalNumberOfDamagesPlayerDoesntKnow = xmlFile:getValue(key.."#TotalNumberOfDamagesPlayerDoesntKnow", spec.TotalNumberOfDamagesPlayerDoesntKnow)

			spec.NextKnownDamageOperatingHour = xmlFile:getValue(key.."#NextKnownDamageOperatingHour", spec.NextKnownDamageOperatingHour)
			spec.NextUnknownDamageOperatingHour = xmlFile:getValue(key.."#NextUnknownDamageOperatingHour", spec.NextUnknownDamageOperatingHour)
			spec.DamagesMultiplier = xmlFile:getValue(key.."#DamagesMultiplier", spec.DamagesMultiplier)

			spec.FirstLoadNumbersSet = xmlFile:getValue(key.."#FirstLoadNumbersSet", spec.FirstLoadNumbersSet)
			spec.MaintenanceActive = xmlFile:getValue(key.."#MaintenanceActive", spec.MaintenanceActive)
			spec.InspectionActive = xmlFile:getValue(key.."#InspectionActive", spec.InspectionActive)
			spec.CVTRepairActive = xmlFile:getValue(key.."#CVTRepairActive", spec.CVTRepairActive)
			spec.CVTRepairActive = xmlFile:getValue(key.."#EngineDied", self.spec_RealisticDamageSystemEngineDied.EngineDied)

			spec.LengthForDamages = RealisticDamageSystem:StringToLengthTable(xmlFile:getValue(key.."#LengthForDamages", spec.LengthForDamages))
		end
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--save values in XML for every vehicle
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_RealisticDamageSystem
	
	if spec ~= nil then
		xmlFile:setValue(key.."#NextInspectionAge", spec.NextInspectionAge)
		xmlFile:setValue(key.."#DamagesThatAddedWear", spec.DamagesThatAddedWear)
		xmlFile:setValue(key.."#FinishDay", spec.FinishDay)
		xmlFile:setValue(key.."#FinishHour", spec.FinishHour)
		xmlFile:setValue(key.."#FinishMinute", spec.FinishMinute)
		xmlFile:setValue(key.."#DialogSelectedOptionCallback", spec.DialogSelectedOptionCallback)
		xmlFile:setValue(key.."#NextKnownDamageAge", spec.NextKnownDamageAge)
		xmlFile:setValue(key.."#NextUnknownDamageAge", spec.NextUnknownDamageAge)
		xmlFile:setValue(key.."#TotalNumberOfDamagesPlayerKnows", spec.forDBL_TotalNumberOfDamagesPlayerKnows)
		xmlFile:setValue(key.."#TotalNumberOfDamagesPlayerDoesntKnow", spec.TotalNumberOfDamagesPlayerDoesntKnow)

		xmlFile:setValue(key.."#NextKnownDamageOperatingHour", spec.NextKnownDamageOperatingHour)
		xmlFile:setValue(key.."#NextUnknownDamageOperatingHour", spec.NextUnknownDamageOperatingHour)
		xmlFile:setValue(key.."#DamagesMultiplier", spec.DamagesMultiplier)

		xmlFile:setValue(key.."#FirstLoadNumbersSet", spec.FirstLoadNumbersSet)
		xmlFile:setValue(key.."#MaintenanceActive", spec.MaintenanceActive)
		xmlFile:setValue(key.."#InspectionActive", spec.InspectionActive)
		xmlFile:setValue(key.."#CVTRepairActive", spec.CVTRepairActive)
		xmlFile:setValue(key.."#EngineDied", self.spec_RealisticDamageSystemEngineDied.EngineDied)

		xmlFile:setValue(key.."#LengthForDamages", RealisticDamageSystem:LengthTableToString(spec.LengthForDamages))
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--multiplayer sync
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:onReadStream(streamId, connection)
	local spec = self.spec_RealisticDamageSystem

	if spec ~= nil then
		spec.NextInspectionAge = streamReadInt32(streamId)
		spec.DamagesThatAddedWear = streamReadInt32(streamId)
		spec.FinishDay = streamReadInt32(streamId)
		spec.FinishHour = streamReadInt32(streamId)
		spec.FinishMinute = streamReadInt32(streamId)
		spec.DialogSelectedOptionCallback = streamReadInt32(streamId)
		spec.NextKnownDamageAge = streamReadInt32(streamId)
		spec.NextUnknownDamageAge = streamReadInt32(streamId)
		spec.forDBL_TotalNumberOfDamagesPlayerKnows = streamReadInt32(streamId)
		spec.TotalNumberOfDamagesPlayerDoesntKnow = streamReadInt32(streamId)
		
		spec.NextKnownDamageOperatingHour = streamReadFloat32(streamId)
		spec.NextUnknownDamageOperatingHour = streamReadFloat32(streamId)
		spec.DamagesMultiplier = streamReadFloat32(streamId)

		spec.FirstLoadNumbersSet = streamReadBool(streamId)
		spec.MaintenanceActive = streamReadBool(streamId)
		spec.InspectionActive = streamReadBool(streamId)
		spec.CVTRepairActive = streamReadBool(streamId)
		self.spec_RealisticDamageSystemEngineDied.EngineDied = streamReadBool(streamId)

		spec.LengthForDamages = RealisticDamageSystem:StringToLengthTable(streamReadString(streamId))
		RealisticDamageSystem.UsersHadTutorialDialog = RealisticDamageSystem:MPStringToTable(streamReadString(streamId))
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--multiplayer sync
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:onWriteStream(streamId, connection)
	local spec = self.spec_RealisticDamageSystem

	if spec ~= nil then
		streamWriteInt32(streamId, spec.NextInspectionAge)
		streamWriteInt32(streamId, spec.DamagesThatAddedWear)
		streamWriteInt32(streamId, spec.FinishDay)
		streamWriteInt32(streamId, spec.FinishHour)
		streamWriteInt32(streamId, spec.FinishMinute)
		streamWriteInt32(streamId, spec.DialogSelectedOptionCallback)
		streamWriteInt32(streamId, spec.NextKnownDamageAge)
		streamWriteInt32(streamId, spec.NextUnknownDamageAge)
		streamWriteInt32(streamId, spec.forDBL_TotalNumberOfDamagesPlayerKnows)
		streamWriteInt32(streamId, spec.TotalNumberOfDamagesPlayerDoesntKnow)

		streamWriteFloat32(streamId, spec.NextKnownDamageOperatingHour)
		streamWriteFloat32(streamId, spec.NextUnknownDamageOperatingHour)
		streamWriteFloat32(streamId, spec.DamagesMultiplier)

		streamWriteBool(streamId, spec.FirstLoadNumbersSet)
		streamWriteBool(streamId, spec.MaintenanceActive)
		streamWriteBool(streamId, spec.InspectionActive)
		streamWriteBool(streamId, spec.CVTRepairActive)
		streamWriteBool(streamId, self.spec_RealisticDamageSystemEngineDied.EngineDied)

		streamWriteString(streamId, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages))
		streamWriteString(streamId, RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog))
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--multiplayer sync
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() then
		local spec = self.spec_RealisticDamageSystem
		
		if streamReadBool(streamId) then
			if spec ~= nil then
				spec.NextInspectionAge = streamReadInt32(streamId)
				spec.DamagesThatAddedWear = streamReadInt32(streamId)
				spec.FinishDay = streamReadInt32(streamId)
				spec.FinishHour = streamReadInt32(streamId)
				spec.FinishMinute = streamReadInt32(streamId)
				spec.DialogSelectedOptionCallback = streamReadInt32(streamId)
				spec.MultiplayerCosts = streamReadInt32(streamId)
				spec.NextKnownDamageAge = streamReadInt32(streamId)
				spec.NextUnknownDamageAge = streamReadInt32(streamId)
				spec.forDBL_TotalNumberOfDamagesPlayerKnows = streamReadInt32(streamId)
				spec.TotalNumberOfDamagesPlayerDoesntKnow = streamReadInt32(streamId)
				
				spec.NextKnownDamageOperatingHour = streamReadFloat32(streamId)
				spec.NextUnknownDamageOperatingHour = streamReadFloat32(streamId)
				spec.DamagesMultiplier = streamReadFloat32(streamId)

				spec.FirstLoadNumbersSet = streamReadBool(streamId)
				spec.MaintenanceActive = streamReadBool(streamId)
				spec.InspectionActive = streamReadBool(streamId)
				spec.CVTRepairActive = streamReadBool(streamId)
				self.spec_RealisticDamageSystemEngineDied.EngineDied = streamReadBool(streamId)

				spec.LengthForDamages = RealisticDamageSystem:StringToLengthTable(streamReadString(streamId))
				RealisticDamageSystem.UsersHadTutorialDialog = RealisticDamageSystem:MPStringToTable(streamReadString(streamId))
			end
		end
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--multiplayer sync
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:onWriteUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local spec = self.spec_RealisticDamageSystem
		if spec ~= nil then
			if spec.dirtyFlag ~= nil then
				if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
					streamWriteInt32(streamId, spec.NextInspectionAge)
					streamWriteInt32(streamId, spec.DamagesThatAddedWear)
					streamWriteInt32(streamId, spec.FinishDay)
					streamWriteInt32(streamId, spec.FinishHour)
					streamWriteInt32(streamId, spec.FinishMinute)
					streamWriteInt32(streamId, spec.DialogSelectedOptionCallback)
					streamWriteInt32(streamId, spec.MultiplayerCosts)
					streamWriteInt32(streamId, spec.NextKnownDamageAge)
					streamWriteInt32(streamId, spec.NextUnknownDamageAge)
					streamWriteInt32(streamId, spec.forDBL_TotalNumberOfDamagesPlayerKnows)
					streamWriteInt32(streamId, spec.TotalNumberOfDamagesPlayerDoesntKnow)
					
					streamWriteFloat32(streamId, spec.NextKnownDamageOperatingHour)
					streamWriteFloat32(streamId, spec.NextUnknownDamageOperatingHour)
					streamWriteFloat32(streamId, spec.DamagesMultiplier)

					streamWriteBool(streamId, spec.FirstLoadNumbersSet)
					streamWriteBool(streamId, spec.MaintenanceActive)
					streamWriteBool(streamId, spec.InspectionActive)
					streamWriteBool(streamId, spec.CVTRepairActive)
					streamWriteBool(streamId, self.spec_RealisticDamageSystemEngineDied.EngineDied)

					streamWriteString(streamId, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages))
					streamWriteString(streamId, RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog))

					spec.MultiplayerCosts = 0
				end
			else 
				streamWriteBool(streamId, false)
			end
		end
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--multiplayer sync event
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem.SyncClientServer(vehicle, NextInspectionAge, DamagesThatAddedWear, FinishDay, FinishHour, FinishMinute, DialogSelectedOptionCallback, NextKnownDamageAge, NextUnknownDamageAge, forDBL_TotalNumberOfDamagesPlayerKnows, TotalNumberOfDamagesPlayerDoesntKnow, NextKnownDamageOperatingHour, NextUnknownDamageOperatingHour, DamagesMultiplier, FirstLoadNumbersSet, MaintenanceActive, InspectionActive, CVTRepairActive, EngineDied, LengthForDamages, UsersHadTutorialDialog)
	local spec = vehicle.spec_RealisticDamageSystem

	spec.NextInspectionAge = NextInspectionAge
	spec.DamagesThatAddedWear = DamagesThatAddedWear
	spec.FinishDay = FinishDay
	spec.FinishHour = FinishHour
	spec.FinishMinute = FinishMinute
	spec.DialogSelectedOptionCallback = DialogSelectedOptionCallback
	spec.NextKnownDamageAge = NextKnownDamageAge
	spec.NextUnknownDamageAge = NextUnknownDamageAge
	spec.forDBL_TotalNumberOfDamagesPlayerKnows = forDBL_TotalNumberOfDamagesPlayerKnows
	spec.TotalNumberOfDamagesPlayerDoesntKnow = TotalNumberOfDamagesPlayerDoesntKnow

	spec.NextKnownDamageOperatingHour = NextKnownDamageOperatingHour
	spec.NextUnknownDamageOperatingHour = NextUnknownDamageOperatingHour
	spec.DamagesMultiplier = DamagesMultiplier
	
	spec.FirstLoadNumbersSet = FirstLoadNumbersSet
	spec.MaintenanceActive = MaintenanceActive
	spec.InspectionActive = InspectionActive
	spec.CVTRepairActive = CVTRepairActive
	vehicle.spec_RealisticDamageSystemEngineDied.EngineDied = EngineDied

	spec.LengthForDamages = RealisticDamageSystem:StringToLengthTable(LengthForDamages)
	RealisticDamageSystem.UsersHadTutorialDialog = RealisticDamageSystem:MPStringToTable(UsersHadTutorialDialog)
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--everything that happens all the time when playing
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.spec_motorized ~= nil then
		local spec = self.spec_RealisticDamageSystem
		local changeFlag = false --change to true when multiplayer needs to be synced

		if self.isClient and isActiveForInputIgnoreSelection then
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--set values that need to be saved only on the first load with the mod
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			if spec.FirstLoadNumbersSet ~= true then
				spec.forDBL_TotalNumberOfDamagesPlayerKnows = math.floor(self:getDamageAmount() * 12) --set damages according to vehicle damage
				
				spec.NextInspectionAge = self.age + 12 --set time until next inspection to 12
				spec.NextKnownDamageAge = self.age + RealisticDamageSystem:RoundValue(math.random(6, 13) / RealisticDamageSystem.DamagesMultiplier, 0); --next age when a known damage occurs
				spec.NextUnknownDamageAge = self.age + RealisticDamageSystem:RoundValue(math.random(3, 10) / RealisticDamageSystem.DamagesMultiplier, 0); --next age when an unknown damage occurs
				spec.NextKnownDamageOperatingHour = self:getFormattedOperatingTime() + RealisticDamageSystem:RoundValue((math.random (45, 75) / 10) / RealisticDamageSystem.DamagesMultiplier, 1); --next operating hour when a known damage occurs --float --need /10 to get a decimal number
				spec.NextUnknownDamageOperatingHour = self:getFormattedOperatingTime() + RealisticDamageSystem:RoundValue((math.random (105, 135) / 10) / RealisticDamageSystem.DamagesMultiplier, 1); --next operating hour when an unknown damage occurs --float --need /10 to get a decimal number

				self:setDamageAmount(0, true) -- reset damage to set it later in the script to the proper amount
				
				spec.FirstLoadNumbersSet = true

				changeFlag = true --multiplayer sync
			end;
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--ask player if he wants to start the tutorial
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			if RealisticDamageSystem.UsersHadTutorialDialog[getUniqueUserId()] == nil then
				if not spec.MaintenanceActive and not spec.InspectionActive and not spec.CVTRepairActive then
					g_gui:showYesNoDialog(
						{
							text = g_i18n:getText("tutorial_Question_text", RealisticDamageSystem.l10nEnv),
							title = g_i18n:getText("tutorial_Question_title", RealisticDamageSystem.l10nEnv),
							target = self,
							callback = RealisticDamageSystem.Tutorial,
						}
					)

					--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
					--insert unique user id into table to make sure every player in multiplayer gets the question only once
					--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
					RealisticDamageSystem.UsersHadTutorialDialog[getUniqueUserId()] = {}

					changeFlag = true --multiplayer sync
				else
					if spec.CVTRepairActive then
						g_currentMission:showBlinkingWarning(g_i18n:getText("warning_CantStartTutorialCVT", RealisticDamageSystem.l10nEnv), 500) --show warning
					elseif spec.InspectionActive then
						g_currentMission:showBlinkingWarning(g_i18n:getText("warning_CantStartTutorialInspection", RealisticDamageSystem.l10nEnv), 500) --show warning
					else
						g_currentMission:showBlinkingWarning(g_i18n:getText("warning_CantStartTutorialMaintenance", RealisticDamageSystem.l10nEnv), 500) --show warning
					end
				end
			end
			
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--when maintenance menu is open, update the text for every selection (update price and length)
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			local dialog = g_gui.guis["OptionDialog"]
			if dialog ~= nil then
				if dialog.target.isOpen then
					if spec.menuIsOpen == true then --set menu is open
						if self.spec_CVTaddon ~= nil and self.spec_CVTaddon.CVTdamage ~= nil and self.spec_CVTaddon.isVarioTM then
							RealisticDamageSystemGUI:setText(dialog, spec, self.spec_CVTaddon)
						elseif self.spec_CVTaddon ~= nil and self.spec_CVTaddon.CVTdamage ~= nil and spec.TutorialStarted then
							RealisticDamageSystemGUI:setText(dialog, spec, self.spec_CVTaddon)
						else
							RealisticDamageSystemGUI:setText(dialog, spec, nil)
						end
					end
				elseif not dialog.target.isOpen and spec.menuIsOpen == true then
					local Dialog = dialog.target.optionElement.target

					spec.menuIsOpen = false --set menu is open

					if Dialog.newButtonInspection ~= nil then -- delete button to prevent mod conflict
						Dialog.newButtonInspection:delete()	-- works so never touch a running system
						Dialog.newButtonInspection = nil -- workes so never touch a running system
					end
					if dialog.target.dialogTextElementCVT ~= nil then -- delete text to prevent mod conflict
						dialog.target.dialogTextElementCVT:delete() -- works so never touch a running system
						dialog.target.dialogTextElementCVT = nil -- workes so never touch a running system
					end
					if Dialog.newButtonCVT ~= nil then -- delete button to prevent mod conflict
						Dialog.newButtonCVT:delete() -- works so never touch a running system
						Dialog.newButtonCVT = nil  -- workes so never touch a running system
					end
					if Dialog.yesButton ~= nil then -- enable button after tutorial again
						Dialog.yesButton.disabled = false -- enable button after tutorial again
					end
					if Dialog.noButton ~= nil then -- enable button after tutorial again
						Dialog.noButton.disabled = false -- enable button after tutorial again
					end
				end
			end
			
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--motor false start and die function when total damages are > 8
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			if spec.TotalNumberOfDamages >= 9 and spec.MaintenanceActive ~= true and spec.InspectionActive ~= true and spec.CVTRepairActive ~= true then
				if g_currentMission.missionInfo.automaticMotorStartEnabled == false then
					if spec.RandomNumber == 0 then
						spec.RandomNumber = math.random(1, 3) --motor doens't start when random number is 1
					end;
					if spec.DontStopMotor == false then
						if self:getIsMotorStarted() then
							spec.MotorDieTimer = spec.MotorDieTimer - dt
							spec.NumberMotorDieTimer = math.min(-spec.MotorDieTimer / 2000, 0.9) --timer for multiple ignition sound effect

							if spec.NumberMotorDieTimer >= 0.290789 then
								self:stopMotor() 												--stop motor
								spec.MotorDieTimer = -1 										--reset timer for multiple ignition sound effect
								self:startMotor() 												--start motor for multiple ignition sound effect
								spec.TimesSoundPlayed = spec.TimesSoundPlayed - 1 				--count down the times the sound played (4 times)
							end;
							if spec.RandomNumber == 1 and spec.NumberMotorDieTimer >= 0.290789 and spec.TimesSoundPlayed == 0 then --if random number is 1 -> don't start motor
								self:stopMotor()
								g_currentMission:showBlinkingWarning(g_i18n:getText("warning_MotorFailed", RealisticDamageSystem.l10nEnv), 2300) --show warning
								self.spec_RealisticDamageSystemEngineDied.EngineDied = true 	--set EngineDied for CVTneedClutch and NeedMotorStarted blinking warning
								spec.TimesSoundPlayed = 4										--reset TimesSoundPlayed
								spec.BlinkingWarningTimer = -1									--reset timer for blinking warning length
								spec.RandomNumber = 0											--set random number to 0 to reset it
							elseif spec.RandomNumber ~= 1 and spec.NumberMotorDieTimer >= 0.290789 and spec.TimesSoundPlayed == 1 then --if random number is not 1 -> start motor
								spec.DontStopMotor = true										--set DontStopMotor to prevent the vehicle from looping the multiple ignition sound effect
								spec.RandomNumber = 0											--set random number to 0 to reset it
								spec.TimesSoundPlayed = 4										--reset TimesSoundPlayed
							end;
						end;
					else
						if spec.LoadTooHigh ~= true then
							self.spec_RealisticDamageSystemEngineDied.EngineDied = false		--set EngineDied to false when vehicle is started again

							if self:getIsMotorStarted() then
								--giants bug:
								--vehicle has been started with the multiple ignition sound effect + any item in the shop has been selected and "opened" -> leads to the motor sound being stopped
								--everything else works fine, but the motor and gearbox sound is stopped (every other sound is still active as well)
								local MotorSounds = self.spec_motorized.motorSamples
								local gearboxSounds = self.spec_motorized.gearboxSamples
								if not g_soundManager:getIsSamplePlaying(MotorSounds[1]) then
									g_soundManager:playSamples(MotorSounds)
								end
								if not g_soundManager:getIsSamplePlaying(gearboxSounds[1]) then
									g_soundManager:playSamples(gearboxSounds)
								end
								if not g_soundManager:getIsSamplePlaying(self.spec_motorized.samples.retarder) then
									g_soundManager:playSample(self.spec_motorized.samples.retarder)
								end
							end
						end
					end;

					if not self:getIsMotorStarted() then
						spec.DontStopMotor = false 												--set DontStopMotor to allow the multiple ignition sound effect again
					end
				end;

				--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
				--stop motor if engine load is too high
				--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
				if self:getMotorLoadPercentage() > 0.999999 and spec.LoadTooHigh == false then
					self:stopMotor()																									--stop motor
					g_currentMission:showBlinkingWarning(g_i18n:getText("warning_MotorFailed", RealisticDamageSystem.l10nEnv), 2300) 	--show warning
					self.spec_RealisticDamageSystemEngineDied.EngineDied = true															--set EngineDied for CVTneedClutch and NeedMotorStarted blinking warning
					spec.LoadTooHigh = true																								--set LoadTooHigh to true to prevent the vehicle from stalling directly again because of a giants bug
					spec.BlinkingWarningTimer = -1																						--reset timer for blinking warning length
				elseif self:getMotorLoadPercentage() < 0.3 and spec.LoadTooHigh == true then
					spec.LoadTooHigh = false																							--set LoadTooHigh back to false to allow the engine to die again
				end;

				if self.spec_RealisticDamageSystemEngineDied.EngineDied then
					spec.BlinkingWarningTimer = spec.BlinkingWarningTimer - dt
					spec.NumberBlinkingWarningTimer = math.min(-spec.BlinkingWarningTimer / 2000, 1) --timer for blinking warning visibility

					--if blinking warning disappeared again -> set engineDied to false to enable the NeedMotorStarted and CVTneedClutch blinking warning again
					if spec.NumberBlinkingWarningTimer == 1 then
						self.spec_RealisticDamageSystemEngineDied.EngineDied = false
						spec.BlinkingWarningTimer = -1
					end
				end

				spec.forDBL_EngineLight = true
			else
				spec.forDBL_EngineLight = false
			end
			
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--looks for the position of the pallets and adds the action event if the vehicle is in range of one
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			local inRange = RealisticDamageSystem:inRangeOfPallet(RealisticDamageSystem.MaintenancePallets, self.rootNode, self.ownerFarmId)
			if inRange ~= nil then
				g_inputBinding:setActionEventTextVisibility(RealisticDamageSystem.wartungsEvent, true)
				g_inputBinding:setActionEventActive(RealisticDamageSystem.wartungsEvent, true)
			else
				g_inputBinding:setActionEventTextVisibility(RealisticDamageSystem.wartungsEvent, false)
				g_inputBinding:setActionEventActive(RealisticDamageSystem.wartungsEvent, false)
			end

			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--calculate time until next inspection
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			spec.forDBL_NextInspectionMonths = math.max(0, spec.NextInspectionAge - self.age)

			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--set text "inspection needed" when months until next inspection < 1
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			if spec.MaintenanceActive ~= true and spec.InspectionActive ~= true and spec.CVTRepairActive ~= true then
				if spec.forDBL_NextInspectionMonths == 0  then -- checks if a value is under 0
					g_currentMission:addExtraPrintText(g_i18n:getText("warning_wartung", RealisticDamageSystem.l10nEnv):format(spec.forDBL_TotalNumberOfDamagesPlayerKnows)) --set hud text
				else
					g_currentMission:addExtraPrintText(g_i18n:getText("information_Motor", RealisticDamageSystem.l10nEnv):format(spec.forDBL_NextInspectionMonths, spec.forDBL_TotalNumberOfDamagesPlayerKnows)) --set hud text
				end;
			end
			
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--calculate damages
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--

			---------------
			--known damages
			---------------
			--with operating hours
			if self:getFormattedOperatingTime() >= spec.NextKnownDamageOperatingHour then --if a new damage should occur then:
				spec.forDBL_TotalNumberOfDamagesPlayerKnows = spec.forDBL_TotalNumberOfDamagesPlayerKnows + 1 --add damage
				spec.NextKnownDamageOperatingHour = self:getFormattedOperatingTime() + RealisticDamageSystem:RoundValue((math.random (45, 75) / 10) / RealisticDamageSystem.DamagesMultiplier, 1) --calculate new operating time until the next damage --need /10 to get a decimal number (4.5 - 7.5)

				changeFlag = true --multiplayer sync
			end
			--with age
			if self.age >= spec.NextKnownDamageAge and (spec.InspectionActive or spec.MaintenanceActive or spec.CVTRepairActive) then --if a new damage should occur then:
				spec.NextKnownDamageAge = self.age + 1 --when active repair and new damage should be added: extend the time until the next damage so that no damage is being added during repair
			
				changeFlag = true --multiplayer sync
			elseif self.age >= spec.NextKnownDamageAge then
				spec.forDBL_TotalNumberOfDamagesPlayerKnows = spec.forDBL_TotalNumberOfDamagesPlayerKnows + 1 --add damage
				spec.NextKnownDamageAge = self.age + RealisticDamageSystem:RoundValue(math.random(6, 13) / RealisticDamageSystem.DamagesMultiplier, 0) --calculate new age until the next damage

				changeFlag = true --multiplayer sync
			end

			-----------------
			--unknown damages
			-----------------
			--with operating hours
			if self:getFormattedOperatingTime() >= spec.NextUnknownDamageOperatingHour then --if a new damage should occur then:
				spec.TotalNumberOfDamagesPlayerDoesntKnow = spec.TotalNumberOfDamagesPlayerDoesntKnow + 1 --add damage
				spec.NextUnknownDamageOperatingHour = self:getFormattedOperatingTime() + RealisticDamageSystem:RoundValue((math.random (105, 135) / 10) / RealisticDamageSystem.DamagesMultiplier, 1) --calculate new operating time until the next damage --need /10 to get a decimal number (10.5 - 13.5)

				changeFlag = true --multiplayer sync
			end
			--with age
			if self.age >= spec.NextUnknownDamageAge and (spec.InspectionActive or spec.MaintenanceActive or spec.CVTRepairActive) then --if a new damage should occur then:
				spec.NextUnknownDamageAge = self.age + 1 --when active repair and new damage should be added: extend the time until the next damage so that no damage is being added during repair

				changeFlag = true --multiplayer sync
			elseif self.age >= spec.NextUnknownDamageAge then
				spec.TotalNumberOfDamagesPlayerDoesntKnow = spec.TotalNumberOfDamagesPlayerDoesntKnow + 1 --add damage
				spec.NextUnknownDamageAge = self.age + RealisticDamageSystem:RoundValue(math.random(3, 10) / RealisticDamageSystem.DamagesMultiplier, 0) --calculate new age until the next damage

				changeFlag = true --multiplayer sync
			end

			--total damages
			spec.TotalNumberOfDamages = spec.TotalNumberOfDamagesPlayerDoesntKnow + spec.forDBL_TotalNumberOfDamagesPlayerKnows

			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--set vehicle damage if new damage has been created
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			if not g_currentMission.shopMenu.isOpen then
				if spec.TotalNumberOfDamages ~= spec.DamagesThatAddedWear then
					self:addDamageAmount((spec.TotalNumberOfDamages - spec.DamagesThatAddedWear) * 0.083, true) --add vehicle damage when new damage was created
					spec.DamagesThatAddedWear = spec.TotalNumberOfDamages
					
					changeFlag = true
				end
			end

			if math.abs(self:getDamageAmount() - spec.TotalNumberOfDamages * 0.083) >= 0.083 then --if vehicle damage does not represent the rds damage amount -> add rds damages
				spec.forDBL_TotalNumberOfDamagesPlayerKnows = spec.forDBL_TotalNumberOfDamagesPlayerKnows + math.floor((self:getDamageAmount() - spec.TotalNumberOfDamages * 0.083) / 0.083)
				spec.DamagesThatAddedWear = spec.DamagesThatAddedWear + math.floor((self:getDamageAmount() - spec.TotalNumberOfDamages * 0.083) / 0.083)
				
				changeFlag = true
			end

			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--everything that happens when maintenance is started
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			if spec.MaintenanceActive == true then
				if spec.FinishDay - g_currentMission.environment.currentDay ~= 1 then
					g_currentMission:addExtraPrintText(g_i18n:getText("information_wartungMoreDays", RealisticDamageSystem.l10nEnv):format(spec.FinishDay - g_currentMission.environment.currentDay, spec.FinishHour, spec.FinishMinute)) --show info when maintenance is finished
				else
					g_currentMission:addExtraPrintText(g_i18n:getText("information_wartung", RealisticDamageSystem.l10nEnv):format(spec.FinishHour, spec.FinishMinute)) --show info when maintenance is finished
				end

				self.spec_RealisticDamageSystemEngineDied.EngineDied = true 	--set EngineDied for CVTneedClutch and NeedMotorStarted blinking warning

				--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
				--everything that happens when finish time is reached
				--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
				if RealisticDamageSystem.StopActiveRepairCommand or ((g_currentMission.environment.currentDay > spec.FinishDay) or ((g_currentMission.environment.currentDay == spec.FinishDay and g_currentMission.environment.currentHour > spec.FinishHour)) or (g_currentMission.environment.currentDay == spec.FinishDay and g_currentMission.environment.currentHour >= spec.FinishHour and g_currentMission.environment.currentMinute >= spec.FinishMinute)) then
					if spec.DialogSelectedOptionCallback ~= 0 then --need this because DialogSelectedOptionCallback was not saved in the xml in a previous version and therefore could be 0 when reloading the savegame during a maintenance
						self:addDamageAmount(- (self:getDamageAmount() / spec.TotalNumberOfDamages) * spec.DialogSelectedOptionCallback, true) --remove so much vehicle damage, so that when you repair all damages at once, there is 0% damage left
					else
						self:setDamageAmount(0, true) --set vehicle damage to 0
					end
					spec.MaintenanceActive = false
					self.spec_RealisticDamageSystemEngineDied.EngineDied = false
					spec.forDBL_TotalNumberOfDamagesPlayerKnows = spec.forDBL_TotalNumberOfDamagesPlayerKnows - spec.DialogSelectedOptionCallback
					spec.DamagesThatAddedWear = spec.TotalNumberOfDamages - spec.DialogSelectedOptionCallback

					spec.DialogSelectedOptionCallback = 0

					--show info when maintenance is finished
					g_gui:showInfoDialog({
						titel = "titel",
						text = g_i18n:getText("dialog_maintenance_finishedInformation", RealisticDamageSystemMotorStartDialog.l10nEnv):format(spec.forDBL_TotalNumberOfDamagesPlayerKnows),
						})
					
					changeFlag = true --multiplayer sync
				end;
			end;
			
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--everything that happens when inspection is started
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			if spec.InspectionActive == true then
				g_currentMission:addExtraPrintText(g_i18n:getText("information_Inspection", RealisticDamageSystem.l10nEnv):format(spec.FinishHour, spec.FinishMinute)) --show info when inspection is finished

				self.spec_RealisticDamageSystemEngineDied.EngineDied = true 	--set EngineDied for CVTneedClutch and NeedMotorStarted blinking warning

				--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
				--everything that happens when finish time is reached
				--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
				if RealisticDamageSystem.StopActiveRepairCommand or ((g_currentMission.environment.currentDay > spec.FinishDay) or ((g_currentMission.environment.currentDay == spec.FinishDay and g_currentMission.environment.currentHour > spec.FinishHour)) or (g_currentMission.environment.currentDay == spec.FinishDay and g_currentMission.environment.currentHour >= spec.FinishHour and g_currentMission.environment.currentMinute >= spec.FinishMinute)) then
					--show info when inspection is finished
					g_gui:showInfoDialog({
					titel = "titel",
					text = g_i18n:getText("dialog_inspection_finishedInformation", RealisticDamageSystemMotorStartDialog.l10nEnv):format(spec.TotalNumberOfDamagesPlayerDoesntKnow, spec.forDBL_TotalNumberOfDamagesPlayerKnows + spec.TotalNumberOfDamagesPlayerDoesntKnow),
					})

					spec.InspectionActive = false
					self.spec_RealisticDamageSystemEngineDied.EngineDied = false
					spec.forDBL_TotalNumberOfDamagesPlayerKnows = spec.forDBL_TotalNumberOfDamagesPlayerKnows + spec.TotalNumberOfDamagesPlayerDoesntKnow
					spec.TotalNumberOfDamagesPlayerDoesntKnow = 0
					spec.NextInspectionAge = self.age + 12
					
					changeFlag = true --multiplayer sync
				end
			end

			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--FS22_CVT_Addon NEEDED!!  everything that happens when CVT-repair is started
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			if self.spec_CVTaddon ~= nil and self.spec_CVTaddon.CVTdamage ~= nil and self.spec_CVTaddon.isVarioTM then
				if spec.CVTRepairActive == true then
					self.spec_RealisticDamageSystemEngineDied.EngineDied = true 	--set EngineDied for CVTneedClutch and NeedMotorStarted blinking warning

					if self.spec_CVTaddon.CVTdamage >= 90 then
						g_currentMission:addExtraPrintText(g_i18n:getText("information_CVTChange", RealisticDamageSystem.l10nEnv):format(spec.FinishHour, spec.FinishMinute)) --show info when cvt-gearbox-change is finished
					else
						g_currentMission:addExtraPrintText(g_i18n:getText("information_CVTRepair", RealisticDamageSystem.l10nEnv):format(spec.FinishHour, spec.FinishMinute)) --show info when cvt-gearbox-repair is finished
					end
					--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
					--everything that happens when finish time is reached
					--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
					if RealisticDamageSystem.StopActiveRepairCommand or ((g_currentMission.environment.currentDay > spec.FinishDay) or ((g_currentMission.environment.currentDay == spec.FinishDay and g_currentMission.environment.currentHour > spec.FinishHour)) or (g_currentMission.environment.currentDay == spec.FinishDay and g_currentMission.environment.currentHour >= spec.FinishHour and g_currentMission.environment.currentMinute >= spec.FinishMinute)) then
						spec.CVTRepairActive = false
						self.spec_RealisticDamageSystemEngineDied.EngineDied = false

						self.spec_CVTaddon.CVTdamage = 0 --reset CVT-gearbox damage
						self.spec_CVTaddon.forDBL_critDamage = 0 --reset CVT-gearbox damage
						self.spec_CVTaddon.forDBL_warnHeat = 0 --reset CVT-gearbox damage
						self.spec_CVTaddon.forDBL_warnDamage = 0 --reset CVT-gearbox damage
						self.spec_CVTaddon.forDBL_critHeat = 0 --reset CVT-gearbox damage
						self.spec_CVTaddon.forDBL_critDamage = 0 --reset CVT-gearbox damage
						
						--show info when CVT-repair is finished
						g_gui:showInfoDialog({
						titel = "titel",
						text = g_i18n:getText("dialog_cvt_finishedInformation", RealisticDamageSystemMotorStartDialog.l10nEnv),
						})
						
						changeFlag = true --multiplayer sync
					end
				end
			end

			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			--when console command is called (need this because spec is nil in console command)
			--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			if RealisticDamageSystem.ResetDamagesCommand then
				self:setDamageAmount(0, true)
				spec.forDBL_TotalNumberOfDamagesPlayerKnows = 0
				spec.TotalNumberOfDamagesPlayerDoesntKnow = 0
				spec.DamagesThatAddedWear = 0

				RealisticDamageSystem.ResetDamagesCommand = false

				changeFlag = true --multiplayer sync
			end
			if RealisticDamageSystem.RemoveDamagesCommand ~= 0 then
				spec.DamagesThatAddedWear = spec.TotalNumberOfDamages - RealisticDamageSystem.RemoveDamagesCommand
				spec.forDBL_TotalNumberOfDamagesPlayerKnows = spec.forDBL_TotalNumberOfDamagesPlayerKnows - RealisticDamageSystem.RemoveDamagesCommand
				if RealisticDamageSystem.RemoveDamagesCommand > 0 then
					self:addDamageAmount(- ((self:getDamageAmount() / spec.TotalNumberOfDamages) * RealisticDamageSystem.RemoveDamagesCommand), true)
				else
					self:addDamageAmount(-RealisticDamageSystem.RemoveDamagesCommand * 0.083, true)
				end

				RealisticDamageSystem.RemoveDamagesCommand = 0

				changeFlag = true --multiplayer sync
			end
			if RealisticDamageSystem.FindDamagesCommand then
				spec.forDBL_TotalNumberOfDamagesPlayerKnows = spec.forDBL_TotalNumberOfDamagesPlayerKnows + spec.TotalNumberOfDamagesPlayerDoesntKnow
				spec.TotalNumberOfDamagesPlayerDoesntKnow = 0

				RealisticDamageSystem.FindDamagesCommand = false

				changeFlag = true --multiplayer sync
			end
			if RealisticDamageSystem.ResetTimeUntilInspectionCommand then
				spec.NextInspectionAge = self.age + 12

				RealisticDamageSystem.ResetTimeUntilInspectionCommand = false

				changeFlag = true --multiplayer sync
			end
			if RealisticDamageSystem.StopActiveRepairCommand then
				RealisticDamageSystem.StopActiveRepairCommand = false
			end
			if RealisticDamageSystem.DebugCommand then
				print("Vehicle name: "..tostring(self:getName()))
				print("Vehicle age: "..tostring(self.age))
				print("Vehicle operating time: "..tostring(self:getFormattedOperatingTime()))
				print("Finish day: "..tostring(spec.FinishDay))
				print("Current day: "..tostring(g_currentMission.environment.currentDay))
				print("Finish hour: "..tostring(spec.FinishHour))
				print("Current hour: "..tostring(g_currentMission.environment.currentHour))
				print("Finish minute: "..tostring(spec.FinishMinute))
				print("Current minute: "..tostring(g_currentMission.environment.currentMinute))
				print("Number of damages that added base game damage: "..tostring(spec.DamagesThatAddedWear))
				print("Total number of damages: "..tostring(spec.TotalNumberOfDamages))
				print("Total number of damages player knows: "..tostring(spec.forDBL_TotalNumberOfDamagesPlayerKnows))
				print("Total number of damages player doesnt know: "..tostring(spec.TotalNumberOfDamagesPlayerDoesntKnow))
				print("Next operating time for new known damage: "..tostring(spec.NextKnownDamageOperatingHour))
				print("Next operating time for new unknown damage: "..tostring(spec.NextUnknownDamageOperatingHour))
				print("Next age for new known damage: "..tostring(spec.NextKnownDamageAge))
				print("Next age for new unknown damage: "..tostring(spec.NextUnknownDamageAge))
				print("Vehicle age when the next inspection is needed: "..tostring(spec.NextInspectionAge))
				print("General damage multiplier setting: "..tostring(RealisticDamageSystem.DamagesMultiplier * 100))
				print("Vehicle damage multiplier (should be same as general): "..tostring(spec.DamagesMultiplier * 100))
				print("Players who had tutorial question:")
				DebugUtil.printTableRecursively(RealisticDamageSystem.UsersHadTutorialDialog, "-" , 0, 3)
			end
			if RealisticDamageSystem.DebugCommandOnce then
				print("Vehicle name: "..tostring(self:getName()))
				print("Vehicle age: "..tostring(self.age))
				print("Vehicle operating time: "..tostring(self:getFormattedOperatingTime()))
				print("Finish day: "..tostring(spec.FinishDay))
				print("Current day: "..tostring(g_currentMission.environment.currentDay))
				print("Finish hour: "..tostring(spec.FinishHour))
				print("Current hour: "..tostring(g_currentMission.environment.currentHour))
				print("Finish minute: "..tostring(spec.FinishMinute))
				print("Current minute: "..tostring(g_currentMission.environment.currentMinute))
				print("Number of damages that added base game damage: "..tostring(spec.DamagesThatAddedWear))
				print("Total number of damages: "..tostring(spec.TotalNumberOfDamages))
				print("Total number of damages player knows: "..tostring(spec.forDBL_TotalNumberOfDamagesPlayerKnows))
				print("Total number of damages player doesnt know: "..tostring(spec.TotalNumberOfDamagesPlayerDoesntKnow))
				print("Next operating time for new known damage: "..tostring(spec.NextKnownDamageOperatingHour))
				print("Next operating time for new unknown damage: "..tostring(spec.NextUnknownDamageOperatingHour))
				print("Next age for new known damage: "..tostring(spec.NextKnownDamageAge))
				print("Next age for new unknown damage: "..tostring(spec.NextUnknownDamageAge))
				print("Vehicle age when the next inspection is needed: "..tostring(spec.NextInspectionAge))
				print("General damage multiplier setting: "..tostring(RealisticDamageSystem.DamagesMultiplier * 100))
				print("Vehicle damage multiplier (should be same as general): "..tostring(spec.DamagesMultiplier * 100))
				print("Players who had tutorial question:")
				DebugUtil.printTableRecursively(RealisticDamageSystem.UsersHadTutorialDialog, "-" , 0, 3)

				print("") --separate stop print
				print("RDS DebugCommandOnce stopped.")
				RealisticDamageSystem.DebugCommandOnce = false
			end
			if RealisticDamageSystem.ResetTimeUntilNextDamageCommand then
				spec.NextKnownDamageOperatingHour = self:getFormattedOperatingTime() + RealisticDamageSystem:RoundValue((math.random (45, 75) / 10) / RealisticDamageSystem.DamagesMultiplier, 1) --calculate new operating time for damage --need /10 to get a decimal number (4.5 - 7.5)
				spec.NextUnknownDamageOperatingHour = self:getFormattedOperatingTime() + RealisticDamageSystem:RoundValue((math.random (105, 135) / 10) / RealisticDamageSystem.DamagesMultiplier, 1) --calculate new operating time for damage --need /10 to get a decimal number (10.5 - 13.5)
				spec.NextKnownDamageAge = self.age + RealisticDamageSystem:RoundValue(math.random(6, 13) / RealisticDamageSystem.DamagesMultiplier, 0) --calculate new age until the next damage
				spec.NextUnknownDamageAge = self.age + RealisticDamageSystem:RoundValue(math.random(3, 10) / RealisticDamageSystem.DamagesMultiplier, 0) --calculate new age until the next damage

				RealisticDamageSystem.ResetTimeUntilNextDamageCommand = false

				changeFlag = true --multiplayer sync
			end
			if RealisticDamageSystem.ResetEverythingCommand then
				RealisticDamageSystem.ResetTimeUntilNextDamageCommand = true
				RealisticDamageSystem.StopActiveRepairCommand = true
				RealisticDamageSystem.ResetTimeUntilInspectionCommand = true
				RealisticDamageSystem.ResetDamagesCommand = true

				RealisticDamageSystem.ResetEverythingCommand = false

				changeFlag = true --multiplayer sync
			end
			if RealisticDamageSystem.TimeUntilInspectionCommand ~= 0 then
				spec.NextInspectionAge = self.age + RealisticDamageSystem.TimeUntilInspectionCommand

				RealisticDamageSystem.TimeUntilInspectionCommand = 0

				changeFlag = true --multiplayer sync
			end

			if spec.DamagesMultiplier ~= RealisticDamageSystem.DamagesMultiplier then --if damage intervall is changed
				RealisticDamageSystem.ResetTimeUntilNextDamageCommand = true --calculate new time
				spec.DamagesMultiplier = RealisticDamageSystem.DamagesMultiplier --set new damage multiplier
				
				--multiplayer sync is in ResetTimeUntilNextDamageCommand
			end
		end

		--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
		--multiplayer
		--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
		if g_server ~= nil and spec.MultiplayerCosts ~= nil then
			if spec.MultiplayerCosts > 0 then
				local farm = self.ownerFarmId
				g_currentMission:addMoney(-spec.MultiplayerCosts, farm, MoneyType.VEHICLE_RUNNING_COSTS, true, true);

				spec.MultiplayerCosts = 0

				changeFlag = true
			end
		end
		if changeFlag then
			self:raiseDirtyFlags(spec.dirtyFlag)

			if g_server ~= nil then
				g_server:broadcastEvent(SyncClientServerEvent.new(self, spec.NextInspectionAge, spec.DamagesThatAddedWear, spec.FinishDay, spec.FinishHour, spec.FinishMinute, spec.DialogSelectedOptionCallback, spec.NextKnownDamageAge, spec.NextUnknownDamageAge, spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.TotalNumberOfDamagesPlayerDoesntKnow, spec.NextKnownDamageOperatingHour, spec.NextUnknownDamageOperatingHour, spec.DamagesMultiplier, spec.FirstLoadNumbersSet, spec.MaintenanceActive, spec.InspectionActive, spec.CVTRepairActive, self.spec_RealisticDamageSystemEngineDied.EngineDied, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages), RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog)), nil, nil, self)
			else
				g_client:getServerConnection():sendEvent(SyncClientServerEvent.new(self, spec.NextInspectionAge, spec.DamagesThatAddedWear, spec.FinishDay, spec.FinishHour, spec.FinishMinute, spec.DialogSelectedOptionCallback, spec.NextKnownDamageAge, spec.NextUnknownDamageAge, spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.TotalNumberOfDamagesPlayerDoesntKnow, spec.NextKnownDamageOperatingHour, spec.NextUnknownDamageOperatingHour, spec.DamagesMultiplier, spec.FirstLoadNumbersSet, spec.MaintenanceActive, spec.InspectionActive, spec.CVTRepairActive, self.spec_RealisticDamageSystemEngineDied.EngineDied, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages), RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog)))
			end
		end
	end
end;

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--return nearest palletRootNode
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:inRangeOfPallet(pallets, vehicle, vehicleFarm)
	for rootNodePallet,_ in pairs(pallets) do --go through every pallet that is on the map (that is inserted in the table in onLoad)
		if g_currentMission.nodeToObject[rootNodePallet] ~= nil then --make sure pallet can be found
			if g_currentMission.nodeToObject[rootNodePallet]:getActiveFarm() == vehicleFarm then --is pallet owned by the farm that owns the vehicle?
				local distanceToPallet = calcDistanceFrom(rootNodePallet, vehicle);	--calculate distance to pallet with giants function
				if distanceToPallet < 6 then --if pallet in range -> return true -> function ~= nil -> button active
					return true
				end
			end
		end
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--own getCanMotorRun function to disable the motor start when maintenance active
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:getCanMotorRun(superFunc)
    if self.spec_RealisticDamageSystem.MaintenanceActive ~= true and self.spec_RealisticDamageSystem.InspectionActive ~= true and self.spec_RealisticDamageSystem.CVTRepairActive ~= true then
        return superFunc(self)
    end
	
    return false
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--own getIsPowered function to disable the blinking warning for need motor started when the engine died
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:getIsPowered(superFunc)
	if self.spec_RealisticDamageSystemEngineDied ~= nil then
		if self.spec_RealisticDamageSystemEngineDied.EngineDied == true then
			return false
		end
	end
	return superFunc(self)
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--tutorial start
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:Tutorial(yes)
	if yes then
		self.spec_RealisticDamageSystem.TutorialStarted = true
		g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text1", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialSecondScreen, self)
	end
end
function RealisticDamageSystem:TutorialSecondScreen()
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text2", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialThirdScreen, self)
end
function RealisticDamageSystem:TutorialThirdScreen()
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text3", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialThirdScreen2, self)
	if self.spec_CVTaddon ~= nil and self.spec_CVTaddon.CVTdamage ~= nil then
		RealisticDamageSystemGUI:showMenu(self, true)
	else
		RealisticDamageSystemGUI:showMenu(self, false)
	end
end
function RealisticDamageSystem:TutorialThirdScreen2()
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text3_2", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialFourthScreen, self)
end
function RealisticDamageSystem:TutorialFourthScreen()
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text4", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialFourthScreen2, self)
end
function RealisticDamageSystem:TutorialFourthScreen2()
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text4_2", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialFourthScreen3, self)
end
function RealisticDamageSystem:TutorialFourthScreen3()
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text4_3", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialFourthScreen4, self)
end
function RealisticDamageSystem:TutorialFourthScreen4()
	if self.spec_CVTaddon ~= nil and self.spec_CVTaddon.CVTdamage ~= nil then
		g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text4_4", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialCVTScreen, self)
	else
		g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text4_4", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialFifthScreen, self)
	end
end
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--tutorial with FS22_CVT_Addon
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:TutorialCVTScreen()
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_textCVT", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialCVTScreen2, self)
end
function RealisticDamageSystem:TutorialCVTScreen2()
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_textCVT2", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialCVTScreen3, self)
end
function RealisticDamageSystem:TutorialCVTScreen3()
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_textCVT3", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialCVTScreen4, self)
end
function RealisticDamageSystem:TutorialCVTScreen4()
	local dialog = g_gui.guis["YesNoDialog"]
	dialog.target.dialogElement.target.yesButton.disabled = true
	dialog.target.dialogElement.target.noButton.disabled = true

	local dialogOption = g_gui.guis["OptionDialog"]
	dialogOption.target.optionElement.target:close()

	g_gui:showYesNoDialog(
		{
			text = g_i18n:getText("dialog_cvtInfo_text_RepairGearbox_Tutorial", RealisticDamageSystemGUI.l10nEnv),
			title = g_i18n:getText("dialog_cvtInfo_title", RealisticDamageSystemGUI.l10nEnv),
			target = self,
			args = (spec),
			callback = RealisticDamageSystemGUI.StartRepair,
		}
	)

	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_textCVT4", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialFifthScreen, self)
end
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--tutorial skips the part above when the mod FS22_CVT_Addon is not active
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:TutorialFifthScreen()
	if self.spec_CVTaddon ~= nil and self.spec_CVTaddon.CVTdamage ~= nil then
		local dialog = g_gui.guis["YesNoDialog"]
		dialog.target.dialogElement.target:close()
		dialog.target.dialogElement.target.yesButton.disabled = false
		dialog.target.dialogElement.target.noButton.disabled = false

		RealisticDamageSystemGUI:showMenu(self, true)
	end
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text5", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialFifthScreen2, self)
end
function RealisticDamageSystem:TutorialFifthScreen2()
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text5_2", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialFifthScreen3, self)
end
function RealisticDamageSystem:TutorialFifthScreen3()
	self.spec_RealisticDamageSystem.TutorialUpdateFinishedTime = true
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text5_3", RealisticDamageSystem.l10nEnv), -1, nil, RealisticDamageSystem.TutorialSixthScreen, self)
end
function RealisticDamageSystem:TutorialSixthScreen()
	g_currentMission.hud:showInGameMessage(g_i18n:getText("tutorial_title", RealisticDamageSystem.l10nEnv), g_i18n:getText("tutorial_text6", RealisticDamageSystem.l10nEnv), -1, nil, nil, self)

	local dialog = g_gui.guis["OptionDialog"]
	dialog.target.optionElement.target:close()
	self.spec_RealisticDamageSystem.TutorialUpdateFinishedTime = false
	self.spec_RealisticDamageSystem.TutorialStarted = false
end
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--tutorial end
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--open maintenance menu
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:DIALOG_MAINTENANCE()
	if self.spec_RealisticDamageSystem == nil then 
		return
	end
	
	--don't open if a inspection is already started
	if self.spec_RealisticDamageSystem.InspectionActive == true then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_AlreadyActiveInspection", RealisticDamageSystem.l10nEnv), 5000)
		return
	end
	--don't open if a maintenance is already started
	if self.spec_RealisticDamageSystem.MaintenanceActive == true then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_AlreadyActiveMaintenance", RealisticDamageSystem.l10nEnv), 5000)
		return
	end
	--don't open if a CVT-repair is already started
	if self.spec_RealisticDamageSystem.CVTRepairActive == true then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_AlreadyActiveMaintenance", RealisticDamageSystem.l10nEnv), 5000)
		return
	end

	if self.spec_CVTaddon ~= nil and self.spec_CVTaddon.CVTdamage ~= nil and self.spec_CVTaddon.isVarioTM then
		RealisticDamageSystemGUI:showMenu(self, true) --open maintenance menu with mod FS22_CVT_Addon active
	else
		RealisticDamageSystemGUI:showMenu(self, false) --open maintenance menu without mod FS22_CVT_Addon active
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--turn all the lengths from all damages that were inserted into the AllDamagesTable into a string to save the time in a XML
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:LengthTableToString(table)
	local string = ""

	if table ~= nil and table[1] ~= nil then
		for i = 1, #table, 1 do
			string = string..tostring(table[i])..";" --add every number from the tabel to a string
		end											 --add ";" behind every number in the string so that I can match the phrase and extract the number from the string on load again
	end

	return string
end
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--extract the numbers out of the saved string from the XML to assign them to "their" damage
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:StringToLengthTable(string)
	local collectedInfo = {}
	if string ~= nil and string ~= "" and string.gmatch ~= nil then
		for match in string:gmatch("(.-;)") do --search for ";" in the string and insert the found match into the table
			table.insert(collectedInfo, string.sub(match, 0, -2)); --need string.sub with -2 to remove the ";" at the end
		end
	end
	return collectedInfo --final LengthForDamages table
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--turn the table for which player had seen the question whether he wants to start the tutorial or not into a string to save the table in a XML
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:MPTableToString(table)
	local string = ""

	if table ~= nil then
		for index,userID in pairs(table) do
			string = string..tostring(index)..";" --add every string from the tabel at the end of another string for one complete string
		end										  --add ";" behind every string so that I can match the phrase and extract the string from the saved one on load again
	end
	return string
end
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--turn the saved string from the XML back into the table for which player had seen the question for the tutorial
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:MPStringToTable(string)
	local collectedInfo = {}
	if string ~= nil and string ~= "" and string.gmatch ~= nil then
		for match in string:gmatch("(.-;)") do --search for ";" in the string and insert the found match into the table
			collectedInfo[string.sub(match, 0, -2)] = {};
		end
	end
	return collectedInfo --return finished table
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--help menu for the esc menu
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:loadMapDataHelpLineManager(superFunc, ...)
    local ret = superFunc(self, ...)
    if ret then
		if g_gui.languageSuffix == "_de" or g_gui.languageSuffix == "_en" or g_gui.languageSuffix == "_fr" or g_gui.languageSuffix == "_es" or g_gui.languageSuffix == "_ru" or g_gui.languageSuffix == "_pl" then
			if FS22_CVT_Addon ~= nil and FS22_CVT_Addon.CVTaddon ~= nil then
				self:loadFromXML(Utils.getFilename("helpMenu/helpMenuCVT"..g_gui.languageSuffix..".xml", RealisticDamageSystem.modDirectory))
			else
				self:loadFromXML(Utils.getFilename("helpMenu/helpMenu"..g_gui.languageSuffix..".xml", RealisticDamageSystem.modDirectory))
			end
		else
			if FS22_CVT_Addon ~= nil and FS22_CVT_Addon.CVTaddon ~= nil then
				self:loadFromXML(Utils.getFilename("helpMenu/helpMenuCVT_en.xml", RealisticDamageSystem.modDirectory))
			else
				self:loadFromXML(Utils.getFilename("helpMenu/helpMenu_en.xml", RealisticDamageSystem.modDirectory))
			end
		end
        return true
    end
    return false
end

HelpLineManager.loadMapData = Utils.overwrittenFunction(HelpLineManager.loadMapData, RealisticDamageSystem.loadMapDataHelpLineManager)


--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--append to function from the FS to create custom XML file
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
if RealisticDamageSystem.loaded == nil then
	Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, RealisticDamageSystem.loadedMission);
	FSCareerMissionInfo.saveToXMLFile = Utils.appendedFunction(FSCareerMissionInfo.saveToXMLFile, RealisticDamageSystem.saveToEXTRAXMLFile);

	Vehicle.getIsPowered = Utils.overwrittenFunction(Vehicle.getIsPowered, RealisticDamageSystem.getIsPowered); --prepend to getIsPowered function to disable the motor start warning

	RealisticDamageSystem.loaded = true
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--console command reset tutorial
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
addConsoleCommand("rdsResetTutorial", "Reset Tutorial for RealisticDamageSystem", "rdsResetTutorial", RealisticDamageSystem)
function RealisticDamageSystem:rdsResetTutorial()
	if RealisticDamageSystem.UsersHadTutorialDialog ~= nil and RealisticDamageSystem.UsersHadTutorialDialog[getUniqueUserId()] ~= nil then
		RealisticDamageSystem.UsersHadTutorialDialog[getUniqueUserId()] = nil
		print("Reset successful. You can now restart the tutorial by entering a vehicle.")
	else
		print("Reset failed. You can start the tutorial by entering a vehicle.")
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--console command reset damages
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
addConsoleCommand("rdsResetDamages", "Reset all RealisticDamageSystem damages for vehicle", "rdsResetDamages", RealisticDamageSystem)
function RealisticDamageSystem:rdsResetDamages()
	if g_currentMission.isMasterUser then
		RealisticDamageSystem.ResetDamagesCommand = true

		print("Damages have been reset for this vehicle.")
	else
		print("Please log in as admin first.")
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--console command remove damages
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
addConsoleCommand("rdsRemoveDamages", "Remove RealisticDamageSystem damages from vehicle", "rdsRemoveDamages", RealisticDamageSystem)
function RealisticDamageSystem:rdsRemoveDamages(number)
	if g_currentMission.isMasterUser then
		if tonumber(number) ~= nil then
			RealisticDamageSystem.RemoveDamagesCommand = tonumber(number)
			print("Damages have been subtracted from the of damages of the vehicle (only known damages).")
		else
			print("Please enter the number of damages you want to remove.")
		end
	else
		print("Please log in as admin first.")
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--console command find hidden damages
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
addConsoleCommand("rdsFindDamages", "Find RealisticDamageSystem damages", "rdsFindDamages", RealisticDamageSystem)
function RealisticDamageSystem:rdsFindDamages()
	if g_currentMission.isMasterUser then
		RealisticDamageSystem.FindDamagesCommand = true

		print("Added found hidden damages to the vehicle.")
	else
		print("Please log in as admin first.")
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--console command reset inspection
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
addConsoleCommand("rdsResetTimeUntilInspection", "Reset the time until the next RealisticDamageSystem inspection", "rdsResetTimeUntilInspection", RealisticDamageSystem)
function RealisticDamageSystem:rdsResetTimeUntilInspection()
	if g_currentMission.isMasterUser then
		RealisticDamageSystem.ResetTimeUntilInspectionCommand = true

		print("Time until next inspection has been reset for this vehicle.")
	else
		print("Please log in as admin first.")
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--console command stop repair
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
addConsoleCommand("rdsStopActiveRepair", "Stop an active repair or inspection", "rdsStopActiveRepair", RealisticDamageSystem)
function RealisticDamageSystem:rdsStopActiveRepair()
	if g_currentMission.isMasterUser then
		RealisticDamageSystem.StopActiveRepairCommand = true
	
		print("Active repair or inspection has been stopped for this vehicle.")
	else
		print("Please log in as admin first.")
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--console command debug
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
addConsoleCommand("rdsDebug", "Show debug", "rdsDebug", RealisticDamageSystem)
function RealisticDamageSystem:rdsDebug()
	RealisticDamageSystem.DebugCommand = not RealisticDamageSystem.DebugCommand

	if RealisticDamageSystem.DebugCommand == false then
		print("RDS DebugCommand stopped.")
	else
		print("RDS DebugCommand started.")
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--console command debug once
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
addConsoleCommand("rdsDebugOnce", "Show debug once", "rdsDebugOnce", RealisticDamageSystem)
function RealisticDamageSystem:rdsDebugOnce()
	RealisticDamageSystem.DebugCommandOnce = true

	print("RDS DebugCommandOnce started.")
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--console command reset time until next damage
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
addConsoleCommand("rdsResetTimeUntilNextDamage", "Reset the time until the next damage occurs", "rdsResetTimeUntilNextDamage", RealisticDamageSystem)
function RealisticDamageSystem:rdsResetTimeUntilNextDamage()
	if g_currentMission.isMasterUser then
		RealisticDamageSystem.ResetTimeUntilNextDamageCommand = true

		print("Time until the next damage occurs has been reset for this vehicle.")
	else
		print("Please log in as admin first.")
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--console command reset everything
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
addConsoleCommand("rdsResetEverything", "Reset every damage and time until next inspection", "rdsResetEverything", RealisticDamageSystem)
function RealisticDamageSystem:rdsResetEverything()
	if g_currentMission.isMasterUser then
		RealisticDamageSystem.ResetEverythingCommand = true

		print("Time until the next damage occurs has been reset for this vehicle.")
	else
		print("Please log in as admin first.")
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--console command set time until inspection
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
addConsoleCommand("rdsSetTimeUntilInspection", "Manually set the time until the next inspection is needed", "rdsSetTimeUntilInspection", RealisticDamageSystem)
function RealisticDamageSystem:rdsSetTimeUntilInspection(number)
	if g_currentMission.isMasterUser then
		if tonumber(number) ~= nil then
			RealisticDamageSystem.TimeUntilInspectionCommand = tonumber(number)
			print("Time until the next inspection has been set.")
		else
			print("Please enter a number the time should be set to.")
		end
	else
		print("Please log in as admin first.")
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--round with one decimal
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:RoundValue(number, decimalPlaces)
	return tonumber(string.format("%." .. (decimalPlaces or 0) .. "f", number))
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--deactivate automatic repair from AutoRepair mod
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:AutoRepairOnOpen()
	self.option1Value:setState(2)
	self.option1Value:setDisabled(true)
	self.option1bValue:setText("0")
	FS22_AutoRepair.AutoRepair.doRepair = false
end
if FS22_AutoRepair ~= nil and FS22_AutoRepair.AutoRepairUI ~= nil then
	FS22_AutoRepair.AutoRepairUI.onOpen = Utils.appendedFunction(FS22_AutoRepair.AutoRepairUI.onOpen, RealisticDamageSystem.AutoRepairOnOpen);
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--deactivate repair button from Advanced Farm Manager mod
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:updateMenuButtons()
	self.extra1ButtonInfo.disabled = true
end
if FS22_AdvancedFarmManager ~= nil and FS22_AdvancedFarmManager.AIMGuiVehicleFrame ~= nil then
	FS22_AdvancedFarmManager.AIMGuiVehicleFrame.updateMenuButtons = Utils.appendedFunction(FS22_AdvancedFarmManager.AIMGuiVehicleFrame.updateMenuButtons, RealisticDamageSystem.updateMenuButtons);
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--set multiplier for damages from Configure Maintenance mod
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystem:run()
	RealisticDamageSystem.DamagesMultiplier = FS22_Configure_Maintenance.g_r_maintenance.maintenanceDuration
end
--overwrite the FS damage system to stop the damage amount and control it over my script
function RealisticDamageSystem.updateDamageAmount(wearable, superFunc, dt)
	return 0
end
if FS22_Configure_Maintenance ~= nil and FS22_Configure_Maintenance.ReduceMaintenanceSettings ~= nil then
	FS22_Configure_Maintenance.ChangeMaintenanceSettingsEvent.run = Utils.appendedFunction(FS22_Configure_Maintenance.ChangeMaintenanceSettingsEvent.run, RealisticDamageSystem.run);
	FS22_Configure_Maintenance.ReduceMaintenance.updateDamageAmount = Utils.overwrittenFunction(FS22_Configure_Maintenance.ReduceMaintenance.updateDamageAmount, RealisticDamageSystem.updateDamageAmount);
else
	--overwrite the FS damage system to stop the damage amount and control it over my script
	Wearable.updateDamageAmount = Utils.overwrittenFunction(Wearable.updateDamageAmount, RealisticDamageSystem.updateDamageAmount)
end
if RealisticDamageSystem.DamagesMultiplier == nil then
	RealisticDamageSystem.DamagesMultiplier = 1
end