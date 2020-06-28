
print "SplatoonSWEPs: Splat bomb is loading"
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return {} end

-- Parameters are from Splatoon 2 ver. 5.2.0, https://leanny.github.io/splat2new/parameters.html
local module = {}
local p = {
    BringCloseRateCrossVec = 0.7,
    BringCloseRateMoveVec = 0.7,
    Burst_Damage_Far = 0.3,
    Burst_Damage_Near = 1.8,
    Burst_KnockBackCoreImpact = 3,
    Burst_KnockBackKb = 0.8,
    Burst_KnockBackRadius = 120,
    Burst_PaintR = 40,
    Burst_Radius_Far = 70,
    Burst_Radius_Near = 40,
    Burst_SeFrm = 10,
    Burst_SplashAroundFuzzyRate = 2,
    Burst_SplashNum = 15,
    Burst_SplashOfstY = 5,
    Burst_SplashPaintR = 10,
    Burst_SplashPitH = 45,
    Burst_SplashPitL = 5,
    Burst_SplashVelH = 5.4,
    Burst_SplashVelL = 4.8,
    Burst_WaitFrm = 30,
    Burst_WarnFrm = 30,
    CollisionSeSilentFrame = 4,
    CollisionSeVelDotGndNrm = 0.08,
    CollisionSeVelDotGndTimes = 1.2,
    CrossPaintRadius = 20,
    CrossPaintRayLength = 20,
    CrossPaintRayRadius = 1,
    EffectShakeRange = 100,
    Fly_AirFrm = 4,
    Fly_CeilingKf_Y = 1,
    Fly_CeilingKr_Y = 0.5,
    Fly_Gravity = 0.16,
    Fly_InitPit = 0.4,
    Fly_InitRol = 0.12,
    Fly_RotI = 20,
    Fly_RotKd = 0.98015,
    Fly_VelKd = 0.94134,
    Fly_WallKf_XZ = 0.7,
    Fly_WallKf_Y = 0.2,
    Fly_WallKr = 0.2,
    ForceSleepFrame = 900,
    InkConsume = 0.7,
    Land_AbsorveRt = 0.1,
    Land_GndKf = 0.2,
    Land_GndKr = 0.05,
    Land_GravGndK = 0.5,
    Land_GravH = 0.08,
    Land_GravKf = 0.1,
    Land_GravL = 0.016,
    Land_NrmGndKf = 0.1,
    Land_RotI = 10,
    Land_RotKd = 0.96059,
    Land_VelKdXZ = 0.92237,
    Land_VelKdY = 0.92237,
    Shape_SphereD = 5,
    Shape_SphereR = 2,

    -- Parameters from Player_Spec_BombDistance_Up.param
    BombThrow_VelZ_Low = 2.8,
    BombThrow_VelZ_Mid = 3.5,
    BombThrow_VelZ_High = 4.2,
}

function module:SharedSecondaryAttack(throwable)
    
end

function module:CanSecondaryAttack()
    return self:GetInk() > p.InkConsume * ss.MaxInkAmount
end

if SERVER then
    function module:ServerSecondaryAttack(throwable)
        local tr = util.QuickTrace(self:GetShootPos(), self:GetAimVector() * self.Range, self.Owner)
        local e = ents.Create "ent_splatoonsweps_splatbomb"
        e.Owner = self.Owner
        e:SetNWInt("inkcolor", self:GetNWInt "inkcolor")
        e:SetInkColorProxy(self:GetInkColorProxy())
        e:SetPos(self:GetShootPos())
        e:Spawn()

        local ph = e:GetPhysicsObject()
        if IsValid(ph) then
            local dir = self:GetAimVector()
            local speed_amount = 11.2 * ss.ToHammerUnitsPerSec -- From Splatoon 2 ability effect database
            local speed_mul = 2 / 3 -- Distance unit between Splatoon 2 and Splatoon seems to be difficult.
            speed_amount = speed_amount * speed_mul
            ph:AddVelocity(dir * speed_amount + vector_up * speed_amount * 0.2 + self:GetVelocity())
            ph:AddAngleVelocity(Vector(-math.deg(p.Fly_InitRol), math.deg(p.Fly_InitPit), 0) * ss.SecToFrame)
            ph:SetAngles(dir:Angle())
        end

        self:SetInk(math.max(0, self:GetInk() - p.InkConsume * ss.MaxInkAmount))
        self:SetReloadDelay(40 * ss.FrameToSec)
    end
else
    function module:DrawOnSubTriggerDown()
        local start = self:GetShootPos()
        local endpos = start + self:GetAimVector() * self.Range
        local color = ss.GetColor(self:GetNWInt "inkcolor")
        render.SetColorMaterial()
        render.DrawBeam(start + self:GetRight() * 2 - vector_up, endpos, 1, 0, 1, color)
    end

    function module:ClientSecondaryAttack(throwable)

    end
end

return module
