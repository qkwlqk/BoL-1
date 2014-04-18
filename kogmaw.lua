--[[
ProKogMaw
]]
if myHero.charName ~= "KogMaw" then return end
require "Prodiction"
local version = "1.1"

--[[Spells data]]
local Qrange = 625
local Wrange = {0, 130, 150, 170, 190, 210}
local Erange = 1200
local Rrange = {0, 1200, 1550, 1750}

local Eradius = 50
local Rradius = 90

local Edelay = 300
local Rdelay = 800

local Qready = false
local Wready = false
local Eready = false
local Rready = false
local Rstacks = 0

local Qtarget = nil
local Wtarget = nil
local Etarget = nil
local Rtarget = nil

local ProdictionManager = nil
local EProdiction = nil
local RProdiction = nil

function OnLoad()
	Menu = scriptConfig("ProKogMaw", "ProKogMaw")
	Menu:addSubMenu("Combo", "Combo")
	Menu.Combo:addParam("UseQ", "Use Q in combo", SCRIPT_PARAM_ONOFF , true)
	Menu.Combo:addParam("UseW", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.Combo:addParam("UseE", "Use E in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.Combo:addParam("UseR", "Use R in combo", SCRIPT_PARAM_ONOFF, true)
	Menu.Combo:addParam("MoveTo", "Move to mouse while comboing", SCRIPT_PARAM_ONOFF, false)
	Menu.Combo:addParam("MaxR", "Max R stacks", SCRIPT_PARAM_SLICE, 4, 1, 10, 0)
	Menu.Combo:addParam("Enabled", "Use Combo!", SCRIPT_PARAM_ONKEYDOWN, false,   32)
	
	Menu:addSubMenu("Harass", "Harass")
	Menu.Harass:addParam("UseQ", "Harass using Q", SCRIPT_PARAM_ONOFF, false)
	Menu.Harass:addParam("UseW", "Harass using W", SCRIPT_PARAM_ONOFF, false)
	Menu.Harass:addParam("UseE", "Harass using E", SCRIPT_PARAM_ONOFF, false)
	Menu.Harass:addParam("UseR", "Harass using R", SCRIPT_PARAM_ONOFF, false)
	Menu.Harass:addParam("MoveTo", "Move to mouse while harassing", SCRIPT_PARAM_ONOFF, false)
	Menu.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
	Menu.Harass:addParam("MaxR", "Max R stacks", SCRIPT_PARAM_SLICE, 4, 1, 10, 0)
	
	Menu:addSubMenu("Drawing", "Drawing")
	Menu.Drawing:addSubMenu("Ranges", "Ranges")
	Menu.Drawing.Ranges:addParam("Qrange", "Draw Q range", SCRIPT_PARAM_ONOFF, false)
	Menu.Drawing.Ranges:addParam("Erange", "Draw E range", SCRIPT_PARAM_ONOFF, true)
	Menu.Drawing.Ranges:addParam("Rrange", "Draw R range", SCRIPT_PARAM_ONOFF, false)
	Menu.Drawing.Ranges:addParam("Qcolor", "Q range color", SCRIPT_PARAM_COLOR, {255, 0, 255, 0})
	Menu.Drawing.Ranges:addParam("Ecolor", "E range color", SCRIPT_PARAM_COLOR, {255, 0, 255, 0})
	Menu.Drawing.Ranges:addParam("Rcolor", "R range color", SCRIPT_PARAM_COLOR, {255, 0, 255, 0})
	
	Menu:addParam("Version", "Version", SCRIPT_PARAM_INFO, version)
	ProdictionManager = ProdictManager.GetInstance()
	EProdiction = ProdictionManager:AddProdictionObject(_E, math.huge, math.huge, Edelay/1000, Eradius)
    	RProdiction = ProdictionManager:AddProdictionObject(_R, math.huge, math.huge, Rdelay/1000, Rradius-10)
	PrintChat("<font color=\"#81BEF7\">ProKogMaw ("..version..") loaded successfully</font>")
end

function GetBestTarget(Range)
	local LessToKill = 100
	local LessToKilli = 0
	local target = nil
	
	--	LESS_CAST	
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, Range) then
			DamageToHero = myHero:CalcMagicDamage(enemy, 200)
			ToKill = enemy.health / DamageToHero
			if (ToKill < LessToKill)  or (LessToKilli == 0) then
				LessToKill = ToKill
				LessToKilli = i
				target = enemy
			end
		end
	end
	return target
end

function UseSpells(Array)
	for i, spell in ipairs(Array) do
		if spell == _Q and Qready then
			if Qtarget then Packet("S_CAST", {spellId = _Q, targetNetworkId = Qtarget.networkID}):send() end
		elseif spell == _W and Wready then
			if Wtarget then CastSpell(_W) end
		elseif spell == _E then
			if Etarget then EProdiction:GetPredictionCallBack(Etarget, UseE) end
		elseif spell == _R then
			if Rtarget then RProdiction:GetPredictionCallBack(Rtarget, UseR) end
		end
	end
end

function UseE(unit, pos, spell)
	if not pos then return end
	if not Eready then return end
	local predictedpos = Vector(pos.x, 0, pos.z)
	local mypos = Vector(myHero.x, 0, myHero.z)
	if GetDistance(pos) < Erange then
		CastSpell(_E, pos.x, pos.z)
	end
end

function UseR(unit, pos, spell)
	if not pos then return end
	if not Rready then return end
	local predictedpos = Vector(pos.x, 0, pos.z)-Rradius*3/4*Vector(unit.x - pos.x, 0, unit.z - pos.z):normalized() 
	local mypos = Vector(myHero.x, 0, myHero.z) 
	if GetDistance(predictedpos) <= (Rrange[myHero:GetSpellData(_R).level +1 ] + Rradius/2) then
		if (Menu.Combo.Enabled and (Menu.Combo.MaxR > Rstacks)) or (Menu.Harass.Enabled and (Menu.Harass.MaxR > Rstacks)) then
			CastSpell(_R, pos.x, pos.z)
		end
	end
end

function OnTick()
	Qready = (myHero:CanUseSpell(_Q) == READY)
	Wready = (myHero:CanUseSpell(_W) == READY)
	Eready = (myHero:CanUseSpell(_E) == READY)
	Rready = (myHero:CanUseSpell(_R) == READY)
	Qtarget = GetBestTarget(Qrange)
	Wtarget = GetBestTarget(myHero.range + Wrange[myHero:GetSpellData(_W).level + 1])
	Etarget = GetBestTarget(Erange)
	Rtarget = GetBestTarget(Rrange[myHero:GetSpellData(_R).level +1 ] + Rradius/2)
	Array = {}
		if (Menu.Combo.UseQ and Menu.Combo.Enabled) or (Menu.Harass.Enabled and Menu.Harass.UseQ) then
			table.insert(Array, _Q)
		end
		if (Menu.Combo.UseW and Menu.Combo.Enabled) or (Menu.Harass.Enabled and Menu.Harass.UseW) then
			table.insert(Array, _W)
		end
		if (Menu.Combo.UseE and Menu.Combo.Enabled) or (Menu.Harass.Enabled and Menu.Harass.UseE) then
			table.insert(Array, _E)
		end
		if (Menu.Combo.UseR  and Menu.Combo.Enabled) or (Menu.Harass.Enabled and Menu.Harass.UseR) then
			table.insert(Array, _R)
		end
	UseSpells(Array)
end

function OnDraw()
	if Menu.Drawing.Ranges.Qrange then
		DrawCircle(myHero.x, myHero.y, myHero.z, Qrange, ARGB(Menu.Drawing.Ranges.Qcolor[1], Menu.Drawing.Ranges.Qcolor[2], Menu.Drawing.Ranges.Qcolor[3], Menu.Drawing.Ranges.Qcolor[4] ))
	end
	if Menu.Drawing.Ranges.Erange then
		DrawCircle(myHero.x, myHero.y, myHero.z, Erange, ARGB(Menu.Drawing.Ranges.Ecolor[1], Menu.Drawing.Ranges.Ecolor[2], Menu.Drawing.Ranges.Ecolor[3], Menu.Drawing.Ranges.Ecolor[4] ))
	end
	if Menu.Drawing.Ranges.Rrange then
		DrawCircle(myHero.x, myHero.y, myHero.z, Rrange[myHero:GetSpellData(_R).level +1 ], ARGB(Menu.Drawing.Ranges.Rcolor[1], Menu.Drawing.Ranges.Rcolor[2], Menu.Drawing.Ranges.Rcolor[3], Menu.Drawing.Ranges.Rcolor[4] ))
	end
end

function OnGainBuff(unit, buff)
	if unit.isMe then
		if buff.name == "kogmawlivingartillerycost" then
			Rstacks = Rstacks +1
		end
	end
end

function OnLoseBuff(unit, buff)
	if unit.isMe then
		if buff.name == "kogmawlivingartillerycost" then
			Rstacks = 0
		end
	end
end
--EOS--
