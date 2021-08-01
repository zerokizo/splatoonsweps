
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.AutomaticFrameAdvance = true
ENT.Base = "ent_splatoonsweps_throwable"
ENT.Model = Model "models/splatoonsweps/subs/splashwall/splashwall.mdl"
ENT.SubWeaponName = "splashwall"
ENT.IsFirstTimeContact = true

function ENT:IsStuck()
    return IsValid(self.ContactEntity)
    or isentity(self.ContactEntity) and self.ContactEntity:IsWorld()
end

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
end

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "InkColorProxy")
end

function ENT:OnRemove()
    self.RunningSound:Stop()
end

function ENT:TracePaint()
    local t = util.QuickTrace(self:GetPos(), -vector_up * 10, self)
    if not t.Hit then return end
    ss.Paint(t.HitPos, t.HitNormal, self.TracePaintRadius, self:GetNWInt "inkcolor",
    self:GetAngles().yaw + 90, math.random(10, 12), 0.5, self.Owner, self.WeaponClassName)
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

    return true
end

function ENT:PhysicsCollide(data, collider)
    if self:IsStuck() then return end
    collider:EnableMotion(not data.HitEntity:IsWorld())
    collider:SetPos(data.HitPos)
    timer.Simple(0, function()
        if not IsValid(self) then return end
        if not IsValid(data.HitEntity) then return end
        constraint.Weld(self, data.HitEntity, 0,
        self:FindBoneFromPhysObj(data.HitEntity, data.HitObject), 0, false, false)
    end)
    if not self.ContactStartTime then
        self.ContactStartTime = CurTime()
    end
    self.HitNormal = -data.HitNormal
    self.ContactEntity = data.HitEntity
    
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
