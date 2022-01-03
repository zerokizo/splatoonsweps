
local ss = SplatoonSWEPs
if not ss then return end
include "shared.lua"

local crosshairalpha = 64
local originalres = 1920 * 1080
local hitline, hitwidth = 50, 3
local line, linewidth = 16, 3
local texlinesize = 128 / 2
local texlinewidth = 8 / 2
SWEP.Crosshair = {
    color_circle = ColorAlpha(color_black, crosshairalpha),
    color_nohit = ColorAlpha(color_white, crosshairalpha),
    color_hit = ColorAlpha(color_white, 192),
    Dot = 5, HitLine = 20, HitWidth = 2, -- in pixel
    Inside1 = 40, Inside2 = 46, Outside1 = 56, Outside2 = 64,
    InsideColored = 60, OutsideColored = 70,
    InsideCenter = 44, OutsideCenter = 52,
    HitLineSize = 114,
}

local function Spin(self, vm, weapon, ply)
    if self:GetCharge() < math.huge or self:GetFireInk() > 0 then
        local sgn = self:GetNWBool "lefthand" and 1 or -1
        local prog = self:GetFireInk() > 0 and self:GetFireAt() or self:GetChargeProgress(true)
        local b = self:LookupBone "rotate_1" or 0
        local a = self:GetManipulateBoneAngles(b)
        local dy = RealFrameTime() * 60 / self.Parameters.mRepeatFrame * (prog + .1)
        a.y = a.y + sgn * dy
        self:ManipulateBoneAngles(b, a)
        if not IsValid(vm) then return end
        local b = vm:LookupBone "rotate_1" or 0
        local a = vm:GetManipulateBoneAngles(b)
        a.y = a.y + sgn * dy
        vm:ManipulateBoneAngles(b, a)
    end

    if not IsValid(vm) then return end
    function vm.GetInkColorProxy()
        return ss.ProtectedCall(self.GetInkColorProxy, self) or ss.vector_one
    end
end

SWEP.PreViewModelDrawn = Spin
SWEP.PreDrawWorldModel = Spin

function SWEP:ClientInit()
    self.CrosshairFlashTime = CurTime()
    self.MinChargeDeg = self.Parameters.mMinChargeFrame / self.Parameters.mFirstPeriodMaxChargeFrame * 360
    self:GetBase().ClientInit(self)
    self:AddSchedule(0, function()
        local e = EffectData()
        local prog = self:GetChargeProgress()
        e:SetEntity(self)
        if prog == 1 and self.FullChargeFlag then
            self.FullChargeFlag = false
            self.CrosshairFlashTime = CurTime() - self:Ping()
            if self:IsMine() then self:EmitSound(ss.ChargerBeep, 75, 115) end
        elseif self.MediumCharge < prog and prog < 1 and not self.FullChargeFlag then
            self.FullChargeFlag = true
            self.CrosshairFlashTime = CurTime() - .1 - self:Ping()
            if self:IsMine() then self:EmitSound(ss.ChargerBeep) end
        end

        if not self:IsFirstTimePredicted() then return end
        local prog_predicted = self:GetChargeProgress(self:IsMine())
        if prog_predicted == 1 then
            if self.FullChargeFlagPredicted then
                e:SetScale(30)
                e:SetFlags(0)
                util.Effect("SplatoonSWEPsSplatlingSpinup", e)
                self.FullChargeFlagPredicted = false
            elseif CurTime() > self.SpinupEffectTime then
                self.SpinupEffectTime = CurTime() + .2
                e:SetScale(9)
                e:SetFlags(1)
                util.Effect("SplatoonSWEPsSplatlingSpinup", e)
            end
        elseif self.MediumCharge < prog_predicted and prog_predicted < 1 then
            if self.FullChargeFlagPredicted then return end
            e:SetScale(17.5)
            e:SetFlags(0)
            util.Effect("SplatoonSWEPsSplatlingSpinup", e)
            self.FullChargeFlagPredicted = true
        end
    end)
end

function SWEP:GetArmPos()
    return (self:GetADS() or ss.GetOption "doomstyle") and 5 or 1
end

function SWEP:DisplayAmmo()
    if self:GetCharge() == math.huge then return 0 end
    return math.max(self:GetChargeProgress(true) * 100, 0)
end

function SWEP:DrawFourLines(t, degx, degy)
    local frac = t.Trace.Fraction
    local bgcolor = t.IsSplatoon2 and t.Trace.Hit and self.Crosshair.color_nohit or color_white
    local forecolor = t.HitEntity and ss.GetColor(self:GetNWInt "inkcolor")
    local dir = self:GetAimVector() * t.Distance
    local org = self:GetShootPos()
    local right = EyeAngles():Right()
    local range = self.Range
    local adjust = not t.IsSplatoon2 and t.HitEntity
    local dx, dy = 0, 0
    if not t.IsSplatoon2 then
        local SPREAD_HITWALL = 5
        dx = t.HitPosScreen.x - t.EndPosScreen.x
        dy = t.HitPosScreen.y - t.EndPosScreen.y
        degx = Lerp(1 - frac, degx, SPREAD_HITWALL)
        degy = Lerp(1 - frac, degy, SPREAD_HITWALL)
        if t.HitEntity then
            bgcolor = Color(
                (forecolor.r + 512) / 3,
                (forecolor.g + 512) / 3,
                (forecolor.b + 512) / 3)
        end
    end

    ss.DrawCrosshair.SplatlingFourLinesAround(
    org, right, dir, range, degx, degy, dx, dy, adjust, bgcolor, forecolor)
end

function SWEP:DrawHitCross(t) -- Hit cross pattern, foreground
    if not t.HitEntity then return end
    local frac = 1 - (t.Distance / self:GetRange()) / 2
    ss.DrawCrosshair.SplatlingFourLines(
    t.HitPosScreen.x, t.HitPosScreen.y,
    frac, t.CrosshairDarkColor, t.CrosshairBrightColor)
end

function SWEP:DrawChargeCircle(t)
    local p = self.Parameters
    local prog = self:GetChargeProgress(true)
    local p1, p2 = 0, 0
    if self:GetFireInk() > 0 then
        local frac = math.max(self:GetNextPrimaryFire() - CurTime() - self:Ping(), 0) / p.mRepeatFrame
        local max1 = math.floor(p.mFirstPeriodMaxChargeShootingFrame  / p.mRepeatFrame) + 1
        local max2 = math.floor(p.mSecondPeriodMaxChargeShootingFrame / p.mRepeatFrame) + 1
        p1 = math.Clamp((self:GetFireInk() + frac) / max1, 0, 1) * 360
        p2 = math.Clamp((self:GetFireInk() + frac - max1) / (max2 - max1), 0, 1) * 360
    else
        p1 = math.min(prog / self.MediumCharge, 1) * (360 - self.MinChargeDeg) + self.MinChargeDeg
        p2 = math.Clamp((prog - self.MediumCharge) / (1 - self.MediumCharge), 0, 1) * 360
        if p1 <= self.MinChargeDeg then
            local frac = math.max(CurTime() - self:GetCharge() + self:Ping(), 0) / p.mFirstPeriodMaxChargeFrame
            p1 = math.Clamp(frac * ss.GetTimeScale(self:GetOwner()), 0, 1) * 360
        end
    end

    ss.DrawCrosshair.SplatlingProgress(t.HitPosScreen.x, t.HitPosScreen.y, p1, p2)
end

function SWEP:DrawColoredCircle(t)
    if not t.Trace.Hit then return end
    ss.DrawCrosshair.SplatlingColoredCircle(t.HitPosScreen.x, t.HitPosScreen.y, t.CrosshairColor)
end

function SWEP:DrawCenterDot(t) -- Center circle
    if self:GetCharge() < math.huge or t.IsSplatoon2 and self:GetFireInk() > 0 then
        ss.DrawCrosshair.ChargerCenterDot(t.EndPosScreen.x, t.EndPosScreen.y)
        if t.Trace.Hit then
            ss.DrawCrosshair.SplatlingBaseCircle(t.EndPosScreen.x, t.EndPosScreen.y)
        end
    end

    if not t.Trace.Hit then return end
    ss.DrawCrosshair.ChargerCenterDot(
        t.HitPosScreen.x, t.HitPosScreen.y, 1,
        t.CrosshairDarkColor, t.CrosshairColor)
end

function SWEP:DrawCrosshairFlash(t)
    local frac = math.TimeFraction(self.CrosshairFlashTime,
    self.CrosshairFlashTime + self.FlashDuration, CurTime())
    if frac > 1 then return end
    ss.DrawCrosshair.SplatlingFlash(t.HitPosScreen.x, t.HitPosScreen.y, self:GetInkColor(), frac)
end

function SWEP:DrawCrosshair(x, y)
    if self:GetCharge() == math.huge and self:GetFireInk() == 0 then return end
    local t = self:SetupDrawCrosshair()
    t.EndPosScreen = (self:GetShootPos() + self:GetAimVector() * self.Range):ToScreen()
    t.CrosshairDarkColor = ColorAlpha(t.CrosshairColor, 192)
    t.CrosshairDarkColor.r = t.CrosshairDarkColor.r / 2
    t.CrosshairDarkColor.g = t.CrosshairDarkColor.g / 2
    t.CrosshairDarkColor.b = t.CrosshairDarkColor.b / 2
    t.CrosshairBrightColor = ColorAlpha(ss.GetColor(self:GetNWInt "inkcolor"), 255)
    t.CrosshairBrightColor.r = (t.CrosshairBrightColor.r + 255) / 2
    t.CrosshairBrightColor.g = (t.CrosshairBrightColor.g + 255) / 2
    t.CrosshairBrightColor.b = (t.CrosshairBrightColor.b + 255) / 2
    self:DrawCenterDot(t)
    self:DrawColoredCircle(t)
    self:DrawChargeCircle(t)
    self:DrawHitCross(t)
    self:DrawFourLines(t, self:GetSpreadAmount())
    self:DrawCrosshairFlash(t)
    return true
end
