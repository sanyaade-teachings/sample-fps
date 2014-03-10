--Author: Denmark Gibbs
--This script controls the behavior of the Trigger Box that adds ammo to the player's weapon
--Attach this script to the Trigger Box that adds ammo.
--Note: the model should be a child of the trigger in the scene for this to work properly

function OnAfterSceneLoaded(self)
	--these values can be moved to OnExpose for easy access in Vision
	self.Activate = ActivateBox
	self.ammoCount = 50
	self.respawnTime = 10
	self.timeToNextSpawn = 0
end

function OnThink(self)
	--if the box was already hit, countdown to respawn
	if self.timeToNextSpawn > 0 then
		self.timeToNextSpawn = self.timeToNextSpawn - Timer:GetTimeDiff()
		return
	elseif self.timeToNextSpawn <= 0 then
		self.timeToNextSpawn = 0
	end
	
	--when the respawn time reaches 0, show the box
	if self.timeToNextSpawn == 0 then
		SetBoxState(self, true)
	end
end

function OnObjectEnter(self, object)
	--if the other object was the player, add ammo to the player's gun
	if object:GetKey() == "Player" then
		if(object.gun.AddAmmo(object.gun, self.ammoCount) ) then
			SetBoxState(self, false)
			StartCoolDown(self)
		end
	end
end

--If state = true, enamble the trigger and show the box, else disable the trigger and hide box
function SetBoxState(self, state) 
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

--begin the cool down to the next spawn 
function StartCoolDown(self)
	self.timeToNextSpawn = self.respawnTime
end
