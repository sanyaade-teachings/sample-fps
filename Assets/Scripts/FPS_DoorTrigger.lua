
function OnAfterSceneLoaded(self)
	self.door = Game:GetEntity(self.targetName)
	if self.door ~= nil then
		self.doorAnim = self.door:GetComponentOfType("VAnimationComponent")
	end
	self.lastCollision = 0
end

function OnExpose(self)
	self.targetName = "Door"
end

function OnObjectEnter(self, object)
	local time = Timer:GetTime()
	local otherObj = object.ColliderObject

	--check for the double hit
	if self.lastCollider == otherObj and time - self.lastCollision < 0.1 then
		return
	end
	
	--remember the collision time
	self.lastCollider = otherObj
	self.lastCollision = time

	if object:GetKey() == "Player" then
		self.doorAnim:Play("Open")
	end
end