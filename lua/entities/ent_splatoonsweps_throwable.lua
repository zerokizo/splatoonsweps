
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.CollisionGroup = COLLISION_GROUP_PASSABLE_DOOR
ENT.Model = Model "models/splatoonsweps/subs/splat_bomb/splat_bomb.mdl"
ENT.Type = "anim"
ENT.UseSubWeaponFilter = true
ENT.WeaponClassName = ""

hook.Add("ShouldCollide", "SplatoonSWEPs: Sub weapon filter", function(e1, e2)
    if e2.UseSubWeaponFilter then e1, e2 = e2, e1 end
    if e2.UseSubWeaponFilter then return false end
    if not e1.UseSubWeaponFilter then return end
    if not IsValid(e1.Owner) then return end
    local w1 = ss.IsValidInkling(e1.Owner)
    local w2 = ss.IsValidInkling(e2)
    if not (w1 and w2) then return end
    if ss.IsAlly(w1, w2) then return false end
end)

function ENT:Initialize()
    if IsValid(self.Owner) then
        local w = ss.IsValidInkling(self.Owner)
        if w then self.WeaponClassName = w:GetClass() end
    end

    self:SetModel(self.Model)
    self:SetCollisionGroup(self.CollisionGroup)
    self:SetCustomCollisionCheck(true)
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
