
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
	-- local time = Timer:GetTime()
	-- local otherObj = object.ColliderObject

	-- check for the double hit
	-- if self.lastCollider == otherObj and time - self.lastCollision < 0.1 then
		-- return
	-- end
	
	--remember the collision time
	self.lastCollider = otherObj
	self.lastCollision = time

	if object:GetKey() == "Player" and not self.played then
		self.doorRB:SetActive(false)
		-- Debug:PrintLine("Playing")
		self.door.Animation:Play("Open", false)
		self.played = true;
	end
end

-- function OnObjectLeave(self, object)
	-- if object:GetKey() == "Player" then
		-- self.door.Animation:Play("Open", false)
		-- self.door.Animation:SetSpeed(-.25)
		-- self.doorRB:SetActive(true)
	-- end
-- end
