
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.SubWeaponName = "disruptor"
ENT.Base = "ent_splatoonsweps_burstbomb"
ENT.Model = Model "models/props_splatoon/weapons/subs/disruptor/disruptor.mdl"

if CLIENT then return end
function ENT:PhysicsCollide(data, collider)
    local params = ss.disruptor.Parameters
    local rnear = params.Burst_Radius_Near
    local rmid = params.Burst_Radius_Middle
    local dnear = params.Burst_Damage_Near
    local dmid = params.Burst_Damage_Middle
    local dfar = params.Burst_Damage_Far
    local ddirecthit = dfar + dmid
    
    self:StopSound "SplatoonSWEPs.SubWeaponThrown"
    self:EmitSound(ss.disruptor.BurstSound)
    SafeRemoveEntity(self)
end
