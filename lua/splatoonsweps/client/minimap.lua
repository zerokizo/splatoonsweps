
local ss = SplatoonSWEPs
if not ss then return end

local toggle = true
local cos, sin, rad = math.cos, math.sin, math.rad
function ss.OpenMiniMap()
    local bb
    for i, t in ipairs(ss.MinimapAreaBounds) do
        if LocalPlayer():GetPos():WithinAABox(t.mins, t.maxs) then
            bb = t
            break
        end
    end

    if not bb then return end
    local inclined = true
    local inclinedYaw = 30
    local inclinedPitch = 30
    local angleRate = 90
    local upAngle = Angle(90, 0, 0)
    local inclinedAngle = Angle(90 - inclinedPitch, inclinedYaw, 0)
    local desiredAngle = Angle(inclinedAngle)
    local currentAngle = Angle(desiredAngle)
    local mins, maxs = bb.mins, bb.maxs
    local bbsize = maxs - mins
    local org = Vector(mins.x, mins.y, maxs.z + 1)
    local props = vgui.Create("DProperties")
    local frame = vgui.Create("DFrame")
    local panel = vgui.Create("DButton", frame)
    props:Dock(FILL)
    frame:SetSizable(true)
    frame:SetSize(ScrH(), ScrH())
    frame:Center()
    frame:MakePopup()
    frame:SetTitle("Splatoon SWEPs: Minimap")
    panel:Dock(FILL)
    panel:SetText("")

    local keydown = input.IsKeyDown(KEY_LSHIFT)
    function panel:Think()
        local k = input.IsKeyDown(KEY_LSHIFT)
        if Either(toggle, not keydown and k, not k) then frame:Close() end
        keydown = k
    end

    function panel:DoClick()
        inclined = not inclined
        desiredAngle = inclined and inclinedAngle or upAngle
    end

    function panel:Paint(w, h)
        currentAngle.yaw = math.ApproachAngle(currentAngle.yaw, desiredAngle.yaw, angleRate * RealFrameTime())
        currentAngle.pitch = math.ApproachAngle(currentAngle.pitch, desiredAngle.pitch, angleRate * RealFrameTime())
        local x, y = self:LocalToScreen(0, 0)
        local left = -bbsize.y * cos(rad(currentAngle.yaw))
        local right = bbsize.x * sin(rad(currentAngle.yaw))
        local top = -bbsize.z * sin(rad(90 - currentAngle.pitch))
        local bottom = bbsize.x * cos(rad(currentAngle.yaw)) + bbsize.y * sin(rad(currentAngle.yaw)) + bbsize.z * sin(rad(90 - currentAngle.pitch))
        local width = right - left
        local height = bottom - top
        local aspectratio = w / h
        local addMarginAxisY = aspectratio < (width / height)
        if addMarginAxisY then
            local diff = width / aspectratio - height
            local margin = diff / 2
            top = top - margin
            bottom = bottom + margin
        else
            local diff = height * aspectratio - width
            local margin = diff / 2
            left = left - margin
            right = right + margin
        end
        ss.IsDrawingMinimap = true
        render.PushCustomClipPlane(Vector( 0,  0, -1), -maxs.z - 0.5)
        render.PushCustomClipPlane(Vector( 0,  0,  1),  mins.z - 0.5)
        render.PushCustomClipPlane(Vector(-1,  0,  0), -maxs.x - 0.5)
        render.PushCustomClipPlane(Vector( 1,  0,  0),  mins.x - 0.5)
        render.PushCustomClipPlane(Vector( 0, -1,  0), -maxs.y - 0.5)
        render.PushCustomClipPlane(Vector( 0,  1,  0),  mins.y - 0.5)
        render.RenderView {
            drawviewmodel = false,
            origin = org,
            angles = currentAngle,
            aspectratio = aspectratio,
            x = x, y = y,
            w = w, h = h,
            ortho = {
                left   = left,
                right  = right,
                top    = top,
                bottom = bottom,
            },
            znear = 1,
            zfar = 56756,
        }
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()
        ss.IsDrawingMinimap = false
    end
end

local WaterMaterial = Material "gm_construct/water_13_beneath"
hook.Add("PreDrawTranslucentRenderables", "SplatoonSWEPs: Draw water surfaces", function(bDrawingDepth, bDrawingSkybox)
    if not ss.IsDrawingMinimap then return end
    render.SetMaterial(WaterMaterial)
    for i, m in ipairs(ss.WaterMesh) do m:Draw() end
    render.OverrideDepthEnable(true, true)
    render.UpdateRefractTexture()
    render.SetMaterial(ss.GetWaterMaterial())
    for i, m in ipairs(ss.WaterMesh) do m:Draw() end
    render.OverrideDepthEnable(false)
end)

hook.Add("PreDrawSkyBox", "SplatoonSWEPs: Disable rendering skybox in a minimap", function()
    if ss.IsDrawingMinimap then return true end
end)
