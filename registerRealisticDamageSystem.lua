-- Contact: RealisticDamageSystem@gmail.com
-- THANKS TO W33ZL (POWER TOOLS MOD) FOR LETTING ME USE HIS MENU!
-- Date 2.12.2021


-- THANKS YOU FOR THE REGISTER.LUA IAN!

registerRealisticDamageSystem = {}


g_specializationManager:addSpecialization("RealisticDamageSystem", "RealisticDamageSystem", g_currentModDirectory.."RealisticDamageSystem.lua", "")

function registerRealisticDamageSystem.registerSpecialization()
	local specName = "RealisticDamageSystem"

	for vehicleType, vehicle in pairs(g_vehicleTypeManager.types) do

		if vehicle ~= nil and vehicleType ~= "locomotive" and vehicleType ~= "ConveyorBelt" and vehicleType ~= "pickupConveyorBelt" and vehicleType ~= "woodCrusherTrailermotorized" and vehicleType ~= "baleWrapper" and vehicleType ~= "craneTrailer" then

			local ismotorized = false;
			local hasNotRDS = true;

			for name, spec in pairs(vehicle.specializationsByName) do
				if name == "motorized" then
					ismotorized = true;
				elseif name == "RealisticDamageSystem" then
					hasNotRDS = false;
				end
			end
			if hasNotRDS and ismotorized then
				print("  adding RealisticDamageSystem to vehicleType '"..tostring(vehicleType).."'")

				local specObject = g_specializationManager:getSpecializationObjectByName(specName);

				vehicle.specializationsByName[specName] = specObject;
				table.insert(vehicle.specializationNames, specName);
				table.insert(vehicle.specializations, specObject);
			end
		end
	end
end

TypeManager.finalizeTypes = Utils.appendedFunction(TypeManager.finalizeTypes, registerRealisticDamageSystem.registerSpecialization)

-- make localizations available
local i18nTable = getfenv(0).g_i18n
for l18nId,l18nText in pairs(g_i18n.texts) do
  i18nTable:setText(l18nId, l18nText)
end