
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.Type = "anim"
ENT.ContactTotalTime = 0

local Burst_WaitFrm = 30 * ss.FrameToSec
local Burst_WarnFrm = 30 * ss.FrameToSec
local BurstTotalFrame = Burst_WaitFrm + Burst_WarnFrm
local Fly_AirFrm = 4 * ss.FrameToSec
local Fly_Gravity = 0.16 * ss.ToHammerUnitsPerSec2
local Fly_RotKd = 0.98015 -- Assume that angle velocity is multiplied by this once per frame
local Fly_VelKd = 0.94134 -- Assume that velocity is multiplied by this once per frame
local mdl = Model "models/splatoonsweps/subs/splat_bomb/splat_bomb.mdl"
function ENT:Initialize()
    self:SetModel(mdl)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self.DragCoeffChangeTime = CurTime() + Fly_AirFrm
    self.TraceVector = -vector_up * self:BoundingRadius() / 2
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
    if self:GetContactTime() < BurstTotalFrame then return end
    ss.MakeBombExplosion(self:GetPos(), self.Owner, self:GetNWInt "inkcolor")
    self.RemoveFlag = true
end

function ENT:Think()
    self:NextThink(CurTime())
    local p = self:GetPhysicsObject()
    if not IsValid(p) then return true end

    local t = self:GetContactTime()
    if t > Burst_WaitFrm then -- Brighten and inflate it
        local f = math.Clamp(math.TimeFraction(Burst_WaitFrm, BurstTotalFrame, t), 0, 1)
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

local prev
local pt = 0
function ENT:PhysicsUpdate(p) -- Apply 1.5x gravity
    if CurTime() < self.DragCoeffChangeTime then return end

    -- Gravity
    local g_dir = physenv.GetGravity():GetNormalized()
    p:AddVelocity(g_dir * Fly_Gravity * FrameTime())
    
    -- Linear drag for X/Y axis
    local v = p:GetVelocity()
    if v.z < 0 then v.z = 0 end
    p:AddVelocity(v * (Fly_VelKd - 1))

    -- Angular drag
    local a = p:GetAngleVelocity()
    p:AddAngleVelocity(a * (Fly_RotKd - 1))
end

function ENT:PhysicsCollide(data, collider)
    if self.RemoveFlag then return end
    if self.ContactStartTime then return end
    if -data.HitNormal.z < ss.MAX_COS_DIFF then return end
    self.ContactStartTime = CurTime()
end
