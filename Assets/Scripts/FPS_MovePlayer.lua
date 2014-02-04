-- new script file
function OnAfterSceneLoaded(self)
	--get the characterController
	self.characterController = self:GetComponentOfType("vHavokCharacterController")
	self.walkHeight = self.characterController:GetCapsuleHeight()
	self.crouchHeight = self.walkHeight / 2
	
	if self.characterController == nil then
		self.AddComponentOfType("vHavokCharacterController")
	end
	
	--create the input map
	self.map = Input:CreateMap("PlayerInputMap")
	--set the controls for windows
	
	--mouse control for aiming and rotation
	self.map:MapTrigger("X", "MOUSE", "CT_MOUSE_NORM_DELTA_X")
	self.map:MapTrigger("Y", "MOUSE", "CT_MOUSE_NORM_DELTA_Y")
	
	--WASD control for character movement
	self.map:MapTrigger("LEFT", "KEYBOARD", "CT_KB_A")
	self.map:MapTrigger("RIGHT", "KEYBOARD", "CT_KB_D")
	self.map:MapTrigger("FORWARD", "KEYBOARD", "CT_KB_W")
	self.map:MapTrigger("BACK", "KEYBOARD", "CT_KB_S")
	
	--additional controls
	self.map:MapTrigger("FIRE01", "MOUSE", "CT_MOUSE_LEFT_BUTTON", {onceperframe = true} )
	self.map:MapTrigger("JUMP", "KEYBOARD", "CT_KB_SPACE", {onceperframe = true} )
	self.map:MapTrigger("RELOAD", "KEYBOARD", "CT_KB_R", {onceperframe = true} )
	self.map:MapTrigger("RUN", "KEYBOARD", "CT_KB_LSHIFT")
	self.map:MapTrigger("CROUCH", "KEYBOARD", "CT_KB_C")
	
	self.map:MapTrigger("INVERT", "KEYBOARD", "CT_KB_I", {onceperframe = true} )
	
	self.jogSpeed = 5
	self.runSpeed = 10
	self.rotSpeed = 50
	self.invertY = true
	self.yMaxRot = 40
	self.yMinRot = -75
	
	self.gun = GetWeapon(self)
	if self.gun ~= nil then
		SetInitialRotation(self)
	end
	
	Debug:Enable(true)
end

function OnThink(self)
	ShowStats(self)
	
	local x = self.map:GetTrigger("X")
	local y = self.map:GetTrigger("Y")
	
	local left = self.map:GetTrigger("LEFT") ~= 0 
	local right = self.map:GetTrigger("RIGHT") ~= 0 
	local forward = self.map:GetTrigger("FORWARD") ~= 0	
	local back = self.map:GetTrigger("BACK") ~= 0
	
	local jump = self.map:GetTrigger("JUMP") > 0
	local reload = self.map:GetTrigger("RELOAD") > 0
	local run = self.map:GetTrigger("RUN") > 0 
	local fire01 = self.map:GetTrigger("FIRE01") > 0
	local crouch = self.map:GetTrigger("CROUCH") > 0
	
	local invert = self.map:GetTrigger("INVERT") > 0
	
	local forwardVec = self:GetObjDir()
	local rightVec = self:GetObjDir_Right()
	
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
	
	if crouch then
		Crouch(self)
	else
		local top = self.characterController:GetCapsuleHeight()
		if top < self.walkHeight then
			self.characterController:SetCapsuleHeight( self.walkHeight )
		end
	end
	
	--rotation control		
	if math.abs(x) > 0 or math.abs(y) > 0 then
		local step = self.rotSpeed --* Timer:GetTimeDiff()
		local rotation = self:GetOrientation()
		rotation.x = rotation.x - x * step
		if self.invertY then
			rotation.y = rotation.y - y * step
		else
			rotation.y = rotation.y + y * step
		end
		rotation.y = ClampValue(rotation.y, self.yMinRot, self.yMaxRot)
		--rotation.y = math.clamp(rotation.y, self.yMinRot, self.yMaxRot)
		self:SetOrientation(rotation)
	end
	
	--locomotion control
	if (left or right or forward or back or run) and self.characterController:IsStanding() then
		--reset the moveVector to avoid steadily increasing velocity
		self.moveVector = G.zeroVector
		local moveSpeed = 0
		
		if run then 
			moveSpeed = self.runSpeed
		else
			moveSpeed = self.jogSpeed
		end
	
		if left then
			self.moveVector = self.moveVector + rightVec
		elseif right then
			self.moveVector = self.moveVector - rightVec
		end
		
		if forward then
			self.moveVector = self.moveVector + forwardVec
		elseif back then
			self.moveVector = self.moveVector - forwardVec
		end
		
		if self.moveVector:getLength() > 1 then
			self.moveVector:normalize()
		end
		
		self.moveVector = self.moveVector * moveSpeed
		
		--move the character
		self:SetMotionDeltaWorldSpace(self.moveVector)
	end
	
	if invert then
		ToggleInvert(self)
	end
end

function OnBeforeSceneUnloaded(self)
	Input:DestroyMap(self.map)
	self.map = nil
	Game:DeleteAllUnrefScreenMasks()
end

function Fire(self)
	self.gun.FireWeapon(self.gun)
end

function Reload(self)
	self.gun.ReloadWeapon(self.gun)
end

function Jump(self)
	if self.characterController:IsStanding() then
		self.characterController:SetWantJump(true)
	end
end

function Crouch(self)
	Debug:PrintLine("Crouching")
	-- self.characterController:SetCapsuleTop(Vision.hkvVec3(0,0,self.crouchHeight) )
	self.characterController:SetCapsuleHeight( self.crouchHeight )
end

function ShowStats(self)
	Debug:PrintAt(0, 25, "Ammo: " .. self.gun.roundsLoaded .. "/" .. self.gun.magazineSize, Vision.V_RGBA_YELLOW)
	Debug:PrintAt(0, 40, "Rounds: " .. self.gun.totalRounds, Vision.V_RGBA_YELLOW)
end

function ToggleInvert(self)
	self.invertY = not self.invertY
	Debug:PrintLine("Toggled")
end

function GetWeapon(self)
	local numChildren = self:GetNumChildren()
	
	for i = 0, numChildren - 1, 1 do
		local entity = self:GetChild(i)
		
		if entity ~= nil then
			if entity:GetKey() == "Gun" then 
				return entity
			end
		end
	end
end

function SetInitialRotation(self)
	local screenVect = Screen:Project3D(G.w / 2, G.h / 2, self.gun.gunRange)

	if screenVect ~= nil then
		local dir = screenVect - self.gun:GetPosition()
		dir:normalize()
		self.gun:SetDirection(dir)
	end
end

function ClampValue(num, minVal, maxVal)
	if num > maxVal then
		num = maxVal
	elseif num < minVal then
		num = minVal
	end
	return num
end