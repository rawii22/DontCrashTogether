local Health = Class(function(self, inst)
    self.inst = inst

    self._isdead = net_bool(inst.GUID, "health._isdead")
    self._isnotfull = net_bool(inst.GUID, "health._isnotfull")
    self._cannotheal = net_bool(inst.GUID, "health._cannotheal")
    self._cannotmurder = net_bool(inst.GUID, "health._cannotmurder")

    if TheWorld.ismastersim then
        self.classified = inst.player_classified
    elseif self.classified == nil and inst.player_classified ~= nil then
        self:AttachClassified(inst.player_classified)
    end
end)

--------------------------------------------------------------------------

function Health:OnRemoveFromEntity()
    if self.classified ~= nil then
        if TheWorld.ismastersim then
            self.classified = nil
        else
            self.inst:RemoveEventCallback("onremove", self.ondetachclassified, self.classified)
            self:DetachClassified()
        end
    end
end

Health.OnRemoveEntity = Health.OnRemoveFromEntity

function Health:AttachClassified(classified)
    self.classified = classified
    self.ondetachclassified = function() self:DetachClassified() end
    self.inst:ListenForEvent("onremove", self.ondetachclassified, classified)
end

function Health:DetachClassified()
    self.classified = nil
    self.ondetachclassified = nil
end

--------------------------------------------------------------------------
--Client helpers

local function GetPenaltyPercent_Client(self)
    return self.classified.healthpenalty:value() / 200
end

local function MaxWithPenalty_Client(self)
    return self.classified.maxhealth:value() * (1 - GetPenaltyPercent_Client(self))
end

--------------------------------------------------------------------------

function Health:SetCurrent(current)
    if self.classified ~= nil then
        self.classified:SetValue("currenthealth", current)
    end
end

function Health:SetMax(max)
    if self.classified ~= nil then
        self.classified:SetValue("maxhealth", max)
    end
end

function Health:SetPenalty(penalty)
    if self.classified ~= nil then
        assert(penalty >= 0 and penalty <= 1, "Player healthpenalty out of range: "..tostring(penalty))
        self.classified.healthpenalty:set(math.floor(penalty * 200 + .5))
    end
end

function Health:Max()
    if self.inst.components.health ~= nil then
        return self.inst.components.health.maxhealth
    elseif self.classified ~= nil then
        return self.classified.maxhealth:value()
    else
        return 100
    end
end

function Health:MaxWithPenalty()
    if self.inst.components.health ~= nil then
        return self.inst.components.health:GetMaxWithPenalty()
    elseif self.classified ~= nil then
        return MaxWithPenalty_Client(self)
    else
        return 100
    end
end

function Health:GetPercent()
    if self.inst.components.health ~= nil then
        return self.inst.components.health:GetPercent()
    elseif self.classified ~= nil then
        return self.classified.currenthealth:value() / self.classified.maxhealth:value()
    else
        return 1
    end
end

function Health:GetCurrent()
    if self.inst.components.health ~= nil then
        return self.inst.components.health.currenthealth
    elseif self.classified ~= nil then
        return self.classified.currenthealth:value()
    else
        return 100
    end
end

function Health:GetPenaltyPercent()
    if self.inst.components.health ~= nil then
        return self.inst.components.health:GetPenaltyPercent()
    elseif self.classified ~= nil then
        return GetPenaltyPercent_Client(self)
    else
        return 0
    end
end

function Health:IsHurt()
    if self.inst.components.health ~= nil then
        return self.inst.components.health:IsHurt()
    elseif self.classified ~= nil then
        return self.classified.currenthealth:value() < MaxWithPenalty_Client(self)
    else
        return false
    end
end

function Health:SetIsFull(isfull)
    self._isnotfull:set(not isfull)
end

function Health:IsFull()
    return not self._isnotfull:value()
end

function Health:SetIsDead(isdead)
    self._isdead:set(isdead)
end

function Health:IsDead()
    return self._isdead:value()
end

function Health:SetIsTakingFireDamage(istakingfiredamage)
    if self.classified ~= nil then
        self.classified.istakingfiredamage:set(istakingfiredamage)
    end
end

function Health:IsTakingFireDamage()
    if self.inst.components.health ~= nil then
        return self.inst.components.health.takingfiredamage
    else
        return self.classified ~= nil and self.classified.istakingfiredamage:value()
    end
end

function Health:SetIsTakingFireDamageLow(istakingfiredamagelow)
    if self.classified ~= nil then
        self.classified.istakingfiredamagelow:set(istakingfiredamagelow)
    end
end

function Health:IsTakingFireDamageLow()
    if self.inst.components.health ~= nil then
        return self.inst.components.health.takingfiredamagelow == true
    else
        return self.classified ~= nil and self.classified.istakingfiredamagelow:value()
    end
end

function Health:IsTakingFireDamageFull()
    if self.inst.components.health ~= nil then
        return self.inst.components.health.takingfiredamage and not self.inst.components.health.takingfiredamagelow
    else
        return self.classified ~= nil and self.classified.istakingfiredamage:value() and not self.classified.istakingfiredamagelow:value()
    end
end

function Health:SetCanHeal(canheal)
    self._cannotheal:set(not canheal)
end

function Health:CanHeal()
    return not self._cannotheal:value()
end

function Health:SetCanMurder(canmurder)
    self._cannotmurder:set(not canmurder)
end

function Health:CanMurder()
    return not self._cannotmurder:value()
end

return Health
