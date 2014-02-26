--the global variables and scene logic go here
function OnAfterSceneLoaded(self)
	--check the platform
	G.isWidows = (Application:GetPlatformName() == "WIN32DX9" or Application:GetPlatformName() == "WIN32DX11")
	
	-- set up the reticle
	G.w, G.h = Screen:GetViewportSize()
	local width = G.w * 0.1
	G.screenMask = Game:CreateScreenMask(G.w / 2 - width / 2.0, G.h / 2 - width / 2.0, "Textures/FPS_Reticule_DIFFUSE.tga")
	G.screenMask:SetTargetSize(width, width)
	G.screenMask:SetBlending(Vision.BLEND_ADDITIVE)
	
	--set up the texure for the player's gun
	G.gunMask = Game:CreateScreenMask( (G.w * 3 / 4), (G.h * 0.1), "FPS_AmmoDisplay_Inactive_TEX.tga")
	G.gunMask:SetTargetSize(128, 64)
	
	--set up the variables for checking the win condition
	G.targetsHit = {}
	G.numTargets = 0
	local targetParent = Game:GetEntity("TargetParent")
	for i = 0, targetParent:GetNumChildren(), 1 do
		local entity = targetParent:GetChild(i)
		if entity ~= nil and entity:GetKey() == "Target" then
			G.numTargets = G.numTargets + 1
		end
	end
	
	--find the player and get the starting position and rotation
	G.player = Game:GetEntity("Player")
	G.playerSpawn = Game:GetEntity("PlayerSpawn")
	G.playerStartPos = G.playerSpawn:GetPosition()
	G.playerStartRot = G.playerSpawn:GetOrientation()
	
	--create some utility vectors to be used by other scripts
	G.worldUp = G.playerSpawn:GetObjDir_Up()
	G.zeroVector = Vision.hkvVec3(0,0,0)
	
	--find the game camera
	G.camera = Game:GetEntity("Camera")
	
	--set the font path
	G.fontPath = "Fonts/Stencil.fnt"
end

function OnBeforeSceneUnloaded(self)
	Game:DeleteAllUnrefScreenMasks()
end




