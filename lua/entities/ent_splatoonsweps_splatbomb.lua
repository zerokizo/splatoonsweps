
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.Type = "anim"

local mdl = Model "models/props_splatoon/weapons/subs/splat_bombs/splat_bomb.mdl"
function ENT:Initialize()
    self:SetModel(mdl)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    if CLIENT then return end
    self:PhysicsInit(SOLID_VPHYSICS)
    self:PhysWake()
end

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "InkColorProxy")
end

if CLIENT then return end

function ENT:Detonate()
    if not self.DetonateTime then return end
    if CurTime() < self.DetonateTime then return end
    ss.MakeBombExplosion(self:GetPos(), self.Owner, self:GetNWInt "inkcolor")
    self.RemoveFlag = true
end

function ENT:Think()
    if util.QuickTrace(self:GetPos(), -vector_up * 12, self).Hit then self:Detonate() end
    if not self.RemoveFlag then return end
    self:Remove()
end

function ENT:PhysicsCollide(data, collider)
    if self.RemoveFlag then return end
    if -data.HitNormal.z < ss.MAX_COS_DIFF then return end
    self.DetonateTime = self.DetonateTime or (CurTime() + 1)
    self:Detonate()
end
