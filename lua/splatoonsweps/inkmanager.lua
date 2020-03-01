
-- This lua manages whole ink in map.

local ss = SplatoonSWEPs
if not ss then return end
local abs = math.abs
local Angle = Angle
local SearchAABB = ss.SearchAABB
local CLIENT = CLIENT
local CollisionAABB = ss.CollisionAABB
local cos = math.cos
local Either = Either
local EndSuppressHostEventsMP = ss.EndSuppressHostEventsMP
local floor = math.floor
local InkQueueReceiveFunction = ss.InkQueueReceiveFunction
local ipairs = ipairs
local isnumber = isnumber
local KeyFromValue = table.KeyFromValue
local min = math.min
local mp = ss.mp
local net_Send = net.Send
local net_Start = net.Start
local net_WriteDouble = net.WriteDouble
local net_WriteEntity = net.WriteEntity
local net_WriteFloat = net.WriteFloat
local net_WriteInt = net.WriteInt
local net_WriteUInt = net.WriteUInt
local net_WriteVector = net.WriteVector
local NormalizeAngle = math.NormalizeAngle
local pairs = pairs
local rad = math.rad
local Round = math.Round
local SERVER = SERVER
local sin = math.sin
local sp = ss.sp
local SuppressHostEventsMP = ss.SuppressHostEventsMP
local To2D = ss.To2D
local To3D = ss.To3D
local Vector = Vector
local vector_origin = vector_origin
local WorldToLocal = WorldToLocal
local MAX_COS_DIFF = ss.MAX_COS_DIFF
local MIN_BOUND = 20 -- Ink minimum bounding box scale
local POINT_BOUND = ss.vector_one * .1
local reference_polys = {}
local reference_vert = Vector(1)
local circle_polys = 360 / 12
for i = 1, circle_polys do
	reference_polys[#reference_polys + 1] = Vector(reference_vert)
	reference_vert:Rotate(Angle(0, circle_polys))
end

-- Internal function to record a new ink to the map.
local gridsize = ss.InkGridSize
local gridarea = gridsize * gridsize
local griddivision = 1 / gridsize
function ss.AddInkRectangle(color, inktype, localang, pos, radius, ratio, s)
	local pos2d = To2D(pos, s.Origin, s.Angles) * griddivision
	local x0, y0 = pos2d.x, pos2d.y
	local ink = s.InkSurfaces
	local t = ss.InkShotMaterials[inktype]
	local w, h = t.width, t.height
	local surfsize = s.Bound * griddivision
	local sw, sh = floor(surfsize.x), floor(surfsize.y)
	local dy = radius * griddivision
	local dx = ratio * dy
	local y_const = dy * 2 / h
	local x_const = ratio * dy * 2 / w
	local ang = rad(-localang)
	local sind, cosd = sin(ang), cos(ang)
	local pointcount = {}
	local area = 0
	for x = 0, w - 1, 0.5 do
		local tx = t[floor(x)]
		if tx then
			for y = 0, h - 1, 0.5 do
				if tx[floor(y)] then
					local p = x * x_const - dx
					local q = y * y_const - dy
					local i = floor(p * cosd - q * sind + x0)
					local k = floor(p * sind + q * cosd + y0)
					if 0 <= i and i <= sw and 0 <= k and k <= sh then
						pointcount[i] = pointcount[i] or {}
						pointcount[i][k] = (pointcount[i][k] or 0) + 1
						if pointcount[i][k] > 25 then
							ink[i] = ink[i] or {}
							if ink[i][k] ~= color then area = area + 1 end
							ink[i][k] = color
						end
					end
				end
			end
		end
	end

	return area
end

-- Draws ink.
-- Arguments:
--   Vector pos		  | Center position.
--   Vector normal	  | Normal of the surface to draw.
--   number radius	  | Scale of ink in Hammer units.
--   number angle	  | Ink rotation in degrees.
--   number inktype   | Shape of ink.
--   number ratio	  | Aspect ratio.
--   Entity ply       | The shooter.
--   string classname | Weapon's class name.
local Order, OrderTime = 1, 0 -- The ink paint order at OrderTime[sec]
local AddInkRectangle = ss.AddInkRectangle
function ss.Paint(pos, normal, radius, color, angle, inktype, ratio, ply, classname)
	-- Parameter limit to reduce network traffic
	pos.x = Round(pos.x * 2) / 2
	pos.y = Round(pos.y * 2) / 2 -- -16384 to 16384, 0.5 step
	pos.z = Round(pos.z * 2) / 2
	radius = min(Round(radius), 255) -- 0 to 255, integer
	inktype = floor(inktype) -- 0 to MAX_INK_TYPE, integer
	angle = Round(NormalizeAngle(angle))

	local area = 0
	local ang = normal:Angle()
	local ignoreprediction = not ply:IsPlayer() and SERVER and mp or nil
	local AABB = {mins = ss.vector_one * math.huge, maxs = -ss.vector_one * math.huge}
	ang.roll = abs(normal.z) > MAX_COS_DIFF and angle * normal.z or ang.yaw
	for i, v in ipairs(reference_polys) do
		local vertex = To3D(v * radius, pos, ang)
		AABB.mins = ss.MinVector(AABB.mins, vertex)
		AABB.maxs = ss.MaxVector(AABB.maxs, vertex)
	end

	AABB.mins:Add(-ss.vector_one * MIN_BOUND)
	AABB.maxs:Add(ss.vector_one * MIN_BOUND)
	SuppressHostEventsMP(ply)
	for _, s in SearchAABB(AABB, normal) do
		local _, localang = WorldToLocal(vector_origin, ang, vector_origin, s.Normal:Angle())
		localang = ang.yaw - localang.roll + s.DefaultAngles + (CLIENT and s.Moved and 90 or 0)
		localang = Round(NormalizeAngle(localang)) -- -180 to 179, integer
		area = area + AddInkRectangle(color, inktype, localang, pos, radius, ratio, s)

		Order = Order + 1
		if CurTime() > OrderTime then
			OrderTime = CurTime()
			Order = 1
		end

		if SERVER then
			net_Start "SplatoonSWEPs: Send an ink queue"
			net_WriteUInt(s.Index, ss.SURFACE_ID_BITS)
			net_WriteUInt(color, ss.COLOR_BITS)
			net_WriteUInt(ply:EntIndex(), 13)
			net_WriteUInt(inktype, ss.INK_TYPE_BITS)
			net_WriteUInt(radius, 8)
			net_WriteVector(Vector(ratio))
			net_WriteInt(localang, 9)
			net_WriteInt(pos.x * 2, 16)
			net_WriteInt(pos.y * 2, 16)
			net_WriteInt(pos.z * 2, 16)
			net_WriteUInt(Order, 8) -- 119 to 128 bits
			net_WriteFloat(OrderTime)
			net_Send(ss.PlayersReady)
		else
			InkQueueReceiveFunction(s.Index, radius, localang, ratio, color, ply, inktype, pos, Order - 256, OrderTime)
		end
	end

	EndSuppressHostEventsMP(ply)
	if not ply:IsPlayer() or ply:IsBot() then return end

	ss.WeaponRecord[ply].Inked[classname] = (ss.WeaponRecord[ply].Inked[classname] or 0) - area * gridarea
	if sp and SERVER then
		net_Start "SplatoonSWEPs: Send turf inked"
		net_WriteDouble(ss.WeaponRecord[ply].Inked[classname])
		net_WriteUInt(KeyFromValue(ss.WeaponClassNames, classname), ss.WEAPON_CLASSNAMES_BITS)
		net_Send(ply)
	end
end

-- Takes a TraceResult and returns ink color of its HitPos.
-- Argument:
--   TraceResult tr	| A TraceResult structure to pick up a position.
-- Returning:
--   number			| The ink color of the specified position.
--   nil			| If there is no ink, returns nil.
function ss.GetSurfaceColor(tr)
	if not tr.Hit then return end
	local pos = tr.HitPos
	local AABB = {mins = pos - POINT_BOUND, maxs = pos + POINT_BOUND}
	for _, s in SearchAABB(AABB, tr.HitNormal) do
		local p2d = To2D(pos, s.Origin, s.Angles)
		local ink = s.InkSurfaces
		local x, y = floor(p2d.x * griddivision), floor(p2d.y * griddivision)
		local colorid = ink[x] and ink[x][y]
		if ss.Debug then ss.Debug.ShowInkStateMesh(Vector(x, y), i, s) end
		if colorid then return colorid end
	end
end
