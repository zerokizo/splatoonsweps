
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model "models/splatoonsweps/subs/splat_bomb/splat_bomb.mdl"
ENT.WeaponClassName = ""
function ENT:Initialize()
    if IsValid(self.Owner) then
        local w = ss.IsValidInkling(self.Owner)
        if w then self.WeaponClassName = w:GetClass() end
    end

    self:SetModel(self.Model)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self.DragCoeffChangeTime = CurTime() + self.StraightFrame
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
function ENT:PhysicsUpdate(p)
    local fix = FrameTime() * ss.SecToFrame
    -- Linear drag for X/Y axis
    p:AddVelocity(p:GetVelocity() * self.AirResist * fix)

    -- Angular drag
    local a = p:GetAngleVelocity()
    p:AddAngleVelocity(a * self.AngleAirResist * fix)

    if CurTime() < self.DragCoeffChangeTime then return end

    -- Gravity
    local g_dir = ss.GetGravityDirection()
    p:AddVelocity(g_dir * self.Gravity * FrameTime() * fix)
end
