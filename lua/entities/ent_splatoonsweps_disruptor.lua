
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
        if w then
            w:SetIsDisrupted(true)
            w:SetDisruptorEndTime(CurTime() + ss.DisruptorDuration)
            if IsValid(w.Owner) then
                w.Owner:EmitSound "SplatoonSWEPs.DisruptorTaken"
            end
        end
    end
end
