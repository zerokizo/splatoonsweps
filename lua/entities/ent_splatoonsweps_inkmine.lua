
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model "models/splatoonsweps/subs/inkmine/inkmine.mdl"
ENT.WeaponClassName = ""
function ENT:Initialize()
    if IsValid(self.Owner) then
        local w = ss.IsValidInkling(self.Owner)
        if w then self.WeaponClassName = w:GetClass() end
    end

    self:SetModel(self.Model)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self.InitTime = CurTime()
end

if SERVER then return end
function ENT:Draw()
    ENT:DrawModel()
end
