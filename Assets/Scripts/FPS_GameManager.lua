-- new script file
function OnAfterSceneLoaded(self)
	--a table of bullets (also tables)
	G.allBullets = {}
	
	G.Reset = ResetGame
	G.CreateBullet = CreateNewBullet
end

function OnThink(self)
	local numBullets = table.getn(G.allBullets)
	
	if numBullets > 0 then
		for i = 1, numBullets, 1 do
			local currentBullet = G.allBullets[i]
			if currentBullet ~= nil then 
				if UpdateBullet(currentBullet) then
					currentBullet.particle:Remove()
					table.remove(G.allBullets, i)
					i = i - 1
					-- Debug:PrintLine("Bullet deleted. " ..table.getn(G.allBullets) .. "bullets still in scene")
				end
			end	
		end
	end
end

function OnBeforeSceneUnloaded(self)
	--
end

function ResetGame()
	--reactivate the targets that were hit
	local hitCount = table.getn(G.targetsHit)
	for i = 1, hitCount, 1 do
		G.targetsHit[i].Activate(G.targetsHit[i])
	end
	G.targetsHit = {}

	--move the player back to the start pos
	--[[
	this section does not currently work, but I'm moving on due to time constraints
	G.player:SetMotionDeltaWorldSpace(G.zeroVector)
	G.player.characterController:SetWantJump(false)
	G.player:SetPosition(G.playerStartPos)
	G.player:SetOrientation(G.playerStartRot)
	--]]
end

function UpdateBullet(bullet)
	--find the bullet's next position
	local nextPos = (bullet.dir * bullet.speed) + bullet.pos 
	
	
	--[[without this line the game breaks, with it, it breaks--]]
	local distance = bullet.startPos:getDistanceToSquared(nextPos)
	local rangeSq = bullet.range * bullet.range 
	if  distance > rangeSq then
		return true
	end
	
	local dist = bullet.pos:getDistanceToSquared(nextPos)
	
	local color = Vision.V_RGBA_GREEN
	Debug.Draw:Line(bullet.pos, nextPos, color)
	
	if dist > .1 then
		local rayStart = bullet.pos
		
		local iCollisionFilterInfo = Physics.CalcFilterInfo(Physics.LAYER_ALL, 0,0,0)
		local hit, result = Physics.PerformRaycast(rayStart, nextPos, iCollisionFilterInfo)
		
		if hit == true then
			if result ~= nil then
				if result["HitType"] == "Entity" then
					local hitObj = result["HitObject"]
					if hitObj:GetKey() == "Target" then
						-- Debug:PrintLine("Hit target")
						hitObj.Deactivate(hitObj)
						table.insert(G.targetsHit, hitObj)
					end
				end
				
				local size = 2
				local distance = size / 2
				local lifetime = 5 --seconds
				local rotation = 0
				
				local dir = -result["ImpactNormal"]
				local pos = result["ImpactPoint"] - (dir * distance)
				Debug.Draw:Wallmark(
					pos,
					dir,
					"Textures/Decals/FPS_BulletWallMark_TEX.tga",
					Vision.BLEND_ALPHA,
					size, rotation, lifetime)
					
				bullet.HitCallback(pos)	
				return true
			end
		else
			bullet.pos = nextPos
			bullet.particle:SetPosition(nextPos)
			return false
		end
	end
	return false
end

function CreateNewBullet(bulletSpeed, bulletStartPos, bulletDir, bulletParticle, ricochetChance, bulletRange)
	local newBullet = {}
	newBullet.speed = bulletSpeed
	newBullet.startPos = bulletStartPos
	newBullet.dir = bulletDir
	newBullet.particle = bulletParticle
	newBullet.ricochet = ricochetChance
	newBullet.range = bulletRange
	newBullet.pos = newBullet.startPos --set start position to current position for init
	
	newBullet.HitCallback = function(position)
		local hitSound = Fmod:CreateSound(position, "Sounds/Hit_Sound.wav", false)
		hitSound:SetVolume(0.5)
		hitSound:Play()
	end
	
	table.insert(G.allBullets, newBullet)
end