
function OnAfterSceneLoaded(self)
	self.door = Game:GetEntity(self.targetName)
	if self.door ~= nil then
		self.doorAnim = self.door:AddAnimation("Animation")
		self.door.currentAnim = 1
		self.doorRB = self.door:GetComponentOfType("vHavokRigidBody")
	end
	
	self.played = false
	self.lastCollision = 0
end

function OnExpose(self)
	self.targetName = "Door"
end

function OnObjectEnter(self, object)
	--if the other object is the player, play the door animation oncce
	if object:GetKey() == "Player" and not self.played then
		self.doorRB:SetActive(false)
		-- Debug:PrintLine("Playing")
		self.door.Animation:Play("Open", false)
		self.played = true;
	end
end