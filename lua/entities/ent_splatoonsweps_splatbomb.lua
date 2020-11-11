
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.Base = "ent_splatoonsweps_throwable"
ENT.ContactTotalTime = 0
ENT.NextPlayHitSE = 0
ENT.WarnSoundPlayed = false
ENT.Model = Model "models/splatoonsweps/subs/splat_bomb/splat_bomb.mdl"

function ENT:Initialize()
    local p = ss.splatbomb.Parameters
    self.Parameters = p
    self.StraightFrame = p.Fly_AirFrm
    self.AirResist = p.Fly_VelKd - 1
    self.AngleAirResist = p.Fly_RotKd - 1
    self.Gravity = p.Fly_Gravity
    self.BurstTotalFrame = p.Burst_WaitFrm + p.Burst_WarnFrm
    self.HitNormal = vector_up

    self.BaseClass.Initialize(self)
    if CLIENT then return end
    self.WarnSound = CreateSound(self, ss.BombAlert)
end

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "InkColorProxy")
end

if CLIENT then return end
function ENT:GetContactTime()
    local t = self.ContactTotalTime
    if not self.ContactStartTime then return t end
    return t + CurTime() - self.ContactStartTime
end

function ENT:Detonate()
    if self.RemoveFlag then return end
    if self:GetContactTime() < self.BurstTotalFrame then return end
    ss.MakeBombExplosion(self:GetPos(), self.HitNormal, self, self:GetNWInt "inkcolor", "splatbomb")
    self:StopSound "SplatoonSWEPs.BombAlert"
    self.RemoveFlag = true
end

function ENT:Think()
    self:NextThink(CurTime())
    local p = self:GetPhysicsObject()
    if not IsValid(p) then return true end

    local t = self:GetContactTime()
    if t > self.Parameters.Burst_WaitFrm then -- Brighten and inflate it
        local f = math.Clamp(math.TimeFraction(self.Parameters.Burst_WaitFrm, self.BurstTotalFrame, t), 0, 1)
        local freq = 6 -- Hz
        local pulse = math.sin(2 * math.pi * t * freq)
        self:SetFlexWeight(0, f)
        self:SetSkin(pulse > 0 and 1 or 0)
    end
    

    if p:GetStress() > 0 then
        self:Detonate()
        if t > self.Parameters.CollisionSeSilentFrame then
            self.WarnSound:PlayEx(1, 100)
        end
    else
        self.ContactStartTime = nil
        self.ContactTotalTime = t
        self.WarnSound:PlayEx(1, 0)
    end
    
    if not self.RemoveFlag then return true end
    self:Remove()
    return true
end

function ENT:PhysicsCollide(data, collider)
    if self.RemoveFlag then return end
    if data.OurOldVelocity:LengthSqr() > 1000 and CurTime() > self.NextPlayHitSE then
        self:EmitSound "SplatoonSWEPs.SplatbombHitWorld"
        self.NextPlayHitSE = CurTime() + self.Parameters.CollisionSeSilentFrame
    end

    if self.ContactStartTime then return end
    if data.HitNormal:Dot(ss.GetGravityDirection()) < ss.MAX_COS_DIFF then return end
    self.HitNormal = -data.HitNormal
    self.ContactStartTime = CurTime()
end
