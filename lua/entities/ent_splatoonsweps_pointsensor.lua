
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.SubWeaponName = "pointsensor"
ENT.Base = "ent_splatoonsweps_burstbomb"
ENT.Model = Model "models/props_splatoon/weapons/subs/point_sensor/point_sensor.mdl"

if CLIENT then return end
function ENT:PhysicsCollide(data, collider)
    local params = ss.pointsensor.Parameters
    local rnear = params.Burst_Radius_Near
    local rmid = params.Burst_Radius_Middle
    local dnear = params.Burst_Damage_Near
    local dmid = params.Burst_Damage_Middle
    local dfar = params.Burst_Damage_Far
    local ddirecthit = dfar + dmid
    
    self:StopSound "SplatoonSWEPs.SubWeaponThrown"
    self:EmitSound(ss.pointsensor.BurstSound)
    SafeRemoveEntity(self)
end
