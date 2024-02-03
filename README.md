# 🛠️ Realistic Damage System - Realistisches Schadenssystem 🛠️

## AT THE MOMENT THIS SCRIPT ONLY AFFECTS MOTORISED VEHICLES. IMPLEMENTS STILL HAVE TO BE REPAIRED LIKE NORMAL
## THIS SCRIPT IS AN EARLY-ACCESS VERSION. IT MAY AND WILL CONTAIN BUGS!

![icon_RealisticDamageSystem](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/01e8ec66-2aad-4fc1-86f9-97d58da1e836)

[⤵️ Changelog](#Changelog)

## ▶ YouTube Video: Introduction

[![Preview](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/7b4589a5-2b12-4eb1-8a21-eb0f277ac17f)](https://youtu.be/RVxSv0zQq84)

## English description [⤵️ Hier findest du die deutsche Bescheibung](#Deutsche-Beschreibung)

#### * At the moment this script only affects motorised vehicles. Implements still have to be repaired like normal *
#### * This script is an early-access version. It may and will contain bugs!

The mod "Extended Vehicle Maintenance" from FS19 returns to FS22 with new features!

With this script you will make the maintenance of your vehicle a lot more complex and actually have to think about when you want to repair damages of your vehicle.
Damages occur on every vehicle over time. Some of them you will be notified of in the help window, some you will have to find through a one-hour inspection. 
To start an inspection or repair the damages, you need to buy a pallet in the shop, drive close to it and then call up the maintenance menu. In this menu you can select how many damages you want to repair. In addition, you will receive a detailed cost overview and a time estimate for the expected duration of the repair based on your current selection.

Once a maintenance or inspection has been started, it will only be carried out during the working hours from 7:00 - 21:00 o'clock. However, if it falls within a time window when no work is being carried out, it will be paused until the morning.

If you don't repair the damages your vehicle has suffered over time, it will take longer to start, risk false starts and stall if the engine is under excessive load.

The first time you start the game with this mod, the script looks at the current vehicle damage and adds the number of damages that would have caused this vehicle damage. These damages are already known, so they do not have to be found by an inspection and can be repaired straight away via the maintenance menu.

If you are playing with the latest version of the CVT_Addon mod, improper vehicle operation increases wear on the gearbox. Below 90% damage, the gearbox can be repaired for money (maximum 10.769,-) and a lot of time (maximum 11hrs) - above 90%, the gearbox must be completely replaced. This costs considerably more (15.000,-), but takes less time (7 hours)

In addition, the costs for the repair and the amount of damages can be set in the ESC menu with the "Repair and paint settings (Configure Maintenance)" mod.

#### If you have any questions, requests or problems, please feel free to contact the following email: RealisticDamageSystem@gmail.com
#### You can also join the following discord: [SbSh-Pool Discord](https://discord.com/invite/mfergkwhDu)
  
- #### Full local multiplayer and dedicated server compatibility
- #### Supports the mod "CVT_Addon"
- #### Supports the mod "Repair and paint settings (Configure Maintenance)"
- #### Supports the mod "Dashboard Live"
- #### Compatible with the mod "Advanced Maintenance"
- #### Compatible with the mod "Advanced Farm Manager"
- #### Compatible with the mod "Auto Repair"
- #### Compatible with the mod "Mobile Workshop" (does not replace the maintenance pallet!)
- #### In-game tutorial available (Console command "rdsResetTutorial" available to restart the in-game tutorial for yourself)
- #### Help available in the ESC menu
- ### !When activating the automatic engine start, the engine stall function is deactivated!

## 📷 English tutorial 📷
### 1️⃣ HUD
#### Information
When you operate a vehicle, the help window informs you about the current condition of the vehicle.
This allows you to see the number of currently known damages and when the vehicle should be inspected for further hidden damages at the latest.
After an inspection, the damages found are added to the number of current damages.

![gameplay_en](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/1aa4307b-d2bc-463e-b6ce-e5efc6b34050)

Any damage, whether known or not, leads to a loss of engine power.
If the inspection is not carried out, consequences of the unknown damages must be expected. For example, the vehicle will stall if the engine load is too high and will not start properly if the automatic engine start is deactivated in the game settings.

![stalled_en](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/4b893deb-c7e9-4146-abf2-981d39f1f8af)

#### Open maintenance menu
By default, the vehicle maintenance menu can be called up with CTRL + J when you are near a vehicle maintenance palette (available in the shop).

![menu_open_en](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/1fb42b9b-6982-47f4-a786-f2325857bb13)

#### Maintenance started
As soon as maintenance or similar has been started, you will be shown in the help window when it will be completed.

![repairing_en](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/ecc0363c-392b-4c5e-8e43-f77d041a0d45)

### 2️⃣ Maintenance menu
In this window (CTRL + J) you can see a text that shows how many damages can be repaired in total, how much the repair will cost with the current selection and when it will be completed. 
The vehicle cannot be used during maintenance!

Below the text you can select how many damages should be repaired...

Select option -> Start repair -> Money is deducted from the account -> Vehicle is only ready for use again when the displayed time is reached.

An inspection can also be started, which would take one hour. After completion, the number of damages found is displayed.

The costs for the repair and the amount of damages can be set in the ESC menu with the 'Repair and paint settings (Configure Maintenance)' mod.

![menu_normal_en](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/8734903e-7482-4fc4-a0b6-f2957f6d9710)

#### CVT_Addon support
Due to the 'CVT_Addon' script, improper vehicle operation increases wear on the gearbox in vehicles with a variable (CVT) gearbox.
Below 90% damage, the gearbox can be repaired for money (maximum 10.769,-) and a lot of time (5-11hrs).
Above 90%, the gearbox must be completely replaced. This costs considerably more (15.000,-), but takes less time (7 hours).

![menu_cvt_en](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/51fded86-5663-402c-b369-c84b51eea224)

Before the gearbox repair is actually started, you will be shown how much it will cost and how long it will take, just to be on the safe side.

![menu_cvt2_en](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/dc8e3a76-6837-4716-a508-8899c8776172)

#### Maintenance paused - working hours
Once the maintenance/inspection has started, it will only be carried out during working hours (7:00 to 21:00).
However, if the maintenance/inspection falls within a time window in which no work is being carried out, it will be paused.
If the maintenance/inspection has to be paused with the current selection, this is displayed in an additional line of text in this window.

![menu_paused_en](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/d8ccafb7-56fb-4b67-ac84-9edce6a47f74)


### 😃 Have fun! 😃



## Deutsche Beschreibung

#### * Im Moment betrifft dieses Skript nur motorisierte Fahrzeuge. Anbaugeräte müssen weiterhin wie gewohnt repariert werden *
#### * Dieses Script ist eine Early-Access Version. Es kann und wird Bugs enthalten!

Der Mod "Fahrzeugwartung" aus dem LS19 kehrt mit neuen Funktionen in den LS22 zurück!

Mit diesem Script machen Sie die Wartung Ihres Fahrzeugs um einiges komplexer und müssen sich tatsächlich überlegen, wann Sie Schäden an Ihrem Fahrzeug reparieren wollen.
An jedem Fahrzeug treten mit der Zeit Schäden auf. Manche von ihnen bekommen Sie im Hilfefenster mitgeteilt, manche müssen Sie erst durch eine einstündige Inspektion finden. 
Um eine Inspektion zu starten oder die Schäden zu reparieren, müssen Sie eine Palette im Shop kaufen, nah an diese heranfahren und anschließend das Wartungsmenü aufrufen. In diesem Menü können Sie auswählen wie viele Schäden repariert werden sollen. Außerdem erhalten Sie eine detaillierte Kostenübersicht und eine Zeitangabe für die voraussichtliche Dauer der Reparatur basierend auf Ihrer aktuellen Auswahl.

Sobald eine Wartung oder Inspektion gestartet wurde, wird sie nur während den Arbeitszeiten von 7:00 - 21:00 Uhr durchgeführt. Sollte sie dennoch in ein Zeitfenster fallen, wo nicht gearbeitet wird, wird sie bis zum Morgen pausiert.

Wenn Sie die Schäden, die Ihr Fahrzeug im Laufe der Zeit erlitten hat, nicht reparieren, braucht es länger, um anzuspringen, könnte fehlstarten und wird absterben, wenn der Motor übermäßig belastet wird.

Beim ersten Spielstart mit diesem Mod, schaut das Script den aktuellen Fahrzeugschaden an und fügt so viele Schäden hinzu, die diesen Fahrzeugschaden verursacht hätten. Diese sind bereits bekannte, müssen also nicht erst durch eine Inspektion aufgedeckt werden und können direkt über das Wartungsmenü repariert werden.

Sollten Sie mit der neusten Version des Mods CVT_Addon spielen, so nimmt Ihr Getriebe durch unsachgemäße Bedienung an Schaden zu. Unter 90% Schaden, kann das Getriebe für Geld und viel Zeit repariert werden - ab 90%, muss dieses ausgetauscht werden. Dies kostet deutlich mehr Geld, geht aber schneller.

Zusätzlich können die Kosten für die Reparatur und die Menge der Schäden im ESC-Menü mit dem Mod "Reparatur und Lackiereinstellungen (Configure Maintenance)" eingestellt werden.

#### Wenn Sie Fragen, Wünsche oder Probleme haben, wenden Sie sich bitte an die folgende E-Mail-Adresse: RealisticDamageSystem@gmail.com
#### Außerdem können Sie folgendem Discord beitreten: [SbSh-Pool Discord](https://discord.com/invite/mfergkwhDu)

- #### Vollständige lokaler Multiplayer und Dedicated Server Unterstützung
- #### Ingame Tutorial verfügbar (Konsolenbefehl "rdsResetTutorial", um das ingame Tutorial für sich selbst neu zu starten)
- #### Unterstützung des Mods "CVT_Addon"
- #### Unterstützung des Mods "Dashboard Live"
- #### Unterstützung des Mods "Reparatur Und Lackierungseinstellungen (Configure Maintenance)"
- #### Kompatibel mit dem Mod "Erweiterte Wartung (Advanced Maintenance)"
- #### Kompatibel mit dem Mod "Fortgeschrittener Farm Manager (Advanced Farm Manager)"
- #### Kompatibel mit dem Mod "Auto Repair"
- #### Kompatibel mit dem Mod "Mobile Werkstatt" (ersetzt nicht die Wartungspallete!)
- #### Hilfe im ESC-Menü verfügbar
- ### !Bei Aktivierung des automatischen Motorstarts, wird die Funktion des Motorabsterbens deaktiviert!

## 📷 Deutsches Tutorial 📷
### 1️⃣ HUD
#### Information
Wenn Sie ein Fahrzeug fahren, informiert Sie das Hilfefenster über den aktuellen Zustand des Fahrzeugs.
So können Sie die Anzahl der aktuell bekannten Schäden und wann das Fahrzeug spätestens auf weitere versteckte Schäden inspiziert werden sollte, ablesen.
Nach einer Inspektion werden die gefundenen Schäden zu der Anzahl der aktuellen Schäden hinzugefügt.

![gameplay_de](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/07b07d46-4439-483b-865a-e5442936f8f0)

Jeder Schaden, ob bekannt oder nicht, führt zu Leistungsverlust.
Sollte die Inspektion nicht durchgeführt werden, muss mit Folgen der unbekannten Schäden zu rechnen sein. So stirbt das Fahrzeug bei zu hoher Motorlast ab und startet nicht ordnungsgemäß, wenn der automatische Motorstart in den Spieleinstellungen deaktiviert ist.

![stalled_de](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/89dbb792-fa33-4411-8a3f-7b59569f3950)

#### Wartungsmenü aufrufen
Standardgemäß kann das Menü für die Fahrzeugwartung mit STRG + J aufgerufen werden, wenn Sie in der Nähe einer Farzeugwartungs-Palette (im Shop erhältlich) sind.

![menu_open_de](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/84624ce8-c893-46bd-acab-80e2331cef5c)

#### Wartung gestartet
Sobald eine Wartung oder ähnliches gestartet wurde, wird ihnen im Hilfefenster angezeigt, wann sie abgeschlossen sein wird.

![repairing_de](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/4f7a3dd8-9eff-4820-bfce-5be0604a9688)

### 2️⃣ Wartungsmenü
In diesem Fenster (STRG + J) kann man einen Text sehen, der anzeigt, wie viele Schäden insgesamt repariert werden können, wie viel die Reparatur mit der aktuellen Auswahl kosten wird und wann sie abgeschlossen sein wird. 
Während der Wartung kann das Fahrzeug nicht benutzt werden!

Unter dem Text können Sie auswählen, wie viele Schäden repariert werden sollen...

Option auswählen -> Reparatur starten -> Geld wird vom Konto abgezogen -> Fahrzeug ist erst wieder einsatzbereit, wenn die angezeigte Zeit erreicht ist.

Außerdem kann eine Inspektion gestartet werden, welche eine Stunde dauern würde. Nach Abschluss wird die Anzahl der gefundenen Schäden angezeigt.

Die Kosten für die Reparatur und die Menge der Schäden können im ESC-Menü mit dem Mod 'Reparatur und Lackiereinstellungen (Configure Maintenance)' eingestellt werden.

![menu_normal_de](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/b91368fe-0225-4d6b-8332-7ee5622497f1)

#### CVT_Addon Unterstützung
Durch das Script 'CVT_Addon' nimmt bei Fahrzeugen mit stufenlosem Getriebe durch unsachgemäße Bedienung der Verschleiß des Getriebes zu. 
Unter 90% Schaden, kann das Getriebe für Geld (maximal 10.769,-) und viel Zeit (maximal 11h) repariert werden.
Ab einer Höhe von 90%, muss das Getriebe vollständig getauscht werden. Dies kostet deutlich mehr (15.000,-), dauert allerdings weniger lang (7h).

![menu_cvt_de](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/5c1339ac-ec3f-48f0-84f9-2578f5e80823)

Bevor die Getriebe-Reparatur wirklich gestartet wird, wird Ihnen sicherheitshalber noch angezeigt wie viel sie kosten und wie lange sie dauern würde.

![menu_cvt2_de](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/ea06735c-3913-4b5c-8c19-fdf15bc931ef)

#### Wartung pausiert - Arbeitszeiten
Wenn die Wartung/Inspektion begonnen hat, wird sie nur während den Arbeitszeiten (7:00 bis 21:00 Uhr) durchgeführt.
Sollte die Wartung/Inspektion dennoch in ein Zeitfenster fallen, in dem keine Arbeiten durchgeführt werden, wird diese pausiert.
Falls die Wartung/Inspektion mit der aktuellen Auswahl pausiert werden muss, wird dies in einer weiteren Zeile Text in diesem Fenster angezeigt.

![menu_paused_de](https://github.com/Frvetz/FS22_RealisticDamageSystem/assets/76913845/7ffec625-98bd-45c2-98c4-ca5f711603dc)


### 😃 Viel Spaß! 😃


## Changelog
### Changelog Version 0.9.0.2:
- bug with FS22 normal-damage-system fixed (too much normal-damage)
- bug with mod FS22_A-ProductionRevamp fixed (text did not show correctly)
- bug with mod FS22_PowerTools fixed (text did not show correctly)
- general fix for every other mod that shows a optionDialog (text did not show correctly)

### Changelog Version 0.9.0.3:
- fixed helpMenu localization error when playing with a language that is not de/en/fr

### Changelog Version 0.9.0.4:
- FS22 normal-damage-system bug at first savegame load with mod fixed (vehicle damage did not represent the damages in the hud)

### Changelog Version 0.9.0.5:
- Russian translation added
- fixed where not enough FS22 normal-damage was repaired (still FS22 normal-damage left when repairing all damages)

### Changelog Version 0.9.0.6:
- fixed multiplayer problem where the tutorial question got asked again
- fixed another bug with mod FS22_A-ProductionRevamp (another text did not show correctly)
- fixed wrong text for CVT-Gearbox-Change (takes 7h not 15 hours to complete)
- added text for when the CVT-Gearbox-Change needs to be paused
- fixed missing repair needs to be paused text when clicking on "start repair"
- added displayed finish time for the question if you want to start an inspection
- added displayed finish time for the question if you want to start a CVT-Gearbox-Change
- fixed Russian translation problems with CVT-Addon

### Changelog Version 0.9.0.7:
- fixed problem where the time was not paused for a second night (finishHour > 21 o'clock)

### Changelog Version 0.9.0.8:
- added console command to reset all damages of a vehicle (rdsResetDamages)
- added console command to reset the time until next inspection (rdsResetInspection)
- added console command to complete an active inspection or maintenance immediately (rdsStopActiveRepair)
- added console command to show debug in log (rdsDebug)
- added console command to remove a number of damages you want (rdsRemoveDamages [number])
- added console command to find all hidden damages (rdsFindDamages)

### Changelog Version 0.9.0.9:
- fixed bug where the vehicle could no longer be started after completing maintenance
- fixed error with console command "rdsRemoveDamages" when no number has been entered behind the command
- added DBL (dashboard live - mod) support
- adapted description

### Changelog Version 0.9.1.0:
- fixed problem where vehicles gained damages during repair
- added Brazilian translation
- fixed problem where buttons from other optionDialog windows where disabled
- fixed problem where a maintenance/inspection/cvt-repair did not finish even though the current time is greater than the displayed end time
- fixed problem where the months until the next inspection were not reset to 12 again after an inspection
- fixed problem where the vehicle no longer got damages because of its age
- remade the whole damage calculation. Now it is random how many damages your vehicle gets
(had to reset the time until the next inspect - had to make all currently unknown damages known)
- added console command to reset the time until a next damage occurs (rdsResetTimeUntilNextDamage) (needed when the operating time a vehicle was changed manually)
- added console command to reset everything (rdsResetEverything)
- changed repair/inspection text so it displays how many days it takes

[⤴️ Go to top / ⤴️ Nach oben springen](#top)
