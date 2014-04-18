if myHero.charName ~= "Xerath" then return end

local version = 1.435
local AUTOUPDATE = true
local SCRIPT_NAME = "Xerath"

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

if FileExist(SOURCELIB_PATH) then
require("SourceLib")
else
DOWNLOADING_SOURCELIB = true
DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() print("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...") return end

if AUTOUPDATE then
SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/honda7/BoL/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/honda7/BoL/master/VersionFiles/"..SCRIPT_NAME..".version"):CheckUpdate()
end

local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.github.com/honda7/BoL/master/Common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.github.com/honda7/BoL/master/Common/SOW.lua")
RequireI:Check()

if RequireI.downloadNeeded == true then return end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------


local Qrange = {750, 1550}
local CurrentQrange = Qrange[2]
local Wrange = 1100
local Erange = 1050
local Rrange = {3200, 4400, 5600}

local QWidth = 100
local WWidth = 200
local EWidth = 60
local RWidth = 200

local QDelay = 0.7
local WDelay = 0.7
local EDelay = 0.25
local RDelay = 0.9

local ESpeed = 1400
local PassiveUp = true
local Qdamage = {80, 120, 160, 200, 240}
local Qscaling = 0.75
local Wdamage = {60, 90, 120, 150, 180}
local Wscaling = 0.6
local Edamage = {80, 110, 140, 170, 200}
local Escaling = 0.45
local Rdamage = {570, 735, 900}
local Rscaling = 1.29
local MainCombo = {_Q, _W, _E, _R}

local DamageToHeros = {}
local lastrefresh = 0
local LastPing = 0

local CastingQ = 0
local CastingR = 0

local LastRTarget
local LastRTargetTime
local RPressTime, RPressTime2 = 0, 0
local UsedR = 0
local SelectedTarget


function OnLoad()
	VP = VPrediction()
	SOWi = SOW(VP)

	Menu = scriptConfig("Xerath", "Xerath")

	Menu:addSubMenu("Orbwalking", "Orbwalking")
		SOWi:LoadToMenu(Menu.Orbwalking)

	--[[Combo]]
	Menu:addSubMenu("Combo", "Combo")
		Menu.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF , true)
		Menu.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("Enabled", "Combo!", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	
	--[[Harassing]]
	Menu:addSubMenu("Harass", "Harass")
		Menu.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF , true)
		Menu.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 10, 0, 100)
		Menu.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	
	--[[RSnipe]]
	Menu:addSubMenu("RSnipe", "RSnipe")
		Menu.RSnipe:addParam("Alert", "Draw when an enemy is killable with R", SCRIPT_PARAM_ONOFF , true)
		Menu.RSnipe:addParam("Ping", "Ping when an enemy is killable with R (only local)", SCRIPT_PARAM_ONOFF , true)
		Menu.RSnipe:addParam("AutoR", "Auto use R charges", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("R"))
		Menu.RSnipe:addParam("AutoR2", "Use 1 charge (tap)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))

		TapMenu = #Menu.RSnipe._param

		Menu.RSnipe:addParam("Delay", "Wait X ms before changing target", SCRIPT_PARAM_SLICE, 0, 0, 3000)
		Menu.RSnipe:addParam("Targetting", "Targetting mode: ", SCRIPT_PARAM_LIST, 2, { "Near mouse (1000) range from mouse", "Most killable"})
	
	--[[Farming]]
	Menu:addSubMenu("Farm", "Farm")
		Menu.Farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Farm:addParam("UseW",  "Use W", SCRIPT_PARAM_ONOFF, false)
		Menu.Farm:addParam("ManaCheck", "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 10, 0, 100)
		Menu.Farm:addParam("Enabled", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))
	
	--[[Jungle farming]]
	Menu:addSubMenu("JungleFarm", "JungleFarm")
		Menu.JungleFarm:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("Enabled", "Farm jungle!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	--[[Misc]]
	Menu:addSubMenu("Misc", "Misc")
		Menu.Misc:addParam("WCenter", "Cast W centered", SCRIPT_PARAM_ONOFF, false)
		Menu.Misc:addParam("Selected", "Focus selected target", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addParam("AutoE", "Auto E on dashing enemies", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addParam("AutoE2", "Auto E on stunned enemies", SCRIPT_PARAM_ONOFF, true)
		
	--[[Drawing]]
	Menu:addSubMenu("Drawing", "Drawing")
	  Menu.Drawing:addParam("AArange", "Draw AA range", SCRIPT_PARAM_ONOFF, true)
		Menu.Drawing:addParam("Qrange", "Draw Q range", SCRIPT_PARAM_ONOFF, true)
		Menu.Drawing:addParam("Wrange", "Draw W range", SCRIPT_PARAM_ONOFF, false)
		Menu.Drawing:addParam("Rrange", "Draw R range", SCRIPT_PARAM_ONOFF, false)
		Menu.Drawing:addParam("RrangeM", "Draw R range on the minimap", SCRIPT_PARAM_ONOFF, true)
		Menu.Drawing:addParam("DrawDamage", "Draw damage after combo in healthbars", SCRIPT_PARAM_ONOFF, false)

	Menu:addParam("Version", "Version", SCRIPT_PARAM_INFO, version)
	
	EnemyMinions = minionManager(MINION_ENEMY, Qrange[2], myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, Qrange[2], myHero, MINION_SORT_MAXHEALTH_DEC)
 	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		_IGNITE = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		_IGNITE = SUMMONER_2
	else
		_IGNITE = nil
	end
end

function GetComboDamage(Combo, Unit)
	local totaldamage = 0
	for i, spell in ipairs(Combo) do
		totaldamage = totaldamage + GetDamage(spell, Unit)
	end
	return totaldamage
end

function GetDamage(Spell, Unit)
	local truedamage = 0
	if Spell == _Q and myHero:GetSpellData(_Q).level ~= 0 then
		truedamage = myHero:CalcMagicDamage(Unit, Qdamage[myHero:GetSpellData(_Q).level] + myHero.ap * Qscaling)
	elseif Spell == _W and myHero:GetSpellData(_W).level ~= 0 and (myHero:CanUseSpell(_W) == READY) then
		truedamage = myHero:CalcMagicDamage(Unit, Wdamage[myHero:GetSpellData(_W).level] + myHero.ap * Wscaling)
	elseif Spell == _E and myHero:GetSpellData(_E).level ~= 0 then
		truedamage = myHero:CalcMagicDamage(Unit, Edamage[myHero:GetSpellData(_E).level] + myHero.ap * Escaling)
	elseif Spell == _R and myHero:GetSpellData(_R).level ~= 0 and (myHero:CanUseSpell(_R) == READY) then
		truedamage = myHero:CalcMagicDamage(Unit, Rdamage[myHero:GetSpellData(_R).level] + myHero.ap * Rscaling)
	elseif Spell == _IGNITE and _IGNITE and (myHero:CanUseSpell(_IGNITE) == READY) then
		truedamage = 50 + 20 * myHero.level
	end
	return truedamage
end

function OnLoseBuff(unit, buff)
	if unit.isMe then
		if buff.name:lower():find("xerathrshots") then
			CastingR = 0
		end
		if buff.name == "xerathascended2onhit" then
			PassiveUp = false
		end
	end
end

function ImCastingR()
	return ((os.clock() - CastingR) < 10 and (myHero:GetSpellData(_R).currentCd < 10))
end

function RecPing(X, Y)
	Packet("R_PING", {x = X, y = Y, type = PING_FALLBACK}):receive()
end

function OnTick()
	RefreshKillableTexts()
	

	if Menu.RSnipe.AutoR then
		RPressTime = os.clock()
	end
