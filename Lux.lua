if myHero.charName ~= "Lux" then return end

	require "VPrediction"
	require "SOW"
	require "SourceLib"


local ablazebuffname = "brandablaze"

local MainCombo = {_DFG, _AA, _Q, _E, _R, _PASIVE, _IGNITE}

--Spell data
local Ranges = {[_Q] = 1300, [_W] = 1175, [_E] = 1100, [_R] = 3500}
local Delays = {[_Q] = 0.25, [_W] = 0.25, [_E] = 0.25, [_R] = 1.35}
local Widths = {[_Q] = 70, [_W] = 110, [_E] = 275, [_R] = 190}
local Speeds = {[_Q] = 1200, [_W] = 1400, [_E] = 1300, [_R] = math.huge}


local LastQTime = 0
function OnLoad()

	VP = VPrediction()
	SOWi = SOW(VP)
	STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
	DLib = DamageLib()
	DManager = DrawManager()
	

	Q = Spell(_Q, Ranges[_Q])
	W = Spell(_W, Ranges[_W])
	E = Spell(_E, Ranges[_E])
	R = Spell(_R, Ranges[_R])

	Q:SetSkillshot(VP, SKILLSHOT_LINEAR, Widths[_Q], Delays[_Q], Speeds[_Q], true)
	E:SetSkillshot(VP, SKILLSHOT_CIRCULAR, Widths[_W], Delays[_W], Speeds[_E], false)
	E:SetAOE(true, W.width, 0)
	R:SetSkillshot(VP, SKILLSHOT_LINEAR, Widths[_R], Delays[_R], Speeds[_R], false)
	R:SetAOE(true, W.width, 0)

	DLib:RegisterDamageSource(_Q, _MAGIC, 10, 50, _MAGIC, _AP, 0.7, function() return (player:CanUseSpell(_Q) == READY) end)
	DLib:RegisterDamageSource(_E, _MAGIC, 15, 45, _MAGIC, _AP, 0.6, function() return (player:CanUseSpell(_E) == READY) end)
	DLib:RegisterDamageSource(_R, _MAGIC, 200, 100, _MAGIC, _AP, 0.75, function() return (player:CanUseSpell(_R) == READY) end)
	DLib:RegisterDamageSource(_PASIVE, _MAGIC, 0, 0, _MAGIC, _AP, 0, nil, function(target) return 10 + 10 * player.level end)

	Menu = scriptConfig("Lux", "Lux")

	Menu:addSubMenu("Orbwalking", "Orbwalking")
		SOWi:LoadToMenu(Menu.Orbwalking)

	Menu:addSubMenu("Target selector", "STS")
		STS:AddToMenu(Menu.STS)

	Menu:addSubMenu("Combo", "Combo")
		Menu.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseR", "Use R (Killable)", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("Enabled", "Use Combo!", SCRIPT_PARAM_ONKEYDOWN, false, 32)

	Menu:addSubMenu("Harass", "Harass")
		Menu.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))

	Menu:addSubMenu("Farm", "Farm")
		Menu.Farm:addParam("UseE",  "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Farm:addParam("ManaCheck", "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Farm:addParam("Enabled", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("JungleFarm", "JungleFarm")
		Menu.JungleFarm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_ONOFF, false)
		Menu.JungleFarm:addParam("UseE",  "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("Enabled", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("Ultimate", "R")
		Menu.R:addParam("AutoR", "Auto R if it will hit: ", SCRIPT_PARAM_LIST, 1, { "No", ">0 targets", ">1 targets", ">2 targets", ">3 targets", ">4 targets" })

	Menu:addSubMenu("Misc", "Misc")
		Menu.Misc:addParam("AutoQ", "Auto Q on gapclosing targets", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addParam("AutoQ2", "Auto Q on stunned targets", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addParam("AutoE", "Auto E on stunned targets", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addParam("AutoR", "Auto R on stunned killable targets", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addParam("Laught", "Spam laught after killing the target", SCRIPT_PARAM_ONOFF, true)

	Menu:addSubMenu("Drawings", "Drawings")
	--[[Spell ranges]]
	for spell, range in pairs(Ranges) do
		DManager:CreateCircle(myHero, range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, SpellToString(spell).." Range", true, true, true)
	end
	--[[Predicted damage on healthbars]]
	DLib:AddToMenu(Menu.Drawings, MainCombo)

	EnemyMinions = minionManager(MINION_ENEMY, Ranges[_Q], myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, Ranges[_Q], myHero, MINION_SORT_MAXHEALTH_DEC)

end

function IsIlluminated(target)
	return HasBuff(target, "luxilluminatingfraulein")
end

function OnCreateObj(obj)
	if obj.name == "LuxLightstrike_tar_green.troy" then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) and GetDistanceSqr(obj, enemy) <= (Widths[_E] + VP:GetHitBox(enemy))^2 then
				CastSpell(_E)
			end
		end
	end
end

function Combo()
	local Qtarget = STS:GetTarget(Ranges[_Q])
	local Etarget = STS:GetTarget(Ranges[_E])
	local Rtarget = STS:GetTarget(Ranges[_R])
	local status
	SOWi:DisableAttacks()

	if Qtarget and Q:IsReady() and Menu.Combo.UseQ then
		status = Q:Cast(Qtarget)
	end

	if Etarget and E:IsReady() and Menu.Combo.UseE then
		E:Cast(Etarget)
	end

	if Qtarget and ((not Q:IsReady() and not E:IsReady() and not R:IsReady()) or IsIlluminated(Qtarget)) then
		SOWi:EnableAttacks()
	end

	if R:IsReady() and Menu.Combo.UseR then
		if Rtarget and DLib:IsKillable(Rtarget, {_R})  then
			R:Cast(Rtarget)
		end
	end
end

function Harass()
	if Menu.Harass.ManaCheck > (myHero.mana / myHero.maxMana) * 100 then return end
	local Qtarget = STS:GetTarget(Ranges[_Q])
	local Etarget = STS:GetTarget(Ranges[_E])

	if Qtarget and Q:IsReady() and Menu.Harass.UseQ then
		Q:Cast(Qtarget)
	end

	if Etarget and E:IsReady() and Menu.Harass.UseE then
		E:Cast(Etarget)
	end
end

function Farm()

	if Menu.Farm.ManaCheck > (myHero.mana / myHero.maxMana) * 100 then return end
	EnemyMinions:update()
	local UseE = Menu.Farm.UseE

	local minion = EnemyMinions.objects[1]
	if minion then
		if UseE then
			local CasterMinions = SelectUnits(EnemyMinions.objects, function(t) return (t.charName:lower():find("wizard") or t.charName:lower():find("caster")) and ValidTarget(t) end)
			CasterMinions = GetPredictedPositionsTable(VP, CasterMinions, Delays[_E], Widths[_E], Ranges[_E], math.huge, myHero, false)

			local BestPos, BestHit = GetBestCircularFarmPosition(Ranges[_E], Widths[_E], CasterMinions)
			if BestHit > 2 then
				CastSpell(_E, BestPos.x, BestPos.z)
				do return end
			end

			local AllMinions = SelectUnits(EnemyMinions.objects, function(t) return ValidTarget(t) end)
			AllMinions = GetPredictedPositionsTable(VP, AllMinions, Delays[_E], Widths[_E], Ranges[_E], math.huge, myHero, false)

			local BestPos, BestHit = GetBestCircularFarmPosition(Ranges[_E], Widths[_E], AllMinions)
			if BestHit > 2 then
				CastSpell(_E, BestPos.x, BestPos.z)
				do return end
			end
		end
	end
end

function JungleFarm()
	JungleMinions:update()

	local UseQ = Menu.Farm.UseQ
	local UseE = Menu.Farm.UseE
	local minion = JungleMinions.objects[1]
	if minion then
		if UseQ then
			Q:Cast(minion)
		end
		if UseE then
			local BestPos, BestHit = GetBestCircularFarmPosition(Ranges[_E], Widths[_E], JungleMinions.objects)
			if BestPos then
				CastSpell(_E, BestPos.x, BestPos.z)
			end
		end
		CastSpell(_W, myHero.x, myHero.z)
	end
end

function OnTick()
	SOWi:EnableAttacks()
	if Menu.Combo.Enabled then
		Combo()
	elseif Menu.Harass.Enabled then
		Harass()
	end

	if Menu.Farm.Enabled then
		Farm()
	end

	if Menu.JungleFarm.Enabled then
		JungleFarm()
	end

	--[[Misc options]]
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) and GetDistanceSqr(enemy) <= (Ranges[_Q]*Ranges[_Q]) then

			if Menu.Misc.AutoQ2 then
				Q:CastIfImmobile(enemy)
			end
			if Menu.Misc.AutoQ then
				Q:CastIfDashing(enemy)
				if GetDistanceSqr(enemy) < 200*200 then
					Q:Cast(enemy)
				end
			end
		end

		if Menu.Misc.AutoE then
			E:CastIfImmobile(enemy)
		end

		if Menu.Misc.AutoR and GetDistanceSqr(enemy) <= (Ranges[_R])^2 and (IsIlluminated(enemy) and DLib:IsKillable(enemy, {_R, _PASIVE}) or DLib:IsKillable(enemy, {_R})) then
			R:CastIfImmobile(enemy)
		end
	end
end

--[[
function send71()
	local p = CLoLPacket(71)
	p.pos = 1
	p:EncodeF(myHero.networkID)
	p:Encode1(2)
	p:Encode1(0)
	SendPacket(p)
end

function OnSendPacket(p)
	if p.header == Packet.headers.S_MOVE and (last == nil or os.clock() - last > 1) then
		last = os.clock()
		send71()
	end
end

function OnRecvPacket(p)
	if p.header == 65 then
		p.pos = 1
		if p:DecodeF() == myHero.networkID then
		--	p:Replace1(255,5)
		end
	end
end
]]