
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.SubWeaponName = "disruptor"
ENT.Base = "ent_splatoonsweps_burstbomb"
ENT.Model = Model "models/props_splatoon/weapons/subs/disruptor/disruptor.mdl"

if CLIENT then return end
function ENT:PhysicsCollide(data, collider)
    local p = ss.disruptor.Parameters
    
    self:StopSound "SplatoonSWEPs.SubWeaponThrown"
    self:EmitSound(ss.disruptor.BurstSound)
    SafeRemoveEntity(self)
    for _, e in ipairs(ents.FindInSphere(self:GetPos(), p.Burst_Radius)) do
        local w = ss.IsValidInkling(e)
        if e:IsPlayer() then ss.EmitSound(e, "SplatoonSWEPs.DisruptorTaken") end
        if not (w and ss.IsAlly(self, w)) then
            hit = true
            e:SetNWBool("SplatoonSWEPs: IsDisrupted", true)
            e:SetNWFloat("SplatoonSWEPs: DisruptorEndTime", CurTime() + ss.DisruptorDuration)
        end
    end
end
