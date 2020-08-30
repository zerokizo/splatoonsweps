
local ss = SplatoonSWEPs
if not ss then return end

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
