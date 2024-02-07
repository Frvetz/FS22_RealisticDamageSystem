-- by Frvetz
-- Contact: RealisticDamageSystem@gmail.com
-- Date 2.12.2021

RealisticDamageSystemShopRepair = {};

function RealisticDamageSystemShopRepair:update(dt)
  if g_workshopScreen.isOpen == true and g_workshopScreen.vehicle ~= nil and g_workshopScreen.vehicle.spec_motorized ~= nil then
    g_workshopScreen.repairButton.disabled = true
  end
end;
addModEventListener(RealisticDamageSystemShopRepair)