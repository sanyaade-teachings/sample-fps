function OnAfterSceneLoaded(self)
	self.Activate = ActivateBox
	self.ammoCount = 25
	self.respawnTime = 10
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
	elseif self.timeToNextSpawn <= 0 then
		self.timeToNextSpawn = 0
	end
	
	if self.timeToNextSpawn == 0 then
		SetBoxState(self, true)
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
			SetBoxState(self, false)
			StartCoolDown(self)
		end
	end
end

function SetBoxState(self, state) --state should be true when activating, false when deactivating
	self:SetEnabled(state)
	self:SetVisible(state)
	
	--de/activate the children of this object as well
	local numChildren = self:GetNumChildren()
	for i = 0, numChildren - 1, 1 do
		local entity = self:GetChild(i)
		if entity ~= nil then
			entity:SetVisible(state)
		end
	end
end

function StartCoolDown(self)
	self.timeToNextSpawn = self.respawnTime
end