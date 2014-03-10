--Author: Denmark Gibbs
--This script controls all logic for the player.
--This includes player movement, and all input

function OnAfterSceneLoaded(self)	
	--enable Debug Mode
	Debug:Enable(true)
	
	--get the characterController
	self.characterController = self:GetComponentOfType("vHavokCharacterController")
	self.walkHeight = self.characterController:GetCapsuleTop()
	self.crouchHeight = self.walkHeight.z / 2
	
	if self.characterController == nil then
		self.AddComponentOfType("vHavokCharacterController")
	end

	if G.playerStartPos ~= nil and G.playerStartRot ~= nil then
		self.characterController:SetPosition(G.playerStartPos)
		self:SetOrientation(G.playerStartRot)
	end
	
	--These variables can be moved to OnExpose for easy access
	self.singleFire = false --if true, the gun will only fire once per click
	
	--movement variables
	self.jogSpeed = 7.5
	self.runSpeed = 10
	self.rotSpeed = 50
	
	--Invert Y
	self.invertY = true
	
	--Y values to clamp to
	self.yMaxRot = 40
	self.yMinRot = -75
	
	--create the input map
	self.map = Input:CreateMap("PlayerInputMap")
	--set the controls for windows
	
	if G.isWindows then
		--tell the player how to access help
		Debug:PrintLine("*==========================", Vision.V_RGBA_YELLOW)
		Debug:PrintLine("*== For Help, Hold \"H\"", Vision.V_RGBA_YELLOW)
		Debug:PrintLine("*==========================", Vision.V_RGBA_YELLOW)
				
		--mouse control for aiming and rotation
		self.map:MapTrigger("X", "MOUSE", "CT_MOUSE_NORM_DELTA_X")
		self.map:MapTrigger("Y", "MOUSE", "CT_MOUSE_NORM_DELTA_Y")
		
		--WASD control for character movement
		self.map:MapTrigger("LEFT", "KEYBOARD", "CT_KB_A")
		self.map:MapTrigger("RIGHT", "KEYBOARD", "CT_KB_D")
		self.map:MapTrigger("FORWARD", "KEYBOARD", "CT_KB_W")
		self.map:MapTrigger("BACK", "KEYBOARD", "CT_KB_S")
		
		--the firing style
		if self.singleFire then
			self.map:MapTrigger("FIRE01", "MOUSE", "CT_MOUSE_LEFT_BUTTON", {onceperframe = true} )
		else
			self.map:MapTrigger("FIRE01", "MOUSE", "CT_MOUSE_LEFT_BUTTON")
		end
		
		--additional controls
		self.map:MapTrigger("JUMP", "KEYBOARD", "CT_KB_SPACE")
		self.map:MapTrigger("RELOAD", "KEYBOARD", "CT_KB_R", {onceperframe = true} ) 
		self.map:MapTrigger("RUN", "KEYBOARD", "CT_KB_LSHIFT")
		self.map:MapTrigger("CROUCH", "KEYBOARD", "CT_KB_C")
		
		self.map:MapTrigger("INVERT", "KEYBOARD", "CT_KB_I", {onceperframe = true} ) --invert Y
		--self.map:MapTrigger("RESET", "KEYBOARD", "CT_KB_1", {onceperframe = true} )	--reset targets
		self.map:MapTrigger("DISPLAY", "KEYBOARD", "CT_KB_H") --will show the display whilst holding 
		self.map:MapTrigger("ANY", "KEYBOARD", "CT_KB_ANYKEY") --will show the display whilst holding
	else
		--mouse control for aiming and rotation
		self.map:MapTrigger("X", {0, 0, G.w, G.h, "new"}, "CT_TOUCH_NORM_DELTA_X")
		self.map:MapTrigger("Y", {0, 0, G.w, G.h}, "CT_TOUCH_NORM_DELTA_Y")

		--WASD control for character movement
		self.map:MapTrigger("LEFT", G.dpad.left, "CT_TOUCH_ANY")
		self.map:MapTrigger("RIGHT", G.dpad.right, "CT_TOUCH_ANY")
		self.map:MapTrigger("FORWARD", G.dpad.up, "CT_TOUCH_ANY")
		self.map:MapTrigger("BACK", G.dpad.down, "CT_TOUCH_ANY")
		
		--the firing style
		if self.singleFire then
			self.map:MapTrigger("FIRE01", G.left, "CT_TOUCH_ANY", {once = true} )
		else
			self.map:MapTrigger("FIRE01", G.left, "CT_TOUCH_ANY")
		end
		
		--additional controls
		self.map:MapTrigger("JUMP", G.down, "CT_TOUCH_ANY")
		self.map:MapTrigger("RELOAD", G.up, "CT_TOUCH_ANY", {once = true} ) 
		self.map:MapTrigger("RUN", G.right, "CT_TOUCH_ANY")
		--self.map:MapTrigger("CROUCH", -input here-, "CT_TOUCH_ANY")
		
		self.map:MapTrigger("INVERT", {0, 0, G.h, G.w}, "CT_TOUCH_TRIPLE_TAP", {once = true} ) --invert Y
		self.map:MapTrigger("DISPLAY", {0, G.h * .9, G.w * .1, G.h}, "CT_TOUCH_ANY") --will show the display whilst holding 
		self.map:MapTrigger("ANY", {0, 0, G.h, G.w}, "CT_TOUCH_ANY")
		--self.map:MapTrigger("RESET", "KEYBOARD", "CT_KB_1", {onceperframe = true} )	--reset targets
	end
	
	--get the gun object, it is a child of the camera
	self.gun = GetWeapon(G.camera)
end

function OnThink(self)
	if not G.gameOver then
		--get all the current player inputs
		local x = self.map:GetTrigger("X")
		local y = self.map:GetTrigger("Y")
		
		local left = self.map:GetTrigger("LEFT") ~= 0 
		local right = self.map:GetTrigger("RIGHT") ~= 0 
		local forward = self.map:GetTrigger("FORWARD") ~= 0	
		local back = self.map:GetTrigger("BACK") ~= 0
		
		local fire01 = self.map:GetTrigger("FIRE01") > 0
		local jump = self.map:GetTrigger("JUMP") > 0
		local reload = self.map:GetTrigger("RELOAD") > 0
		local run = self.map:GetTrigger("RUN") > 0 
		
		-- local crouch = self.map:GetTrigger("CROUCH") > 0
		
		local invert = self.map:GetTrigger("INVERT") > 0
		local display = self.map:GetTrigger("DISPLAY") > 0
		
		--determine the forward vector and right vector based on orientation of the camera
		local forwardVec = G.camera:GetObjDir()
		forwardVec.z = 0;
		forwardVec:normalize()
		local rightVec = G.camera:GetObjDir_Right()
		rightVec.z = 0
		rightVec:normalize()

		--action control (jump, fire, shoot, reload)
		if jump then
			Jump(self)
		end
		
		if reload then
			Reload(self)
		end
		
		if fire01 then
			Fire(self)
		end
		
		--[[
		if crouch then
			Crouch(self)
		else
			local top = self.characterController:GetCapsuleTop()
			if top.z < self.walkHeight.z then
				self.characterController:SetCapsuleTop( self.walkHeight )
			end
		end
		--]]
		
		-- rotation control		
		if math.abs(x) > 0 or math.abs(y) > 0 then
			UpdateRotation(self, x, y)
		end
		
		self.gun.UpdateSight(self.gun)
		self.gun.UpdateTransform(self.gun)
		
		--locomotion control
		if (left or right or forward or back or run) then
			UpdatePosition(self, left, right, forward, back, run, forwardVec, rightVec)
		end
		
		--inversion control
		if invert then
			ToggleInvert(self)
		end
		
		--show 'Help'
		if display then
			ShowControls(self)
		end
	end
end

function OnBeforeSceneUnloaded(self)
	Input:DestroyMap(self.map)
	self.map = nil

	Game:DeleteAllUnrefScreenMasks()
end

function UpdatePosition(self, left, right, forward, back, run, forwardVec, rightVec)
	-- reset the moveVector to avoid steadily increasing velocity
	self.moveVector = G.zeroVector
	local moveSpeed = 0
	
	-- set the proper speed
	if run then 
		moveSpeed = self.runSpeed
	else
		moveSpeed = self.jogSpeed
	end
	
	-- move the character left/right
	if left then
		self.moveVector = self.moveVector + rightVec
	elseif right then
		self.moveVector = self.moveVector - rightVec
	end
	
	-- move the character forward/back
	if forward then
		self.moveVector = self.moveVector + forwardVec
	elseif back then
		self.moveVector = self.moveVector - forwardVec
	end
	
	-- normalize the movement vector
	if self.moveVector:getLength() > 1 then
		self.moveVector:normalize()
	end
	
	-- multiply the move vector by the moveSpeed
	self.moveVector = self.moveVector * moveSpeed
	
	-- move the character
	self:SetMotionDeltaWorldSpace(self.moveVector)
end

function UpdateRotation(self, x, y)
	-- set the amount to move by each frame
	local step = self.rotSpeed
	local rotation = G.camera:GetOrientation()
	rotation.x = rotation.x - x * step
	
	-- get the up/down rotation, accounting for invert state
	if self.invertY then
		rotation.y = rotation.y - y * step
	else
		rotation.y = rotation.y + y * step
	end
	rotation.y = ClampValue(rotation.y, self.yMinRot, self.yMaxRot)
	
	-- update the camera roation
	G.camera:SetOrientation(rotation)
	local orienation = self:GetOrientation()
	orienation.x = rotation.x
	self:SetRotationDelta( Vision.hkvVec3(-x * step, 0, 0) )
end

--calls the fire function on the attached weapon
function Fire(self)
	if self.gun ~= nil then
		self.gun.FireWeapon(self.gun)
	end
end

--calls the reload function on the attached gun
function Reload(self)
	self.gun.ReloadWeapon(self.gun)
end

--A basic function to make the character jump if already on the ground
function Jump(self)
	if self.characterController:IsStanding() then
		self.characterController:SetWantJump(true)
	end
end

--[[
the method to change the character controller's height to allow 'crouching'
this section does not work without a special download from github

function Crouch(self)
	--Debug:PrintLine("Crouching")
	--self.characterController:SetCapsuleTop(Vision.hkvVec3(0, 0, 40) )
end
--]]

function ToggleInvert(self)
	self.invertY = not self.invertY
end

--finds the weapon as a child of the camera. 
function GetWeapon(camea)
	local numChildren = camera:GetNumChildren()
	
	for i = 0, numChildren - 1, 1 do
		local entity = camera:GetChild(i)
		
		if entity ~= nil then
			if entity:GetKey() == "Gun" then 
				entity:SetAlwaysInForeGround(true)
				entity.SetUp(entity)
				return entity
			end
		end
	end
end

--Clamps a num between a min and max, then returns that number
function ClampValue(num, minVal, maxVal)
	if num > maxVal then
		num = maxVal
	elseif num < minVal then
		num = minVal
	end
	return num
end

--This will show all the controls available to the user
function ShowControls(self)
	Debug:PrintAt(10, 32, "Move: WASD", Vision.V_RGBA_WHITE, G.fontPath)
	Debug:PrintAt(10, 64, "Look: MOUSE", Vision.V_RGBA_WHITE, G.fontPath)
	Debug:PrintAt(10, 96, "Run: LEFT SHIFT", Vision.V_RGBA_WHITE, G.fontPath)
	Debug:PrintAt(10, 128, "Fire: LEFT MOUSE BUTTON", Vision.V_RGBA_WHITE, G.fontPath)
	Debug:PrintAt(10, 160, "Reload: R", Vision.V_RGBA_WHITE, G.fontPath)
	Debug:PrintAt(10, 192, "Jump: SPACEBAR", Vision.V_RGBA_WHITE, G.fontPath)
	Debug:PrintAt(10, 224, "Invert Y: I", Vision.V_RGBA_WHITE, G.fontPath)
	local inverted = self.invertY and "yes" or "No"
	Debug:PrintAt(10, 256, "Invered?: " .. inverted , Vision.V_RGBA_WHITE, G.fontPath)
	
end