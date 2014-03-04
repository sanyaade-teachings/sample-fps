-- new script file
function OnAfterSceneLoaded(self)
	--a table of bullets (each bullet is also a table)
	G.allBullets = {}
	
	--global functions to create a bullet, and 
	G.Reset = ResetGame
	G.CreateBullet = CreateNewBullet
	
	G.gameOver = false
end

function OnThink(self)
	if not G.gameOver then
		--check to see if all targets have been hit
		local numHit = table.getn(G.targetsHit)
		
		--show the number of targets remaining
		Debug:PrintAt(G.w * 0.1, G.h - G.h * 0.1, "Targets Remaining: " .. (G.numTargets - numHit) , Vision.V_RGBA_WHITE, G.fontPath)
		
		--if numHit > numTargets, win!
		if numHit == G.numTargets then
			Win()
		end
		
		--get the number of bullets in the scence
		local numBullets = table.getn(G.allBullets)
		
		--for each bullet, update it's position and delete if necessary
		if numBullets > 0 then
			for i = 1, numBullets, 1 do
				local currentBullet = G.allBullets[i]
				if currentBullet ~= nil then 
					--if the udate bullet function returns true, delete the bullet ***won't be true if bullet ricochets
					if UpdateBullet(currentBullet) then
						currentBullet.particle:Remove()
						table.remove(G.allBullets, i)
						i = i - 1
					end
				end	
			end
		end
	else
		local winText1 = "You Win!"
		local winText2 = "Press Any Key To Continue"
		Debug:PrintAt( (G.w / 2.0) - (winText1:len() * 8), G.h / 2.0, "" .. winText1, Vision.V_RGBA_WHITE, G.fontPath)
		Debug:PrintAt( (G.w / 2.0) - (winText2:len() * 8), G.h / 2.0 + 32, "" .. winText2, Vision.V_RGBA_WHITE, G.fontPath)
		if G.player.map:GetTrigger("ANY") > 0 then
			ResetGame()
		end
	end
end

--Inform the user if s/he has hit all targets
function Win()
	Debug:PrintLine("You Win!")
	G.gameOver = true
	G.winMask = Game:CreateScreenMask(0, 0, "Textures/FPS_WinScreenMask_DIFFUSE.tga")
	G.winMask:SetTargetSize(G.w, G.h)
	G.winMask:SetBlending(Vision.BLEND_MULTIPLY)
end

--for all targets that have been hit, show them again
function ResetGame()
	--reactivate the targets that were hit
	local hitCount = table.getn(G.targetsHit)
	for i = 1, hitCount, 1 do
		G.targetsHit[i].Activate(G.targetsHit[i])
	end
	
	--unfreeze the player
	G.gameOver = false
	
	--reset the targetsHit to nil
	G.targetsHit = {}
	
	--clear the screen mask
	G.winMask:SetTextureObject(nil)
end

--Moves each bullet based on speed, if it hits anything along the path, return true
function UpdateBullet(bullet)
	--find the bullet's next position
	local nextPos = (bullet.dir * bullet.speed) + bullet.pos 
	
	--getn the distance to the next position
	local dist = bullet.pos:getDistanceTo(nextPos)
	
	--draw a ray along the bullets current route
	local color = Vision.V_RGBA_GREEN
	--Debug.Draw:Line(bullet.pos, nextPos, color)
	
	--check for collisions if the bullet has traveled a certain distance
	if dist > .1 then
		--start the ray at the bullet's current' pos
		local rayStart = bullet.pos
		
		--get the collision info for the ray
		local iCollisionFilterInfo = Physics.CalcFilterInfo(Physics.LAYER_ALL, 0,0,0)
		local hit, result = Physics.PerformRaycast(rayStart, nextPos, iCollisionFilterInfo)
		
		--check for the ray hit
		if hit == true then
			if result ~= nil then
				if result["HitType"] == "Entity" then
					local hitObj = result["HitObject"]
					if hitObj:GetKey() == "Target" then
						--if a target was hit, deactivate it and add it to the global table
						hitObj.Deactivate(hitObj)
						table.insert(G.targetsHit, hitObj)
					end
				end
				
				--if the ricochet fails, draw wallmark and destroy the bullet	
				if not bullet.HitCallback(bullet, pos, result) then	
					--set the values for the wallmark
					local size = 2
					local distance = size / 2
					local lifetime = 5 --seconds
					local rotation = 0
					
					--Project the wallmark at the hit location
					local dir = -result["ImpactNormal"]
					local pos = result["ImpactPoint"] - (dir * distance)
					Debug.Draw:Wallmark(
						pos,
						dir,
						"Textures/Decals/FPS_BulletWallMark_TEX.tga",
						Vision.BLEND_ALPHA,
						size, rotation, lifetime)
						
					return true
				end
			end
		else
			--update the bullet's total distance traveled
			bullet.distance = bullet.distance + (nextPos - bullet.pos):getLength()
			
			--move it tot he next position
			bullet.pos = nextPos
			bullet.particle:SetPosition(nextPos)
			
			--if the bullet's new position is past the range of the gun, return true and delete
			if  bullet.distance >  bullet.range then
				return true
			end
			
			return false
		end
	end
	return false
end

function CreateNewBullet(bulletSpeed, bulletStartPos, bulletDir, bulletParticle, ricochetChance, bulletRange)
	--set the new values for the bulet
	local newBullet = {}
	newBullet.speed = bulletSpeed
	newBullet.startPos = bulletStartPos
	newBullet.dir = bulletDir
	newBullet.particle = bulletParticle
	newBullet.ricochet = ricochetChance
	newBullet.range = bulletRange
	newBullet.pos = newBullet.startPos --set start position to current position for init
	newBullet.distance = 0
	
	--this function will be called everyime a bullet hits something
	newBullet.HitCallback = function(bullet, soundPosition, result)
		--find out what was hit
		local hitObj = result["HitObject"]
		
		--if the object was the player or gun return
		if hitObj ~= nil then
			--if the object was the player or gun return
			if hitObj:GetKey() == "Player" and hitObj:GetKey() == "Gun" then
				return
			end
			
			--Play the impact sound
			local hitSound = Fmod:CreateSound(soundPosition, "Sounds/Hit_Sound.wav", false)
			hitSound:SetVolume(0.5)
			hitSound:Play()
		end
		
		--calculate the ricochet chance return true if the bullet ricochets
		local ricochet = Util:GetRandInt(100)
		if ricochet < ricochetChance then
			-- Debug:PrintLine("Ricohet")
			bullet.dir:reflect(result["ImpactNormal"] )
			bullet.range = bullet.range / 4
			bullet.particle:SetDirection(bullet.dir)
			return true
		end
		
		return false
	end
	
	--add the new bullet to the global array
	table.insert(G.allBullets, newBullet)
end