
local ss = SplatoonSWEPs
if not ss then return end
AddCSLuaFile()

ENT.Base = "ent_splatoonsweps_burstbomb"
ENT.Model = Model "models/props_splatoon/weapons/subs/point_sensor/point_sensor.mdl"
ENT.SubWeaponName = "pointsensor"

if CLIENT then return end
function ENT:PhysicsCollide(data, collider)
    self:StopSound "SplatoonSWEPs.SubWeaponThrown"
    self:EmitSound(ss.pointsensor.BurstSound)
    SafeRemoveEntity(self)

    local hit = false
    local p = ss.pointsensor.Parameters
    local e = EffectData()
    e:SetOrigin(self:GetPos())
    e:SetRadius(p.Burst_Radius)
    e:SetColor(self:GetNWInt "inkcolor")
    util.Effect("SplatoonSWEPsPointSensor", e)

    for _, e in ipairs(ents.FindInSphere(self:GetPos(), p.Burst_Radius)) do
        local w = ss.IsValidInkling(e)
        if (e:IsPlayer() or e:IsNPC() or e:IsNextBot()) and not (w and ss.IsAlly(self, w)) then
            hit = true
            e:EmitSound "SplatoonSWEPs.PointSensorTaken"
            e:SetNWBool("SplatoonSWEPs: IsMarked", true)
            e:SetNWInt("SplatoonSWEPs: PointSensorMarkedBy", self:GetNWInt "inkcolor")
            e:SetNWFloat("SplatoonSWEPs: PointSensorEndTime", CurTime() + ss.PointSensorDuration)
            local name = "SplatoonSWEPs: Timer for Point Sensor duration " .. e:EntIndex()
            timer.Create(name, 0, 0, function()
                if not IsValid(e) then timer.Remove(name) return end
                if not e:GetNWBool "SplatoonSWEPs: IsMarked" then timer.Remove(name) return end
                if CurTime() < e:GetNWFloat "SplatoonSWEPs: PointSensorEndTime" then return end
                e:SetNWBool("SplatoonSWEPs: IsMarked", false)
                e:EmitSound "SplatoonSWEPs.PointSensorLeft"
                timer.Remove(name)
            end)
        end
    end

    if not hit then return end
    local ply = {}
    for _, e in ipairs(player.GetAll()) do
        local w = ss.IsValidInkling(e)
        if w and ss.IsAlly(self, w) then
            table.insert(ply, e)
        end
    end

    ss.EmitSound(ply, "SplatoonSWEPs.PointSensorHit")
end
