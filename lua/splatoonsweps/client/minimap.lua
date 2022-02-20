
local ss = SplatoonSWEPs
if not ss then return end
function ss.OpenMiniMap()
    local bb
    for i, t in ipairs(ss.MinimapAreaBounds) do
        if LocalPlayer():GetPos():WithinAABox(t.mins, t.maxs) then
            bb = t
            break
        end
    end

    if not bb then return end
    local mins, maxs = bb.mins, bb.maxs
    local msx = maxs.y - mins.y
    local msy = maxs.x - mins.x
    local msxy = math.max(msx, msy)
    local shiftx = (maxs.x + mins.x) / 2
    local shifty = (maxs.y + mins.y) / 2
    local shiftz = maxs.z + 1
    local orthoscale = msxy / 2

    local props = vgui.Create("DProperties")
    local frame = vgui.Create("DFrame")
    props:Dock(FILL)
    frame:SetSize(900 * msx / msy, 900)
    frame:Center()
    frame:MakePopup()
    frame:SetTitle("Splatoon SWEPs: Minimap")
    frame.Paint = function(s, w, h)
        surface.SetDrawColor(118, 200, 227, 100)
        surface.DrawRect(0, 0, w, h)
    end

    local panel = vgui.Create("DButton", frame)
    panel:Dock(FILL)
    panel:SetText("")
    panel:SetSize(600, 600)

    local toggle = true
    local keydown = input.IsKeyDown(KEY_LSHIFT)
    panel.Think = function(s)
        local k = input.IsKeyDown(KEY_LSHIFT)
        if Either(toggle, not keydown and k, not k) then frame:Close() end
        keydown = k
    end

    panel.Paint = function(s, w, h)
        local x, y = s:GetPos()
        local x1, y1 = s:GetParent():GetPos()
        x, y = x + x1, y + y1
        ss.IsDrawingMinimap = true
        render.RenderView {
            drawviewmodel = false,
            origin = Vector(shiftx, shifty, shiftz),
            angles = Angle(90, 0, 0),
            aspectratio = msx / msy,
            x = x, y = y,
            w = w, h = h,
            ortho = {
                left   = -1 * orthoscale,
                right  =  1 * orthoscale,
                top    = -1 * orthoscale * msy / msx,
                bottom =  1 * orthoscale * msy / msx,
            },
            znear = 1,
            zfar = 32768,
        }
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
