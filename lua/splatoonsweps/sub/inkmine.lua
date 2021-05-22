
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return {} end
ss.inkmine = {
    Merge = {
        IsSubWeaponThrowable = false,
        NumInkmines = 0,
    },
    Parameters = {
        Burst_Damage_Far = 0.3,
        Burst_Damage_Near = 1.8,
        Burst_PaintR = 40,
        Burst_Radius_Far = 70,
        Burst_Radius_Near = 40,
        Burst_SplashNum = 0,
        Burst_SplashOfstY = 0,
        Burst_SplashPaintR = 0,
        Burst_SplashPitH = 0,
        Burst_SplashPitL = 0,
        Burst_SplashVelH = 0,
        Burst_SplashVelL = 0,
        CrossPaintRadius = 20,
        CrossPaintRayLength = 20,
        Fly_Gravity = 0.16,
        Fly_VelKd = 0.94134,
        InitInkRadius = 10,
        InkConsume = 0.6,
        MaxInkmines = 1,
        PlayerColRadius = 30,
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
        Fly_Gravity = "du/f^2",
        Fly_VelKd = "ratio",
        InitInkRadius = "du",
        InkConsume = "ink",
        MaxInkmines = "num",
        PlayerColRadius = "du",
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

ss.ConvertUnits(ss.inkmine.Parameters, ss.inkmine.Units)

local module = ss.inkmine.Merge
local p = ss.inkmine.Parameters
function module:CanSecondaryAttack()
    return self:GetInk() > p.InkConsume
end

function module:GetSubWeaponInkConsume()
    return p.InkConsume
end

if CLIENT then return end
function module:ServerSecondaryAttack(throwable)
    if not self.Owner:OnGround() then return end
    if self.NumInkmines >= p.MaxInkmines then return end
    local start = self.Owner:GetPos()
    local tracedz = -vector_up * p.CrossPaintRayLength
    local tr = util.QuickTrace(start, tracedz, self.Owner)
    if not tr.Hit then return end

    local inkcolor = self:GetNWInt "inkcolor"
    local e = ents.Create "ent_splatoonsweps_inkmine"
    local ang = (tr.Hit and tr.HitNormal or vector_up):Angle()
    ang:RotateAroundAxis(ang:Right(), -90)
    e.Weapon = self
    e:SetOwner(self.Owner)
    e:SetNWInt("inkcolor", inkcolor)
    e:SetPos(tr.HitPos + tr.HitNormal * 9)
    e:SetAngles(ang)
    e:Spawn()
    self.NumInkmines = self.NumInkmines + 1
    self:SetInk(math.max(0, self:GetInk() - p.InkConsume))

    ss.Paint(tr.HitPos, tr.HitNormal, p.InitInkRadius,
    inkcolor, ang.yaw, ss.GetDropType(), 1, self.Owner, self:GetClass())
end
