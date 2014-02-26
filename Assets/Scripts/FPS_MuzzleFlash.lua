function Create(self)
	self:AddTriggerTarget("ToggleLight")
end

function OnAfterSceneLoaded(self)
	self.light = Game:GetLight("MuzzleLight")
	self.light:SetVisible(false)
	self.on = false
end

function OnTrigger(self, sourceName, targetName)
	Toggle(self)
end

function Toggle(self)
	if self.on then
		self.light:SetVisible(false)
	else
		self.light:SetVisible(true)
	end
end
