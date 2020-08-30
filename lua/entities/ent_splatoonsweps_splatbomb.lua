
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.Type = "anim"
ENT.ContactTotalTime = 0
local mdl = Model "models/splatoonsweps/subs/splat_bomb/splat_bomb.mdl"
function ENT:Initialize()
    local p = ss.splatbomb.Parameters
    self:SetModel(mdl)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self.BurstTotalFrame = p.Burst_WaitFrm + p.Burst_WarnFrm
    self.DragCoeffChangeTime = CurTime() + p.Fly_AirFrm
    self.Parameters = p
    if CLIENT then return end
    self:PhysicsInit(SOLID_VPHYSICS)
    self:PhysWake()
    local p = self:GetPhysicsObject()
    if not IsValid(p) then return end
    p:EnableDrag(false)
    p:EnableGravity(false)
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
    ss.MakeBombExplosion(self:GetPos(), self.Owner, self:GetNWInt "inkcolor", self.Parameters)
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
    else
        self.ContactStartTime = nil
        self.ContactTotalTime = t
    end
    
    if not self.RemoveFlag then return true end
    self:Remove()
    return true
end

function ENT:PhysicsUpdate(p)
    local fix = FrameTime() * ss.SecToFrame
    
    -- Linear drag for X/Y axis
    local v = p:GetVelocity()
    if v.z < 0 then v.z = 0 end
    p:AddVelocity(v * (self.Parameters.Fly_VelKd - 1) * fix)

    -- Angular drag
    local a = p:GetAngleVelocity()
    p:AddAngleVelocity(a * (self.Parameters.Fly_RotKd - 1) * fix)

    if CurTime() < self.DragCoeffChangeTime then return end

    -- Gravity
    local g_dir = ss.GetGravityDirection()
    p:AddVelocity(g_dir * self.Parameters.Fly_Gravity * FrameTime() * fix)
end

function ENT:PhysicsCollide(data, collider)
    if self.RemoveFlag then return end
    if self.ContactStartTime then return end
    if data.HitNormal:Dot(ss.GetGravityDirection()) < ss.MAX_COS_DIFF then return end
    self.ContactStartTime = CurTime()
end
