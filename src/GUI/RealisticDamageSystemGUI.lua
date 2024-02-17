-- by Frvetz
-- Contact: RealisticDamageSystem@gmail.com
-- Date 02.12.2021

source(g_currentModDirectory.."events/SyncClientServerEvent.lua") --multiplayer event file

RealisticDamageSystemGUI = {}
RealisticDamageSystemGUI.l10nEnv = "FS22_RealisticDamageSystem";


--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--show maintenance menu
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystemGUI:showMenu(self, CVTActive)
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
	--set multiplier from configure maintenance mod
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
	if FS22_Configure_Maintenance ~= nil and FS22_Configure_Maintenance.g_r_maintenance ~= nil then
		RealisticDamageSystemGUI.costsMultiplier = FS22_Configure_Maintenance.g_r_maintenance.maintenanceCost
	else
		RealisticDamageSystemGUI.costsMultiplier = 1
	end

	local spec = self.spec_RealisticDamageSystem

	spec.menuIsOpen = true --set menu is open

	if spec.TutorialStarted then
		spec.InsertDamagesInTable = 1 --if tutorial is started -> only show 1 damage in the menu
	else
		spec.InsertDamagesInTable = math.min(spec.forDBL_TotalNumberOfDamagesPlayerKnows, 12) --show as many damages as the vehicle has
	end
	for i = 1, spec.InsertDamagesInTable, 1 do --go through every damage the vehicle
		--if a damage is found that doesn't have an entry in the table yet -> create new entry with costs for that damage and random length
		if spec.AllDamagesTable[i] == nil then
			if spec.LengthForDamages[i] == nil then
				table.insert(spec.LengthForDamages, i, string.format("%.1f",(math.random(5, 30) / 10)))
			end
			
															--set text for the option																		-- 2 (is saved in XML)		 -3 total Lenght  -4 costs for 1 damage 	-5 total costs
			table.insert(spec.AllDamagesTable, i, { g_i18n:getText("dialog_maintenance_NumberDamages"..tostring(i), RealisticDamageSystemGUI.l10nEnv), spec.LengthForDamages[i],	  	0,				  0,						0})
		end
		spec.AllDamagesTable[i][4] = math.floor(RealisticDamageSystemGUI.costsMultiplier * (spec.VehiclePrice / 666) + (100 * spec.AllDamagesTable[i][2])) --calculate the price 1 damage
		if spec.AllDamagesTable[i - 1] ~= nil then
			spec.AllDamagesTable[i][3] = spec.AllDamagesTable[i - 1][3] + spec.AllDamagesTable[i][2] --add all lengths from all damages before to show the total length
			spec.AllDamagesTable[i][5] = spec.AllDamagesTable[i - 1][5] + spec.AllDamagesTable[i][4] --add all costs from all damages before to show the total length
		else
			spec.AllDamagesTable[i][3] = spec.AllDamagesTable[i][2] --if the vehicle only has 1 damage, then don't add stuff
			spec.AllDamagesTable[i][5] = spec.AllDamagesTable[i][4]--if the vehicle only has 1 damage, then don't add stuff
		end
	end

	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
	--create menu
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
	local dialog = g_gui.guis["OptionDialog"]
	local Dialog = dialog.target.optionElement.target

	local options = {}
	for i = 1, spec.InsertDamagesInTable, 1 do
		options[#options + 1] = spec.AllDamagesTable[i][1]
		currentSelection = #options
		if spec.TutorialStarted ~= true then
			Dialog.yesButton.disabled = false
		end
	end
	if #options == 0 then
		options[1] = ""
		currentSelection = #options
		Dialog.yesButton.disabled = true
	end

	if spec.TutorialStarted then --if tutorial started -> disable buttons to prevent clicking on something while reading tutorial
		dialog.target.optionElement.target.yesButton.disabled = true
		dialog.target.optionElement.target.noButton.disabled = true
	else
		dialog.target.optionElement.target.noButton.disabled = false
	end
	
	local dialogArguments = {
		
		text = "",
		title = g_i18n:getText("dialog_maintenance_title", RealisticDamageSystemGUI.l10nEnv),
		options = options,
		target = self,
		disableFilter = true,
		args = { },
		callback = function(target, selectedOption)
			if type(selectedOption) ~= "number" or selectedOption == 0 then
				return
			end

			spec.DialogSelectedOptionCallback = selectedOption
			
			if spec.FinishDay ~= g_currentMission.environment.currentDay or g_currentMission.environment.currentHour < 7 then
				if spec.FinishDay - g_currentMission.environment.currentDay > 1 then
					g_gui:showYesNoDialog(
						{
							text = g_i18n:getText("dialog_RepairInfo_text_withPaused2x", RealisticDamageSystemGUI.l10nEnv):format(spec.FinishHour, spec.FinishMinute, spec.AllDamagesTable[selectedOption][5]),
							title = g_i18n:getText("dialog_RepairInfo_title", RealisticDamageSystemGUI.l10nEnv):format(selectedOption),
							target = self,
							args = (self),
							callback = RealisticDamageSystemGUI.StartMaintenance,
						}
					)
				else
					g_gui:showYesNoDialog(
						{
							text = g_i18n:getText("dialog_RepairInfo_text_withPaused", RealisticDamageSystemGUI.l10nEnv):format(spec.FinishHour, spec.FinishMinute, spec.AllDamagesTable[selectedOption][5]),
							title = g_i18n:getText("dialog_RepairInfo_title", RealisticDamageSystemGUI.l10nEnv):format(selectedOption),
							target = self,
							args = (self),
							callback = RealisticDamageSystemGUI.StartMaintenance,
						}
					)
				end
			else
				g_gui:showYesNoDialog(
					{
						text = g_i18n:getText("dialog_RepairInfo_text", RealisticDamageSystemGUI.l10nEnv):format(spec.FinishHour, spec.FinishMinute, spec.AllDamagesTable[selectedOption][5]),
						title = g_i18n:getText("dialog_RepairInfo_title", RealisticDamageSystemGUI.l10nEnv):format(selectedOption),
						target = self,
						args = (self),
						callback = RealisticDamageSystemGUI.StartMaintenance,
					}
				)
			end
		end,
	}
	
	--when mod FS22_CVT_Addon is activated -> change position of buttons and hitboxes to make it look good
	if CVTActive then
		Dialog.noButton.textOffset[2] = -0.016
		Dialog.noButton.textFocusedOffset[2] = -0.016
		Dialog.noButton.hotspot[2] = -0.016
		Dialog.noButton.hotspot[4] = -0.016

		Dialog.yesButton.textOffset[2] = -0.016
		Dialog.yesButton.textFocusedOffset[2] = -0.016
		Dialog.yesButton.hotspot[2] = -0.016
		Dialog.noButton.hotspot[4] = -0.016
	end
	
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
	--create new button for inspection
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
	if Dialog.newButtonInspection == nil then
		local buttonElement = Dialog.noButton:clone(Dialog) --dublicate the "noButton"

		buttonElement:setText(g_i18n:getText("dialog_inspection_text", RealisticDamageSystemGUI.l10nEnv)) --change text
		buttonElement:setInputAction("MENU_EXTRA_1")
		--when mod FS22_CVT_Addon is activated -> change position of button and hitbox to make it look good
		if CVTActive then 
			buttonElement.textOffset[2] = -0.016
			buttonElement.textFocusedOffset[2] = -0.016
			buttonElement.hotspot[2] = -0.016
			buttonElement.hotspot[4] = -0.016
		end
		--if tutorial started -> disable button to prevent clicking on it while reading tutorial
		if spec.TutorialStarted then
			buttonElement.disabled = true
		else
			buttonElement.disabled = false
		end
		--set callback from dublicated button
		buttonElement.onClickCallback = 
			function()
				dialog.target.optionElement.target:close()
				
				if g_currentMission.environment.currentHour + 1 >= 21 or g_currentMission.environment.currentHour < 7 then
					g_gui:showYesNoDialog(
						{
							text = g_i18n:getText("dialog_InspectionInfo_text_withPaused", RealisticDamageSystemGUI.l10nEnv):format("8", g_currentMission.environment.currentMinute),
							title = g_i18n:getText("dialog_InspectionInfo_title", RealisticDamageSystemGUI.l10nEnv),
							target = self,
							args = (self),
							callback = RealisticDamageSystemGUI.StartInspection,
						}
					)
				else
					g_gui:showYesNoDialog(
						{
							text = g_i18n:getText("dialog_InspectionInfo_text", RealisticDamageSystemGUI.l10nEnv):format(g_currentMission.environment.currentHour + 1, g_currentMission.environment.currentMinute),
							title = g_i18n:getText("dialog_InspectionInfo_title", RealisticDamageSystemGUI.l10nEnv),
							target = self,
							args = (self),
							callback = RealisticDamageSystemGUI.StartInspection,
						}
					)
				end
			end


		Dialog.noButton.parent:addElement(buttonElement)
		Dialog.newButtonInspection = buttonElement
	end

	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
	--mod FS22_CVT_Addon needed!!!  create new button for CVT-repair
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
	if CVTActive then
		--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
		--create new text for CVT_Addon at the bottom
		--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
		if dialog.target.dialogTextElementCVT == nil then
			local textElement = dialog.target.dialogTextElement:clone(dialog) --dublicate text from above

			textElement.textOffset[2] = -0.12 --set new text position
			--set text content in "setText" function below
			textElement.textSize = 0.012 --change text size to fit the window

			dialog.target.dialogTextElementCVT = textElement
		end

		if Dialog.newButtonCVT == nil then
			local buttonElement = Dialog.noButton:clone(Dialog) --create CVT_Button
			if math.floor(self.spec_CVTaddon.CVTdamage) >= 90 then
				buttonElement:setText(g_i18n:getText("dialog_cvt_textChangeGearbox", RealisticDamageSystemGUI.l10nEnv)) --if damage is > 89 then change the button name to "change"
				if spec.TutorialStarted ~= true then
					buttonElement.disabled = false
				else
					buttonElement.disabled = true
				end
			elseif math.floor(self.spec_CVTaddon.CVTdamage) > 0 and math.floor(self.spec_CVTaddon.CVTdamage) < 90 then
				buttonElement:setText(g_i18n:getText("dialog_cvt_textRepairGearbox", RealisticDamageSystemGUI.l10nEnv)) --if damage is < 90 then change the button name to "repair"
				if spec.TutorialStarted ~= true then
					buttonElement.disabled = false
				else
					buttonElement.disabled = true
				end
			else
				buttonElement:setText(g_i18n:getText("dialog_cvt_textRepairGearbox", RealisticDamageSystemGUI.l10nEnv)) --if damage is 0 then change the button name to "repair"
				buttonElement.disabled = true 																			--and disable it
			end

			--change position of button and hitbox to make it look good
			buttonElement:setInputAction("MENU_EXTRA_2")
			buttonElement.textOffset[2] = -0.029
			buttonElement.hotspot[2] = -0.029 
			buttonElement.hotspot[4] = -0.029 
			buttonElement.textFocusedOffset[2] = -0.029

			--callback when clicking on button
			buttonElement.onClickCallback = 
				function()
					dialog.target.optionElement.target:close()
					if math.floor(self.spec_CVTaddon.CVTdamage) >= 90 then

						spec.FinishDay, spec.FinishHour, spec.FinishMinute = RealisticDamageSystemGUI:CalculateFinishTime(7, 0)
						if g_currentMission.environment.currentHour + 7 > 21 or g_currentMission.environment.currentHour < 7 then
							g_gui:showYesNoDialog(
								{
									text = g_i18n:getText("dialog_cvtInfo_text_ChangeGearbox_withPaused", RealisticDamageSystemGUI.l10nEnv):format(spec.FinishHour, spec.FinishMinute),
									title = g_i18n:getText("dialog_cvtInfo_title", RealisticDamageSystemGUI.l10nEnv),
									target = self,
									args = (self),
									callback = RealisticDamageSystemGUI.StartCVTChange,
								}
							)
						else
							g_gui:showYesNoDialog(
								{
									text = g_i18n:getText("dialog_cvtInfo_text_ChangeGearbox", RealisticDamageSystemGUI.l10nEnv):format(spec.FinishHour, spec.FinishMinute),
									title = g_i18n:getText("dialog_cvtInfo_title", RealisticDamageSystemGUI.l10nEnv),
									target = self,
									args = (self),
									callback = RealisticDamageSystemGUI.StartCVTChange,
								}
							)
						end
					else
						spec.CVTlength = string.format("%.1f", self.spec_CVTaddon.CVTdamage / 8.18)
						spec.CVTcosts = self.spec_CVTaddon.CVTdamage * 121
						spec.FinishDay, spec.FinishHour, spec.FinishMinute = RealisticDamageSystemGUI:CalculateFinishTime(math.floor(spec.CVTlength), (spec.CVTlength%1 * 60))

						if spec.FinishDay ~= g_currentMission.environment.currentDay or g_currentMission.environment.currentHour < 7 then
							g_gui:showYesNoDialog(
								{
									text = g_i18n:getText("dialog_cvtInfo_text_RepairGearbox_withPaused", RealisticDamageSystemGUI.l10nEnv):format(spec.FinishHour, spec.FinishMinute, spec.CVTcosts),
									title = g_i18n:getText("dialog_cvtInfo_title", RealisticDamageSystemGUI.l10nEnv),
									target = self,
									args = (self),
									callback = RealisticDamageSystemGUI.StartCVTRepair,
								}
							)
						else
							g_gui:showYesNoDialog(
								{
									text = g_i18n:getText("dialog_cvtInfo_text_RepairGearbox", RealisticDamageSystemGUI.l10nEnv):format(spec.FinishHour, spec.FinishMinute, spec.CVTcosts),
									title = g_i18n:getText("dialog_cvtInfo_title", RealisticDamageSystemGUI.l10nEnv),
									target = self,
									args = (self),
									callback = RealisticDamageSystemGUI.StartCVTRepair,
								}
							)
						end
					end
				end

			Dialog.noButton.parent:addElement(buttonElement)
			Dialog.newButtonCVT = buttonElement
		end
	end
	
	
	--TODO: hack to reset the "remembered" option (i.e. solve a bug in the game engine)
    local dialog2 = g_gui:showDialog("OptionDialog")
    if dialog2 ~= nil then
        dialog2.target:setOptions({" "}) -- Add fake option to force a "reset"
    end

	g_gui:showOptionDialog(dialogArguments)

	--Rename Yes Button
	dialog.target.optionElement.target.yesButton:setText(g_i18n:getText("dialog_yesButton_text", RealisticDamageSystemGUI.l10nEnv))
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--set the text depending on which option is selected
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystemGUI:setText(dialog, spec, spec_CVTaddon)
	local SelectedOption = tonumber(string.sub(dialog.target.optionElement.elements[3].sourceText,1,2))
	
	if SelectedOption ~= nil then
		--calculate the time when the maintenance would be finished
		spec.FinishDay, spec.FinishHour, spec.FinishMinute = RealisticDamageSystemGUI:CalculateFinishTime(math.floor(spec.AllDamagesTable[SelectedOption][3]), (spec.AllDamagesTable[SelectedOption][3]%1 * 60))
		
		local costs = spec.AllDamagesTable[SelectedOption][5]
		if spec.FinishDay ~= g_currentMission.environment.currentDay or spec.TutorialUpdateFinishedTime == true then
			if spec.TutorialStarted == false or spec.TutorialUpdateFinishedTime == true then
				if spec.FinishDay - g_currentMission.environment.currentDay > 1 then
					dialog.target:setText(g_i18n:getText("dialog_maintenance_MustBePaused2x_text", RealisticDamageSystemGUI.l10nEnv):format(spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.FinishHour, spec.FinishMinute, costs)) --update numbers in information text for each selection but the maintenance has to be paused 2x
				else
					dialog.target:setText(g_i18n:getText("dialog_maintenance_MustBePaused_text", RealisticDamageSystemGUI.l10nEnv):format(spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.FinishHour, spec.FinishMinute, costs)) --update numbers in information text for each selection but the maintenance has to be paused
				end
			else
				dialog.target:setText(g_i18n:getText("dialog_maintenance_text", RealisticDamageSystemGUI.l10nEnv):format(spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.FinishHour, spec.FinishMinute, costs)) --update numbers in information text for each selection
			end
		else
			dialog.target:setText(g_i18n:getText("dialog_maintenance_text", RealisticDamageSystemGUI.l10nEnv):format(spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.FinishHour, spec.FinishMinute, costs)) --update numbers in information text for each selection
		end
	else
		dialog.target:setText(g_i18n:getText("dialog_maintenance_NoMoreKnownDamagesToRepair", RealisticDamageSystemGUI.l10nEnv)) --no damages that need to be repaired
	end

	if spec_CVTaddon ~= nil then
		--update CVTdamage number
		dialog.target.dialogTextElementCVT:setText(g_i18n:getText("dialog_cvt_textExplanation", RealisticDamageSystemGUI.l10nEnv):format(spec_CVTaddon.CVTdamage))
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--callback when hitting button "start maintenance"
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystemGUI:StartMaintenance(yes, self)
	if yes then
		local spec = self.spec_RealisticDamageSystem

		spec.DamagesBeforeMaintenance = spec.TotalNumberOfDamages

		spec.MultiplayerCosts = spec.AllDamagesTable[spec.DialogSelectedOptionCallback][5]

		spec.MaintenanceActive = true
		RealisticDamageSystem.eventActive = false

		for i = 1, spec.DialogSelectedOptionCallback, 1 do
			table.remove(spec.AllDamagesTable, 1)	--remove as many damages from table as selected
			table.remove(spec.LengthForDamages, 1)	--remove as many damages from table as selected
		end

		for i = 1, table.getn(spec.AllDamagesTable), 1 do
			spec.AllDamagesTable[i][1] = g_i18n:getText("dialog_maintenance_NumberDamages"..tostring(i), RealisticDamageSystemGUI.l10nEnv)  --rename tables so that the first options displayes "1 damage" in the selection again
		end
	
		--Multiplayer
		self:raiseDirtyFlags(spec.dirtyFlag)

		if g_server ~= nil then
			g_server:broadcastEvent(SyncClientServerEvent.new(self, spec.NextInspectionAge, spec.DamagesThatAddedWear, spec.FinishDay, spec.FinishHour, spec.FinishMinute, spec.DialogSelectedOptionCallback, spec.NextKnownDamageAge, spec.NextUnknownDamageAge, spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.TotalNumberOfDamagesPlayerDoesntKnow, spec.NextKnownDamageOperatingHour, spec.NextUnknownDamageOperatingHour, spec.DamagesMultiplier, spec.FirstLoadNumbersSet, spec.MaintenanceActive, spec.InspectionActive, spec.CVTRepairActive, self.spec_RealisticDamageSystemEngineDied.EngineDied, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages), RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog)), nil, nil, self)
		else
			g_client:getServerConnection():sendEvent(SyncClientServerEvent.new(self, spec.NextInspectionAge, spec.DamagesThatAddedWear, spec.FinishDay, spec.FinishHour, spec.FinishMinute, spec.DialogSelectedOptionCallback, spec.NextKnownDamageAge, spec.NextUnknownDamageAge, spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.TotalNumberOfDamagesPlayerDoesntKnow, spec.NextKnownDamageOperatingHour, spec.NextUnknownDamageOperatingHour, spec.DamagesMultiplier, spec.FirstLoadNumbersSet, spec.MaintenanceActive, spec.InspectionActive, spec.CVTRepairActive, self.spec_RealisticDamageSystemEngineDied.EngineDied, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages), RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog)))
		end
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--callback when hitting button "start inspection"
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystemGUI:StartInspection(yes, self)
	if yes then
		local spec = self.spec_RealisticDamageSystem

		spec.FinishDay, spec.FinishHour, spec.FinishMinute = RealisticDamageSystemGUI:CalculateFinishTime(1, 0)
		
		spec.InspectionActive = true
		RealisticDamageSystem.eventActive = false
		
		--Multiplayer
		self:raiseDirtyFlags(spec.dirtyFlag)

		if g_server ~= nil then
			g_server:broadcastEvent(SyncClientServerEvent.new(self, spec.NextInspectionAge, spec.DamagesThatAddedWear, spec.FinishDay, spec.FinishHour, spec.FinishMinute, spec.DialogSelectedOptionCallback, spec.NextKnownDamageAge, spec.NextUnknownDamageAge, spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.TotalNumberOfDamagesPlayerDoesntKnow, spec.NextKnownDamageOperatingHour, spec.NextUnknownDamageOperatingHour, spec.DamagesMultiplier, spec.FirstLoadNumbersSet, spec.MaintenanceActive, spec.InspectionActive, spec.CVTRepairActive, self.spec_RealisticDamageSystemEngineDied.EngineDied, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages), RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog)), nil, nil, self)
		else
			g_client:getServerConnection():sendEvent(SyncClientServerEvent.new(self, spec.NextInspectionAge, spec.DamagesThatAddedWear, spec.FinishDay, spec.FinishHour, spec.FinishMinute, spec.DialogSelectedOptionCallback, spec.NextKnownDamageAge, spec.NextUnknownDamageAge, spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.TotalNumberOfDamagesPlayerDoesntKnow, spec.NextKnownDamageOperatingHour, spec.NextUnknownDamageOperatingHour, spec.DamagesMultiplier, spec.FirstLoadNumbersSet, spec.MaintenanceActive, spec.InspectionActive, spec.CVTRepairActive, self.spec_RealisticDamageSystemEngineDied.EngineDied, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages), RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog)))
		end
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--mod FS22_CVT_Addon needed!!!  callback when hitting button "CVT start change"
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystemGUI:StartCVTChange(yes, self)
	if yes then
		local spec = self.spec_RealisticDamageSystem
		
		spec.FinishDay, spec.FinishHour, spec.FinishMinute = RealisticDamageSystemGUI:CalculateFinishTime(7, 0)
		
		spec.MultiplayerCosts = 15000

		spec.CVTRepairActive = true
		RealisticDamageSystem.eventActive = false

		--Multiplayer
		self:raiseDirtyFlags(spec.dirtyFlag)

		if g_server ~= nil then
			g_server:broadcastEvent(SyncClientServerEvent.new(self, spec.NextInspectionAge, spec.DamagesThatAddedWear, spec.FinishDay, spec.FinishHour, spec.FinishMinute, spec.DialogSelectedOptionCallback, spec.NextKnownDamageAge, spec.NextUnknownDamageAge, spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.TotalNumberOfDamagesPlayerDoesntKnow, spec.NextKnownDamageOperatingHour, spec.NextUnknownDamageOperatingHour, spec.DamagesMultiplier, spec.FirstLoadNumbersSet, spec.MaintenanceActive, spec.InspectionActive, spec.CVTRepairActive, self.spec_RealisticDamageSystemEngineDied.EngineDied, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages), RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog)), nil, nil, self)
		else
			g_client:getServerConnection():sendEvent(SyncClientServerEvent.new(self, spec.NextInspectionAge, spec.DamagesThatAddedWear, spec.FinishDay, spec.FinishHour, spec.FinishMinute, spec.DialogSelectedOptionCallback, spec.NextKnownDamageAge, spec.NextUnknownDamageAge, spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.TotalNumberOfDamagesPlayerDoesntKnow, spec.NextKnownDamageOperatingHour, spec.NextUnknownDamageOperatingHour, spec.DamagesMultiplier, spec.FirstLoadNumbersSet, spec.MaintenanceActive, spec.InspectionActive, spec.CVTRepairActive, self.spec_RealisticDamageSystemEngineDied.EngineDied, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages), RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog)))
		end
	end
end
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--mod FS22_CVT_Addon needed!!!  callback when hitting button "CVT start repair"
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystemGUI:StartCVTRepair(yes, self)
	if yes then
		local spec = self.spec_RealisticDamageSystem

		spec.MultiplayerCosts = spec.CVTcosts
		
		spec.CVTRepairActive = true
		RealisticDamageSystem.eventActive = false

		--Multiplayer
		self:raiseDirtyFlags(spec.dirtyFlag)

		if g_server ~= nil then
			g_server:broadcastEvent(SyncClientServerEvent.new(self, spec.NextInspectionAge, spec.DamagesThatAddedWear, spec.FinishDay, spec.FinishHour, spec.FinishMinute, spec.DialogSelectedOptionCallback, spec.NextKnownDamageAge, spec.NextUnknownDamageAge, spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.TotalNumberOfDamagesPlayerDoesntKnow, spec.NextKnownDamageOperatingHour, spec.NextUnknownDamageOperatingHour, spec.DamagesMultiplier, spec.FirstLoadNumbersSet, spec.MaintenanceActive, spec.InspectionActive, spec.CVTRepairActive, self.spec_RealisticDamageSystemEngineDied.EngineDied, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages), RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog)), nil, nil, self)
		else
			g_client:getServerConnection():sendEvent(SyncClientServerEvent.new(self, spec.NextInspectionAge, spec.DamagesThatAddedWear, spec.FinishDay, spec.FinishHour, spec.FinishMinute, spec.DialogSelectedOptionCallback, spec.NextKnownDamageAge, spec.NextUnknownDamageAge, spec.forDBL_TotalNumberOfDamagesPlayerKnows, spec.TotalNumberOfDamagesPlayerDoesntKnow, spec.NextKnownDamageOperatingHour, spec.NextUnknownDamageOperatingHour, spec.DamagesMultiplier, spec.FirstLoadNumbersSet, spec.MaintenanceActive, spec.InspectionActive, spec.CVTRepairActive, self.spec_RealisticDamageSystemEngineDied.EngineDied, RealisticDamageSystem:LengthTableToString(spec.LengthForDamages), RealisticDamageSystem:MPTableToString(RealisticDamageSystem.UsersHadTutorialDialog)))
		end
	end
end

--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
--calculate the time when maintenance/inspection/cvt-repair/cvt-change is finished
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
function RealisticDamageSystemGUI:CalculateFinishTime(AddHour, AddMinute)
	local FinishHour = 0 --hour when finished
	local FinishMinute = 0 --minute when finished
	local PlusHourForMinutes = math.floor((g_currentMission.environment.currentMinute + AddMinute) / 60) --finish minute is greater than 60 and hour needs to be higher
	local FinishDay = g_currentMission.environment.currentDay + math.floor((g_currentMission.environment.currentHour + PlusHourForMinutes + AddHour) / 21) --day when finished

	if g_currentMission.environment.currentHour + AddHour + PlusHourForMinutes >= 21 then --when finish time is not in working hours (>21 o'clock)
		FinishHour = g_currentMission.environment.currentHour + AddHour + PlusHourForMinutes  - 14 - (math.max(g_currentMission.environment.currentHour - 21, 0))  --calculate hour on new day
		if PlusHourForMinutes >= 1 then --when finish minute is > 60
			FinishMinute = g_currentMission.environment.currentMinute + AddMinute - 60 --new finish minute when minute is > 60
		else
			FinishMinute = g_currentMission.environment.currentMinute + AddMinute --calculate normal finish minute when finish minute is not > 60
		end
	elseif g_currentMission.environment.currentHour < 7 then --when current hour is not in working hours (<7 o'clock)
		FinishHour = g_currentMission.environment.currentHour + AddHour + (7 - g_currentMission.environment.currentHour) --remove spare time until 7 o'clock
		FinishMinute = 0 + AddMinute --start minute from 0
	else
		FinishHour = g_currentMission.environment.currentHour + AddHour + PlusHourForMinutes --normal calculation when time is in working hours
		if PlusHourForMinutes >= 1 then --when finish minute is > 60
			FinishMinute = g_currentMission.environment.currentMinute + AddMinute - 60 --new finish minute when minute is > 60
		else
			FinishMinute = g_currentMission.environment.currentMinute + AddMinute --calculate normal finish minute when finish minute is not > 60
		end
	end

	if FinishHour >= 21 then				--if the time has to be paused two times
		FinishDay = FinishDay + 1			--change to next day
		FinishHour = FinishHour - 14		--remove time from 21:00 - 07:00 o'clock
	end

	return FinishDay, FinishHour, FinishMinute --return day, hour and minute
end