
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.Type = "anim"

local Fly_AirFrm = 4 * ss.FrameToSec
local mdl = Model "models/splatoonsweps/subs/splat_bomb/splat_bomb.mdl"
function ENT:Initialize()
    self:SetModel(mdl)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self.DragCoeffChangeTime = CurTime() + Fly_AirFrm
    self.DragCoefficient = 0
    self.TraceVector = -vector_up * self:BoundingRadius() / 2
    if CLIENT then return end
    self:PhysicsInit(SOLID_VPHYSICS)
    self:PhysWake()
    local p = self:GetPhysicsObject()
    if not IsValid(p) then return end
    p:EnableDrag(false)
end

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "InkColorProxy")
end

if CLIENT then return end
function ENT:Detonate()
    if self.RemoveFlag then return end
    if not self.DetonateTime then return end
    if CurTime() < self.DetonateTime then return end
    ss.MakeBombExplosion(self:GetPos(), self.Owner, self:GetNWInt "inkcolor")
    self.RemoveFlag = true
end

function ENT:Think()
    if CurTime() > self.DragCoeffChangeTime then
        local p = self:GetPhysicsObject()
        if IsValid(p) then
            local intensity = CurTime() - self.DragCoeffChangeTime
            self.DragCoefficient = intensity * 50
            p:EnableDrag(true)
            p:SetDragCoefficient(self.DragCoefficient)
            p:SetAngleDragCoefficient(self.DragCoefficient)
        end
    end

    if util.QuickTrace(self:GetPos(), self.TraceVector, self).Hit then
        self:Detonate()
    end

    if not self.RemoveFlag then return end
    self:Remove()
end

function ENT:PhysicsUpdate(p) -- Apply 1.5x gravity
    if CurTime() < self.DragCoeffChangeTime then return end
    local g = physenv.GetGravity()
    local g_dir = g:GetNormalized()
    local g_len = g:Length()
    local g_desired = 0.16 * ss.ToHammerUnitsPerSec2
    local g_amount = g_desired - g_len
    local m = p:GetMass()
    local dt = FrameTime()
    local drag = self.DragCoefficient * p:GetVelocity().z
    p:ApplyForceCenter(g_dir * g_amount * m * dt)
    p:ApplyForceCenter(vector_up * drag * dt)
end

function ENT:PhysicsCollide(data, collider)
    if self.RemoveFlag then return end
    if -data.HitNormal.z < ss.MAX_COS_DIFF then return end
    self.DetonateTime = self.DetonateTime or (CurTime() + 1)
    self:Detonate()
end
