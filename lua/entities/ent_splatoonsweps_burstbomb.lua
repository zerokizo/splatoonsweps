
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.SubWeaponName = "burstbomb"
ENT.Base = "ent_splatoonsweps_throwable"
ENT.Model = Model "models/props_splatoon/weapons/subs/burst_bombs/burst_bomb.mdl"

function ENT:Initialize()
    local p = ss[self.SubWeaponName].Parameters
    self.Parameters = p
    self.StraightFrame = p.Fly_AirFrm
    self.AirResist = p.Fly_VelKd - 1
    self.AngleAirResist = p.Fly_RotKd - 1
    self.Gravity = p.Fly_Gravity
    local base = self.BaseClass
    while base.ClassName ~= "ent_splatoonsweps_throwable" do base = base.BaseClass end
    base.Initialize(self)
    if CLIENT then return end
    self:GetPhysicsObject():SetMass(0.001)
end

if CLIENT then return end
function ENT:PhysicsCollide(data, collider)
    local params = ss.burstbomb.Parameters
    local rnear = params.Burst_Radius_Near
    local rmid = params.Burst_Radius_Middle
    local dnear = params.Burst_Damage_Near
    local dmid = params.Burst_Damage_Middle
    local dfar = params.Burst_Damage_Far
    local ddirecthit = dfar + dmid
    ss.burstbomb.GetDamage = function(dist, ent)
        if ent == data.HitEntity then return ddirecthit end
        if dist < rmid then return dmid end
        return dfar
    end

    ss.MakeBombExplosion(self:GetPos(), -data.HitNormal, self, self:GetNWInt "inkcolor", "burstbomb")
    self:StopSound "SplatoonSWEPs.SubWeaponThrown"
    SafeRemoveEntity(self)
end
