function OnAfterSceneLoaded(self)
	self.infiniteAmmo = false
	self.bulletSpeed = 64
	self.particlePath = "Particles\\FPS_Bullet_PAR.xml"
	self.ricochetChance = .3

	self.FireWeapon = Fire
	self.ReloadWeapon = Reload
	self.AddAmmo = AddMoreAmmo
	self.UpdateSight = UpdateLOS
	
	self.timeToNextShot = 0
	self.roundsLoaded = self.magazineSize
	
	self.bulletSpawn = Game:GetEntity("BulletSpawn")
end

function OnExpose(self)
	self.fireRate = .15
	self.magazineSize = 10
	self.totalRounds = 50
	self.gunRange = 50
	self.roundsCapacity = 50
end

function OnThink(self)
	if self.roundsLoaded == 0 and self.totalRounds > 0 then
		Reload(self)
	end
	
	if self.timeToNextShot > 0 then
		self.timeToNextShot = self.timeToNextShot - Timer:GetTimeDiff()
	elseif self.timeToNextShot < 0 then
		self.timeToNextShot = 0
	end		
	
	UpdateLOS(self)
	SetGunRotation(self)
end

function Fire(gun)
	if gun.timeToNextShot <= 0 then 
		if gun.roundsLoaded > 0 then
			local bulletParticle = Game:CreateEffect(gun.bulletSpawn:GetPosition(), gun.particlePath)
			bulletParticle:SetDirection(gun:GetObjDir() )
			CreateBullet(gun.bulletSpeed, gun.bulletSpawn:GetPosition(), gun.bulletSpawn:GetObjDir(), bulletParticle, gun.ricochetChance, gun.gunRange)
			
			if not gun.infiniteAmmo then
				gun.roundsLoaded = gun.roundsLoaded - 1
				gun.totalRounds = gun.totalRounds - 1
			end
			
			StartCoolDown(gun)
		end
	end
end

function StartCoolDown(gun)
	gun.timeToNextShot = gun.fireRate
end

function Reload(gun)
	if gun.totalRounds > 0 then
		while (gun.roundsLoaded < gun.magazineSize) and (gun.roundsLoaded < gun.totalRounds) do
			gun.roundsLoaded = gun.roundsLoaded + 1
		end
	end
end

function SetGunRotation(self)
	local rayStart = Screen:Project3D(G.w / 2, G.h / 2, 0)
	local rayEnd = Screen:Project3D(G.w / 2, G.h / 2, self.gunRange)

	local iCollisionFilterInfo = Physics.CalcFilterInfo(Physics.LAYER_ALL, 0,0,0)
	local hit, result = Physics.PerformRaycast(rayStart, rayEnd, iCollisionFilterInfo)
	
	if hit == true then
		local hitPoint = rayEnd
		
		if hit == true and result ~= nil then
			local resultKey = result["HitObject"]:GetKey()
			if resultKey ~= "Player" and resultKey ~= Gun then
				hitPoint = result["ImpactPoint"]
			end
			
			Debug:PrintLine(resultKey)
		end
		
		local d = (hitPoint - self:GetPosition()):getNormalized()
		self:SetDirection(d)
	end
end

function UpdateLOS(self)
	local rayStart = self:GetPosition()
	rayEnd = (self:GetObjDir() * self.gunRange) + rayStart
	-- local rayEnd = Screen:Project3D(G.w / 2, G.h / 2, self.gunRange)
	
	local iCollisionFilterInfo = Physics.CalcFilterInfo(Physics.LAYER_ALL, 0,0,0)
	local hit, result = Physics.PerformRaycast(rayStart, rayEnd, iCollisionFilterInfo)
	
	local color = Vision.V_RGBA_RED
	--Debug.Draw:Line(rayStart, rayEnd, color)
	
	local hitTarget = false

	if hit == true then
		if result ~= nil and result["HitType"] == "Entity" then
			local hitObj = result["HitObject"]
			if hitObj:GetKey() == "Target" then
				hitTarget = true
			end
		end
			local size = 2
			local distance = size / 2
			local lifetime = .05	--seconds
			local rotation = 0
			
			local dir = -result["ImpactNormal"]
			local pos = result["ImpactPoint"] - (dir * distance)
			Debug.Draw:Wallmark(
				pos,
				dir,
				"Textures/Decals/FPS_RedDot_TEX.tga",
				Vision.BLEND_ALPHA,
				size, rotation, lifetime)
	end
	
	if hitTarget == true then
		G.screenMask:SetColor(Vision.V_RGBA_RED)
	else
		G.screenMask:SetColor(Vision.V_RGBA_WHITE)
	end
	
	
end

function AddMoreAmmo(gun, amount)
	if gun.totalRounds < gun.roundsCapacity then
		while gun.totalRounds < gun.roundsCapacity and amount > 0 do
			gun.totalRounds = gun.totalRounds + 1
			amount = amount - 1
		end
		return true
	else
		return false
	end
end

