ArcHUD.comboTemplate = {}
local module = ArcHUD:NewModule("ComboPoints")
module.version = "5.0 (@file-abbreviated-hash@)"

module.unit = "player"
module.noAutoAlpha = nil

module.defaults = {
	profile = {
		Enabled = true,
		Outline = true,
		Flash = true,
		Side = 2,
		Level = 1,
		ShowSeparators = true,
		Color = PowerBarColor["COMBO_POINTS"],
		RingVisibility = 2, -- always fade out when out of combat, regardless of ring status
		ShowTextHuge = true
	}
}
module.options = {
	{name = "Flash", text = "FLASH", tooltip = "FLASH"},
	{name = "ShowTextHuge", text = "SHOWTEXTHUGE", tooltip = "SHOWTEXTHUGE"}, -- fka "combo points"
	attach = true,
	hasseparators = true,
}
module.localized = true

module.class = "ROGUE"
module.specs = nil -- array of SPEC_... constants; nil if this ring is available for all specs
module.powerType = Enum.PowerType.ComboPoints
module.powerTypeString = "COMBO_POINTS"
module.flashAt = nil -- flash when full

local powerTemplate = ArcHUD.templatePowerRing
local comboTemplate = ArcHUD.comboTemplate
-- Combo points aren't player specific in classic, so properly track and update
-- them per target
if not ArcHUD.classic then
	comboTemplate.InitializePowerRing = powerTemplate.InitializePowerRing
	comboTemplate.OnModuleUpdate = powerTemplate.OnModuleUpdate
	comboTemplate.OnModuleEnable = powerTemplate.OnModuleEnable
	comboTemplate.UpdatePowerRing = powerTemplate.UpdatePowerRing
	comboTemplate.UpdatePower = powerTemplate.UpdatePower
	comboTemplate.UpdateActive = powerTemplate.UpdateActive
else
	comboTemplate.InitializePowerRing = powerTemplate.InitializePowerRing
	comboTemplate.OnModuleUpdate = powerTemplate.OnModuleUpdate
	comboTemplate.OnModuleEnable = powerTemplate.OnModuleEnable

function comboTemplate:UpdatePowerRing()
	local maxPower = UnitPowerMax(self.unit, self.powerType);
	local num = GetComboPoints(self.unit, "target");
	self.f:SetMax(maxPower)
	self.f:SetValue(num)

	if self.db.profile.ShowTextHuge then
		if (num > 0) then
			self.TextHuge:SetText(num)
		else
			self.TextHuge:SetText("")
		end
	end
	
	if self.db.profile.Flash then
		local flashAt = self.flashAt or maxPower
		if (num >= flashAt) then
			self.f:StartPulse()
		else
			self.f:StopPulse()
		end
	end
end

function comboTemplate:UpdatePower(event, arg1, arg2)
	if (event == "UNIT_COMBO_POINTS") or (event == "PLAYER_TARGET_CHANGED") then
		self:UpdatePowerRing()
	end
end

function comboTemplate:UpdateActive(event, arg1)
	local isActive = false

	if not self.specs then
		isActive = true
	else
		local spec = GetSpecialization()
		for i,s in ipairs(self.specs) do
			if s == spec then
				isActive = true
				break
			end
		end
	end

	if self.active ~= isActive then
		if isActive then
			-- Register the events we will use
			self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdatePower")
			if (not ArcHUD.classic) then
				self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "UpdateActive")
			end
			self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdatePower")
			self:RegisterUnitEvent("UNIT_COMBO_POINTS", "UpdatePower", self.unit)

			-- Activate ring timers
			self:StartRingTimers()
		else
			-- Unregister the events if we are in the wrong specialization
			self:UnregisterEvent("PLAYER_ENTERING_WORLD")
			if (not ArcHUD.classic) then
				self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
			end
			self:UnregisterEvent("PLAYER_TARGET_CHANGED")
			self:UnregisterUnitEvent("UNIT_COMBO_POINTS")

			-- Deactivate ring timers
			self:StopRingTimers()
		end
		if self.OnActiveChanged then
			self:OnActiveChanged(self.active, isActive)
		end
		self.active = isActive
	end
	
	self.f:SetShown(isActive and ((not self.CheckVisible) or self:CheckVisible()))
end
end

function module:Initialize()
	self.InitializePowerRing = comboTemplate.InitializePowerRing
	self.OnModuleUpdate = comboTemplate.OnModuleUpdate
	self.OnModuleEnable = comboTemplate.OnModuleEnable
	self.UpdatePowerRing = comboTemplate.UpdatePowerRing
	self.UpdatePower = comboTemplate.UpdatePower
	self.UpdateActive = comboTemplate.UpdateActive

	self:InitializePowerRing()
end
