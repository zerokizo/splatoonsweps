
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.Base = "ent_splatoonsweps_splatbomb"
ENT.HitSound = "SplatoonSWEPs.SubWeaponPut"
ENT.Model = Model "models/splatoonsweps/subs/sprinkler/sprinkler.mdl"
ENT.SubWeaponName = "sprinkler"

if CLIENT then return end
function ENT:Initialize()
    self.BaseClass.Initialize(self)
    self:SetMaxHealth(100)
    self:SetHealth(self:GetMaxHealth())
end

function ENT:OnTakeDamage(d)
    local health = self:Health()
    self:SetHealth(math.max(0, health - d:GetDamage()))
    if self:Health() > 0 then return d:GetDamage() end
    self:EmitSound "SplatoonSWEPs.SubWeaponDestroy"
    SafeRemoveEntity(self)

    local p = self:GetPos()
    local n = self.HitNormal
    timer.Simple(0, function()
        local e = EffectData()
        e:SetOrigin(p)
        e:SetNormal(n)
        e:SetScale(3)
        e:SetMagnitude(2)
        e:SetRadius(5)
        util.Effect("Sparks", e)
    end)
    
    return health
end

function ENT:Think() end
function ENT:PhysicsCollide(data, collider)
    if self.RemoveFlag then return end
    if self:IsStuck() then return end
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
    collider:SetPos(data.HitPos)
    collider:SetAngles(ang)
    timer.Simple(0, function()
        constraint.Weld(self, data.HitEntity, 0,
        self:FindBoneFromPhysObj(data.HitEntity, data.HitObject), 0, false, false)
    end)
    if not self.ContactStartTime then self.ContactStartTime = CurTime() end
    self.HitNormal = -data.HitNormal
    self.ContactEntity = data.HitEntity
    self:SetNWFloat("t0", CurTime())
    self:SetNWBool("hit", true)

    local inkcolor = self:GetNWInt "inkcolor"
    ss.Paint(data.HitPos, self.HitNormal, ss.sprinkler.Parameters.InitInkRadius,
    inkcolor, 0, ss.GetDropType(), 1, self.Owner, self:GetClass())

    if IsValid(self.DestroyOnLand) then
        local d = DamageInfo()
        d:SetDamage(self.DestroyOnLand:Health())
        self.DestroyOnLand:TakeDamageInfo(d)
    end
end
