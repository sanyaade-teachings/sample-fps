--Author: Denmark Gibbs
--This script controls the behavior of the targets
--Attach this script to the Targets in the scene

function OnAfterSceneLoaded(self)
	self.Deactivate = DeactivateTarget
	self.Activate = ActivateTarget
end

function DeactivateTarget(target)
	--get or create the attached RigidBody
	local targetRB = target:GetComponentOfType("vHavokRigidBody")
	
	if targetRB == nil then
		targetRB = target:AddComponentOfType("vHavokRigidBody")
	end
	
	--deactivate the rigidbody
	targetRB:SetActive(false)
	
	--hide the target
	target:SetVisible(false)
	
	local hitSound = Fmod:CreateSound(target:GetPosition(), "Sounds/Target_Sound.wav", false)
	hitSound:Play()
end

function ActivateTarget(target)
	--get or create the attached RigidBody
	local targetRB = target:GetComponentOfType("vHavokRigidBody")
	
	if targetRB == nil then
		targetRB = target:AddComponentOfType("vHavokRigidBody")
	end
	
	--the the RigidBody to active
	targetRB:SetActive(false)
	
	--unhide the target
	target:SetVisible(true)
end
