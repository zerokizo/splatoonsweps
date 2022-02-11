
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
    local props = vgui.Create("DProperties")
    local frame = vgui.Create("DFrame")
    -- local entpos = LocalPlayer():GetPos()
    local mins, maxs = bb.mins, bb.maxs
    -- local sky3d = GetConVar "r_3dsky"
    -- local sky2d = GetConVar "r_drawskybox"
    -- local sky = util.QuickTrace(entpos, vector_up * 32768, LocalPlayer())
    local scale = 2048
    local relx = 0
    local rely = 0
    local shiftx = (maxs.x + mins.x) / 2 / scale
    local shifty = (maxs.y + mins.y) / 2 / scale
    local shiftz = (maxs.z + 1) / scale
    local fov = math.deg(math.atan2(math.max(maxs.x, maxs.y, -mins.x, -mins.y) / scale, shiftz))
    -- local menuopen = false
    local zooming = false
    local msx = maxs.y - mins.y
    local msy = maxs.x - mins.x
    local msxy = math.max(msx, msy)
    props:Dock(FILL)
    frame:SetSize(900 * msx / msy, 900)
    frame:Center()
    frame:MakePopup()
    frame:SetTitle("Splatoon SWEPs: Minimap")
    frame.Paint = function(s, w, h)
        surface.SetDrawColor(118, 200, 227, 100)
        surface.DrawRect(0, 0, w, h)
    end

    -- local progress = vgui.Create("DProgress", frame)
    -- progress:Dock(TOP)
    -- progress.Think = function(s)
    --     s:SetFraction(1 - math.max(self:GetNWFloat("nextuse") - CurTime(), 0))
    -- end

    local panel = vgui.Create("DButton", frame)
    panel:Dock(FILL)
    panel:SetText("")
    panel:SetSize(600, 600)

    -- panel.DoClick = function(s)
        -- local x, y = s:GetPos()
        -- local x1, y1 = s:GetParent():GetPos()

        -- local x = x + x1
        -- local y = y + y1

        -- local sizex, sizey = s:GetSize()

        -- net.Start("rebel_mortar_msg")
        -- net.WriteEntity(self)
        -- net.WriteVector(Vector(shiftx, shifty, shiftz) * scale)
        -- net.WriteVector(util.AimVector(Angle(90, 0, 0), fov, gui.MouseX() - x, gui.MouseY() - y, sizex, sizey))
        -- net.WriteInt(attack, 8)
        -- net.SendToServer()
    -- end

    panel.Think = function(s)
        local x, y = s:GetPos()
        local x1, y1 = s:GetParent():GetPos()

        x = x + x1
        y = y + y1

        local sizex, sizey = s:GetSize()

        relx = ((gui.MouseX() - x) - sizex * 0.5) / (sizex * 0.5)
        rely = ((gui.MouseY() - y) - sizey * 0.5) / (sizey * 0.5)

        if math.abs(relx) < 1.01 && math.abs(rely) < 1.01 then
            if not zooming then
                local en = 0.6
                local sense = 3

                if relx > en then
                    shifty = shifty - RealFrameTime() * Lerp((relx - en) / en, 0, sense)
                elseif relx < -en then
                    shifty = shifty + RealFrameTime() * Lerp((-relx - en) / en, 0, sense)
                end

                if rely > en then
                    shiftx = shiftx - RealFrameTime() * Lerp((rely - en) / en, 0, sense)
                elseif rely < -en then
                    shiftx = shiftx + RealFrameTime() * Lerp((-rely - en) / en, 0, sense)
                end
            end

            zooming = false

            if input.IsMouseDown(MOUSE_RIGHT) then
                zooming = true

                local en = 0.3
                local sense = 1

                if rely > en then
                    shiftz = shiftz - RealFrameTime() * Lerp((rely - en) / en, 0, sense)
                elseif rely < -en then
                    shiftz = shiftz + RealFrameTime() * Lerp((-rely - en) / en, 0, sense)
                end
            end

            if not input.IsKeyDown(KEY_LSHIFT) then frame:Close() end
            -- if(input.IsKeyDown(KEY_R) && !IsValid(menu)) then
            --     menu = DermaMenu()
            --     menu:AddOption("Headcrab Canister", function() attack = 0 end)
            --     menu:AddOption("Explosion", function() attack = 1 end)
            --     menu:AddOption("Combine Warp Cannon", function() attack = 2 end)
            --     menu:AddOption("Napalm", function() attack = 3 end)
            --     menu:AddOption("Meteor strike", function() attack = 4 end)
            --     menu:AddOption("Rocket strike", function() attack = 5 end)
            --     menu:AddOption("Dropship Assault", function() attack = 6 end)
            --     menu:AddOption("Gunship Patrol", function() attack = 7 end)
            --     menu:AddOption("Dropship Strider Assault", function() attack = 7 end)
            --     menu:Open()

            --     menuopen = true
            -- end
        end
    end

    -- local matMaterial = Material "pp/texturize"
    -- local texturize = "pp/texturize/plain.png"
    -- local pMaterial = Material(texturize)
    panel.Paint = function(s, w, h)
        local x, y = s:GetPos()
        local x1, y1 = s:GetParent():GetPos()

        x = x + x1
        y = y + y1

        local oldclip = DisableClipping(true)
        local orthoscale = msxy / 2
        ss.DisableRenderingSkyBox = true
        render.RenderView {
            drawviewmodel = false,
            origin = Vector(shiftx, shifty, shiftz) * scale,
            angles = Angle(90, 0, 0),
            aspectratio = msx / msy,
            fov = fov,
            x = x, y = y,
            w = w, h = h,
            ortho = {
                left   = -1 * orthoscale,
                right  =  1 * orthoscale,
                top    = -1 * orthoscale * msy / msx,
                bottom =  1 * orthoscale * msy / msx,
            },
            znear = 2,
            zfar = 32768,
        }

        -- render.CopyRenderTargetToTexture(render.GetScreenEffectTexture())
        -- matMaterial:SetFloat("$scalex", w / 2048)
        -- matMaterial:SetFloat("$scaley", h / 2048 / 8)
        -- matMaterial:SetTexture("$basetexture", pMaterial:GetTexture "$basetexture")
        -- render.SetMaterial(matMaterial)
        -- render.SetScissorRect(x, y, x + w, y + h, true)
        -- render.DrawScreenQuad()
        -- render.SetScissorRect(0, 0, 0, 0, false)
        ss.DisableRenderingSkyBox = false
        DisableClipping(oldclip)
    end
end

hook.Remove("HUDPaint", "test", function()
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
    -- shiftx = LocalPlayer():GetPos().x
    -- shifty = LocalPlayer():GetPos().y
    -- shiftz = LocalPlayer():GetPos().z + LocalPlayer():OBBMaxs().z + 10
    -- shiftx = 0
    -- shifty = 0
    -- shiftz = 0
    local width = 900
    local x, y, w, h = 0, 0, width * msx / msy, width
    local orthoscale = msxy / 2
    -- orthoscale = 800
    debugoverlay.Axis(Vector(), Angle(), 100, FrameTime() * 2, true)
    ss.DisableRenderingSkyBox = true
    -- render.ClearStencil()
    -- render.SetStencilEnable(true)
    -- render.SetStencilWriteMask(255)
    -- render.SetStencilTestMask(255)
    -- render.SetStencilReferenceValue(255)
    -- render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
    -- render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)
    -- render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
    -- render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
    -- render.SuppressEngineLighting(true)
    -- render.SetColorModulation(0, 1, 0)
    -- render.SetBlend(0.4)

    render.RenderView {
        drawviewmodel = false,
        origin = Vector(shiftx, shifty, shiftz),
        angles = Angle(90, 0, 0),
        aspectratio = msx / msy,
        -- fov = fov,
        x = x, y = y,
        w = w, h = h,
        ortho = {
            left   = -1 * orthoscale,
            right  =  1 * orthoscale,
            top    = -1 * orthoscale * msy / msx,
            bottom =  1 * orthoscale * msy / msx,
        },
        znear = 2,
        zfar = 32768,
    }
    -- render.SuppressEngineLighting(false)
    -- render.SetColorModulation(1, 1, 1)
    -- render.SetBlend(1)
    -- render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
    -- render.SetStencilEnable(false)
    ss.DisableRenderingSkyBox = false
end)

hook.Add("PreDrawSkyBox", "SplatoonSWEPs: Disable rendering skybox in a minimap", function()
    if ss.DisableRenderingSkyBox then return true end
end)
hook.Remove("CalcView", "waterbug", function(ply, pos, angles, fov)
    if not ss.DisableRenderingSkyBox then return end
    return {
        znear = 1,
        zfar = 32768,
        ortho = {
            left   = -ScrW(),
            right  = ScrW(),
            top    = -ScrH(),
            bottom = ScrH()
        }
    }
end)
