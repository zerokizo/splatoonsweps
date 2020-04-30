
-- Clientside ink manager

local ss = SplatoonSWEPs
if not ss then return end
local CVarWireframe = GetConVar "mat_wireframe"
local CVarMinecraft = GetConVar "mat_showlowresimage"
local IsHDREnabled = GetConVar "mat_hdr_level":GetInt() > 0
local lightmapbrush = Material "splatoonsweps/lightmapbrush"
local inkhdrscale = ss.vector_one * 0.5^2.2
local inkmaterials = {}
local rt = ss.RenderTarget
local LightmapQueue = {}
local MAX_QUEUE_TIME = ss.FrameToSec / 4
local MAX_QUEUES_TOLERANCE = 5 -- Possible number of queues to be processed at once without losing FPS.
for i = 1, 14 do
	inkmaterials[i] = {}
	for j = 1, 4 do
		inkmaterials[i][j] = Material(("splatoonsweps/inkshot/%d/%d.vmt"):format(i, j))
	end
end

local amb = render.GetAmbientLightColor() * 0.25
local function LightmapSample(pos, normal)
	local p = pos + normal * 0.5
	local c = render.ComputeLighting(p, normal)
	- render.ComputeDynamicLighting(p, normal)
	local gamma_recip = 1 / 2.2
	c.x = c.x ^ gamma_recip
	c.y = c.y ^ gamma_recip
	c.z = c.z ^ gamma_recip
	return c:ToColor()
end

local function DrawMeshes(bDrawingDepth, bDrawingSkybox)
	if ss.GetOption "hideink" then return end
	if not rt.Ready or bDrawingSkybox or CVarWireframe:GetBool() or CVarMinecraft:GetBool() then return end
	local hdrscale = render.GetToneMappingScaleLinear()
	render.SetToneMappingScaleLinear(inkhdrscale) -- Set HDR scale for custom lightmap
	render.SetMaterial(rt.Material) -- Ink base texture
	render.SetLightmapTexture(rt.Lightmap) -- Set custom lightmap
	render.OverrideDepthEnable(true, true) -- Write to depth buffer for translucent surface culling
	for i, m in ipairs(ss.IMesh) do m:Draw() end -- Draw ink surface
	render.OverrideDepthEnable(false) -- Back to default
	render.SetToneMappingScaleLinear(hdrscale) -- Back to default

	if not LocalPlayer():FlashlightIsOn() and #ents.FindByClass "*projectedtexture*" == 0 then return end
	render.PushFlashlightMode(true) -- Ink lit by player's flashlight or projected texture
	render.SetMaterial(rt.Material) -- Ink base texture
	for i, m in ipairs(ss.IMesh) do m:Draw() end -- Draw once again
	render.PopFlashlightMode() -- Back to default
end

function ss.ReceiveInkQueue(index, radius, ang, ratio, color, inktype, pos, order, tick)
	if color == 0 or inktype == 0 then return end
	local s = ss.SurfaceArray[index]
	local angle = Angle(s.Angles)
	if s.Moved then angle:RotateAroundAxis(s.Normal, -90) end
	local pos2d = ss.To2D(pos, s.Origin, angle) * ss.UnitsToPixels
	local b = s.Bound * ss.UnitsToPixels
	local bound_offset = Vector(0, b.x, 0)
	if s.Moved then
		b.x, b.y = b.y, b.x
		pos2d = bound_offset - pos2d
	end
	
	local start = Vector(s.u, s.v) * ss.UVToPixels
	local center = Vector(math.Round(pos2d.x + start.x), math.Round(pos2d.y + start.y))
	local endpos = Vector(math.ceil(start.x + b.x) + 1, math.ceil(start.y + b.y) + 1)
	start = Vector(math.floor(start.x) - 1, math.floor(start.y) - 1)
	local r = radius * ss.UnitsToPixels
	local vr = ss.vector_one * r
	if not ss.CollisionAABB2D(start, endpos, center - vr, center + vr) then return end
	local lightmapoffset = r / 2
	ss.PaintQueue[tick * 512 + order + 256] = {
		angle = ang,
		center = center,
		color = ss.GetColor(color),
		colorid = color,
		done = 0,
		endpos = endpos,
		height = 2 * r,
		lightmapradius = r,
		lightmapx = center.x - lightmapoffset,
		lightmapy = center.y - lightmapoffset,
		pos = pos,
		radius = radius,
		ratio = ratio,
		start = start,
		surf = s,
		t = inktype,
		width = 2 * r * ratio,
	}
end

local function ProcessPaintQueue()
	while not rt.Ready do coroutine.yield() end
	local NumRepetition = 4
	local Painted = 0
	local Benchmark = SysTime()
	local BaseTexture = rt.BaseTexture
	local Lightmap = rt.Lightmap
	local ceil = math.ceil
	local Clamp = math.Clamp
	local Lerp = Lerp
	local next = next
	local PaintQueue = ss.PaintQueue
	local SortedPairs = SortedPairs
	local SysTime = SysTime
	local yield = coroutine.yield

	local Start2D = cam.Start2D
	local End2D = cam.End2D
	local OverrideBlend = render.OverrideBlend
	local PushRenderTarget = render.PushRenderTarget
	local PopRenderTarget = render.PopRenderTarget
	local SetScissorRect = render.SetScissorRect
	local DrawTexturedRect = surface.DrawTexturedRect
	local DrawTexturedRectRotated = surface.DrawTexturedRectRotated
	local SetDrawColor = surface.SetDrawColor
	local SetMaterial = surface.SetMaterial
	local IsNotSplatoonPortedMap = not ss.SplatoonMapPorts[game.GetMap()]
	local LightmapSampleNum = 7 -- Used to sample lightmap
	local RadianFraction = math.rad(360 / LightmapSampleNum)
	while true do
		Benchmark = SysTime()
		NumRepetition = ceil(Lerp(Painted / MAX_QUEUES_TOLERANCE, 4, 0))
		for order, q in SortedPairs(PaintQueue) do
			local alpha = Clamp(NumRepetition - q.done, 1, 4)
			if q.t > 12 then alpha = 1 end
			local inkmaterial = inkmaterials[q.t][alpha]
			
			PushRenderTarget(BaseTexture)
			Start2D()
			SetDrawColor(q.color)
			SetMaterial(inkmaterial)
			SetScissorRect(q.start.x, q.start.y, q.endpos.x, q.endpos.y, true)
			OverrideBlend(true, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)
			DrawTexturedRectRotated(q.center.x, q.center.y, q.width, q.height, q.angle)
			OverrideBlend(false)
			SetScissorRect(0, 0, 0, 0, false)
			End2D()
			PopRenderTarget()
			
			--Draw on lightmap
			if IsNotSplatoonPortedMap then
				PushRenderTarget(Lightmap)
				SetScissorRect(q.start.x, q.start.y, q.endpos.x, q.endpos.y, true)
				Start2D()
				SetDrawColor(LightmapSample(q.pos, q.surf.Normal))
				OverrideBlend(true, BLEND_ONE_MINUS_DST_ALPHA, BLEND_DST_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)
				DrawTexturedRectRotated(q.center.x, q.center.y, q.width, q.height, q.angle)
				OverrideBlend(false)
				-- SetMaterial(lightmapbrush)
				-- local offset = q.lightmapradius / 2
				-- local sign = q.surf.Moved and -1 or 1
				-- for i = 1, LightmapSampleNum do
				-- 	local rx = math.cos(RadianFraction * i) * offset * sign
				-- 	local ry = math.sin(RadianFraction * i) * offset
				-- 	local rv = Vector(rx, ry) * ss.PixelsToUnits
				-- 	SetDrawColor(LightmapSample(ss.To3D(rv, q.pos, q.surf.Angles), q.surf.Normal))
				-- 	DrawTexturedRectRotated(rx + q.center.x, ry + q.center.y, q.lightmapradius, q.lightmapradius, 0)
				-- end
				End2D()
				SetScissorRect(0, 0, 0, 0, false)
				PopRenderTarget()
			end

			q.done = q.done + 1
			Painted = Painted + 1
			if q.done > NumRepetition then
				ss.AddInkRectangle(q.colorid, q.t, q.angle, q.pos, q.radius, q.ratio, q.surf)
				PaintQueue[order] = nil
			end

			if SysTime() - Benchmark > MAX_QUEUE_TIME then break end
			-- if ss.Debug then ss.Debug.ShowInkDrawn(q.start, q.center, q.endpos, q.surf, q, q.surf.Moved) end
		end

		Painted = 0
		yield()
	end
end

local function ProcessLightmapSampling()
	while not rt.Ready do coroutine.yield() end
	local Lightmap = rt.Lightmap
	local SysTime = SysTime
	local Vector = Vector
	local Angle = Angle
	local RotateAroundAxis = Angle().RotateAroundAxis
	local yield = coroutine.yield
	local PushRenderTarget = render.PushRenderTarget
	local PopRenderTarget = render.PopRenderTarget
	local SetScissorRect = render.SetScissorRect
	local SetMaterial = surface.SetMaterial
	local SetDrawColor = surface.SetDrawColor
	local DrawTexturedRect = surface.DrawTexturedRect
	local NoTexture = draw.NoTexture
	local Start2D = cam.Start2D
	local End2D = cam.End2D
	local ceil = math.ceil
	local floor = math.floor
	local ipairs = ipairs
	local next = next
	local To3D = ss.To3D
	local UnitsToPixels = ss.UnitsToPixels
	local UVToPixels = ss.UVToPixels
	local Benchmark = SysTime()
	local LIGHTMAP_RADIUS = 512 -- Pixels
	while LIGHTMAP_RADIUS > 16 do
		local LIGHTMAP_SIZE = LIGHTMAP_RADIUS * 2
		for _, i in ipairs(ss.SortedSurfaceIDs) do
			local s = ss.SurfaceArray[i]
			if s.Displacement then
				local angle = Angle(s.Angles)
				local b = s.Bound * UnitsToPixels
				local bound_offset = Vector(0, b.x, 0)
				if s.Moved then
					RotateAroundAxis(angle, s.Normal, -90)
					b.x, b.y = b.y, b.x
				end

				local start = Vector(floor(s.u * ss.UVToPixels) - 1, floor(s.v * ss.UVToPixels) - 1)
				local endpos = Vector(ceil(start.x + b.x) + 1, ceil(start.y + b.y) + 1)
				local function ContinueYield()
					SetScissorRect(0, 0, 0, 0, false)
					End2D()
					PopRenderTarget()
					yield()
					PushRenderTarget(Lightmap)
					Start2D()
					SetScissorRect(start.x, start.y, endpos.x, endpos.y, true)
					NoTexture()
				end

				PushRenderTarget(Lightmap)
				Start2D()
				SetScissorRect(start.x, start.y, endpos.x, endpos.y, true)
				NoTexture()
				for x = start.x, endpos.x, LIGHTMAP_SIZE do
					for y = start.y, endpos.y, LIGHTMAP_SIZE do
						local pixel2d = Vector(x + LIGHTMAP_RADIUS - start.x, y + LIGHTMAP_RADIUS - start.y)
						local pos3d = To3D(pixel2d * ss.PixelsToUnits, s.Origin, angle)
						SetDrawColor(LightmapSample(pos3d, s.Normal))
						DrawTexturedRect(x, y, LIGHTMAP_SIZE, LIGHTMAP_SIZE)
						if SysTime() - Benchmark > 0.1 then ContinueYield() end
					end
				end
				SetScissorRect(0, 0, 0, 0, false)
				End2D()
				PopRenderTarget()
			end
		end

		LIGHTMAP_RADIUS = LIGHTMAP_RADIUS / 2
	end
end

local process = coroutine.create(ProcessPaintQueue)
function ss.ClearAllInk()
	table.Empty(ss.InkQueue)
	table.Empty(ss.PaintSchedule)
	if rt.Ready then table.Empty(ss.PaintQueue) end
	for _, s in ipairs(ss.SurfaceArray) do table.Empty(s.InkSurfaces) end
	local amb = ss.AmbientColor
	if not amb then
		amb = render.GetAmbientLightColor():ToColor()
		ss.AmbientColor = amb
	end

	render.PushRenderTarget(rt.BaseTexture)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(0, 0, 0, 0)
	render.OverrideAlphaWriteEnable(false)
	render.PopRenderTarget()
	
	render.PushRenderTarget(rt.Lightmap)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(amb.r, amb.g, amb.b, 0)
	render.OverrideAlphaWriteEnable(false)
	render.PopRenderTarget()
end

hook.Add("Tick", "SplatoonSWEPs: Register ink clientside", function()
	if coroutine.status(process) == "dead" then return end
	local ok, msg = coroutine.resume(process)
	if not ok then ErrorNoHalt(msg) end
end)

hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Draw ink", DrawMeshes)
