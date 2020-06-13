
print "SplatoonSWEPs: Splat bomb is loading"
AddCSLuaFile()
local ss = SplatoonSWEPs
if not ss then return {} end

local module = {}
local InkConsume = 70
function module:SharedSecondaryAttack(throwable)
    
end

function module:CanSecondaryAttack()
    return self:GetInk() > InkConsume
end

if SERVER then
    function module:ServerSecondaryAttack(throwable)
        local tr = util.QuickTrace(self:GetShootPos(), self:GetAimVector() * self.Range, self.Owner)
        local e = ents.Create "ent_splatoonsweps_splatbomb"
        e.Owner = self.Owner
        e:SetNWInt("inkcolor", self:GetNWInt "inkcolor")
        e:SetInkColorProxy(self:GetInkColorProxy())
        e:SetPos(self:GetShootPos())
        e:Spawn()
        e:GetPhysicsObject():ApplyForceCenter(self:GetAimVector() * 20000)
        e:GetPhysicsObject():ApplyTorqueCenter(self:GetRight() * -270)
        self:SetInk(math.max(0, self:GetInk() - InkConsume))
        self:SetReloadDelay(40 * ss.FrameToSec)
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
