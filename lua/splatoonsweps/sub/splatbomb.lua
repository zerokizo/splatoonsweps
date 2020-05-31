
print "SplatoonSWEPs: Splat bomb is loading"
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return {} end

local module = {}
function module:SharedSecondaryAttack(throwable)
    
end

if SERVER then
    function module:ServerSecondaryAttack(throwable)
        local tr = util.QuickTrace(self:GetShootPos(), self:GetAimVector() * self.Range, self.Owner)
        ss.MakeBombExplosion(tr.HitPos + tr.HitNormal * 10, self.Owner, self:GetNWInt "inkcolor")
    end
else
    function module:DrawOnSubTriggerDown()
        local start = self:GetShootPos()
        local endpos = start + self:GetAimVector() * self.Range
        local color = ss.GetColor(self:GetNWInt "inkcolor")
        render.SetColorMaterial()
        render.DrawBeam(start + self:GetRight() * 2 - vector_up, endpos, 1, 0, 1, color)
    end

    function module:ClientSecondaryAttack(throwable)

    end
end

return module
