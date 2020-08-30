
-- Shared library

local ss = SplatoonSWEPs
if not ss then return end

function ss.hook(func)
	if isstring(func) then
		return function(ply, ...)
			local w = ss.IsValidInkling(ply or CLIENT and LocalPlayer() or nil)
			if w then return ss[func](w, ply, ...) end
		end
	else
		return function(ply, ...)
			local w = ss.IsValidInkling(ply or CLIENT and LocalPlayer() or nil)
			if w then return func(w, ply, ...) end
		end
	end
end

-- Faster table.remove() function from stack overflow
-- https://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating
function ss.tableremovefunc(t, toremove)
    local k = 1
    for i = 1, #t do
        if toremove(t[i]) then
			t[i] = nil
		else -- Move i's kept value to k's position, if it's not already there.
            if i ~= k then t[k], t[i] = t[i] end
            k = k + 1 -- Increment position of where we'll place the next kept value.
        end
    end

    return t
end

function ss.tableremove(t, removal)
    local k = 1
    for i = 1, #t do
        if i == removal then
            t[i] = nil
        else -- Move i's kept value to k's position, if it's not already there.
            if i ~= k then t[k], t[i] = t[i] end
            k = k + 1 -- Increment position of where we'll place the next kept value.
        end
    end

    return t
end

-- Even faster than table.remove() and this removes the first element.
function ss.tablepop(t)
	local zero, one = t[0], t[1]
    for i = 1, #t do
        t[i - 1], t[i] = t[i]
    end

	t[0] = zero
    return one
end

-- Faster than table.insert() and this inserts an element at the beginning.
function ss.tablepush(t, v)
    local n = #t
    for i = n, 1, -1 do
        t[i + 1], t[i] = t[i]
    end

	t[1] = v
end

-- Each surface should have these fields.
function ss.CreateSurfaceStructure()
	return CLIENT and {} or {
		Angles = {},
		Areas = {},
		Bounds = {},
		DefaultAngles = {},
		Indices = {},
		InkCircles = {},
		Maxs = {},
		Mins = {},
		Normals = {},
		Origins = {},
		Vertices = {},
	}
end

-- There is an annoying limitation on util.JSONToTable(),
-- which is that the amount of a table is up to 15000.
-- Therefore, GMOD can't save/restore a table if #source > 15000.
-- This function sanitises a table with a large amount of data.
-- Argument:
--   table source | A table containing a large amount of data.
-- Returning:
--   table        | A nested table.  Each element has up to 15000 data.
function ss.AvoidJSONLimit(source)
	local s = {}
	for chunk = 1, math.ceil(#source / 15000) do
		local t = {}
		for i = 1, 15000 do
			local index = (chunk - 1) * 15000 + i
			if index > #source then break end
			t[#t + 1] = source[index]
		end

		s[chunk] = t
	end

	return s
end

-- Restores a table saved with ss.AvoidJSONLimit().
-- Argument:
--   table source | A nested table made by ss.AvoidJSONLimit().
-- Returning:
--   table        | A sequential table.
function ss.RestoreJSONLimit(source)
	local s = {}
	for _, chunk in ipairs(source) do
		for _, v in ipairs(chunk) do s[#s + 1] = v end
	end

	return s
end

-- Finds AABB-tree nodes/leaves which includes the given AABB.
-- Use as an iterator function:
--   for nodes in SplatoonSWEPs:SearchAABB(AABB) do ... end
-- Arguments:
--   table AABB | {mins = Vector(), maxs = Vector()}
-- Returns:
--   table      | A sequential table.
function ss.SearchAABB(AABB, normal)
	local function recursive(a)
		local t = {}
		if a.SurfIndices then
			for _, i in ipairs(a.SurfIndices) do
				local a = ss.SurfaceArray[i]
				local max_diff = a.Displacement and ss.MAX_COS_DIFF_DISP or ss.MAX_COS_DIFF
				if a.Normal:Dot(normal) > max_diff then
					if ss.CollisionAABB(a.AABB.mins, a.AABB.maxs, AABB.mins, AABB.maxs) then
						t[#t + 1] = a
					end
				end
			end
		else
			local l = ss.AABBTree[a.Children[1]]
			local r = ss.AABBTree[a.Children[2]]
			if l and ss.CollisionAABB(l.AABB.mins, l.AABB.maxs, AABB.mins, AABB.maxs) then
				table.Add(t, recursive(l))
			end

			if r and ss.CollisionAABB(r.AABB.mins, r.AABB.maxs, AABB.mins, AABB.maxs) then
				table.Add(t, recursive(r))
			end
		end

		return t
	end

	return ipairs(recursive(ss.AABBTree[1]))
end

-- Compares each component and returns the smaller one.
-- Arguments:
--   Vector a, b	| Two vectors to compare.
-- Returning:
--   Vector			| A vector which contains the smaller components.
function ss.MinVector(a, b)
	return Vector(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z))
end

-- Compares each component and returns the larger one.
-- Arguments:
--   Vector a, b	| Two vectors to compare.
-- Returning:
--   Vector			| A vector which contains the larger components.
function ss.MaxVector(a, b)
	return Vector(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z))
end

-- Takes two AABBs and returns if they are colliding each other.
-- Arguments:
--   Vector mins1, maxs1	| The first AABB.
--   Vector mins2, maxs2	| The second AABB.
-- Returning:
--   bool					| Whether or not the two AABBs intersect each other.
function ss.CollisionAABB(mins1, maxs1, mins2, maxs2)
	return mins1.x < maxs2.x and maxs1.x > mins2.x and
			mins1.y < maxs2.y and maxs1.y > mins2.y and
			mins1.z < maxs2.z and maxs1.z > mins2.z
end

-- Basically same as SplatoonSWEPs:CollisionAABB(), but ignores Z-component.
-- Arguments:
--   Vector mins1, maxs1	| The first AABB.
--   Vector mins2, maxs2	| The second AABB.
-- Returning:
--   bool					| Whether or not the two AABBs intersect each other.
function ss.CollisionAABB2D(mins1, maxs1, mins2, maxs2)
	return mins1.x < maxs2.x and maxs1.x > mins2.x and
			mins1.y < maxs2.y and maxs1.y > mins2.y
end

-- Short for WorldToLocal()
-- Arguments:
--   Vector source	| A 3D vector to be converted into 2D space.
--   Vector orgpos	| The origin of new 2D system.
--   Angle organg	| The angle of new 2D system.
-- Returning:
--   Vector			| A converted 2D vector.
function ss.To2D(source, orgpos, organg)
	local localpos = WorldToLocal(source, angle_zero, orgpos, organg)
	return Vector(localpos.y, localpos.z, 0)
end

-- Short for LocalToWorld()
-- Arguments:
--   Vector source	| A 2D vector to be converted into 3D space.
--   Vector orgpos	| The origin of 2D system in world coordinates.
--   Angle organg	| The angle of 2D system relative to the world.
-- Returning:
--   Vector			| A converted 3D vector.
function ss.To3D(source, orgpos, organg)
	local localpos = Vector(0, source.x, source.y)
	return (LocalToWorld(localpos, angle_zero, orgpos, organg))
end

-- util.IsInWorld() only exists in serverside.
-- This is shared version of it.
-- Argument:
--   Vector pos		| A vector to test.
-- Returning:
--   bool			| The given vector is in world or not.
function ss.IsInWorld(pos)
	return math.abs(pos.x) < 16384 and math.abs(pos.y) < 16384 and math.abs(pos.z) < 16384
end

-- For Charger's interpolation.
-- Arguments:
--   number frac	| Fraction.
--   number min 	| Minimum value.
--   number max 	| Maximum value.
--   number full	| An optional value returned when frac == 1.
-- Returning:
--   number			| Interpolated value.
function ss.Lerp3(frac, min, max, full)
	return frac < 1 and Lerp(frac, min, max) or full or max
end

-- Short for checking isfunction()
-- Arguments:
--   function func	| The function to call safely.
--   vararg			| The arguments to give the function.
-- Returns:
--   vararg			| Returning values from the function.
function ss.ProtectedCall(func, ...)
	if isfunction(func) then return func(...) end
end

-- Checks if the given entity is a valid inkling (if it has a SplatoonSWEPs weapon).
-- Argument:
--   Entity ply		| The entity to be checked.  It is not always player.
-- Returning:
--   Entity			| The weapon the entity has.
--   nil			| The entity is not an inkling.
function ss.IsValidInkling(ply)
	if not IsValid(ply) then return end
	local w = ss.ProtectedCall(ply.GetActiveWeapon, ply)
	return IsValid(w) and w.IsSplatoonWeapon and not w:GetHolstering() and w or nil
end

-- Checks if the given two colors are the same, considering FF setting.
-- Arguments:
--   number c1, c2 | The colors to be compared.  Can also be Splatoon weapons.
-- Returning:
--   bool          | The colors are the same.
function ss.IsAlly(c1, c2)
	if isentity(c1) and IsValid(c1) and isentity(c2) and IsValid(c2) and c1 == c2 then
		return not ss.GetOption "weapon_splatoonsweps_blaster_base" "hurtowner"
	end

	c1 = isentity(c1) and IsValid(c1) and c1:GetNWInt "inkcolor" or c1
	c2 = isentity(c2) and IsValid(c2) and c2:GetNWInt "inkcolor" or c2
	return not ss.GetOption "ff" and c1 == c2
end

-- Get player timescale.
-- Argument:
--   Entity ply    | Optional.
-- Returning:
--   number scale  | The game timescale.
local host_timescale = GetConVar "host_timescale"
function ss.GetTimeScale(ply)
	return IsValid(ply) and ply:IsPlayer() and ply:GetLaggedMovementValue() or 1
end

-- Play a sound that can be heard only one player.
-- Arguments:
--   Player ply			| The player who can hear it.
--   string soundName	| The sound to play.
function ss.EmitSound(ply, soundName, soundLevel, pitchPercent, volume, channel)
	if not (IsValid(ply) and ply:IsPlayer()) then return end
	if SERVER and ss.mp then
		net.Start "SplatoonSWEPs: Send a sound"
		net.WriteString(soundName)
		net.WriteUInt(soundLevel or 75, 9)
		net.WriteUInt(pitchPercent or 100, 8)
		net.WriteFloat(volume or 1)
		net.WriteUInt((channel or CHAN_AUTO) + 1, 8)
		net.Send(ply)
	elseif CLIENT and IsFirstTimePredicted() or ss.sp then
		ply:EmitSound(soundName, soundLevel, pitchPercent, volume, channel)
	end
end

-- Play a sound properly in a weapon predicted hook.
-- Arguments:
--   Player ply | The owner of the weapon.
--   Entity ent | The weapon.
--   vararg     | The arguments of Entity:EmitSound()
function ss.EmitSoundPredicted(ply, ent, ...)
	ss.SuppressHostEventsMP(ply)
	ent:EmitSound(...)
	ss.EndSuppressHostEventsMP(ply)
end

function ss.SuppressHostEventsMP(ply)
	if ss.sp or CLIENT then return end
	if IsValid(ply) and ply:IsPlayer() then
		SuppressHostEvents(ply)
	end
end

function ss.EndSuppressHostEventsMP(ply)
	if ss.sp or CLIENT then return end
	if IsValid(ply) and ply:IsPlayer() then
		SuppressHostEvents(NULL)
	end
end

-- Modify the source table with given units
-- Arguments:
--   table source | The parameter table = {[string ParameterName] = [number Value]}
--   table units  | The table which describes what units each parameter should have {[string ParameterName] = [string Unit]}
function ss.ConvertUnits(source, units)
	for name, value in pairs(source) do
		if isnumber(value) then
			local unit = units[name]
			local converter = unit and ss.UnitsConverter[unit] or 1
			source[name] = value * converter
		end
	end
end

-- The function names of EffectData() don't make sense, renaming.
do local e = EffectData()
	ss.GetEffectSplash = e.GetAngles -- Angle(SplashColRadius, SplashDrawRadius, SplashLength)
	ss.SetEffectSplash = e.SetAngles
	ss.GetEffectColor = e.GetColor
	ss.SetEffectColor = e.SetColor
	ss.GetEffectColRadius = e.GetRadius
	ss.SetEffectColRadius = e.SetRadius
	ss.GetEffectDrawRadius = e.GetMagnitude
	ss.SetEffectDrawRadius = e.SetMagnitude
	ss.GetEffectEntity = e.GetEntity
	ss.SetEffectEntity = e.SetEntity
	ss.GetEffectInitPos = e.GetOrigin
	ss.SetEffectInitPos = e.SetOrigin
	ss.GetEffectInitVel = e.GetStart
	ss.SetEffectInitVel = e.SetStart
	ss.GetEffectSplashInitRate = e.GetNormal
	ss.SetEffectSplashInitRate = e.SetNormal
	ss.GetEffectSplashNum = e.GetSurfaceProp
	ss.SetEffectSplashNum = e.SetSurfaceProp
	ss.GetEffectStraightFrame = e.GetScale
	ss.SetEffectStraightFrame = e.SetScale
	ss.GetEffectFlags = e.GetFlags
	function ss.SetEffectFlags(eff, weapon, flags)
		if isnumber(weapon) and not flags then
			flags, weapon = weapon
		end

		flags = flags or 0
		if IsValid(weapon) then
			local IsLP = CLIENT and weapon:IsCarriedByLocalPlayer()
			flags = flags + (IsLP and 128 or 0)
		end

		eff:SetFlags(flags)
	end

	-- Dispatch an effect properly in a weapon predicted hook.
	-- Arguments:
	--   Player ply        | The owner of the weapon
	--   vararg            | Arguments of util.Effect()
	function ss.UtilEffectPredicted(ply, ...)
		ss.SuppressHostEventsMP(ply)
		util.Effect(...)
		ss.EndSuppressHostEventsMP(ply)
	end
end

include "debug.lua"
include "text.lua"
include "convars.lua"
include "inkballistic.lua"
include "inkpainting.lua"
include "movement.lua"
include "sound.lua"
include "weapons.lua"
include "weaponregistration.lua"

local path = "splatoonsweps/sub/%s"
for i, filename in ipairs(file.Find("splatoonsweps/sub/*.lua", "LUA")) do
	path = path:format(filename)
	if SERVER then AddCSLuaFile(path) end
	include(path)
end

local CrouchMask = bit.bnot(IN_DUCK)
local WALLCLIMB_KEYS = bit.bor(IN_JUMP, IN_FORWARD, IN_BACK)
function ss.PredictedThinkMoveHook(w, ply, mv)
	ss.ProtectedCall(w.Move, w, ply, mv)

	local crouching = ply:Crouching()
	if w:CheckCanStandup() and w:GetKey() ~= 0 and w:GetKey() ~= IN_DUCK
	or CurTime() > w:GetEnemyInkTouchTime() + ss.EnemyInkCrouchEndurance and ply:KeyDown(IN_DUCK)
	or CurTime() < w:GetCooldown() then
		mv:SetButtons(bit.band(mv:GetButtons(), CrouchMask))
		crouching = false
	end

	local maxspeed = math.min(mv:GetMaxSpeed(), w.InklingSpeed * 1.1)
	if ply:OnGround() then -- Max speed clip
		maxspeed = ss.ProtectedCall(w.CustomMoveSpeed, w) or w.InklingSpeed
		maxspeed = maxspeed * Either(crouching, ss.SquidSpeedOutofInk, 1)
		maxspeed = w:GetInInk() and w.SquidSpeed or maxspeed
		maxspeed = w:GetOnEnemyInk() and w.OnEnemyInkSpeed or maxspeed
		maxspeed = maxspeed * (w.IsDisruptored and ss.DisruptoredSpeed or 1)
		ply:SetWalkSpeed(maxspeed)
		if w:GetNWBool "allowsprint" and not (crouching or w:GetInInk() or w:GetOnEnemyInk()) then
			maxspeed = Lerp(0.5, maxspeed, w.SquidSpeed) -- Sprint speed
		end
		
		mv:SetMaxSpeed(maxspeed)
		ply:SetRunSpeed(maxspeed)
	end

	if ss.PlayerShouldResetCamera[ply] then
		local a = ply:GetAimVector():Angle()
		a.p = math.NormalizeAngle(a.p) / 2
		ply:SetEyeAngles(a)
		ss.PlayerShouldResetCamera[ply] = math.abs(a.p) > 1
	end

	ply:SetJumpPower(w:GetOnEnemyInk() and w.OnEnemyInkJumpPower or w.JumpPower)
	if CLIENT then w:UpdateInkState() end -- Ink state prediction

	for v, i in pairs {
		[mv:GetVelocity()] = true, -- Current velocity
		[ss.MoveEmulation.m_vecVelocity[ply] or false] = false,
	} do
		if v then
			local speed, vz = v:Length2D(), v.z -- Horizontal speed, Z component
			if w:GetInWallInk() and mv:KeyDown(WALLCLIMB_KEYS) then -- Wall climbing
				local sp = ply:GetShootPos()
				local t = {
					start = sp, endpos = sp + ply:GetForward() * 32768,
					mask = ss.SquidSolidMask,
					collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
					filter = ply,
				}
				local fw = util.TraceLine(t)
				t.endpos = sp - ply:GetForward() * 32768
				local bk = util.TraceLine(t)
				if fw.Fraction < bk.Fraction == mv:KeyDown(IN_FORWARD) then
					vz = math.max(math.abs(vz) * -.75,
					vz + math.min(12 + (mv:KeyPressed(IN_JUMP) and maxspeed / 4 or 0), maxspeed))
					if ply:OnGround() then
						t.endpos = sp + ply:GetRight() * 32768
						local r = util.TraceLine(t)
						t.endpos = sp - ply:GetRight() * 32768
						local l = util.TraceLine(t)
						if math.min(fw.Fraction, bk.Fraction) < math.min(r.Fraction, l.Fraction) then
							mv:AddKey(IN_JUMP)
						end
					end
				end

				t.start = mv:GetOrigin()
				t.endpos = t.start + vector_up * ss.WALLCLIMB_STEP_CHECK_LENGTH
				t.mins, t.maxs = ply:GetCollisionBounds()
				local tr = util.TraceHull(t)
				if tr.HitWorld then
					t.start = t.endpos + w:GetWallNormal() * ss.MAX_WALLCLIMB_STEP
					tr = util.TraceHull(t)
					if not tr.StartSolid and math.abs(tr.HitNormal.z) < ss.MAX_COS_DIFF then
						mv:SetOrigin(tr.HitPos)
					end
				end
			end

			if not (crouching and ply:OnGround()) and speed > maxspeed then -- Limits horizontal speed
				v:Mul(maxspeed / speed)
				speed = math.min(speed, maxspeed)
			end

			v.z = w.OnOutofInk and not w:GetInWallInk()
			and math.min(vz, ply:GetJumpPower() * .7) or vz
			if i then mv:SetVelocity(v) end
		end
	end

	-- Send viewmodel animation.
	if crouching then
		w.SwimSound:ChangeVolume(math.Clamp(mv:GetVelocity():Length() / w.SquidSpeed * (w:GetInInk() and 1 or 0), 0, 1))
		if not w:GetOldCrouching() then
			w:SetWeaponAnim(ss.ViewModel.Squid)
			if w:GetNWInt "playermodel" ~= ss.PLAYER.NOCHANGE then
				ply:RemoveAllDecals()
			end

			if IsFirstTimePredicted() then
				ss.EmitSoundPredicted(ply, w, "SplatoonSWEPs_Player.ToSquid")
			end
		end
	elseif w:GetOldCrouching() then
		w.SwimSound:ChangeVolume(0)
		w:SetWeaponAnim(w:GetThrowing() and ss.ViewModel.Throwing or ss.ViewModel.Standing)
		if IsFirstTimePredicted() then
			ss.EmitSoundPredicted(ply, w, "SplatoonSWEPs_Player.ToHuman")
		end
	end

	w.OnOutofInk = w:GetInWallInk()
	w:SetOldCrouching(crouching or infence)
end

function ss.MakeExplosionStructure()
	return {
		ClassName = "",
		DamageRadius = 0,
		DoDamage = false,
		DoGroundPaint = false,
		EffectFlags = 0,
		EffectName = "SplatoonSWEPsExplosion",
		EffectRadius = 0,
		GroundPaintRadius = 0,
		GroundPaintType = 13,
		GetDamage = function(dist) return 0 end,
		GetTracePaintRadius = function(dist) return 0 end,
		HurtOwner = false,
		IgnorePrediction = nil,
		IsCarriedByLocalPlayer = false,
		IsPredicted = nil,
		InkColor = 1,
		Origin = Vector(),
		Owner = NULL,
		ProjectileID = 0,
		SplashInitAng = Angle(),
		TraceLength = 0,
		TraceYaw = 0,
	}
end

function ss.MakeExplosion(data)
	local origin = data.Origin
	local owner = data.Owner
	local hurtowner = data.HurtOwner
	local IsCarriedByLocalPlayer = data.IsCarriedByLocalPlayer
	local inkcolor = data.InkColor
	local projectileID = data.ProjectileID
	local splashinitang = data.SplashInitAng
	local effectflags = data.EffectFlags
	local effectname = data.EffectName
	local IgnorePrediction = data.IgnorePrediction
	local splashinitang = data.SplashInitAng
	local classname = data.ClassName
	local GetDamage = data.GetDamage
	local GetTracePaintRadius = data.GetTracePaintRadius
	local d = DamageInfo()
	local damagedealt = false
	local attacker = IsValid(owner) and owner or game.GetWorld()
	local inflictor = ss.IsValidInkling(owner) or game.GetWorld()
	if data.DoDamage then -- Find entities within explosion and deal damage
		for _, e in ipairs(ents.FindInSphere(origin, data.DamageRadius)) do
			local target_weapon = ss.IsValidInkling(e)
			if IsValid(e) and e:Health() > 0 and ss.LastHitID[e] ~= projectileID
			and (not ss.IsAlly(target_weapon, inkcolor) or hurtowner and e == owner) then
				local dist = Vector()
				local maxs, mins = e:OBBMaxs(), e:OBBMins()
				local center = e:LocalToWorld(e:OBBCenter())
				local size = (maxs - mins) / 2
				for i, dir in pairs {
					x = e:GetForward(), y = e:GetRight(), z = e:GetUp()
				} do
					local segment = dir:Dot(origin - center)
					local sign = segment == 0 and 0 or segment > 0 and 1 or -1
					segment = math.abs(segment)
					if segment > size[i] then
						dist = dist + sign * (size[i] - segment) * dir
					end
				end

				local t = ss.SquidTrace
				t.start = origin
				t.endpos = origin + dist
				t.filter = not hurtowner and owner or nil
				t = util.TraceLine(t)
				if not t.Hit or t.Entity == e then
					if IsCarriedByLocalPlayer then
						ss.CreateHitEffect(inkcolor, damagedealt and 6 or 2, origin + dist, -dist)
						if CLIENT and e ~= owner then damagedealt = true break end
					end

					ss.LastHitID[e] = projectileID -- Avoid multiple damages at once
					damagedealt = damagedealt or ss.sp or e == owner
					local dmg = GetDamage(dist:Length())
					
					d:SetDamage(dmg)
					d:SetDamageForce((e:WorldSpaceCenter() - origin):GetNormalized() * dmg)
					d:SetDamagePosition(origin)
					d:SetDamageType(DMG_GENERIC)
					d:SetMaxDamage(dmg)
					d:SetReportedPosition(origin)
					d:SetAttacker(attacker)
					d:SetInflictor(inflictor)
					d:ScaleDamage(ss.ToHammerHealth)
					ss.ProtectedCall(e.TakeDamageInfo, e, d)
				end
			end
		end
	end
	
	if ss.mp and not IsFirstTimePredicted() then return end

	-- Explosion effect
	local e = EffectData()
	e:SetOrigin(origin)
	e:SetColor(inkcolor)
	e:SetFlags(effectflags)
	e:SetRadius(data.EffectRadius)
	if data.IsPredicted then
		ss.UtilEffectPredicted(owner, effectname, e, true, data.IgnorePrediction)
	else
		util.Effect(effectname, e, true, true)
	end

	-- Trace around and paint
	local a = splashinitang
	local a2, a3 = Angle(a), Angle(a)
	a2:RotateAroundAxis(a:Right(), 45)
	a2:RotateAroundAxis(a:Up(), 45)
	a3:RotateAroundAxis(a:Right(), 45)
	a3:RotateAroundAxis(a:Up(), -45)
	for _, d in ipairs {
		a:Forward(), -a:Forward(), a:Right(), -a:Right(), a:Up(),
		a2:Forward(), a2:Right(), -a2:Right(), a2:Up(),
		a3:Forward(), a3:Right(), -a3:Right(), a3:Up(),
	} do
		local t = util.TraceLine {
			collisiongroup = COLLISION_GROUP_DEBRIS,
			start = origin,
			endpos = origin + d * data.TraceLength,
			filter = owner,
			mask = ss.SquidSolidMaskBrushOnly,
		}

		if t.Hit and not t.StartSolid then
			local dist = (t.HitPos - t.StartPos):Length2D()
			ss.Paint(t.HitPos, t.HitNormal, GetTracePaintRadius(dist),
			inkcolor, data.TraceYaw, ss.GetDropType(), 1, owner, classname)
		end
	end

	if not data.DoGroundPaint then return end
	local t = util.TraceLine {
		collisiongroup = COLLISION_GROUP_DEBRIS,
		start = origin,
		endpos = origin - vector_up * data.GroundPaintRadius / 2,
		filter = owner,
		mask = ss.SquidSolidMaskBrushOnly,
	}

	if not t.Hit or t.StartSolid then return end
	ss.Paint(t.HitPos, t.HitNormal, data.GroundPaintRadius,
	inkcolor, data.TraceYaw, data.GroundPaintType, 1, owner, classname)
end

function ss.MakeBombExplosion(org, owner, color, params)
	local w = ss.IsValidInkling(owner)
	if not w then return end
	sound.Play("SplatoonSWEPs.BombExplosion", org) -- TODO: Burst bomb sound
	ss.MakeExplosion(table.Merge(ss.MakeExplosionStructure(), {
		ClassName = w:GetClass(),
		DamageRadius = params.Burst_Radius_Far,
		DoDamage = true,
		DoGroundPaint = true,
		EffectName = "SplatoonSWEPsExplosion",
		EffectRadius = params.Burst_Radius_Far,
		GetDamage = function(dist)
			local rnear = params.Burst_Radius_Near
			local dnear = params.Burst_Damage_Near
			local dfar = params.Burst_Damage_Far
			return dist < rnear and dnear or dfar
		end,
		GetTracePaintRadius = function(dist) return params.CrossPaintRadius end,
		GroundPaintRadius = params.Burst_PaintR,
		HurtOwner = false,
		InkColor = color,
		Origin = org,
		Owner = owner,
		ProjectileID = CurTime(),
		TraceLength = params.CrossPaintRayLength,
	}))
end

function ss.MakeDeathExplosion(org, attacker, color)
	sound.Play("SplatoonSWEPs.PlayerDeathExplosion", org)
	ss.MakeExplosion(table.Merge(ss.MakeExplosionStructure(), {
		ClassName = ss.IsValidInkling(attacker).ClassName,
		DoGroundPaint = true,
		EffectName = "SplatoonSWEPsExplosion",
		EffectRadius = 300,
		GetTracePaintRadius = function(dist) return 50 end,
		GroundPaintRadius = 150,
		GroundPaintType = 14,
		InkColor = color,
		Origin = org,
		Owner = attacker,
		ProjectileID = CurTime(),
		TraceLength = 150,
	}))
end

function ss.MakeBlasterExplosion(ink)
	local data, p = ink.Data, ink.Parameters
	local dmul = ink.BlasterHitWall and p.mShotCollisionHitDamageRate or 1
	local dnear = p.mDamageNear * dmul
	local dmid = p.mDamageMiddle * dmul
	local dfar = p.mDamageFar * dmul
	local rmul = ink.BlasterHitWall and p.mShotCollisionRadiusRate or 1
	local rnear = p.mCollisionRadiusNear * rmul
	local rmid = p.mCollisionRadiusMiddle * rmul
	local rfar = p.mCollisionRadiusFar * rmul
	local e = table.Merge(ss.MakeExplosionStructure(), {
		ClassName = data.Weapon.ClassName,
		DamageRadius = rfar,
		DoDamage = true,
		EffectFlags = ink.BlasterHitWall and 1 or 0,
		EffectName = "SplatoonSWEPsBlasterExplosion",
		EffectRadius = p.mCollisionRadiusFar * rmul,
		GetDamage = function(dist)
			if dist > rmid then
				return math.Remap(dist, rmid, rfar, dmid, dfar)
			elseif dist > rnear then
				return math.Remap(dist, rnear, rmid, dnear, dmid)
			end
	
			return dnear
		end,
		GetTracePaintRadius = function(dist)
			local frac = dist / p.mBoundPaintMinDistanceXZ
			return Lerp(frac, p.mBoundPaintMaxRadius, p.mBoundPaintMinRadius)
		end,
		HurtOwner = ss.GetOption "weapon_splatoonsweps_blaster_base" "hurtowner",
		IgnorePrediction = data.Weapon.IgnorePrediction,
		IsCarriedByLocalPlayer = ink.IsCarriedByLocalPlayer,
		IsPredicted = true,
		InkColor = data.Color,
		Origin = ink.Trace.endpos,
		Owner = ink.Trace.filter,
		ProjectileID = data.ID,
		SplashInitAng = data.InitDir:Angle(),
		TraceLength = p.mMoveLength,
		TraceYaw = data.Yaw,
	})

	if ink.BlasterHitWall then
		e.SplashInitAng:RotateAroundAxis(e.SplashInitAng:Right(), -90)
	end

	ss.MakeExplosion(e)
	if not p.mSphereSplashDropOn then return end

	-- Create a blaster's drop
	local dropdata = ss.MakeProjectileStructure()
	table.Merge(dropdata, {
		Color = data.Color,
		ColRadiusEntity = p.mSphereSplashDropCollisionRadius,
		ColRadiusWorld = p.mSphereSplashDropCollisionRadius,
		DoDamage = false,
		Gravity = ss.ToHammerUnitsPerSec2,
		InitPos = ink.Trace.endpos,
		InitVel = vector_up * p.mSphereSplashDropInitSpeed,
		PaintFarDistance = p.mPaintFarDistance,
		PaintFarRadius = p.mSphereSplashDropPaintRadius,
		PaintNearDistance = p.mPaintNearDistance,
		PaintNearRadius = p.mSphereSplashDropPaintRadius,
		Weapon = data.Weapon,
		Yaw = data.Yaw,
	})
	
	local e = EffectData()
	ss.SetEffectColor(e, dropdata.Color)
	ss.SetEffectColRadius(e, dropdata.ColRadiusWorld)
	ss.SetEffectDrawRadius(e, p.mSphereSplashDropDrawRadius)
	ss.SetEffectEntity(e, dropdata.Weapon)
	ss.SetEffectFlags(e, dropdata.Weapon, 3)
	ss.SetEffectInitPos(e, dropdata.InitPos)
	ss.SetEffectInitVel(e, dropdata.InitVel)
	ss.SetEffectSplash(e, Angle(0, 0, 0))
	ss.SetEffectSplashInitRate(e, Vector(0))
	ss.SetEffectSplashNum(e, 0)
	ss.SetEffectStraightFrame(e, 0)
	ss.UtilEffectPredicted(ink.Trace.filter,
	"SplatoonSWEPsShooterInk", e, true, data.Weapon.IgnorePrediction)
	ss.AddInk(p, dropdata)
end

-- Short for Entity:NetworkVar().
-- A new function Entity:AddNetworkVar() is created to the given entity.
-- Argument:
--   Entity ent	| The entity to add to.
function ss.AddNetworkVar(ent)
	if ent.NetworkSlot then return end
	ent.NetworkSlot = {
		String = -1, Bool = -1, Float = -1, Int = -1,
		Vector = -1, Angle = -1, Entity = -1,
	}

	-- Returns how many network slots the entity uses.
	-- Argument:
	--   string typeof	| The type to inspect.
	-- Returning:
	--   number			| The number of slots the entity uses.
	function ent:GetLastSlot(typeof) return self.NetworkSlot[typeof] end

	-- Adds a new network variable to the entity.
	-- Arguments:
	--   string typeof	| The variable type.  Same as Entity:NetworkVar().
	--   string name	| The variable name.
	-- Returning:
	--   number			| A new assigned slot.
	function ent:AddNetworkVar(typeof, name)
		assert(self.NetworkSlot[typeof] < 31, "SplatoonSWEPs: Tried to use too many network variables!")
		self.NetworkSlot[typeof] = self.NetworkSlot[typeof] + 1
		self:NetworkVar(typeof, self.NetworkSlot[typeof], name)
		return self.NetworkSlot[typeof]
	end
end

-- Lets the given entity use CurTime() based timer library.
-- Call it in the header, and put SplatoonSWEPs:ProcessSchedules() in ENT:Think().
-- Argument:
--   Entity ent	| The entity to be able to use timer library.
function ss.AddTimerFramework(ent)
	if ent.FunctionQueue then return end

	ss.AddNetworkVar(ent) -- Required to use Entity:AddNetworkSchedule()
	ent.FunctionQueue = {}

	-- Sets how many this schedule has done.
	-- Argument:
	--   number done | The new counter.
	local ScheduleFunc = {}
	local ScheduleMeta = {__index = ScheduleFunc}
	function ScheduleFunc:SetDone(done)
		if isstring(self.done) then
			self.weapon["Set" .. self.done](self.weapon, done)
		else
			self.done = done
		end
	end

	-- Returns the current counter value.
	function ScheduleFunc:GetDone()
		return isstring(self.done) and self.weapon["Get" .. self.done](self.weapon) or self.done
	end

	-- Resets the interval of the schedule.
	-- Argument:
	--   number newdelay	| The new interval.
	function ScheduleFunc:SetDelay(newdelay)
		if isstring(self.delay) then
			self.weapon["Set" .. self.delay](self.weapon, newdelay)
		else
			self.delay = newdelay
		end

		if isstring(self.prevtime) then
			self.weapon["Set" .. self.prevtime](self.weapon, CurTime())
		else
			self.prevtime = CurTime()
		end

		if isstring(self.time) then
			self.weapon["Set" .. self.time](self.weapon, CurTime() + newdelay)
		else
			self.time = CurTime() + newdelay
		end
	end

	-- Returns the current interval of the schedule.
	function ScheduleFunc:GetDelay()
		return isstring(self.delay) and self.weapon["Get" .. self.delay](self.weapon) or self.delay
	end

	-- Sets a time for SinceLastCalled()
	-- Argument:
	--   number newtime	| Relative to CurTime()
	function ScheduleFunc:SetLastCalled(newtime)
		if isstring(self.prevtime) then
			self.weapon["Set" .. self.prevtime](self.weapon, CurTime() - newtime)
		else
			self.prevtime = CurTime() - newtime
		end
	end

	-- Returns the time since the schedule has been last called.
	function ScheduleFunc:SinceLastCalled()
		if isstring(self.prevtime) then
			return CurTime() - self.weapon["Get" .. self.prevtime](self.weapon)
		else
			return CurTime() - self.prevtime
		end
	end

	-- Adds an syncronized schedule.
	-- Arguments:
	--   number delay	| How long the function should be ran in seconds.
	--   				| Use 0 to have the function run every time ENT:Think() called.
	--   function func	| The function to run after the specified delay.
	-- Returning:
	--   table			| The created schedule object.
	function ent:AddNetworkSchedule(delay, func)
		local schedule = setmetatable({
			func = func,
			weapon = self,
		}, ScheduleMeta)
		schedule.delay = "TimerDelay" .. tostring(self:GetLastSlot "Float")
		self:AddNetworkVar("Float", schedule.delay)
		self["Set" .. schedule.delay](self, delay)
		schedule.prevtime = "TimerPrevious" .. tostring(self:GetLastSlot "Float")
		self:AddNetworkVar("Float", schedule.prevtime)
		self["Set" .. schedule.prevtime](self, CurTime())
		schedule.time = "Timer" .. tostring(self:GetLastSlot "Float")
		self:AddNetworkVar("Float", schedule.time)
		self["Set" .. schedule.time](self, CurTime())
		schedule.done = "Done" .. tostring(self:GetLastSlot "Int")
		self:AddNetworkVar("Int", schedule.done)
		self["Set" .. schedule.done](self, 0)
		self.FunctionQueue[#self.FunctionQueue + 1] = schedule
		return schedule
	end

	-- Adds an schedule.
	-- Arguments:
	--   number delay	| How long the function should be ran in seconds.
	--   				| Use 0 to have the function run every time ENT:Think() called.
	--   number numcall	| The number of times to repeat.  Set to nil or 0 for infinite schedule.
	--   function func	| The function to run.  Returning true in it to have the schedule stop.
	-- Returning:
	--   table			| The created schedule object.
	function ent:AddSchedule(delay, numcall, func)
		local schedule = setmetatable({
			delay = delay,
			done = 0,
			func = func or numcall,
			numcall = func and numcall or 0,
			time = CurTime() + delay,
			prevtime = CurTime(),
			weapon = self,
		}, ScheduleMeta)
		self.FunctionQueue[#self.FunctionQueue + 1] = schedule
		return schedule
	end

	-- Makes the registered functions run.  Put it in ENT:Think() for desired use.
	function ent:ProcessSchedules()
		for i, s in pairs(self.FunctionQueue) do
			if isstring(s.time) then
				if CurTime() > self["Get" .. s.time](self) then
					local remove = s.func(self, s)
					self["Set" .. s.prevtime](self, CurTime())
					self["Set" .. s.time](self, CurTime() + self["Get" .. s.delay](self))
					self["Set" .. s.done](self, self["Get" .. s.done](self) + 1)
					if remove then self["Set" .. s.done](self, 2^16 - 1) end
				end
			elseif CurTime() > s.time then
				local remove = s.func(self, s)
				s.prevtime = CurTime()
				s.time = CurTime() + s.delay
				if s.numcall > 0 then
					s.done = s.done + 1
					remove = remove or s.done >= s.numcall
				end

				if remove then self.FunctionQueue[i] = nil end
			end
		end
	end
end

-- ss.GetMaxHealth() - Get inkling's desired maximum health
-- ss.GetMaxInkAmount() - Get the maximum amount of an ink tank.
local gain = ss.GetOption "gain"
function ss.GetMaxHealth() return gain "maxhealth" end
function ss.GetMaxInkAmount() return gain "inkamount" end

function ss.GetBotOption(pt)
	print(pt.cl, pt.cl:GetDefault())
	return (pt.cl or pt.sv):GetDefault()
end

-- Play footstep sound of ink.
function ss.PlayerFootstep(w, ply, pos, foot, soundName, volume, filter)
	if SERVER and ss.mp then return end
	if ply:Crouching() and w:GetNWBool "becomesquid" and w:GetGroundColor() < 0
	or not ply:Crouching() and w:GetGroundColor() >= 0 then
		ply:EmitSound "SplatoonSWEPs_Player.InkFootstep"
		return true
	end

	if not ply:Crouching() then return end
	return soundName:find "chainlink" and true or nil
end

function ss.UpdateAnimation(w, ply, velocity, maxseqspeed)
	ss.ProtectedCall(w.UpdateAnimation, w, ply, velocity, maxseqspeed)

	if not w:GetThrowing() then return end

	ply:AnimSetGestureWeight(GESTURE_SLOT_ATTACK_AND_RELOAD, 1)

	local f = (CurTime() - w:GetThrowAnimTime()) / ss.SubWeaponThrowTime
	if CLIENT and w:IsCarriedByLocalPlayer() then
		f = f + LocalPlayer():Ping() / 1000 / ss.SubWeaponThrowTime
	end

	if 0 <= f and f <= 1 then
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD,
		ply:SelectWeightedSequence(ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE),
		f * .55, true)
	end
end

function ss.KeyPress(self, ply, key)
	if ss.KeyMaskFind[key] then
		self:SetKey(key)
		table.RemoveByValue(self.KeyPressedOrder, key)
		self.KeyPressedOrder[#self.KeyPressedOrder + 1] = key
	end
	
	ss.ProtectedCall(self.KeyPress, self, ply, key)
end

function ss.KeyRelease(self, ply, key)
	table.RemoveByValue(self.KeyPressedOrder, key)
	if #self.KeyPressedOrder > 0 then
		ss.KeyPress(self, ply, self.KeyPressedOrder[#self.KeyPressedOrder])
	else
		self:SetKey(0)
	end

	ss.ProtectedCall(self.KeyRelease, self, ply, key)

	if not ss.KeyMaskFind[key] then return end
	if CurTime() < self:GetNextSecondaryFire() then return end
	if not (self:GetThrowing() and key == IN_ATTACK2) then return end
	self:AddSchedule(ss.SubWeaponThrowTime, 1, function() self:SetThrowing(false) end)

	local time = CurTime() + ss.SubWeaponThrowTime
	self:SetCooldown(time)
	self:SetNextPrimaryFire(time)
	self:SetNextSecondaryFire(time)

	local able = self:GetInk() > 0 and self:CheckCanStandup() and self:CanSecondaryAttack()
	if not able then return end
	self:SetThrowAnimTime(CurTime())
	self:SetWeaponAnim(ss.ViewModel.Throw)
	ss.ProtectedCall(self.SharedSecondaryAttack, self, able)
	ss.ProtectedCall(Either(SERVER, self.ServerSecondaryAttack, self.ClientSecondaryAttack), self, able)
end

function ss.OnPlayerHitGround(self, ply, inWater, onFloater, speed)
	if not self:GetInInk() then return end
	if not self:IsFirstTimePredicted() then return end
	local e = EffectData()
	local f = (speed - 100) / 600
	local t = util.QuickTrace(ply:GetPos(), -vector_up * 16384, {self, ply})
	e:SetAngles(t.HitNormal:Angle())
	e:SetAttachment(10)
	e:SetColor(self:GetNWInt "inkcolor")
	e:SetEntity(self)
	e:SetFlags((f > .5 and 7 or 3) + (CLIENT and self:IsCarriedByLocalPlayer() and 128 or 0))
	e:SetOrigin(t.HitPos)
	e:SetRadius(Lerp(f, 25, 50))
	e:SetScale(.5)
	util.Effect("SplatoonSWEPsMuzzleSplash", e, true)
end

hook.Add("PlayerFootstep", "SplatoonSWEPs: Ink footstep", ss.hook "PlayerFootstep")
hook.Add("UpdateAnimation", "SplatoonSWEPs: Adjust TPS animation speed", ss.hook "UpdateAnimation")
hook.Add("KeyPress", "SplatoonSWEPs: Check a valid key", ss.hook "KeyPress")
hook.Add("KeyRelease", "SplatoonSWEPs: Throw sub weapon", ss.hook "KeyRelease")
hook.Add("OnPlayerHitGround", "SplatoonSWEPs: Play diving sound", ss.hook "OnPlayerHitGround")

cvars.AddChangeCallback("gmod_language", function(convar, old, new)
	CompileFile "splatoonsweps/text.lua" ()
end, "SplatoonSWEPs: OnLanguageChanged")

if ss.GetOption "enabled" then
	cleanup.Register(ss.CleanupTypeInk)
end

local nest = nil
for hookname in pairs {CalcMainActivity = true, TranslateActivity = true} do
	hook.Add(hookname, "SplatoonSWEPs: Crouch anim in fence", ss.hook(function(w, ply, ...)
		if nest then nest = nil return end
		if not ply:Crouching() then return end
		if not w:GetInFence() then return end
		nest, ply.m_bWasNoclipping = true
		ply:SetMoveType(MOVETYPE_WALK)
		local res1, res2 = gamemode.Call(hookname, ply, ...)
		ply:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
		ply:SetMoveType(MOVETYPE_NOCLIP)
		return res1, res2
	end))
end

concommand.Add("-splatoonsweps_reset_camera", function(ply) end, nil, ss.Text.CVars.ResetCamera)
concommand.Add("+splatoonsweps_reset_camera", function(ply)
	ss.PlayerShouldResetCamera[ply] = true
end, nil, ss.Text.CVars.ResetCamera)

------------------------------------------
--			!!!WORKAROUND!!!			--
--	This should be removed after		--
--	Adv. Colour Tool fixed the bug!!	--
------------------------------------------
local AdvancedColourToolLoaded
= file.Exists("weapons/gmod_tool/stools/adv_colour.lua", "LUA")
local AdvancedColourToolReplacedSetSubMaterial
= AdvancedColourToolLoaded and FindMetaTable "Entity"._OldSetSubMaterial
if AdvancedColourToolReplacedSetSubMaterial then
	function ss.SetSubMaterial_ShouldBeRemoved(ent, ...)
		ent:_OldSetSubMaterial(...)
	end
else
	function ss.SetSubMaterial_ShouldBeRemoved(ent, ...)
		ent:SetSubMaterial(...)
	end
end
------------------------------------------
--			!!!WORKAROUND!!!			--
------------------------------------------


-- Inkling playermodels hull change fix
if not isfunction(FindMetaTable "Player".SplatoonOffsets) then return end
CreateConVar("splt_Colors", 1, {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}, "Toggles skin/eye colors on Splatoon playermodels.")
if SERVER then
	hook.Remove("KeyPress", "splt_KeyPress")
	hook.Remove("PlayerSpawn", "splt_Spawn")
	hook.Remove("PlayerDeath", "splt_OnDeath")
	hook.Add("PlayerSpawn", "SplatoonSWEPs: Fix PM change", function(ply)
		ss.SetSubMaterial_ShouldBeRemoved(ply)
	end)
else
	hook.Remove("Tick", "splt_Offsets_cl")
end

local width = 16
local splt_EditScale = GetConVar "splt_EditScale"
hook.Add("Tick", "SplatoonSWEPs: Fix playermodel hull change", function()
	for _, p in ipairs(player.GetAll()) do
		local is = ss.DrLilRobotPlayermodels[p:GetModel()]
		if not p:Alive() then
			ss.PlayerHullChanged[p] = nil
		elseif is and splt_EditScale:GetInt() ~= 0 and ss.PlayerHullChanged[p] ~= true then
			p:SetViewOffset(Vector(0, 0, 42))
			p:SetViewOffsetDucked(Vector(0, 0, 28))
			p:SetHull(Vector(-width, -width, 0), Vector(width, width, 53))
			p:SetHullDuck(Vector(-width, -width, 0), Vector(width, width, 33))
			ss.PlayerHullChanged[p] = true
		elseif not is and ss.PlayerHullChanged[p] ~= false then
			p:DefaultOffsets()
			ss.PlayerHullChanged[p] = false
		end
	end
end)
