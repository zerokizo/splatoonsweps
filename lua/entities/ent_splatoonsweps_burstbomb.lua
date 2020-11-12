
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.Base = "ent_splatoonsweps_throwable"
ENT.Model = Model "models/props_splatoon/weapons/subs/burst_bombs/burst_bomb.mdl"
hook.Add("ShouldCollide", "SplatoonSWEPs: Burst bomb filter", function(e1, e2)
    if e2:GetClass() == "ent_splatoonsweps_burstbomb" then e1, e2 = e2, e1 end
    if e1:GetClass() ~= "ent_splatoonsweps_burstbomb" then return end
    if not IsValid(e1.Owner) then return end
    local w1 = ss.IsValidInkling(e1.Owner)
    local w2 = ss.IsValidInkling(e2)
    if not (w1 and w2) then return end
    if ss.IsAlly(w1, w2) then return false end
end)

function ENT:Initialize()
    local p = ss.burstbomb.Parameters
    self.Parameters = p
    self.StraightFrame = p.Fly_AirFrm
    self.AirResist = p.Fly_VelKd - 1
    self.AngleAirResist = p.Fly_RotKd - 1
    self.Gravity = p.Fly_Gravity
    self.BaseClass.Initialize(self)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    self:SetCustomCollisionCheck(true)
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
