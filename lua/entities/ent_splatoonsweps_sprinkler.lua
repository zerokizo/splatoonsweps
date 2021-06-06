
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.SubWeaponName = "sprinkler"
ENT.Model = Model "models/props_splatoon/weapons/subs/sprinkler/sprinkler.mdl"
ENT.Base = "ent_splatoonsweps_splatbomb"
ENT.HitSound = "SplatoonSWEPs.SubWeaponPut"
ENT.ExplosionOffset = 10

if CLIENT then return end
function ENT:Initialize()
    self.BaseClass.Initialize(self)
    self:PhysicsInitSphere(32)
    self:PhysWake()
    local p = self:GetPhysicsObject()
    if not IsValid(p) then return end
    p:EnableDrag(false)
    p:EnableGravity(false)
end

function ENT:Think()
    self:NextThink(CurTime())
    return true
end

function ENT:PhysicsUpdate(p)
    if self.RemoveFlag then return end
    if IsValid(self.ContactEntity) then
        p:SetPos(self.ContactEntity:LocalToWorld(self.ContactOffset))
        p:SetAngles(self.ContactEntity:LocalToWorldAngles(self.ContactAngles))
        return
    elseif self.ContactEntity == NULL then
        self.ContactEntity = nil
        p:EnableMotion(true)
    end

    self.BaseClass.PhysicsUpdate(self, p)
end

function ENT:PhysicsCollide(data, collider)
    if self.RemoveFlag then return end
    self.BaseClass.PhysicsCollide(self, data, collider)
    local n = -data.HitNormal
    local ang = n:Angle()
    local v = collider:GetVelocity()
    local v2d = v - n * n:Dot(v)
    local vn = v2d:GetNormalized()
    local dot = vn:Dot(ang:Right())
    local sign = vn:Dot(ang:Up()) > 0 and -1 or 1
    local deg = math.deg(math.acos(dot)) * sign
    ang:RotateAroundAxis(ang:Forward(), deg)
    ang:RotateAroundAxis(ang:Right(), -90)
    collider:EnableMotion(false)
    collider:SetPos(data.HitPos)
    collider:SetAngles(ang)
    timer.Simple(0, function() self:SetCollisionGroup(COLLISION_GROUP_WORLD) end)
    if not self.ContactStartTime then self.ContactStartTime = CurTime() end
    self.HitNormal = -data.HitNormal
    self.ContactEntity = data.HitEntity
    self.ContactOffset = data.HitEntity:WorldToLocal(data.HitPos)
    self.ContactAngles = data.HitEntity:WorldToLocalAngles(ang)
    self:SetNWFloat("t0", CurTime())
    self:SetNWBool("hit", true)
end
