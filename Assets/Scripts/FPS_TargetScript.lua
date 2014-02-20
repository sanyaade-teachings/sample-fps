function OnAfterSceneLoaded(self)
	self.Deactivate = DeactivateTarget
	self.Activate = ActivateTarget
end

function DeactivateTarget(target)
	target:GetComponentOfType("vHavokRigidBody"):SetActive(false)
	target:SetVisible(false)
	
	local hitSound = Fmod:CreateSound(position, "Sounds/Target_Sound.wav", false)
	hitSound:Play()
end

function ActivateTarget(target)
	target:GetComponentOfType("vHavokRigidBody"):SetActive(true)
	target:SetVisible(true)
end
