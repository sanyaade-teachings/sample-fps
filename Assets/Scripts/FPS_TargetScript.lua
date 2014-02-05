function OnAfterSceneLoaded(self)
	self.Deactivate = DeactivateTarget
	self.Activate = ActivateTarget
end

function DeactivateTarget(target)
	target:GetComponentOfType("vHavokRigidBody"):SetActive(false)
	target:SetVisible(false)
end

function ActivateTarget(target)
	target:GetComponentOfType("vHavokRigidBody"):SetActive(true)
	target:SetVisible(true)
end
