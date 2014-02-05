function OnAfterSceneLoaded(self)
	self.Activate = ActivateBox
	self.ammoCount = 25
	self.respawnTime = 20
	self.timeToNextSpawn = 0
	self.lastCollision = 0
end

function OnExpose(self)
	--self.ammoCount = 25
	-- self.respawnTime = 20
end

--[[???]]
--What's more expensive: coroutines, or multiple OnThink calls? 
function OnThink(self)
	if self.timeToNextSpawn > 0 then
		self.timeToNextSpawn = self.timeToNextSpawn - Timer:GetTimeDiff()
		return
	elseif self.timeToNextSpawn < 0 then
		self.timeToNextSpawn = 0
	end
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
		if(object.gun.AddAmmo(object.gun, self.ammoCount) ) then
			Debug:PrintLine("Ammo Added!")
			Deactivate(self)
			StartCoolDown(self)
		end
	end
end

function Deactivate(self)
	self:SetEnabled(false)
	self:SetVisible(false)
end

function ActivateBox(box)
	--set this to invsible, and turn off collision
end

function StartCoolDown(self)
	self.timeToNextSpawn = self.respawnTime
end