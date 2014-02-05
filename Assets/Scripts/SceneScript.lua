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
	
	G.Reset = ResetGame
	Debug:PrintLine("Here")
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