-- by Frvetz
-- Contact: RealisticDamageSystem@gmail.com
-- Date 2.12.2021

RealisticDamageSystemMotorStartDialog = {};
RealisticDamageSystemMotorStartDialog.l10nEnv = "FS19_RealisticDamageSystemMotorStartDialog";   
 
 
function RealisticDamageSystemMotorStartDialog:loadMap(name)
   RealisticDamageSystemMotorStartDialog.automaticMotorStartEnabledBackup = g_currentMission.missionInfo.automaticMotorStartEnabled
end

function RealisticDamageSystemMotorStartDialog:update(dt)
    if g_currentMission.missionInfo.automaticMotorStartEnabled ~= RealisticDamageSystemMotorStartDialog.automaticMotorStartEnabledBackup then
	    RealisticDamageSystemMotorStartDialog.automaticMotorStartEnabledBackup = g_currentMission.missionInfo.automaticMotorStartEnabled
		RealisticDamageSystem:DIALOG_MOTORSTART()
    end
end 


function RealisticDamageSystem:DIALOG_MOTORSTART()
    if g_currentMission.missionInfo.automaticMotorStartEnabled == true then
    	g_gui:showInfoDialog({text = g_i18n:getText("dialog_AutoMotorStart", RealisticDamageSystemMotorStartDialog.l10nEnv)})
    end
end
addModEventListener(RealisticDamageSystemMotorStartDialog)