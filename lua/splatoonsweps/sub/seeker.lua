
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return {} end
ss.seeker = {
    Merge = {
        IsSubWeaponThrowable = false,
    },
    Parameters = {
        Burst_Damage_Far = 0.3,
        Burst_Damage_Middle = 0.8,
        Burst_Damage_Near = 1.8,
        Burst_PaintR = 40,
        Burst_Radius_Far = 40,
        Burst_Radius_Middle = 38,
        Burst_Radius_Near = 32,
        Burst_SplashNum = 10,
        Burst_SplashOfstY = 3,
        Burst_SplashPaintR = 7,
        Burst_SplashPitH = 30,
        Burst_SplashPitL = 5,
        Burst_SplashVelH = 3.5,
        Burst_SplashVelL = 5.2,
        CrossPaintRadius = 20,
        CrossPaintRayLength = 20,
        Fly_AirFrm = 4,
        Fly_Gravity = 0.16,
        Fly_RotKd = 0.7,
        Fly_VelKd = 0.94134,
        InitInkRadius = 10,
        InkConsume = 0.8,
        
        Fly_InitVel_Estimated = 1.5,
    },
    Units = {
        Burst_Damage_Far = "hp",
        Burst_Damage_Near = "hp",
        Burst_PaintR = "du",
        Burst_Radius_Far = "du",
        Burst_Radius_Near = "du",
        Burst_SplashNum = "num",
        Burst_SplashOfstY = "du",
        Burst_SplashPaintR = "du",
        Burst_SplashPitH = "deg",
        Burst_SplashPitL = "deg",
        Burst_SplashVelH = "du/f",
        Burst_SplashVelL = "du/f",
        CrossPaintRadius = "du",
        CrossPaintRayLength = "du",
        Fly_AirFrm = "f",
        Fly_Gravity = "du/f^2",
        Fly_RotKd = "ratio",
        Fly_VelKd = "ratio",
        InitInkRadius = "du",
        InkConsume = "ink",
        
        Fly_InitVel_Estimated = "du/f",
    },
    BurstSound = "SplatoonSWEPs.BombExplosion",
    GetDamage = function(dist, ent)
        local params = ss.splatbomb.Parameters
        local rnear = params.Burst_Radius_Near
        local dnear = params.Burst_Damage_Near
        local dfar = params.Burst_Damage_Far
        return dist < rnear and dnear or dfar
    end,
}

ss.ConvertUnits(ss.seeker.Parameters, ss.seeker.Units)

local module = ss.seeker.Merge
local p = ss.seeker.Parameters
function module:SharedSecondaryAttack(throwable)
    
end

function module:CanSecondaryAttack()
    return self:GetInk() > p.InkConsume
end

function module:GetSubWeaponInkConsume()
    return p.InkConsume
end

function module:GetSubWeaponInitVelocity()
    local initspeed = p.Fly_InitVel_Estimated
    return self:GetAimVector() * initspeed
end

if SERVER then
    function module:ServerSecondaryAttack(throwable)
        local e = ents.Create "ent_splatoonsweps_seeker"
        e.Owner = self.Owner
        e:SetNWInt("inkcolor", self:GetNWInt "inkcolor")
        e:SetInkColorProxy(self:GetInkColorProxy())
        e:SetPos(self:GetShootPos())
        e:SetAngles(Angle(0, self:GetAimVector():Angle().yaw, 0))
        e:Spawn()
        local ph = e:GetPhysicsObject()
        if IsValid(ph) then
            ph:AddVelocity(self:GetSubWeaponInitVelocity() + self:GetVelocity())
        end

        self:SetInk(math.max(0, self:GetInk() - p.InkConsume))
        self:SetReloadDelay(70 * ss.FrameToSec)
    end
else
    function module:DrawOnSubTriggerDown()
        local seeker_search_deg = self:GetFOV() / 4
        local maxdot, ent = math.cos(math.rad(seeker_search_deg)), nil
        for _, e in ipairs(ents.GetAll()) do
            local w = ss.IsValidInkling(e)
            if (not w and e:Health() > 0
            and (e:IsPlayer() or e:IsNPC() or e:IsNextBot()))
            or w and not ss.IsAlly(self, w) then
                local dir = e:WorldSpaceCenter() - EyePos()
                dir:Normalize()
                local dot = dir:Dot(EyeAngles():Forward())
                if dot > maxdot then
                    maxdot = dot
                    ent = e
                end
            end
        end

        if self.SeekerPreviousTarget ~= ent then
            self.SeekerPreviousTarget = ent
            if ent then surface.PlaySound(ss.SeekerTargetChanged) end
        end
        if not ent then return end

        cam.Start2D()
        local c = ss.GetColor(ss.CrosshairColors[self:GetNWInt "inkcolor"])
        local p = self:TranslateToWorldmodelPos(ent:WorldSpaceCenter())
        local data = p:ToScreen()
        local x, y = data.x, data.y
        ss.DrawCrosshair.LinesHitBG(x, y, 0.4, 1)
        ss.DrawCrosshair.OuterCircleBG(x, y)
        ss.DrawCrosshair.OuterCircle(x, y, c)
        ss.DrawCrosshair.LinesHit(x, y, c, 0.4, 1)
        ss.DrawCrosshair.InnerCircle(x, y)
        cam.End2D()
    end

    function module:ClientSecondaryAttack(throwable)
        self.SeekerPreviousTarget = nil
    end
end
