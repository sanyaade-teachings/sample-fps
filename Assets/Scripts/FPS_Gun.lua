function OnAfterSceneLoaded(self)
	self.FireWeapon = Fire
	self.ReloadWeapon = Reload
	
	self.roundsLoaded = self.magazineSize
	
	self.bulletSpawn = Game:GetEntity("BulletSpawn")
end

function OnThink(self)
	if self.roundsLoaded == 0 and self.totalRounds > 0 then
		Reload(self)
	end
end

function OnExpose(self)
	self.coolDownTime = .5
	self.magazineSize = 10
	self.totalRounds = 50
	self.gunRange = 7000
end

function Fire(gun)
	if gun.roundsLoaded > 0 then
		local rayStart = gun.bulletSpawn:GetPosition()
		local rayEnd = (gun.bulletSpawn:GetObjDir() * gun.gunRange) - rayStart
		local iCollisionFilterInfo = Physics.CalcFilterInfo(Physics.LAYER_ALL, 0,0,0)
		local hit, result = Physics.PerformRaycast(rayStart, rayEnd, iCollisionFilterInfo)
		
		local color = Vision.V_RGBA_GREEN
		Debug.Draw:Line(rayStart, rayEnd, color)
		
		if hit == true then
			if result ~= nil and result["HitType"] == "Entity" then
				if result["HitObject"]:GetKey() == "Target" then
					Debug:PrintLine("Hit target")
				end
			end
		end
		
		gun.roundsLoaded = gun.roundsLoaded - 1
		gun.totalRounds = gun.totalRounds - 1
		
		--Game:CreateEffect(rayStart, "Particles\\FPS_Bullet_PAR.xml")
	end
end

function Reload(gun)
	if gun.totalRounds > 0 then
		while (gun.roundsLoaded < gun.magazineSize) and (gun.roundsLoaded < gun.totalRounds) do
			gun.roundsLoaded = gun.roundsLoaded + 1
		end
	end
end