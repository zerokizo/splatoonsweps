
-- Clientside ink manager

local ss = SplatoonSWEPs
if not ss then return end
local CVarWireframe = GetConVar "mat_wireframe"
local CVarMinecraft = GetConVar "mat_showlowresimage"
local lightmapbrush = Material "splatoonsweps/lightmapbrush"
local inkhdrscale = ss.vector_one * .05
local inkmaterials = {}
local rt = ss.RenderTarget
local LightmapQueue = {}
local MAX_QUEUE_TIME = ss.FrameToSec / 4
local MAX_QUEUES_TOLERANCE = 5 -- Possible number of queues to be processed at once without losing FPS.
for i = 1, 12 do
	inkmaterials[i] = {}
	for j = 1, 4 do
		inkmaterials[i][j] = Material(("splatoonsweps/inkshot/%d/%d.vmt"):format(i, j))
	end
end

local amb = render.GetAmbientLightColor() * 0.25
local function LightmapSample(pos, normal)
	local p = pos + normal * 0.1
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
	
	local start = Vector(math.floor(s.u * ss.UVToPixels) - 1, math.floor(s.v * ss.UVToPixels) - 1)
	local center = Vector(math.Round(pos2d.x + start.x), math.Round(pos2d.y + start.y))
	local endpos = Vector(math.ceil(start.x + b.x) + 1, math.ceil(start.y + b.y) + 1)
	local r = radius * ss.UnitsToPixels
	local vr = ss.vector_one * r
	if not ss.CollisionAABB2D(start, endpos, center - vr, center + vr) then return end
	ss.PaintQueue[tick * 512 + order + 256] = {
		angle = ang,
		center = center,
		color = ss.GetColor(color),
		colorid = color,
		done = 0,
		endpos = endpos,
		height = 2 * r,
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
	local DrawTexturedRectRotated = surface.DrawTexturedRectRotated
	local SetDrawColor = surface.SetDrawColor
	local SetMaterial = surface.SetMaterial
	while true do
		Benchmark = SysTime()
		NumRepetition = ceil(Lerp(Painted / MAX_QUEUES_TOLERANCE, 4, 0))
		for order, q in SortedPairs(PaintQueue) do
			local alpha = Clamp(NumRepetition - q.done, 1, 4)
			if 10 <= q.t and q.t <= 12 then alpha = 1 end
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
						debugoverlay.Cross(pos3d, 5, 10, Color(0, 255, 0), true)
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
local lightmapsampling = coroutine.create(ProcessLightmapSampling)
function ss.ClearAllInk()
	local function SampleLightmap()
		util.TimerCycle()
		local amb = render.GetAmbientLightColor():ToColor()
		render.PushRenderTarget(rt.Lightmap)
		render.ClearDepth()
		render.ClearStencil()
		render.Clear(amb.r, amb.g, amb.b, 255)
		cam.Start2D()
		surface.SetMaterial(lightmapbrush)
		local gamma_recip, overbrightFactor = 1 / 2.2, 1
		local rgb_mul = (1 / 255)^gamma_recip * overbrightFactor
		local bsp = file.Open(("maps/%s.bsp"):format(game.GetMap()), "rb", "GAME")
		for _, s in ipairs(ss.SurfaceArray) do
			local li = s.LightmapInfo
			if li and not s.Displacement then
				local angle = Angle(s.Angles)
				local start = Vector(math.floor(s.u * ss.UVToPixels) - 1, math.floor(s.v * ss.UVToPixels - 1))
				local bound = s.Bound * ss.UnitsToPixels
				local bound_offset = Vector(0, bound.x, 0)
				if s.Moved then
					angle:RotateAroundAxis(s.Normal, -90)
					bound.x, bound.y = bound.y, bound.x
				end
			
				local endpos = Vector(math.ceil(start.x + bound.x) + 1, math.ceil(start.y + bound.y) + 1)
				local n, t1, t2 = s.Normal, Vector(li.VecS), Vector(li.VecT)
				local t1_unit, t2_unit = 1 / t1:Length(), 1 / t2:Length()
				local lightmap_org = Matrix {
					{t1.x, t1.y, t1.z, 0},
					{t2.x, t2.y, t2.z, 0},
					{ n.x,  n.y,  n.z, 0},
					{   0,    0,    0, 1},
				}:GetInverse() * Matrix {
					{li.Mins.x - li.OffsetS, 0, 0, 0},
					{li.Mins.y - li.OffsetT, 0, 0, 0},
					{       n:Dot(s.Origin), 0, 0, 0},
					{                     0, 0, 0, 0},
				}
				lightmap_org = Vector(
					lightmap_org:GetField(1, 1),
					lightmap_org:GetField(2, 1),
					lightmap_org:GetField(3, 1)
				)
				t1:Normalize()
				t2:Normalize()
			
				local tn = t1:Cross(t2)
				if n:Dot(tn) < 0 then tn = -tn end
				local t1_proj = t1 - tn * n:Dot(t1) / n:Dot(tn)
				local t2_proj = t2 - tn * n:Dot(t2) / n:Dot(tn)
				local w = t1_unit * t1_proj:Length() * ss.UnitsToPixels
				local h = t2_unit * t2_proj:Length() * ss.UnitsToPixels
				local size = 3
				local draw_offset = Vector(w, h) * size / 2
				w, h = math.ceil(w) * size, math.ceil(h) * size
				t1, t2 = t1 * t1_unit, t2 * t2_unit
				bsp:Seek(ss.LightmapTableOffset + li.Offset)
				render.SetScissorRect(start.x, start.y, endpos.x, endpos.y, true)
				for v = 0, li.Size.y do
					for u = 0, li.Size.x do
						local r = bsp:ReadByte()
						local g = bsp:ReadByte()
						local b = bsp:ReadByte()
						local e = bsp:ReadByte()
						if e > 127 then e = e - 256 end
						local dxy = t1 * u + t2 * v
						local pos3d = lightmap_org + dxy - tn * n:Dot(dxy) / n:Dot(tn)
						r = math.min(1, (r * 2^e)^gamma_recip * rgb_mul) * 255
						g = math.min(1, (g * 2^e)^gamma_recip * rgb_mul) * 255
						b = math.min(1, (b * 2^e)^gamma_recip * rgb_mul) * 255
						
						local pos2d = ss.To2D(pos3d, s.Origin, angle) * ss.UnitsToPixels
						if s.Moved then pos2d = bound_offset - pos2d end
						local p = start + pos2d - draw_offset
						surface.SetDrawColor(r, g, b)
						surface.DrawTexturedRect(p.x, p.y, w, h)
					end
				end
				render.SetScissorRect(0, 0, 0, 0, false)
			end
		end
		bsp:Close()
		cam.End2D()
		render.PopRenderTarget()
		print("Time to build mesh and sample lightmap[sec]:", util.TimerCycle() / 1000)
		lightmapsampling = coroutine.create(ProcessLightmapSampling)
	end

	table.Empty(ss.InkQueue)
	table.Empty(ss.PaintSchedule)
	if rt.Ready then table.Empty(ss.PaintQueue) end
	for _, s in ipairs(ss.SurfaceArray) do table.Empty(s.InkSurfaces) end

	render.PushRenderTarget(rt.BaseTexture)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(0, 0, 0, 0)
	render.OverrideAlphaWriteEnable(false)
	render.PopRenderTarget()
	timer.Simple(0, SampleLightmap)
end

hook.Add("Tick", "SplatoonSWEPs: Register ink clientside", function()
	if coroutine.status(process) == "dead" then return end
	local ok, msg = coroutine.resume(process)
	if not ok then ErrorNoHalt(msg) end
	if coroutine.status(lightmapsampling) == "dead" then return end
	ok, msg = coroutine.resume(lightmapsampling)
	if not ok then ErrorNoHalt(msg) end
end)

hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Draw ink", DrawMeshes)
