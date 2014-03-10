--Author: Denmark Gibbs
--The global variables and scene logic go here
--Attach this script to the Main Layer in vForge

function OnBeforeSceneLoaded(self)
	--check the platform
	G.isWindows = (Application:GetPlatformName() == "WIN32DX9" or Application:GetPlatformName() == "WIN32DX11")
	
		-- set up the reticle
	G.w, G.h = Screen:GetViewportSize()
	
	local width = G.w * 0.1
	G.screenMask = Game:CreateScreenMask(G.w / 2 - width / 2.0, G.h / 2 - width / 2.0, "Textures/FPS_Reticule_DIFFUSE.tga")
	G.screenMask:SetTargetSize(width, width)
	G.screenMask:SetBlending(Vision.BLEND_ADDITIVE)
	
	G.ToggleRemote = ToggleRemoteInput
	G.remoteEnabled = true;
	
	-- RemoteInput:StartServer('RemoteGui')
	-- RemoteInput:InitEmulatedDevices()
	-- RemoteInput:DebugDrawTouchPoints(Vision.VColorRef(255, 0, 0) )
	
	-- mobile path
	if not G.isWindows then		
		--get the size of the texture
		local dpad = Game:CreateTexture("Textures/FPS_MobileHud/FPS_Dpad_128.tga")
		local x = dpad:GetWidth()
		
		--set the values for the texture's position on screen (as a percentage)
		local xPercent = .2
		local yPercent = .75
		
		--establish the positions of the dpad texture and store them
		local top = (G.h * yPercent) - (x * .5)
		local bottom = (G.h * yPercent) + (x * .5)
		local left = (G.w * xPercent) - (x * .5)
		local right = G.w * xPercent + (x * .5)
		
		G.dpadDisplay = Game:CreateScreenMask(left, top, "Textures/FPS_MobileHud/FPS_Dpad_128.tga")
		G.dpadDisplay:SetBlending(Vision.BLEND_ALPHA)
		
		--			{startx, starty, end x, endy}
		G.dpad = {}
		G.dpad.up = {left + (x / 3), top, right - (x / 3), top + (x / 3), -10, "new"}
		G.dpad.down = {left + (x / 3), bottom - (x / 3), right - (x / 3), bottom, -10, "new"}
		G.dpad.left = {left, top + (x / 3), left + (x / 3), bottom - (x / 3), -10, "new"}
		G.dpad.right = {right - (x / 3), top + (x / 3), right, bottom - (x / 3), -10, "new"}
		
		local xPercent_R = 0.8 --percentage of the screen to align objects to the right
		x = 64 --the texture size
		
		top = (G.h * yPercent) - (x * 1.5)
		bottom = (G.h * yPercent) + (x * 1.5)
		left = (G.w * xPercent_R) - (x * 1.5)
		right = (G.w * xPercent_R) + (x * 1.5)
		
		--{startx, starty, end x, endy}
		G.upButton = Game:CreateScreenMask(left + x, top, "Textures/FPS_MobileHud/FPS_Button_Up_64.tga")
		G.upButton:SetBlending(Vision.BLEND_ALPHA)
		G.up = {left + x, top, right - x, top + x}
		
		G.downButton = Game:CreateScreenMask(left + x, bottom - x, "Textures/FPS_MobileHud/FPS_Button_Down_64.tga")
		G.downButton:SetBlending(Vision.BLEND_ALPHA)
		G.down = {left + x, bottom - x, right - x, bottom}
		
		G.leftButton = Game:CreateScreenMask(left, top + x, "Textures/FPS_MobileHud/FPS_Button_Left_64.tga")
		G.leftButton:SetBlending(Vision.BLEND_ALPHA)
		G.left = {left, top + x, left + x, bottom - x}
		
		G.rightButton = Game:CreateScreenMask(right - x, top + x, "Textures/FPS_MobileHud/FPS_Button_Right_64.tga")
		G.rightButton:SetBlending(Vision.BLEND_ALPHA)
		G.right = {right - x, top + x, right, bottom - x}
	end
end

function OnAfterSceneLoaded(self)
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

function ToggleRemoteInput()
	if not G.remoteEnabled then
		RemoteInput:StartServer('RemoteGui')
		RemoteInput:InitEmulatedDevices()
		RemoteInput:DebugDrawTouchPoints(Vision.VColorRef(255, 0, 0) )
		G.remoteEnabled = true;
	else
		RemoteInput:StartServer('RemoteGui')
		RemoteInput:InitEmulatedDevices()
		RemoteInput:DebugDrawTouchPoints(Vision.VColorRef(255, 0, 0) )
		G.remoteEnabled = false;
	end
end
