-- Contact: RealisticDamageSystem@web.de
-- Date 1.11.2022

SyncClientServerEvent = {}

local SyncClientServerEvent_mt = Class(SyncClientServerEvent, Event)
InitEventClass(SyncClientServerEvent, "SyncClientServerEvent")




---Create instance of Event class
-- @return table self instance of class event
function SyncClientServerEvent.emptyNew()
    local self = Event.new(SyncClientServerEvent_mt)
    return self
end


---Create new instance of event
-- @param table vehicle vehicle
-- @param integer state state
function SyncClientServerEvent.new(vehicle, NextInspectionAge, DamagesThatAddedWear, FinishDay, FinishHour, FinishMinute, DialogSelectedOptionCallback, NextKnownDamageAge, NextUnknownDamageAge, forDBL_TotalNumberOfDamagesPlayerKnows, TotalNumberOfDamagesPlayerDoesntKnow, NextKnownDamageOperatingHour, NextUnknownDamageOperatingHour, DamagesMultiplier, FirstLoadNumbersSet, MaintenanceActive, InspectionActive, CVTRepairActive, EngineDied, LengthForDamages, UsersHadTutorialDialog)
    local self = SyncClientServerEvent.emptyNew()
   
	self.NextInspectionAge = NextInspectionAge
	self.DamagesThatAddedWear = DamagesThatAddedWear
	self.FinishDay = FinishDay
	self.FinishHour = FinishHour
	self.FinishMinute = FinishMinute
	self.DialogSelectedOptionCallback = DialogSelectedOptionCallback
	self.NextKnownDamageAge = NextKnownDamageAge
	self.NextUnknownDamageAge = NextUnknownDamageAge
	self.forDBL_TotalNumberOfDamagesPlayerKnows = forDBL_TotalNumberOfDamagesPlayerKnows
	self.TotalNumberOfDamagesPlayerDoesntKnow = TotalNumberOfDamagesPlayerDoesntKnow

	self.NextKnownDamageOperatingHour = NextKnownDamageOperatingHour
	self.NextUnknownDamageOperatingHour = NextUnknownDamageOperatingHour
	self.DamagesMultiplier = DamagesMultiplier

	self.FirstLoadNumbersSet = FirstLoadNumbersSet
	self.MaintenanceActive = MaintenanceActive
	self.InspectionActive = InspectionActive
	self.CVTRepairActive = CVTRepairActive
	self.EngineDied = EngineDied

	self.LengthForDamages = LengthForDamages
	self.UsersHadTutorialDialog = UsersHadTutorialDialog
    
    self.vehicle = vehicle
    return self
end


---Called on client side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SyncClientServerEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)

    self.NextInspectionAge = streamReadInt32(streamId)
    self.DamagesThatAddedWear = streamReadInt32(streamId)
    self.FinishDay = streamReadInt32(streamId)
    self.FinishHour = streamReadInt32(streamId)
    self.FinishMinute = streamReadInt32(streamId)
    self.DialogSelectedOptionCallback = streamReadInt32(streamId)
    self.NextKnownDamageAge = streamReadInt32(streamId)
    self.NextUnknownDamageAge = streamReadInt32(streamId)
    self.forDBL_TotalNumberOfDamagesPlayerKnows = streamReadInt32(streamId)
    self.TotalNumberOfDamagesPlayerDoesntKnow = streamReadInt32(streamId)

    self.NextKnownDamageOperatingHour = streamReadFloat32(streamId)
    self.NextUnknownDamageOperatingHour = streamReadFloat32(streamId)
    self.DamagesMultiplier = streamReadFloat32(streamId)

	self.FirstLoadNumbersSet = streamReadBool(streamId)
	self.MaintenanceActive = streamReadBool(streamId)
	self.InspectionActive = streamReadBool(streamId)
	self.CVTRepairActive = streamReadBool(streamId)
	self.EngineDied = streamReadBool(streamId)

	self.LengthForDamages = streamReadString(streamId)
	self.UsersHadTutorialDialog = streamReadString(streamId)

    self:run(connection)
end


---Called on server side on join
-- @param integer streamId streamId
-- @param integer connection connection
function SyncClientServerEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)

	streamWriteInt32(streamId, self.NextInspectionAge)
	streamWriteInt32(streamId, self.DamagesThatAddedWear)
	streamWriteInt32(streamId, self.FinishDay)
	streamWriteInt32(streamId, self.FinishHour)
	streamWriteInt32(streamId, self.FinishMinute)
	streamWriteInt32(streamId, self.DialogSelectedOptionCallback)
	streamWriteInt32(streamId, self.NextKnownDamageAge)
	streamWriteInt32(streamId, self.NextUnknownDamageAge)
	streamWriteInt32(streamId, self.forDBL_TotalNumberOfDamagesPlayerKnows)
	streamWriteInt32(streamId, self.TotalNumberOfDamagesPlayerDoesntKnow)
	
	streamWriteFloat32(streamId, self.NextKnownDamageOperatingHour)
	streamWriteFloat32(streamId, self.NextUnknownDamageOperatingHour)
	streamWriteFloat32(streamId, self.DamagesMultiplier)

	streamWriteBool(streamId, self.FirstLoadNumbersSet)
	streamWriteBool(streamId, self.MaintenanceActive)
	streamWriteBool(streamId, self.InspectionActive)
	streamWriteBool(streamId, self.CVTRepairActive)
	streamWriteBool(streamId, self.EngineDied)

	streamWriteString(streamId, self.LengthForDamages)
	streamWriteString(streamId, self.UsersHadTutorialDialog)
end


---Run action on receiving side
-- @param integer connection connection
function SyncClientServerEvent:run(connection)
    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        RealisticDamageSystem.SyncClientServer(self.vehicle, self.NextInspectionAge, self.DamagesThatAddedWear, self.FinishDay, self.FinishHour, self.FinishMinute, self.DialogSelectedOptionCallback, self.NextKnownDamageAge, self.NextUnknownDamageAge, self.forDBL_TotalNumberOfDamagesPlayerKnows, self.TotalNumberOfDamagesPlayerDoesntKnow, self.NextKnownDamageOperatingHour, self.NextUnknownDamageOperatingHour, self.DamagesMultiplier, self.FirstLoadNumbersSet, self.MaintenanceActive, self.InspectionActive, self.CVTRepairActive, self.EngineDied, self.LengthForDamages, self.UsersHadTutorialDialog)
		
		if not connection:getIsServer() then
			g_server:broadcastEvent(SyncClientServerEvent.new(self.vehicle, self.NextInspectionAge, self.DamagesThatAddedWear, self.FinishDay, self.FinishHour, self.FinishMinute, self.DialogSelectedOptionCallback, self.NextKnownDamageAge, self.NextUnknownDamageAge, self.forDBL_TotalNumberOfDamagesPlayerKnows, self.TotalNumberOfDamagesPlayerDoesntKnow, self.NextKnownDamageOperatingHour, self.NextUnknownDamageOperatingHour, self.DamagesMultiplier, self.FirstLoadNumbersSet, self.MaintenanceActive, self.InspectionActive, self.CVTRepairActive, self.EngineDied, self.LengthForDamages, self.UsersHadTutorialDialog), nil, connection, self.vehicle)
		end
    end
end