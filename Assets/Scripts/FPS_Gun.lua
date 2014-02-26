function OnCreate(self)
	--set's up the SetUp method upon creation of the object
	self.SetUp = SetUpHUD
end

function OnAfterSceneLoaded(self)
	--these variables can be moved to the OnExpose function for easier access
	self.infiniteAmmo = false
	self.bulletSpeed = 64
	self.particlePath = "Particles\\FPS_Bullet_PAR.xml"
	self.ricochetChance = 50
	self.roundsCapacity = self.magazineSize * 3 
	self.totalRounds = self.roundsCapacity
	self.timeToNextShot = 0
	
	--assigning functions to variables for external use
	self.FireWeapon = Fire
	self.ReloadWeapon = Reload
	self.AddAmmo = AddMoreAmmo
	self.UpdateSight = UpdateLOS
	self.UpdateTransform = UpdateGunTransform
	
	--fill the magazine
	self.roundsLoaded = self.magazineSize
	
	--find the bullet spawn entity that all bullets will start from
	self.bulletSpawn = Game:GetEntity("BulletSpawn")
	
	--find the muzzle light and turn it off
	self.muzzleLight = Game:GetLight("MuzzleLight")
	self.muzzleLight:SetVisible(false)
	self.timeTimeToLightOff = 0
	self.lightTime = 0.1
end

function OnExpose(self)
	self.fireRate = .15
	self.magazineSize = 30
	self.gunRange = 800
	
	self.bulletRows = 3
	self.bulletColumns = 10
end

function OnThink(self)
	--if the magazine is empty, reload
	if self.roundsLoaded == 0 and self.totalRounds > 0 then
		Reload(self)
	end
	
	--make sure the gun fires at the correct rate
	if self.timeToNextShot > 0 then
		self.timeToNextShot = self.timeToNextShot - Timer:GetTimeDiff()
	elseif self.timeToNextShot <= 0 then
		self.timeToNextShot = 0
	end	
	
	--turn the light back off after a certain amount of time
	if self.timeTimeToLightOff >  0 then
		self.timeTimeToLightOff = self.timeTimeToLightOff - Timer:GetTimeDiff()
	elseif self.timeTimeToLightOff < 0 then
		self.timeTimeToLightOff = 0
		self.muzzleLight:SetVisible(false)
	end
	
	--Show the HUD
	ShowStats(self)
end

function OnBeforeSceneUnloaded(self)
	Game:DeleteAllUnrefScreenMasks()
end

function Fire(gun)
	--make sure the player can fire
	if gun.timeToNextShot <= 0 then 
		--make sure there are rounds left to fire
		if gun.roundsLoaded > 0 then
			--flash the light
			gun.muzzleLight:SetVisible(true)
			
			-- gun.muzzleLight:SetIntensity (10)
			--create the bullet particle and set it's direction to the direction of the gun
			local bulletParticle = Game:CreateEffect(gun.bulletSpawn:GetPosition(), gun.particlePath)
			bulletParticle:SetDirection(gun:GetObjDir() )
			
			--create the 'bullet' object and set's it values
			G.CreateBullet(gun.bulletSpeed, gun.bulletSpawn:GetPosition(), gun.bulletSpawn:GetObjDir(), bulletParticle, gun.ricochetChance, gun.gunRange)
			
			--if the player does not have infinite ammo (debugging purposes) subtract from the loaded rounds
			if not gun.infiniteAmmo then
				gun.roundsLoaded = gun.roundsLoaded - 1
				gun.totalRounds = gun.totalRounds - 1
				
				--update the HUD
				gun.bullets[gun.roundsLoaded]:SetTextureObject(gun.inactiveBulletTexture)
			end
			
			--remove an existing sound before creating a new one (eliminate multiple instances)
			if gun.shotSound ~= nil then
				if gun.shotSound:IsPlaying() then
					gun.shotSound:Stop()
				end
				gun.shotSound:Remove()
			end
			
			--play the shot sound
			gun.shotSound = Fmod:CreateSound(gun.bulletSpawn:GetPosition(), "Sounds/Shot_Sound.wav", false)
			if gun.shotSound ~= nil then
				gun.shotSound = Fmod:CreateSound(gun.bulletSpawn:GetPosition(), "Sounds/Shot_Sound.wav", false)
				gun.shotSound:Play()
			end
			
			--start the cool down
			StartCoolDown(gun)
		end
	end
end

--Starts the 'timer' that will keep the gun firing at the correct rate
function StartCoolDown(gun)
	gun.timeToNextShot = gun.fireRate
	gun.timeTimeToLightOff = gun.lightTime
end

--A reload function to be used internally and externally
function Reload(gun)
	--only reload if there are extra round remaining
	if gun.totalRounds > 0 then
		--fill the magazine with rounds until out of ammo, or mag is full
		while (gun.roundsLoaded < gun.magazineSize) and (gun.roundsLoaded < gun.totalRounds) do
			gun.bullets[gun.roundsLoaded]:SetTextureObject(gun.activeBulletTexture)
			gun.roundsLoaded = gun.roundsLoaded + 1
		end
	end
end

--This function tries makes sure that the gun will always point to the center of the reticle
function UpdateGunTransform(self)
	--cast a ray at through the center of the screen into the world
	local rayStart = Screen:Project3D(G.w / 2., G.h / 2.0, 0)
	local rayEnd = Screen:Project3D(G.w / 2.0, G.h / 2.0, self.gunRange)
	
	--get the collision info for the ray
	local iCollisionFilterInfo = Physics.CalcFilterInfo(Physics.LAYER_ALL, 0,0,0)
	local hit, result = Physics.PerformRaycast(rayStart, rayEnd, iCollisionFilterInfo)
	
	--the gun will point to the hitPoint, so set it to the ray end in case the ray does not hit anything
	local hitPoint = rayEnd
	
	if hit == true then
		--if an object was hit get the hit info
		if hit == true and result ~= nil then
			--get the info of the hit object
			local resultKey = result["HitObject"]:GetKey()
			local impact = result["ImpactPoint"]
			
			--if the ray does not hit the player or the gun, look at the impact point
			if resultKey ~= "Player" and resultKey ~= "Gun" then
				hitPoint = impact
			end
		end
	end
	
	--create the new direction, and normalize it
	local dir = (hitPoint - self:GetPosition() ):getNormalized()
	self:SetDirection(dir)
end

--This function checks to see if the paleyr is aiming at a target
function UpdateLOS(self)
	--cast a ray from the point of the gun in the direction that it's pointing
	local rayStart = self:GetPosition()
	local rayEnd = (self:GetObjDir() * self.gunRange) + rayStart
	
	--get the collision info
	local iCollisionFilterInfo = Physics.CalcFilterInfo(Physics.LAYER_ALL, 0,0,0)
	local hit, result = Physics.PerformRaycast(rayStart, rayEnd, iCollisionFilterInfo)
	
	--set the color of the line for debugging
	local color = Vision.V_RGBA_RED
	Debug.Draw:Line(rayStart, rayEnd, color)
	
	--this will be true if the player is aiming at a target
	local hitTarget = false

	--check for the ray hit
	if hit == true then
		
		--check to see if a target was hit
		if result ~= nil and result["HitType"] == "Entity" then
			local hitObj = result["HitObject"]
			if hitObj:GetKey() == "Target" then
				hitTarget = true
			end
		end
		
		--set the variables for the wallmark
		local size = 2
		local distance = size / 2
		local lifetime = .05	--seconds
		local rotation = 0
		
		--Project the wallmark
		local dir = -result["ImpactNormal"]
		local pos = result["ImpactPoint"] - (dir * distance)
		Debug.Draw:Wallmark(
			pos,
			dir,
			"Textures/Decals/FPS_RedDot_TEX.tga",
			Vision.BLEND_ALPHA,
			size, rotation, lifetime)
	end
	
	--if the target was hit, change the reticle color to red; white if not
	if hitTarget == true then
		G.screenMask:SetColor(Vision.V_RGBA_RED)
	else
		G.screenMask:SetColor(Vision.V_RGBA_WHITE)
	end
end

--A function to increase the player's total ammo, *does not reload the gun*
function AddMoreAmmo(gun, amount)
	--check the capacity and add ammo if lower
	if gun.totalRounds < gun.roundsCapacity then
		while gun.totalRounds < gun.roundsCapacity and amount > 0 do
			gun.totalRounds = gun.totalRounds + 1
			amount = amount - 1
		end
		return true
	else
		--return false if no ammo was added
		return false
	end
end

--Initialization of the HUD
function SetUpHUD(self)	
	--get the gun texture
	self.gunTexture = Game:CreateTexture("Textures/FPS_GunHUD/FPS_AmmoDisplay_TEX.tga")
	
	--assign it to the Global screen mask
	G.gunMask:SetTextureObject(self.gunTexture)
	
	--set it's position and blending
	local x,y = G.gunMask:GetTextureSize()
	G.gunMask:SetPos(G.w - (self.gunTexture:GetWidth() / 2) - 10 , 0)
	G.gunMask:SetBlending(Vision.BLEND_ALPHA)
	G.gunMask:SetTargetSize(256, 128)
	
	--get the bullet texutures
	self.activeBulletTexture = Game:CreateTexture("Textures/FPS_GunHUD/FPS_Bullet_White_TEX.tga")
	self.inactiveBulletTexture = Game:CreateTexture("Textures/FPS_GunHUD/FPS_Bullet_Gray_TEX.tga")
	
	--get the size of the bullet texture
	local size_X = self.activeBulletTexture:GetWidth()
	local size_Y = self.activeBulletTexture:GetHeight() / 2
	
	--create the bullet array
	self.bullets = {}
	local index = 0
	--fill the bullet array and show it
	for i = 0, self.bulletRows - 1 , 1 do
		for j = 0, self.bulletColumns - 1, 1 do
			index = (i * self.bulletColumns) + j
			self.bullets[index] = Game:CreateScreenMask(G.w - ( (size_X * self.bulletColumns) - (size_X * j) ), (y / 2) + (size_Y / 2 * i), "Textures/FPS_GunHUD/FPS_Bullet_White_TEX.tga")
			self.bullets[index]:SetBlending(Vision.BLEND_ALPHA)
		end
	end
end

--This will show the number of rounds remaining for the player
function ShowStats(self)
	if self.roundsLoaded ~= nil and self.magazineSize ~= nil and self.totalRounds ~= nil then
		local x,y = G.gunMask:GetTextureSize()
		Debug:PrintAt(G.w - x / 10, y * 2 / 5, "" .. self.totalRounds, Vision.V_RGBA_WHITE, G.fontPath)
	end
end
