
function OnAfterSceneLoaded(self)
	--find the animation target
	self.door = Game:GetEntity(self.targetName)
	if self.door ~= nil then
		--if there is one, Add the Animation component and RigidBody
		self.doorAnim = self.door:AddAnimation("Animation")
		self.doorRB = self.door:GetComponentOfType("vHavokRigidBody")
	end
	
	--set values to help keep track of the animation
	self.played = false
	self.animationTime = 0
end

function OnExpose(self)
	self.targetName = "Door"
end

function OnObjectEnter(self, object)
	--if the other object is the player, play the door animation oncce
	if object:GetKey() == "Player" and not self.played then
		ToggleAnim(self)
	end
end

function OnObjectLeave(self, object)
	--if the other object is the player, play the anim once in reverse
	if object:GetKey() == "Player" and self.played then
		ToggleAnim(self)
	end
end

function ToggleAnim(self)
	--set the animation speed
	local animSpeed = 0
	if self.played then
		animSpeed = -1
	else
		animSpeed = 1
	end
	----check to see if the animation is playing
	if self.door.Animation:IsPlaying() then
		--if so, set the time to the animation time
		self.animationTime = self.door.Animation:GetTime()
	else
		--if not set the animation time
		if self.played then
			self.animationTime = 1
		else
			self.animationTime = 0
		end
	end
	
	--Play the animation
	self.door.Animation:Play("Open", false)
	self.door.Animation:SetTime(self.animationTime)
	self.door.Animation:SetSpeed(animSpeed)
	
	--Toggle the RigidBody
	self.doorRB:SetActive(not self.doorRB:GetActive() )
	
	--Set whether the animation has been played
	self.played = not self.played;
end