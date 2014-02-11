--the global variables and scene logic go here
function OnAfterSceneLoaded(self)
	G.isWidows = (Application:GetPlatformName() == "WIN32DX9" or Application:GetPlatformName() == "WIN32DX11")
	G.zeroVector = Vision.hkvVec3(0,0,0)
	
	-- set up the reticle
	G.w, G.h = Screen:GetViewportSize()
	local width = G.w * 0.1
	G.screenMask = Game:CreateScreenMask(G.w / 2 - width / 2.0, G.h / 2 - width / 2.0, "Textures/FPS_Reticule_DIFFUSE.tga")
	G.screenMask:SetTargetSize(width, width)
	G.screenMask:SetBlending(Vision.BLEND_ADDITIVE)
	
	G.targetsHit = {}
	
	--find the player and get the starting position and rotation
	G.player = Game:GetEntity("Player")
	G.playerStartPos = G.player:GetPosition()
	G.playerStartRot = G.player:GetOrientation()
end

function OnBeforeSceneUnloaded(self)
	Game:DeleteAllUnrefScreenMasks()
end


