function OnCreate(self)
	self.SetUp = SetUpHUD
end

function OnAfterSceneLoaded(self)
	self.infiniteAmmo = false
	self.bulletSpeed = 64
	self.particlePath = "Particles\\FPS_Bullet_PAR.xml"
	self.ricochetChance = 25
	self.roundsCapacity = self.magazineSize * 3 
	self.totalRounds = self.roundsCapacity
	
	self.FireWeapon = Fire
	self.ReloadWeapon = Reload
	self.AddAmmo = AddMoreAmmo
	self.UpdateSight = UpdateLOS
	
	self.timeToNextShot = 0
	self.roundsLoaded = self.magazineSize
	
	self.bulletSpawn = Game:GetEntity("BulletSpawn")
	-- self.shotSound = Fmod:GetSound("ShotSound")
	-- if self.shotSound == nil then
		--self.shotSound = Fmod:CreateSound(self.bulletSpawn:GetPosition(), "Sounds/Shot_Sound.wav", false)
	-- end
end

function OnExpose(self)
	self.fireRate = .15
	self.magazineSize = 30
	self.gunRange = 600
	
	self.bulletRows = 3
	self.bulletColumns = 10
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
	UpdateGunTransform(self)
end

function OnBeforeSceneUnloaded(self)
	Game:DeleteAllUnrefScreenMasks()
end

function Fire(gun)
	if gun.timeToNextShot <= 0 then 
		if gun.roundsLoaded > 0 then
			local bulletParticle = Game:CreateEffect(gun.bulletSpawn:GetPosition(), gun.particlePath)
			bulletParticle:SetDirection(gun:GetObjDir() )
			G.CreateBullet(gun.bulletSpeed, gun.bulletSpawn:GetPosition(), gun.bulletSpawn:GetObjDir(), bulletParticle, gun.ricochetChance, gun.gunRange)
			
			if not gun.infiniteAmmo then
				gun.roundsLoaded = gun.roundsLoaded - 1
				gun.totalRounds = gun.totalRounds - 1
				gun.bullets[gun.roundsLoaded]:SetTextureObject(gun.inactiveBulletTexture)
				
			end
			
			-- if gun.shotSound ~= nil then
				-- if gun.shotSound:IsPlaying() then
					-- gun.ShotSound:Stop()
				-- end
				-- gun.shotSound:Play()
			-- end
			
			
			--remove an existing sound before creating a new one
			if gun.shotSound ~= nil then
				if gun.shotSound:IsPlaying() then
					gun.shotSound:Stop()
				end
				gun.shotSound:Remove()
			end
			
			gun.shotSound = Fmod:CreateSound(gun.bulletSpawn:GetPosition(), "Sounds/Shot_Sound.wav", false)
			if gun.shotSound ~= nil then
				gun.shotSound = Fmod:CreateSound(gun.bulletSpawn:GetPosition(), "Sounds/Shot_Sound.wav", false)
				gun.shotSound:Play()
			end
			
			-- UpdateHUD(gun, gun.roundsLoaded)
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
			gun.bullets[gun.roundsLoaded]:SetTextureObject(gun.activeBulletTexture)
			gun.roundsLoaded = gun.roundsLoaded + 1
			-- UpdateHUD(gun, gun.roundsLoaded)
		end
	end
end

function UpdateGunTransform(self)		
	local rayStart = Screen:Project3D(G.w / 2, G.h / 2, 0)
	local rayEnd = Screen:Project3D(G.w / 2, G.h / 2, self.gunRange)
	
	local iCollisionFilterInfo = Physics.CalcFilterInfo(Physics.LAYER_ALL, 0,0,0)
	local hit, result = Physics.PerformRaycast(rayStart, rayEnd, iCollisionFilterInfo)
	
	local hitPoint = rayEnd
	
	if hit == true then
		if hit == true and result ~= nil then
			local resultKey = result["HitObject"]:GetKey()
			local impact = result["ImpactPoint"]
			
			--if the impact location is behind the player, cast a new ray from that hit point
			if self:GetPosition():dot(impact) < 0 then
				hit, result = Physics.PerformRaycast(impact, rayEnd, iCollisionFilterInfo)
				if hit == true and result ~= nil then
					impact = result["ImpactPoint"]
				end
			end
			
			--if the ray does not hit the player or the gun, look at the impact point
			if resultKey ~= "Player" and resultKey ~= "Gun" then
				if hitPoint:dot(impact) > 0 then
					-- Debug:PrintLine(resultKey)
					hitPoint = impact
				end
			end
		end
	end
	
	local d = (hitPoint - self:GetPosition() ):getNormalized()
	self:SetDirection(d)
end

function UpdateLOS(self)
	local rayStart = self:GetPosition()
	local rayEnd = (self:GetObjDir() * self.gunRange) + rayStart
	
	local iCollisionFilterInfo = Physics.CalcFilterInfo(Physics.LAYER_ALL, 0,0,0)
	local hit, result = Physics.PerformRaycast(rayStart, rayEnd, iCollisionFilterInfo)
	
	local color = Vision.V_RGBA_RED
	Debug.Draw:Line(rayStart, rayEnd, color)
	
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
	
	local size_X = self.activeBulletTexture:GetWidth()
	local size_Y = self.activeBulletTexture:GetHeight() / 2
	
	--create the bullet array
	self.bullets = {}
	local index = 0
	--fill the bullet array and show it
	for i = 0, self.bulletRows - 1 , 1 do
		for j = 0, self.bulletColumns - 1, 1 do
			index = (i * self.bulletColumns) + j
			self.bullets[index] = Game:CreateScreenMask(x + (size_X * j), (y / 2) + (size_Y / 2 * i), "Textures/FPS_GunHUD/FPS_Bullet_White_TEX.tga")
			self.bullets[index]:SetBlending(Vision.BLEND_ALPHA)
			-- self.bullets[index]:SetTargetSize(size_X / 2, size_Y)
		end
	end
end

function UpdateHUD(self, roundsLoaded) --change the position index instead
	--G.gunMask:SetTextureObject(self.hudArray[self.roundsLoaded] )
	G.gunMask:SetBlending(Vision.BLEND_ALPHA)
	G.gunMask:SetTargetSize(256, 128)
end

