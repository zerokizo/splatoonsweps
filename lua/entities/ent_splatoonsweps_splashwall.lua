
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.AutomaticFrameAdvance = true
ENT.Base = "ent_splatoonsweps_throwable"
ENT.Model = Model "models/splatoonsweps/subs/splashwall/splashwall.mdl"
ENT.SubWeaponName = "splashwall"
ENT.IsFirstTimeContact = true

function ENT:Initialize()
    local p = ss[self.SubWeaponName].Parameters
    self.Parameters = p
    self.StraightFrame = p.Fly_AirFrm
    self.AirResist = p.Fly_VelKd - 1
    self.AngleAirResist = p.Fly_RotKd - 1
    self.GravityHold = p.Fly_Gravity
    self.Gravity = p.Fly_Gravity
    self.HitNormal = vector_up
    self.CollisionSeSilentFrame = p.CollisionSeSilentFrame or math.huge
    self.DragCoeffChangeTime = CurTime() + self.StraightFrame
    self.BaseClass.Initialize(self)
    self.RunningSound = CreateSound(self, ss.SplashWallRunning)
    self:SetSequence "folded"
    self:SetUnfolded(false)
    if SERVER then return end
    self.ParticleEffects = {}
end

function ENT:SetupDataTables()
    self:NetworkVar("Bool", 0, "Unfolded")
    self:NetworkVar("Vector", 0, "InkColorProxy")
end

function ENT:OnRemove()
    local p = self:GetPos()
    local n = self.HitNormal
    local e = EffectData()
    e:SetOrigin(p)
    e:SetNormal(n)
    e:SetScale(3)
    e:SetMagnitude(2)
    e:SetRadius(5)
    util.Effect("Sparks", e)
    self:EmitSound "SplatoonSWEPs.SubWeaponDestroy"
    if self.RunningSound then self.RunningSound:Stop() end
end

function ENT:TracePaint()
    local t = util.QuickTrace(self:GetPos(), -vector_up * 10, self)
    if not t.Hit then return end
    ss.Paint(t.HitPos, t.HitNormal, self.TracePaintRadius, self:GetNWInt "inkcolor",
    self:GetAngles().yaw + 90, math.random(10, 12), 0.5, self.Owner, self.WeaponClassName)
end

if CLIENT then
    ENT.NextEmissionTime = CurTime()
    ENT.EmissionInterval = 0.2
    function ENT:Think()
        self:SetNextClientThink(CurTime())
        if not self:GetUnfolded() then return true end
        if #self.ParticleEffects > 0 then return end
        if CurTime() < self.NextEmissionTime then return true end
        self.NextEmissionTime = CurTime() + self.EmissionInterval

        local scale = 8
        local color = ss.GetColor(self:GetNWInt "inkcolor"):ToVector()
        for i, att in ipairs(self:GetAttachments()) do
            local p = CreateParticleSystem(self, ss.Particles.SplashWall, PATTACH_POINT_FOLLOW, att.id, self:GetPos())
            p:AddControlPoint(1, game.GetWorld(), PATTACH_WORLDORIGIN, nil, color)
            p:AddControlPoint(2, game.GetWorld(), PATTACH_WORLDORIGIN, nil, vector_up * scale)
            self.ParticleEffects[i] = p
        end

        return true
    end

    return
end

-- TODO: 塗り替えす
ENT.NextPaintTime = CurTime()
ENT.PaintInterval = 0.05
ENT.PreviousPaintAt = nil
function ENT:Paint()
    if not self:GetUnfolded() then return end
    if CurTime() < self.NextPaintTime then return end
    self.NextPaintTime = CurTime() + self.PaintInterval

    local radius = self.Parameters.mPaintWidth / 2
    local inkcolor = self:GetNWInt "inkcolor"
    local dz = self:OBBMaxs().z
    local paintPos = {}
    for i, att in ipairs(self:GetAttachments()) do
        local a = self:GetAttachment(att.id)
        local t = util.QuickTrace(a.Pos, a.Ang:Forward() * dz)
        if ss.GetSurfaceColor(t) ~= inkcolor then
            table.insert(paintPos, t.HitPos)
        end
    end

    for _, p in ipairs(paintPos) do
        local sign = math.random() > 0.5 and 1 or -1
        ss.Paint(p, vector_up, radius, inkcolor, self:GetAngles().yaw + 90 * sign,
        ss.GetDropType(), 1, self.Owner, self.WeaponClassName)
    end
end

function ENT:Think()
    self:NextThink(CurTime())
    local p = self:GetPhysicsObject()
    if not IsValid(p) then return true end
    -- if CurTime() > self.NextTracePaintTime then
    --     self.NextTracePaintTime = CurTime() + self.TracePaintInterval
    --     self:TracePaint()
    -- end
    if not self.ContactStartTime then return end
    local t = CurTime() - self.ContactStartTime
    if t > self.Parameters.mNoDamageRunningDurationFrame then
        self:Remove()
    end

    local i = self:GetFlexIDByName "InkAmount"
    self:SetFlexWeight(i, t / self.Parameters.mNoDamageRunningDurationFrame)

    if self:GetSequenceName(self:GetSequence()) == "unfolding" and self:GetCycle() == 1 then
        self:ResetSequence "idle"
        self:SetUnfolded(true)
    end

    self:Paint()

    return true
end

function ENT:PhysicsCollide(data, collider)
    if self:IsStuck() then return end

    if -data.HitNormal.z < 0.7 then
        local v = Vector(data.OurOldVelocity)
        local dot = v:Dot(data.HitNormal)
        v = v - data.HitNormal * dot * 2
        collider:SetAngleVelocityInstantaneous(vector_origin)
        collider:SetVelocityInstantaneous(v)
        return
    end

    collider:EnableMotion(not data.HitEntity:IsWorld())
    collider:SetPos(data.HitPos)
    collider:SetAngles(Angle(0, collider:GetAngles().yaw, 0))
    timer.Simple(0, function()
        if not IsValid(self) then return end
        if not IsValid(data.HitEntity) then return end
        local phys = self:FindBoneFromPhysObj(data.HitEntity, data.HitObject)
        constraint.Weld(self, data.HitEntity, 0, phys, 0, false, false)
    end)

    self.HitNormal = -data.HitNormal
    self.ContactEntity = data.HitEntity
    if not self.ContactStartTime then
        self.ContactStartTime = CurTime()
    end
    
    if self.IsFirstTimeContact then
        self.IsFirstTimeContact = false
        self:EmitSound "SplatoonSWEPs.SplashWallDeploy"
        self:ResetSequence "unfolding"
        timer.Simple(self.Parameters.mPreparationDurationFrame, function()
            if not IsValid(self) then return end
            self.RunningSound:Play()
        end)
    end
end
