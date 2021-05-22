
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return {} end
ss.pointsensor = {
    Merge = {
        IsSubWeaponThrowable = true,
    },
    Parameters = {
        BombDamage = 0.25,
        BringCloseRateCrossVec = 0.7,
        BringCloseRateMoveVec = 0.7,
        Burst_Damage_Far = 0.25,
        Burst_Damage_Middle = 0.35,
        Burst_Damage_Near = 0.35,
        Burst_KnockBackCoreImpact = 2,
        Burst_KnockBackKb = 0.8,
        Burst_KnockBackRadius = 80,
        Burst_PaintR = 40,
        Burst_Radius_Far = 40,
        Burst_Radius_Middle = 32,
        Burst_Radius_Near = 32,
        Burst_SplashAroundFuzzyRate = 2,
        Burst_SplashNum = 10,
        Burst_SplashOfstY = 3,
        Burst_SplashPaintR = 7,
        Burst_SplashPitH = 30,
        Burst_SplashPitL = 5,
        Burst_SplashVelH = 3.5,
        Burst_SplashVelL = 5.2,
        CrossPaintRadius = 14,
        CrossPaintRayLength = 14,
        CrossPaintRayRadius = 1,
        EffectShakeRange = 70,
        Fly_Gravity = 0.16,
        Fly_InitYaw = 0.4,
        Fly_RotI = 20,
        Fly_RotKd = 0.98015,
        Fly_VelKd = 0.94134,
        InkConsume = 0.4,
        Shape_SphereD = 5,
        Shape_SphereR = 2,

        -- Taken from Splat bomb
        Fly_InitVel_Estimated = 9.5,
        Fly_AirFrm = 4,
    },
    Units = {
        BombDamage = "hp",
        BringCloseRateCrossVec = "ratio",
        BringCloseRateMoveVec = "ratio",
        Burst_Damage_Far = "hp",
        Burst_Damage_Middle = "hp",
        Burst_Damage_Near = "hp",
        Burst_KnockBackCoreImpact = "-",
        Burst_KnockBackKb = "ratio",
        Burst_KnockBackRadius = "du",
        Burst_PaintR = "du",
        Burst_Radius_Far = "du",
        Burst_Radius_Middle = "du",
        Burst_Radius_Near = "du",
        Burst_SplashAroundFuzzyRate = "ratio",
        Burst_SplashNum = "num",
        Burst_SplashOfstY = "du",
        Burst_SplashPaintR = "du",
        Burst_SplashPitH = "deg",
        Burst_SplashPitL = "deg",
        Burst_SplashVelH = "du/f",
        Burst_SplashVelL = "du/f",
        CrossPaintRadius = "du",
        CrossPaintRayLength = "du",
        CrossPaintRayRadius = "du",
        EffectShakeRange = "du",
        Fly_Gravity = "du/f^2",
        Fly_InitYaw = "rad",
        Fly_RotI = "-",
        Fly_RotKd = "ratio",
        Fly_VelKd = "ratio",
        InkConsume = "ink",
        Shape_SphereD = "du",
        Shape_SphereR = "du",
    
        Fly_InitVel_Estimated = "du/f",
        Fly_AirFrm = "f",
    },
    BurstSound = "SplatoonSWEPs.PointSensor",
}

ss.ConvertUnits(ss.pointsensor.Parameters, ss.pointsensor.Units)

local module = ss.pointsensor.Merge
local p = ss.pointsensor.Parameters
function module:CanSecondaryAttack()
    return self:GetInk() > p.InkConsume
end

function module:GetSubWeaponInkConsume()
    return p.InkConsume
end

function module:GetSubWeaponInitVelocity()
    local initspeed = p.Fly_InitVel_Estimated
    return self:GetAimVector() * initspeed - ss.GetGravityDirection() * initspeed * 0.25
end

if CLIENT then return end
function module:ServerSecondaryAttack(throwable)
    local e = ents.Create "ent_splatoonsweps_pointsensor"
    e.Owner = self.Owner
    e:SetNWInt("inkcolor", self:GetNWInt "inkcolor")
    e:SetInkColorProxy(self:GetInkColorProxy())
    e:SetPos(self:GetShootPos() + self:GetAimVector() * 20)
    e:Spawn()
    e:EmitSound "SplatoonSWEPs.SubWeaponThrown"

    local ph = e:GetPhysicsObject()
    if IsValid(ph) then
        local dir = self:GetAimVector()
        ph:AddVelocity(self:GetSubWeaponInitVelocity() + self:GetVelocity())
        ph:AddAngleVelocity(Vector(0, 0, math.deg(p.Fly_InitYaw)) * ss.SecToFrame)
        ph:SetAngles(Angle(0, dir:Angle().yaw, 0))
    end

    self:ConsumeInk(p.InkConsume)
    self:SetReloadDelay(40 * ss.FrameToSec)
end
