--Author: Denmark Gibbs
--The global variables and scene logic go here
--Attach this script to the Main Layer in vForge

function OnBeforeSceneLoaded(self)
	--check the platform
	G.isWindows = (Application:GetPlatformName() == "WIN32DX9" or Application:GetPlatformName() == "WIN32DX11")
	
		-- set up the reticle
	G.w, G.h = Screen:GetViewportSize()
	
	--draw the target reticle in the center of the screen
	local width = G.w * 0.1
	G.screenMask = Game:CreateScreenMask(G.w / 2 - width / 2.0, G.h / 2 - width / 2.0, "Textures/FPS_Reticule_DIFFUSE.tga")
	G.screenMask:SetTargetSize(width, width)
	G.screenMask:SetBlending(Vision.BLEND_ADDITIVE)
	
	-- create the help button
	if G.isWindows then
		G.helpButton = Game:CreateScreenMask(0, 0, "Textures/FPS_HelpButton_PC.tga")
	else
		G.helpButton = Game:CreateScreenMask(0, 0, "Textures/FPS_HelpButton_Touch.tga")
	end
	
	--get the size of the help button, then move to the bottom left corner
	local helpX, helpY = G.helpButton:GetTextureSize()
	G.helpButton:SetPos( (G.w / 2) - helpX / 2, G.h - helpY) 
	G.helpButton:SetBlending(Vision.BLEND_ALPHA)
	G.helpTable = { (G.w / 2) - helpX / 2, G.h - helpY, (G.w / 2) + helpX / 2, G.h, -900, "new"}
	
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

		local xPercent_R = 0.8 --percentage of the screen to align objects to the right
		x = 64 --the texture size
		
		top = (G.h * yPercent) - (x * 1.5)
		bottom = (G.h * yPercent) + (x * 1.5)
		left = (G.w * xPercent_R) - (x * 1.5)
		right = (G.w * xPercent_R) + (x * 1.5)
		
		--{startx, starty, end x, endy}
		G.blueButton = Game:CreateScreenMask(left + x, top, "Textures/FPS_MobileHud/FPS_Button_Blue_64.tga")
		G.blueButton:SetBlending(Vision.BLEND_ALPHA)
		G.blueTable = {left + x, top, right - x, top + x, 150}
		
		G.greenButton = Game:CreateScreenMask(left + x, bottom - x, "Textures/FPS_MobileHud/FPS_Button_Green_64.tga")
		G.greenButton:SetBlending(Vision.BLEND_ALPHA)
		G.greenTable = {left + x, bottom - x, right - x, bottom, 150}
		
		G.yellowButton = Game:CreateScreenMask(left, top + x, "Textures/FPS_MobileHud/FPS_Button_Yellow_64.tga")
		G.yellowButton:SetBlending(Vision.BLEND_ALPHA)
		G.yellowTable = {left, top + x, left + x, bottom - x, 150}
		
		G.redButton = Game:CreateScreenMask(right - x, top + x, "Textures/FPS_MobileHud/FPS_Button_Red_64.tga")
		G.redButton:SetBlending(Vision.BLEND_ALPHA)
		G.redTable = {right - x, top + x, right, bottom - x, 150}
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
