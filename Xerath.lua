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

	if ImCastingR() and myHero:GetSpellData(_R).level > 0 and (((os.clock() - RPressTime) < 20) or  ((os.clock() - RPressTime2) < 1)) then
		local RTarget = GetBestTarget(Rrange[myHero:GetSpellData(_R).level], nil, Menu.RSnipe.Targetting)
		if RTarget then
			local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(RTarget, RDelay, RWidth, Rrange[myHero:GetSpellData(_R).level])
			if (HitChance >= 1) and GetDistance(CastPosition) <= (Rrange[myHero:GetSpellData(_R).level] + RWidth) then
				if LastRTarget and LastRTarget.networkID ~= RTarget.networkID then
					LastRTarget = RTarget
					LastRTargetTime = os.clock()
				elseif (os.clock() -  LastRTargetTime) > Menu.RSnipe.Delay / 1000 then
					CastSpell(_R, CastPosition.x, CastPosition.z)
				end
			end
		end
		do return end
	end
	
	if Menu.RSnipe.Ping and myHero:CanUseSpell(_R) == READY and (os.clock() - LastPing > 30) then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, Rrange[myHero:GetSpellData(_R).level]) and GetDamage(_R, enemy) >= enemy.health then
				for i = 1, 3 do
					DelayAction(RecPing,  1000 * 0.3 * i/1000, {enemy.x, enemy.z})
				end
				LastPing = os.clock()
			end
		end
	end
	
	SOWi:EnableAttacks()

	CurrentQrange = math.min(Qrange[1] + (Qrange[2] - Qrange[1]) * (os.clock() - CastingQ) / 1.5 - 200, Qrange[2])
	
	if Menu.Misc.AutoE and myHero:CanUseSpell(_E) == READY then
		for i, target in ipairs(GetEnemyHeroes()) do
			if ValidTarget(target,Erange) then
				local TargetDashing, CanHit, Position = VP:IsDashing(target, EDelay, EWidth, ESpeed, myHero.visionPos) 
				if TargetDashing and CanHit then
					local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(target, EDelay, EWidth, Erange, ESpeed, myHero, true)
					if HitChance >= 3 then
						CastSpell(_E, CastPosition.x,  CastPosition.z)
					end
				end
			end
		end

		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, 400) then
				CastSpell(_E, enemy.x, enemy.z)
			end
		end
	elseif Menu.Misc.AutoE2 and myHero:CanUseSpell(_E) == READY then
		for i, target in ipairs(GetEnemyHeroes()) do
			if ValidTarget(target, Erange) then
				local immobile, Position = VP:IsImmobile(target, EDelay, EWidth, Erange, ESpeed, myHero.visionPos)
				if immobile then
					local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(target, EDelay, EWidth, Erange, ESpeed, myHero, true)
					if HitChance >= 3 then
						CastSpell(_E, CastPosition.x,  CastPosition.z)
					end
				end
			end
		end
	end

	if Menu.Combo.Enabled then
		Combo()
	elseif Menu.Harass.Enabled and ((myHero.mana / myHero.maxMana * 100) >= Menu.Harass.ManaCheck or (os.clock() - CastingQ) < 3) then
		Harass()
	end

	if Menu.Farm.Enabled and ((myHero.mana / myHero.maxMana * 100) >= Menu.Farm.ManaCheck or (os.clock() - CastingQ) < 3) then
		Farm()
	end
	if Menu.JungleFarm.Enabled then
		JungleFarm()
	end
end

function GetBestTarget(Range, Ignore, ttype)
	local LessToKill = 100
	local LessToKilli = 0
	local target = nil
	local Mindist
	if not ttype or ttype == 2 then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, Range) then
				local DamageToHero = myHero:CalcMagicDamage(enemy, 200)
				local ToKill = enemy.health / DamageToHero
				if ((ToKill < LessToKill) or (LessToKilli == 0)) and (Ignore == nil or (Ignore.networkID ~= enemy.networkID)) then
					LessToKill = ToKill
					LessToKilli = i
					target = enemy
				end
			end
		end
	else
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, Range) then
				local Dist = GetDistanceSqr(mousePos, enemy)
				if (not Mindist or Mindist > Dist) and Dist < 1000*1000 then
					Mindist = Dist
					target = enemy
				end
			end
		end
	end

	if Menu.Misc.Selected and SelectedTarget ~= nil and ValidTarget(SelectedTarget, Range) then
		target = SelectedTarget
	end

	return target
end

function GetQTargets(maintarget, Width, Range)
	local targets = {}
	
	local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(maintarget, QDelay, QWidth, Qrange[2])
	table.insert(targets, Position)

	local LineEnd = Vector(myHero) + Range * (Vector(CastPosition) - Vector(myHero)):normalized()
	
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, Qrange[2]) and enemy.networkID ~= maintarget.networkID then
			local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(enemy, QDelay, QWidth, Qrange[2])
			local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(myHero), LineEnd, enemy)
			if isOnSegment and GetDistance(pointSegment, enemy) < Width then
				table.insert(targets, Position)
			end
		end
	end
	return #targets, targets
end

function GetWAOE(unit, position)
	local points = {}
	local targets = {}
	table.insert(points, position)
	table.insert(targets, unit)
	
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, Wrange + WWidth*3) and enemy.networkID ~= unit.networkID then
			local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(enemy, WDelay, WWidth, Wrange)
			table.insert(points, Position)
			table.insert(targets, enemy)
		end
	end
	

	for o = 1, 5 do
		local MECa = MEC(points)
		local Circle = MECa:Compute()
		
		if Circle and Circle.radius <= WWidth and #points > 1 then
			return Circle.center
		end
		
		if #points == 1 then
			return nil
		end
		
		local Dist = -1
		local MyPoint = points[1]
		local index = 0
		
		for i=2, #points, 1 do
			if GetDistance(points[i], MyPoint) >= Dist then
				Dist = GetDistanceSqr(points[i], MyPoint)
				index = i
			end
		end
		if index > 0 then
			table.remove(points, index)
		end
	end
end

function CastQ(target)
	if target and myHero:CanUseSpell(_Q) == READY then 
		if (os.clock() - CastingQ > 5) and myHero:CanUseSpell(_Q) == READY then
			CastSpell(_Q, myHero.x, myHero.z)
		elseif (os.clock() - CastingQ < 3) then 
			local n1, targets = GetQTargets(target, QWidth, CurrentQrange)
			local n2, targets2 = GetQTargets(target, QWidth, Qrange[2])
			
			local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(target, QDelay, QWidth, Qrange[2])
			if (((HitChance >= 2) or (os.clock() - CastingQ > 1.5) or GetDistance(CastPosition) <= CurrentQrange - 200) and GetDistance(CastPosition) <= CurrentQrange) and (GetDistance(target) <= CurrentQrange) and ((n2 == 1) or (n1 >= n2)) then
				Cast2Q(CastPosition)
			end
		end
	end
end

function OnGainBuff(unit, buff) 
	if unit.isMe and buff.name == "xerathascended2onhit" then
		PassiveUp = true
	end
end

function Combo()
	local QTarget = GetBestTarget(Qrange[2])
	local WTarget = GetBestTarget(Wrange + WWidth)
	local ETarget = GetBestTarget(Erange)

	local AAtarget = SOWi:GetTarget()
	SOWi:DisableAttacks()

	if (AAtarget and AAtarget.health < 200) or PassiveUp then
		SOWi:EnableAttacks()
	end

	if WTarget and myHero:CanUseSpell(_W) == READY and Menu.Combo.UseW then 
		local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(WTarget, WDelay, Menu.Misc.WCenter and WWidth or 1, Wrange)
		local CastPoint = GetWAOE(WTarget, Position)
		if CastPoint then
			CastSpell(_W, CastPoint.x, CastPoint.z)
		elseif HitChance >= 2 then
			CastSpell(_W, CastPosition.x, CastPosition.z)
		end
	end

	local Mcol, Mcol2, CollisionD
	if ETarget and myHero:CanUseSpell(_E) == READY and Menu.Combo.UseE then
		local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(ETarget, EDelay, EWidth, Erange, ESpeed, myHero, true)
		if HitChance >= 2 then
				CastSpell(_E, CastPosition.x,  CastPosition.z)
		end
	end

	if QTarget and (myHero:CanUseSpell(_E) ~= READY or (GetDistance(QTarget) >= Erange) or not Menu.Combo.UseE or CollisionD) and (myHero:CanUseSpell(_W) ~= READY or (GetDistance(QTarget) >= Wrange) or not Menu.Combo.UseW ) and Menu.Combo.UseQ then 
		CastQ(QTarget)
	end
end

function Harass()
	local QTarget = GetBestTarget(Qrange[2])
	if QTarget then
		CastQ(QTarget)
	end
end

function CountMinionsHit(QPos)
	local LineEnd = Vector(myHero) + Qrange[2] * (Vector(QPos) - Vector(myHero)):normalized()
	local n = 0
	for i, minion in pairs(EnemyMinions.objects) do
		local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(myHero), LineEnd, minion)	
		if isOnSegment and GetDistance(minion, pointSegment) <= QWidth*1.25 then
			n = n + 1
		end
	end
	return n
end

function GetMaxDistMinion()
	local max = -1
	for i, minion in ipairs(EnemyMinions.objects) do
		if GetDistance(minion) > max then
			max = GetDistance(minion)
		end
	end
	return max
end

function GetBestQPositionFarm()
	local MaxQPos 
	local MaxQ = 0
	for i, minion in pairs(EnemyMinions.objects) do
	local hitQ = CountMinionsHit(minion)
		if hitQ > MaxQ or MaxQPos == nil then
			MaxQPos = minion
			MaxQ = hitQ
		end
	end

	if MaxQPos then
		return MaxQPos
	else
		return nil
	end
end

function countminionshitW(pos)
	local n = 0
	for i, minion in ipairs(EnemyMinions.objects) do
		if GetDistance(minion, pos) < WWidth then
			n = n +1
		end
	end
	return n
end

function GetBestWPositionFarm()
	local MaxW = 0 
	local MaxWPos 
	for i, minion in pairs(EnemyMinions.objects) do
		local hitW = countminionshitW(minion)
		if hitW > MaxW or MaxWPos == nil then
			MaxWPos = minion
			MaxW = hitW
		end
	end

	if MaxWPos then
		local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(MaxWPos, WDelay, WWidth, WRange)
		return Position
	else
		return nil
	end
end

function FarmQ()
	if myHero:CanUseSpell(_Q) == READY and #EnemyMinions.objects > 0 then
	if (os.clock() - CastingQ > 5) and myHero:CanUseSpell(_Q) == READY then
			CastSpell(_Q, myHero.x, myHero.z)
		elseif (os.clock() - CastingQ < 3) and (GetMaxDistMinion() < CurrentQrange or (os.clock() - CastingQ > 1.5)) then 
			local QPos = GetBestQPositionFarm()
			if QPos then
				Cast2Q(QPos)
			end
		end
	end
end

function FarmW()
	if myHero:CanUseSpell(_W) == READY and #EnemyMinions.objects > 0 then
		local WPos = GetBestWPositionFarm()
		if WPos then
			CastSpell(_W, WPos.x, WPos.z)
		end
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe then
		if spell.name:lower() == "xeratharcanopulsechargeup" then
			CastingQ = os.clock()
		elseif spell.name:lower() == "xeratharcanopulse2" then
			CastingQ = 0
		elseif spell.name:lower() == "xerathlocusofpower2" then
			CastingR = os.clock()
			UsedR = 0
			LastRTarget = nil
			LastRTargetTime = 0
		elseif spell.name:lower() == "xerathlocuspulse" then
			UsedR = UsedR + 1
			RPressTime2 = 0
		end
	end
end

function Farm()
	EnemyMinions:update()
	if Menu.Farm.UseQ then
		FarmQ()
	end
	if Menu.Farm.UseW then
		FarmW()
	end
end

function JungleFarm()
	JungleMinions:update()
	if JungleMinions.objects[1] ~= nil then
		if Menu.JungleFarm.UseQ and GetDistance(JungleMinions.objects[1]) <= Qrange[1] and myHero:CanUseSpell(_Q) == READY then
			CastSpell(_Q, JungleMinions.objects[1].x, JungleMinions.objects[1].z)
			Cast2Q(JungleMinions.objects[1])
		end

		if Menu.JungleFarm.UseW and myHero:CanUseSpell(_W) == READY then
			CastSpell(_W, JungleMinions.objects[1].x, JungleMinions.objects[1].z)		
		end
	end
end

function Cast2Q(to)
	local p = CLoLPacket(229)
	p:EncodeF(myHero.networkID)
	p:Encode1(0x80)
	p:EncodeF(to.x)
	p:EncodeF(to.y)
	p:EncodeF(to.z)
	SendPacket(p)
end

function OnSendPacket(p)
	if p.header == 229 then
		if os.clock() - CastingQ <= 0.1 then --CHECKTHIS
			p:Block()
		end
	elseif p.header == Packet.headers.S_CAST then
		local packet = Packet(p)
		if packet:get("spellId") == _Q then
			if os.clock() - CastingQ <= 3 then 
				Cast2Q(mousePos)
				p:Block()
			end
		end
	elseif p.header == Packet.headers.S_MOVE then
		local packet = Packet(p)
		if packet:get("type") ~= 2 and os.clock() - CastingQ <= 3 and CastingQ ~= 0 then
			Packet('S_MOVE',{x = mousePos.x, y = mousePos.z}):send()
			p:Block()
		end
		
		if ImCastingR() and myHero:GetSpellData(_R).level > 0 then
			p:Block()
		end
	end
end

--[[Credits to barasia, vadash and viseversa for anti-lag circles]]
function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8,math.floor(180/math.deg((math.asin((chordlength/(2*radius)))))))
	quality = 2 * math.pi / quality
	radius = radius*.92
	local points = {}
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)
end

function DrawCircle2(x, y, z, radius, color)
	local vPos1 = Vector(x, y, z)
	local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
	local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
	local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 75)	
	end
end


--[[Update the bar texts]]
function RefreshKillableTexts()
	if ((os.clock() - lastrefresh) > 0.3) and Menu.Drawing.DrawDamage then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				DamageToHeros[i] =  GetComboDamage(MainCombo, enemy) 
			end
		end
		lastrefresh = os.clock()
	end
end
	
--[[	Credits to zikkah	]]
function GetHPBarPos(enemy)
	enemy.barData = GetEnemyBarData()
	local barPos = GetUnitHPBarPos(enemy)
	local barPosOffset = GetUnitHPBarOffset(enemy)
	local barOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local barPosPercentageOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local BarPosOffsetX = 171
	local BarPosOffsetY = 46
	local CorrectionY =  0
	local StartHpPos = 31
	barPos.x = barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + StartHpPos
	barPos.y = barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY 
						
	local StartPos = Vector(barPos.x , barPos.y, 0)
	local EndPos =  Vector(barPos.x + 108 , barPos.y , 0)

	return Vector(StartPos.x, StartPos.y, 0), Vector(EndPos.x, EndPos.y, 0)
end

function DrawIndicator(unit, health)
	local SPos, EPos = GetHPBarPos(unit)
	local barlenght = EPos.x - SPos.x
	local Position = SPos.x + (health / unit.maxHealth) * barlenght
	if Position < SPos.x then
		Position = SPos.x
	end
	DrawText("|", 13, Position, SPos.y+10, ARGB(255,0,255,0))
end

function DrawOnHPBar(unit, health)
	local Pos = GetHPBarPos(unit)
	if health < 0 then
		DrawCircle2(unit.x, unit.y, unit.z, 100, ARGB(255, 255, 0, 0))	
		DrawText("HP: "..health,13, Pos.x, Pos.y, ARGB(255,255,0,0))
	else
		DrawText("HP: "..health,13, Pos.x, Pos.y, ARGB(255,0,255,0))
	end
end

function OnDraw()
	if Menu.Drawing.AArange then
		DrawCircle2(myHero.x, myHero.y, myHero.z, SOWi:MyRange() + 50, ARGB(255, 0, 255, 0))
	end
	if Menu.Drawing.Qrange then
		DrawCircle2(myHero.x, myHero.y, myHero.z, CurrentQrange, ARGB(255, 0, 255, 0))
	end

	if Menu.Drawing.Wrange then
		DrawCircle2(myHero.x, myHero.y, myHero.z, Wrange, ARGB(255,0,255,0))
	end
	
	if Menu.Drawing.Erange then
		DrawCircle2(myHero.x, myHero.y, myHero.z, Erange, ARGB(255, 0, 255, 0))
	end
	
	if Menu.Drawing.Rrange and myHero:GetSpellData(_R).level > 0 then
		DrawCircle2(myHero.x, myHero.y, myHero.z, Rrange[myHero:GetSpellData(_R).level], ARGB(255,0,255,0))
	end
	
	if Menu.Drawing.RrangeM and myHero:GetSpellData(_R).level > 0 then
		DrawCircleMinimap(myHero.x,myHero.y,myHero.z, Rrange[myHero:GetSpellData(_R).level])
	end
	
	if myHero:GetSpellData(_R).level > 0 and Menu.RSnipe.Alert then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, Rrange[myHero:GetSpellData(_R).level]) and GetDamage(_R, enemy) >= enemy.health then
				local pos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
				DrawText("Snipe!", 17, pos.x, pos.y, ARGB(255,0,255,0))
			end
		end
	end 

	--[[HealthBar HP tracker]]
	if Menu.Drawing.DrawDamage then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				if DamageToHeros[i] ~= nil then
					RemainingHealth = enemy.health - DamageToHeros[i]
				end
				if RemainingHealth ~= nil then
					DrawIndicator(enemy, math.floor(RemainingHealth))
					DrawOnHPBar(enemy, math.floor(RemainingHealth))
				end
			end
		end
	end

	if Menu.Misc.Selected and SelectedTarget ~= nil and ValidTarget(SelectedTarget) then
		DrawCircle2(SelectedTarget.x, SelectedTarget.y, SelectedTarget.z, 103, ARGB(255,0,255,0))
	end

end

function OnWndMsg(Msg, Key)
	if Msg == WM_LBUTTONDOWN then
		local minD = 0
		local starget = nil
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				if GetDistance(enemy, mousePos) <= minD or starget == nil then
					minD = GetDistance(enemy, mousePos)
					starget = enemy
				end
			end
		end
		
		if starget and minD < 100 then
			if SelectedTarget and starget.charName == SelectedTarget.charName then
				SelectedTarget = nil
			else
				SelectedTarget = starget
				print("<font color=\"#FF0000\">Xerath: New target selected: "..starget.charName.."</font>")
			end
		end
	end
	if Msg == 256 and Key == Menu.RSnipe._param[TapMenu].key then
		RPressTime2 = os.clock()
	end
end
