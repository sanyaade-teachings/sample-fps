--the global variables and scene logic go here
function OnAfterSceneLoaded(self)
	G.isWidows = (Application:GetPlatformName() == "WIN32DX9" or Application:GetPlatformName() == "WIN32DX11")
	G.zeroVector = Vision.hkvVec3(0,0,0)
	
	-- set up the reticle
	G.w, G.h = Screen:GetViewportSize()
	G.screenMask = Game:CreateScreenMask(G.w / 2, G.h / 2, "Textures/FPS_Reticule_DIFFUSE.tga")
	G.screenMask:SetBlending(Vision.BLEND_ADDITIVE)
end