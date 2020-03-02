
-- Clientside ink manager

local ss = SplatoonSWEPs
if not ss then return end
local amb = render.GetAmbientLightColor() * .3
local amblen = amb:Length() * .3
if amblen > 1 then amb = amb / amblen end
local ambscale = ss.GrayScaleFactor:Dot(amb) / 2
local CVarWireframe = GetConVar "mat_wireframe"
local CVarMinecraft = GetConVar "mat_showlowresimage"
local lightmapmaterial = Material "splatoonsweps/lightmapbrush"
local inkhdrscale = ss.vector_one * .05
local inkmaterials = {}
local normalmaterials = {}
for i = 1, 12 do
	inkmaterials[i] = {}
	normalmaterials[i] = {}
	for j = 1, 4 do
		inkmaterials[i][j] = Material(("splatoonsweps/inkshot/%d/%d.vmt"):format(i, j))
		normalmaterials[i][j] = Material(("splatoonsweps/inkshot/%d/%dn.vmt"):format(i, j))
	end
end

local rt = ss.RenderTarget
local world = game.GetWorld()
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

function ss.ClearAllInk()
	table.Empty(ss.InkQueue)
	table.Empty(ss.PaintSchedule)
	if rt.Ready then table.Empty(ss.PaintQueue) end
	local amb = ss.AmbientColor
	if not amb then
		amb = render.GetAmbientLightColor():ToColor()
		ss.AmbientColor = amb
	end

	for _, s in ipairs(ss.SurfaceArray) do table.Empty(s.InkSurfaces) end

	render.PushRenderTarget(rt.BaseTexture)
	render.OverrideAlphaWriteEnable(true, true)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(0, 0, 0, 0)
	render.OverrideColorWriteEnable(false)
	render.PopRenderTarget()

	render.PushRenderTarget(rt.Lightmap)
	render.ClearDepth()
	render.ClearStencil()
	render.Clear(amb.r, amb.g, amb.b, 255)
	render.PopRenderTarget()
end

function ss.InkQueueReceiveFunction(index, radius, ang, ratio, color, ply, inktype, pos, order, tick)
	local s = ss.SurfaceArray[index]
	local angle = Angle(s.Angles)
	if s.Moved then angle:RotateAroundAxis(s.Normal, -90) end
	local pos2d = ss.To2D(pos, s.Origin, angle) * ss.UnitsToPixels
	local b = s.Bound * ss.UnitsToPixels
	if s.Moved then
		b.x, b.y = b.y, b.x
		pos2d.x, pos2d.y = -pos2d.x, b.y - pos2d.y
	end

	local r = math.Round(radius * ss.UnitsToPixels)
	local uv = Vector(s.u, s.v) * ss.UVToPixels
	local center = Vector(math.Round(pos2d.x + uv.x), math.Round(pos2d.y + uv.y))
	local start = Vector(math.floor(uv.x) - 1, math.floor(uv.y) - 1)
	local endpos = Vector(math.ceil(uv.x + b.x) + 1, math.ceil(uv.y + b.y) + 1)
	local vr = ss.vector_one * r
	if not ss.CollisionAABB2D(start, endpos, center - vr, center + vr) then return end
	ss.PaintQueue[tick * 512 + order + 256] = {
		angle = ang,
		center = center,
		color = ss.GetColor(color),
		colorid = color,
		done = 0,
		endpos = endpos,
		ply = ply,
		pos = pos,
		radius = radius,
		ratio = ratio,
		size = 2 * r,
		start = start,
		surf = s,
		t = inktype,
	}
end

local function ProcessPaintQueue()
	while not rt.Ready do coroutine.yield() end
	local NumRepetition = 4
	local Painted = 0
	local Benchmark = SysTime()
	local BaseTexture = rt.BaseTexture
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
	local MAX_QUEUE_TIME = ss.FrameToSec / 2
	local MAX_QUEUES_TOLERANCE = 5 -- Possible number of queues to be processed at once without losing FPS.
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
			DrawTexturedRectRotated(q.center.x, q.center.y, q.size * q.ratio, q.size, q.angle)
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

local process = coroutine.create(ProcessPaintQueue)
hook.Add("Tick", "SplatoonSWEPs: Register ink clientside", function()
	if coroutine.status(process) == "dead" then return end
	local ok, msg = coroutine.resume(process)
	if not ok then ErrorNoHalt(msg) end
end)

hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Draw ink", DrawMeshes)
