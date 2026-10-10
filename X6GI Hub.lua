--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsSvc = game:GetService("Stats")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xiguazhi233/ui/refs/heads/main/LinoriaLib.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xiguazhi233/ui/refs/heads/main/addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xiguazhi233/ui/refs/heads/main/addons/ThemeManager.lua"))()

local CONFIG = {
	DEFAULT_SPEED = 16,
	DEFAULT_GRAVITY = 196.2,
	TELEPORT_HEIGHT = 200,
	INVIS_TRANSPARENCY = 0.7,
	REMOTE_TRIGGER_INTERVAL = 0.1,
	REMOTE_NEW_DISTANCE = 1000,
	INTERACT_NEW_DISTANCE = 20,
	REMOTE_TELEPORT_OFFSET = Vector3.new(0, 2, 0),
}

local playerState = {
	isInvisible = false, isNoclip = false, isInfJump = false,
	isInteract = false, isNightVision = false, speedLocked = false,
	isCoinTP = false, currentSpeed = CONFIG.DEFAULT_SPEED,
	remoteEnabled = false,
	isBananaRemover = false, isAutoRespawn = false, isGPUSpinner = false,
	gravityLocked = false, currentGravity = CONFIG.DEFAULT_GRAVITY,
	coinTPSuspendedByRock = false,
	isTeapotTP = false,
	isDeleteSuperTunnelCars = false, isDeleteRockman = false,
	isDeleteMines = false, isDeleteBallpit = false, isDeleteCars = false,
	isTPRedBallTemple = false, isDeleteIncinerator = false, isDeleteWormhole = false,
	isButtonHarvest = false, isDoorHarvest = false, isNoteHarvest = false,
	isTPObbyEnd = false,
	isDeleteElevatorPrompt = false,
	isDeletePestCoin = false,
	isEatingCompEAT = false,
	autoFloorFeatures = false,
}

local G = {
	speedConnection = nil, gravityConnection = nil,
	coinTPCoroutine = nil, coinTPOrigin = nil,
	remoteOriginalDistances = {},
	remoteOriginalHoldDurations = {},
	remoteEventConnections = {},
	remoteHoldLoops = {},
	remoteListener = nil,
	promptOriginalHold = {}, toolCooldownOriginal = {},
	interactOriginalDistances = {},
	bananaRemoverCoroutine = nil, gpuSpinnerCoroutine = nil, autoRespawnLoop = nil,
	descendantAddedConnection = nil,
	invisConnections = { Heartbeat = nil },
	invisInvisible = false, invisCharacter = nil, invisHumanoid = nil, invisRootPart = nil,
	invisOriginalTransparencies = {}, invisOriginalNameTransparency = 0,
	noclipOriginalCollide = {},
	nightVisionConnection = nil, nightVisionOriginal = {},
	teapotTPConnection = nil,
	deleteSuperTunnelCarsCoroutine = nil, deleteRockmanCoroutine = nil,
	deleteMinesCoroutine = nil, deleteBallpitCoroutine = nil,
	deleteCarsCoroutine = nil, deleteIncineratorCoroutine = nil,
	deleteWormholeCoroutine = nil,
	buttonHarvestCoroutine = nil, doorHarvestCoroutine = nil, noteHarvestCoroutine = nil,
	clickedButtons = setmetatable({}, {__mode = "v"}),
	clickedDoors = setmetatable({}, {__mode = "v"}),
	clickedNotes = setmetatable({}, {__mode = "v"}),
	currentFloor = nil,
	completeFloorCoroutines = {},
	completeFloorStates = {},
	slideTpConnection = nil,
	eatingCompEATConnection = nil,
	remoteOriginalCFrame = nil,
	remoteCurrentTarget = nil,
	deleteElevatorPromptCoroutine = nil,
	deletePestCoinCoroutine = nil,
}

local steppedConnection, jumpRequestConnection, characterAddedConnection

local afkSettings = { antiAFK = true, afkClickInterval = 240, checkInterval = 1.0, heartbeatThreshold = 0.6, glitchCountThreshold = 3 }
local afkState = { startClock = os.clock(), lastAfkTick = 0, fps = 60, glitchCount = 0 }

local FLOOR_FEATURES = {
	["Teapot Dodgeball"] = { features = {"teapotTP"}, display = "茶壶循环触发终点" },
	["Teapot Traversal"] = { features = {"teapotTP"}, display = "茶壶循环触发终点" },
	["Super Tunnel"] = { features = {"deleteSuperTunnelCars"}, display = "删除车辆 (Super Tunnel)" },
	["THE ROCK"] = { features = {"deleteRockman"}, display = "删除NPC (THEROCK)" },
	["Minefield"] = { features = {"deleteMines"}, display = "删除地雷 (Minefield)" },
	["FunTimesAtSquishyFlood"] = { features = {"deleteBallpit"}, display = "球海清理 (FunTimesAtSquishyFlood)" },
	["Superhighway"] = { features = {"deleteCars"}, display = "删除车辆 (Superhighway)" },
	["RedBallTemple"] = { features = {"tpRedBallTemple"}, display = "红球神庙终点" },
	["WALL_OF"] = { features = {"deleteIncinerator"}, display = "删除火墙 (WALL_OF)" },
	["ElevatorInsideAx5"] = { features = {"deleteWormhole"}, display = "删除激光 (ElevatorInsideAx5)" },
	["Obby"] = { features = {"tpObbyEnd"}, display = "Obby终点" },
	["ButtonCompetition"] = { features = {"buttonHarvest"}, display = "按钮收割 (ButtonCompetition)" },
	["Cardboard Room"] = { features = {"doorHarvest"}, display = "门收割 (CardboardRoom)" },
	["FunnyMaze"] = { features = {"noteHarvest"}, display = "笔记收割 (FunnyMaze)" },
}
local FEATURE_DISPLAY = {
	invis = "隐身", noclip = "穿墙", infJump = "无限跳跃",
	nightVision = "夜视", interact = "瞬移交互", remote = "远程交互",
	coinTP = "金币传送", teapotTP = "茶壶循环触发终点",
	deleteSuperTunnelCars = "删除车辆 (Super Tunnel)",
	deleteRockman = "删除NPC (THEROCK)",
	deleteMines = "删除地雷 (Minefield)",
	deleteBallpit = "球海清理 (FunTimesAtSquishyFlood)",
	deleteCars = "删除车辆 (Superhighway)",
	tpRedBallTemple = "红球神庙终点",
	deleteIncinerator = "删除火墙 (WALL_OF)",
	deleteWormhole = "删除激光 (ElevatorInsideAx5)",
	tpObbyEnd = "Obby终点",
	gpuSpinner = "GPU 自动旋转",
	buttonHarvest = "按钮收割 (ButtonCompetition)",
	doorHarvest = "门收割 (CardboardRoom)",
	noteHarvest = "笔记收割 (FunnyMaze)",
}
local FEATURE_TOOLTIPS = {
	invis = "使角色半透明并传送至高处",
	noclip = "角色可以穿过墙壁和物体",
	infJump = "在空中可以无限跳跃",
	nightVision = "提高亮度，看清黑暗区域",
	interact = "瞬间完成交互（ProximityPrompt 和 Tool），并扩大交互范围至20",
	remote = "交互时传送至目标并循环触发（ProximityPrompt专用，已修复短按传送）",
	coinTP = "有金币时传送收集，无金币静默不卡位，收集完返回起始位置（剩余≤3个时循环传送最后一个3.5秒）",
	teapotTP = "循环传送至 TeapotDodgeball 和 TeapotTraversal 终点（无延迟）",
	deleteSuperTunnelCars = "删除 Super Tunnel 的 ActiveVehicles 车辆",
	deleteRockman = "删除 THEROCK 的 Npcs NPC",
	deleteMines = "删除 Minefield 的 Mines 地雷",
	deleteBallpit = "清理 FunTimesAtSquishyFlood 的球海（保留 BallPitBase）",
	deleteCars = "删除 Superhighway 的 ActiveCars 过路车",
	tpRedBallTemple = "单次传送至 RedBallTemple 终点位置",
	deleteIncinerator = "删除 WALL_OF 的 incinerator 火墙",
	deleteWormhole = "删除 ElevatorInsideAx5 的 Wormhole 激光",
	tpObbyEnd = "单次传送至 Obby 的 EndPlatform 终板",
	gpuSpinner = "每 5 秒自动旋转一次 GPU 获取金币",
	buttonHarvest = "自动远程点击 ButtonCompetition 的所有按钮（ClickDetector）",
	doorHarvest = "自动远程点击 CardboardRoom 的所有门（ClickDetector）",
	noteHarvest = "自动远程点击 FunnyMaze 的所有笔记（ClickDetector）",
	bananaRemover = "自动删除 Props 下的 BananaPeel、bananer、PurpleBall",
	autoRespawn = "每秒检测一次角色状态，死亡自动重生",
	deleteElevatorPrompt = "删除电梯交互 (workspace.Elevator.ButtonPanel.ProximityPrompt)",
	deletePestCoin = "删除 Pest 的钱 (workspace.Elevator.Npc.Npcs.Pest.Coin)",
	eatingCompEAT = "当前楼层为 EatingComp_DoD_Hot_Dog 时每帧触发 EAT 事件",
}

local function getHumanoid(): Humanoid?
	local char = player.Character
	return char and char:FindFirstChild("Humanoid") :: Humanoid?
end
local function applySpeed(v) local hum = getHumanoid() if hum then hum.WalkSpeed = v end end
local function applyGravity(v) Workspace.Gravity = v end

local function startLoop(stateField, coroutineField, loopFunc, interval)
	if G[coroutineField] then return end
	G[coroutineField] = task.spawn(function()
		while playerState[stateField] do
			loopFunc()
			task.wait(interval)
		end
		G[coroutineField] = nil
	end)
end

local function stopLoop(stateField, coroutineField)
	playerState[stateField] = false
	if G[coroutineField] then
		task.cancel(G[coroutineField])
		G[coroutineField] = nil
	end
end

function G.startSpeedMonitoring()
	if G.speedConnection then G.speedConnection:Disconnect() end
	if not playerState.speedLocked then return end
	local hum = getHumanoid()
	if not hum then return end
	G.speedConnection = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if hum.WalkSpeed ~= playerState.currentSpeed then hum.WalkSpeed = playerState.currentSpeed end
	end)
end
function G.stopSpeedMonitoring() if G.speedConnection then G.speedConnection:Disconnect(); G.speedConnection = nil end end
function G.enableSpeedLock() playerState.speedLocked = true; applySpeed(playerState.currentSpeed); G.startSpeedMonitoring() end
function G.disableSpeedLock() playerState.speedLocked = false; G.stopSpeedMonitoring() end

function G.startGravityMonitoring()
	if G.gravityConnection then G.gravityConnection:Disconnect() end
	if not playerState.gravityLocked then return end
	G.gravityConnection = Workspace:GetPropertyChangedSignal("Gravity"):Connect(function()
		if Workspace.Gravity ~= playerState.currentGravity then Workspace.Gravity = playerState.currentGravity end
	end)
end
function G.stopGravityMonitoring() if G.gravityConnection then G.gravityConnection:Disconnect(); G.gravityConnection = nil end end
function G.enableGravityLock() playerState.gravityLocked = true; applyGravity(playerState.currentGravity); G.startGravityMonitoring() end
function G.disableGravityLock() playerState.gravityLocked = false; G.stopGravityMonitoring() end

function G.setupInvisCharacter()
	G.invisCharacter = player.Character
	if G.invisCharacter then
		G.invisHumanoid = G.invisCharacter:FindFirstChild("Humanoid")
		G.invisRootPart = G.invisCharacter:FindFirstChild("HumanoidRootPart")
		G.invisOriginalTransparencies = {}
		if G.invisHumanoid and G.invisHumanoid:FindFirstChild("NameDisplay") then
			G.invisOriginalNameTransparency = G.invisHumanoid.NameDisplay.TextTransparency or 0
		end
	end
end
function G.toggleInvis()
	local parts = {}
	if G.invisCharacter then
		for _, obj in pairs(G.invisCharacter:GetDescendants()) do if obj:IsA("BasePart") then table.insert(parts, obj) end end
	end
	G.invisInvisible = not G.invisInvisible
	if G.invisInvisible then
		for _, part in pairs(parts) do
			if not G.invisOriginalTransparencies[part] then G.invisOriginalTransparencies[part] = part.Transparency end
			part.Transparency = CONFIG.INVIS_TRANSPARENCY
		end
		if G.invisHumanoid and G.invisHumanoid:FindFirstChild("NameDisplay") then
			G.invisOriginalNameTransparency = G.invisHumanoid.NameDisplay.TextTransparency
			G.invisHumanoid.NameDisplay.TextTransparency = 1
		end
	else
		for _, part in pairs(parts) do
			local orig = G.invisOriginalTransparencies[part]
			part.Transparency = orig ~= nil and orig or 0
		end
		G.invisOriginalTransparencies = {}
		if G.invisHumanoid and G.invisHumanoid:FindFirstChild("NameDisplay") then
			G.invisHumanoid.NameDisplay.TextTransparency = G.invisOriginalNameTransparency or 0
		end
		if G.invisHumanoid then G.invisHumanoid.CameraOffset = Vector3.new(0,0,0) end
	end
	playerState.isInvisible = G.invisInvisible
end
function G.startInvisTeleportLoop()
	if G.invisConnections.Heartbeat then G.invisConnections.Heartbeat:Disconnect() end
	G.invisConnections.Heartbeat = RunService.Heartbeat:Connect(function()
		if not (G.invisInvisible and G.invisCharacter and G.invisRootPart and G.invisHumanoid) then return end
		local currentCF = G.invisRootPart.CFrame
		local targetPos = currentCF.Position
		local hiddenPos = Vector3.new(targetPos.X, targetPos.Y + CONFIG.TELEPORT_HEIGHT, targetPos.Z)
		local hiddenCF = CFrame.new(hiddenPos) * currentCF.Rotation
		G.invisRootPart.CFrame = hiddenCF
		local cameraOffset = hiddenCF:ToObjectSpace(CFrame.new(targetPos)).Position
		G.invisHumanoid.CameraOffset = cameraOffset
		RunService.RenderStepped:Wait()
		G.invisRootPart.CFrame = CFrame.new(targetPos) * currentCF.Rotation
		G.invisHumanoid.CameraOffset = Vector3.new(0,0,0)
	end)
end
function G.stopInvisMonitoring()
	if G.invisConnections.Heartbeat then G.invisConnections.Heartbeat:Disconnect(); G.invisConnections.Heartbeat = nil end
	if G.invisHumanoid then G.invisHumanoid.CameraOffset = Vector3.new(0,0,0) end
end
function G.enableInvis() if not G.invisCharacter then G.setupInvisCharacter() end; if not G.invisInvisible then G.toggleInvis() end; G.startInvisTeleportLoop() end
function G.disableInvis() if G.invisInvisible then G.toggleInvis() end; G.stopInvisMonitoring() end

function G.storeNoclipState(char)
	G.noclipOriginalCollide = {}
	if char then
		for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then G.noclipOriginalCollide[part] = part.CanCollide end end
	end
end
function G.applyNoclip(state)
	local char = player.Character
	if not char then return end
	if state then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				if G.noclipOriginalCollide[part] == nil then G.noclipOriginalCollide[part] = part.CanCollide end
				part.CanCollide = false
			end
		end
	else
		for part, original in pairs(G.noclipOriginalCollide) do if part and part.Parent then part.CanCollide = original end end
		G.noclipOriginalCollide = {}
	end
end
function G.enableNoclip() playerState.isNoclip = true; local char = player.Character; if char then G.storeNoclipState(char) end; G.applyNoclip(true) end
function G.disableNoclip() playerState.isNoclip = false; G.applyNoclip(false) end

function G.enableInfJump() playerState.isInfJump = true end
function G.disableInfJump() playerState.isInfJump = false end

function G.storeAndModifyPrompt(prompt)
	if prompt:IsA("ProximityPrompt") then
		if not G.promptOriginalHold[prompt] then
			G.promptOriginalHold[prompt] = prompt.HoldDuration
		end
		prompt.HoldDuration = 0
		if not G.interactOriginalDistances[prompt] then
			G.interactOriginalDistances[prompt] = prompt.MaxActivationDistance
		end
		prompt.MaxActivationDistance = CONFIG.INTERACT_NEW_DISTANCE
	end
end
function G.storeAndModifyTool(tool)
	if tool:IsA("Tool") and not G.toolCooldownOriginal[tool] then
		local cooldown = tool:GetAttribute("Cooldown")
		G.toolCooldownOriginal[tool] = cooldown
		tool:SetAttribute("Cooldown", 0)
	end
end
function G.applyToAll()
	for _, obj in ipairs(game:GetDescendants()) do G.storeAndModifyPrompt(obj); G.storeAndModifyTool(obj) end
end
function G.restoreAllInteractions()
	for prompt, original in pairs(G.promptOriginalHold) do if prompt and prompt.Parent then prompt.HoldDuration = original end end
	G.promptOriginalHold = {}
	for tool, original in pairs(G.toolCooldownOriginal) do
		if tool and tool.Parent then
			if original == nil then tool:SetAttribute("Cooldown", nil) else tool:SetAttribute("Cooldown", original) end
		end
	end
	G.toolCooldownOriginal = {}
end
function G.enableInteract()
	playerState.isInteract = true
	G.applyToAll()
	if not G.descendantAddedConnection then
		G.descendantAddedConnection = game.DescendantAdded:Connect(function(obj)
			if playerState.isInteract then G.storeAndModifyPrompt(obj); G.storeAndModifyTool(obj) end
		end)
	end
end
function G.disableInteract()
	playerState.isInteract = false
	G.restoreAllInteractions()
	if not playerState.remoteEnabled then
		for prompt, original in pairs(G.interactOriginalDistances) do
			if prompt and prompt.Parent then
				pcall(function() prompt.MaxActivationDistance = original end)
			end
		end
	end
	G.interactOriginalDistances = {}
	if G.descendantAddedConnection then
		G.descendantAddedConnection:Disconnect()
		G.descendantAddedConnection = nil
	end
end

local function getTargetPosition(prompt)
	local parent = prompt.Parent
	if not parent then return nil end

	local function findBasePart(instance)
		if instance:IsA("BasePart") then
			return instance
		end
		if instance:IsA("Model") then
			if instance.PrimaryPart then
				return instance.PrimaryPart
			end
			for _, child in ipairs(instance:GetDescendants()) do
				if child:IsA("BasePart") then
					return child
				end
			end
		end
		return nil
	end

	local part = findBasePart(parent)
	if part then return part.Position end

	local grandParent = parent.Parent
	if grandParent then
		part = findBasePart(grandParent)
		if part then return part.Position end
	end

	if prompt:IsA("BasePart") then
		return prompt.Position
	end
	return nil
end

local function remoteModifyInstance(instance, enable)
	if not instance or not instance:IsA("ProximityPrompt") then return end
	local propName = "MaxActivationDistance"
	local success, originalDist = pcall(function() return instance[propName] end)
	if success and originalDist ~= nil then
		if enable then
			if not G.remoteOriginalDistances[instance] then
				G.remoteOriginalDistances[instance] = originalDist
			end
			pcall(function() instance.MaxActivationDistance = CONFIG.REMOTE_NEW_DISTANCE end)
		else
			if G.remoteOriginalDistances[instance] ~= nil then
				pcall(function() instance.MaxActivationDistance = G.remoteOriginalDistances[instance] end)
				G.remoteOriginalDistances[instance] = nil
			end
		end
	end

	local holdProp = "HoldDuration"
	local success, origHold = pcall(function() return instance[holdProp] end)
	if success and origHold ~= nil then
		if enable then
			if not G.remoteOriginalHoldDurations[instance] then
				G.remoteOriginalHoldDurations[instance] = origHold
			end
			local newHold = (G.remoteOriginalHoldDurations[instance] or 0) + 1
			pcall(function() instance.HoldDuration = newHold end)
		else
			if G.remoteOriginalHoldDurations[instance] ~= nil then
				pcall(function() instance.HoldDuration = G.remoteOriginalHoldDurations[instance] end)
				G.remoteOriginalHoldDurations[instance] = nil
			end
		end
	end
end

local function remoteStartHoldLoop(prompt)
	if G.remoteHoldLoops[prompt] and G.remoteHoldLoops[prompt].running then return end

	local canFire = type(fireproximityprompt) == "function"
	if not canFire then
		warn("[远程交互] fireproximityprompt 不存在，仅传送不触发")
	end

	local loopRunning = true
	local lastTriggerTime = 0
	local targetPos = getTargetPosition(prompt) or Vector3.new(0,0,0)

	local connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not loopRunning then
			connection:Disconnect()
			return
		end
		if not playerState.remoteEnabled then
			loopRunning = false
			return
		end
		if not prompt or not prompt.Parent then
			loopRunning = false
			return
		end
		local char = player.Character
		if not char then return end
		local rootPart = char:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local pos = getTargetPosition(prompt)
		if pos then
			targetPos = pos
			local newPos = pos + CONFIG.REMOTE_TELEPORT_OFFSET
			pcall(function() rootPart.CFrame = CFrame.new(newPos) end)
		end

		local currentTime = tick()
		if currentTime - lastTriggerTime >= CONFIG.REMOTE_TRIGGER_INTERVAL then
			lastTriggerTime = currentTime
			if canFire then
				pcall(function() fireproximityprompt(prompt) end)
			end
		end
	end)

	G.remoteHoldLoops[prompt] = {
		running = true,
		connection = connection,
	}
end

local function remoteStopHoldLoop(prompt)
	local loop = G.remoteHoldLoops[prompt]
	if loop then
		loop.running = false
		if loop.connection then
			pcall(function() loop.connection:Disconnect() end)
		end
		G.remoteHoldLoops[prompt] = nil
	end
end

local function remoteBindEvents(instance)
	if not instance:IsA("ProximityPrompt") then return end
	if G.remoteEventConnections[instance] then return end

	local beganConn = instance.PromptButtonHoldBegan:Connect(function()
		if not playerState.remoteEnabled then return end
		local char = player.Character
		if not char then return end
		local rootPart = char:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		if G.remoteOriginalCFrame then
			pcall(function() rootPart.CFrame = G.remoteOriginalCFrame end)
			G.remoteOriginalCFrame = nil
			G.remoteCurrentTarget = nil
		end

		G.remoteOriginalCFrame = rootPart.CFrame
		G.remoteCurrentTarget = instance

		local pos = getTargetPosition(instance)
		if pos then
			local newPos = pos + CONFIG.REMOTE_TELEPORT_OFFSET
			pcall(function() rootPart.CFrame = CFrame.new(newPos) end)
		end

		remoteStartHoldLoop(instance)
	end)

	local endedConn = instance.PromptButtonHoldEnded:Connect(function()
		if not playerState.remoteEnabled then return end
		remoteStopHoldLoop(instance)
		if G.remoteOriginalCFrame and G.remoteCurrentTarget == instance then
			local char = player.Character
			if char then
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				if rootPart then
					pcall(function() rootPart.CFrame = G.remoteOriginalCFrame end)
				end
			end
			G.remoteOriginalCFrame = nil
			G.remoteCurrentTarget = nil
		end
	end)

	G.remoteEventConnections[instance] = {beganConn, endedConn}
end

local function remoteUnbindEvents(instance)
	local conns = G.remoteEventConnections[instance]
	if conns then
		for _, conn in ipairs(conns) do
			pcall(function() conn:Disconnect() end)
		end
		G.remoteEventConnections[instance] = nil
	end
	remoteStopHoldLoop(instance)
end

local function remoteScanAndModify(enable)
	for _, obj in ipairs(game:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then
			if enable then
				remoteModifyInstance(obj, true)
				remoteBindEvents(obj)
			else
				remoteUnbindEvents(obj)
				remoteModifyInstance(obj, false)
			end
		end
	end
end

local function remoteStartListening()
	if G.remoteListener then return end
	G.remoteListener = game.DescendantAdded:Connect(function(obj)
		if playerState.remoteEnabled and obj:IsA("ProximityPrompt") then
			remoteModifyInstance(obj, true)
			remoteBindEvents(obj)
		end
	end)
end

local function remoteStopListening()
	if G.remoteListener then
		G.remoteListener:Disconnect()
		G.remoteListener = nil
	end
end

function G.enableRemote()
	if playerState.remoteEnabled then return end
	playerState.remoteEnabled = true
	remoteScanAndModify(true)
	remoteStartListening()
	Library:Notify("远程交互已启用（HoldDuration +1）", 2)
end

function G.disableRemote()
	if not playerState.remoteEnabled then return end
	playerState.remoteEnabled = false
	for prompt, _ in pairs(G.remoteHoldLoops) do
		remoteStopHoldLoop(prompt)
	end
	if G.remoteOriginalCFrame then
		local char = player.Character
		if char then
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if rootPart then
				pcall(function() rootPart.CFrame = G.remoteOriginalCFrame end)
			end
		end
		G.remoteOriginalCFrame = nil
		G.remoteCurrentTarget = nil
	end
	remoteScanAndModify(false)
	remoteStopListening()
	Library:Notify("远程交互已禁用", 2)
end

function G.applyNightVisionValues()
	Lighting.Brightness = 8
	Lighting.Ambient = Color3.fromRGB(120,150,120)
	Lighting.ColorShift_Bottom = Color3.fromRGB(0,150,0)
	Lighting.ColorShift_Top = Color3.fromRGB(0,80,0)
end
function G.restoreLighting()
	if G.nightVisionOriginal.Brightness ~= nil then Lighting.Brightness = G.nightVisionOriginal.Brightness end
	if G.nightVisionOriginal.Ambient ~= nil then Lighting.Ambient = G.nightVisionOriginal.Ambient end
	if G.nightVisionOriginal.ColorShift_Bottom ~= nil then Lighting.ColorShift_Bottom = G.nightVisionOriginal.ColorShift_Bottom end
	if G.nightVisionOriginal.ColorShift_Top ~= nil then Lighting.ColorShift_Top = G.nightVisionOriginal.ColorShift_Top end
end
function G.enableNightVision()
	if playerState.isNightVision then return end
	G.nightVisionOriginal.Brightness = Lighting.Brightness
	G.nightVisionOriginal.Ambient = Lighting.Ambient
	G.nightVisionOriginal.ColorShift_Bottom = Lighting.ColorShift_Bottom
	G.nightVisionOriginal.ColorShift_Top = Lighting.ColorShift_Top
	G.applyNightVisionValues()
	if G.nightVisionConnection then G.nightVisionConnection:Disconnect() end
	G.nightVisionConnection = RunService.Heartbeat:Connect(function() if playerState.isNightVision then G.applyNightVisionValues() end end)
	playerState.isNightVision = true
end
function G.disableNightVision()
	if not playerState.isNightVision then return end
	if G.nightVisionConnection then G.nightVisionConnection:Disconnect(); G.nightVisionConnection = nil end
	G.restoreLighting()
	playerState.isNightVision = false
end

function G.isExcludedCoin(obj)
	if not obj then return false end
	local parent = obj.Parent
	if not parent then return false end
	local grandParent = parent.Parent
	if not grandParent then return false end
	local greatGrandParent = grandParent.Parent
	if not greatGrandParent then return false end
	if greatGrandParent.Name == "THEROCK" and grandParent.Name == "Coins" and parent.Name == "Other" then
		local children = parent:GetChildren()
		for i = 5, 9 do if children[i] == obj then return true end end
	end
	return false
end

function G.getAllCoinsSorted()
	local char = player.Character
	if not char then return {} end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return {} end
	local pos = hrp.Position
	local coins = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "Coin" then
			local isUseless = false
			local current = obj
			while current do if current.Name == "Useless Coin" then isUseless = true break end current = current.Parent end
			if isUseless then continue end
			if G.isExcludedCoin(obj) then continue end
			local coinPos
			if obj:IsA("BasePart") then coinPos = obj.Position
			elseif obj:IsA("Model") and obj.PrimaryPart then coinPos = obj.PrimaryPart.Position
			else
				local part = obj:FindFirstChildWhichIsA("BasePart")
				if part then coinPos = part.Position else continue end
			end
			if coinPos then table.insert(coins, {obj = obj, dist = (coinPos - pos).Magnitude}) end
		end
	end
	table.sort(coins, function(a,b) return a.dist < b.dist end)
	return coins
end

function G.teleportToCoin(coin)
	if not coin then return false end
	local char = player.Character
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local targetPos
	if coin:IsA("BasePart") then targetPos = coin.Position
	elseif coin:IsA("Model") and coin.PrimaryPart then targetPos = coin.PrimaryPart.Position
	else
		local part = coin:FindFirstChildWhichIsA("BasePart")
		if part then targetPos = part.Position else return false end
	end
	hrp.CFrame = CFrame.new(targetPos + Vector3.new(0,2,0))
	hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
	local hum = char:FindFirstChild("Humanoid")
	if hum then hum.PlatformStand = true end
	return true
end

function G.startCoinTPLoop()
	if G.coinTPCoroutine then return end
	local lastCoin = nil; local sameCoinStart = 0
	G.coinTPCoroutine = task.spawn(function()
		while playerState.isCoinTP do
			if playerState.coinTPSuspendedByRock then task.wait(0.5) continue end
			local coins = G.getAllCoinsSorted()
			if #coins == 0 then
				if G.coinTPOrigin then
					local char = player.Character
					if char then
						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp then
							hrp.CFrame = CFrame.new(G.coinTPOrigin + Vector3.new(0,2,0))
							hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
							local hum = char:FindFirstChild("Humanoid")
							if hum then hum.PlatformStand = true end
						end
					end
				end
				lastCoin = nil; sameCoinStart = 0; task.wait(0.5)
			else
				for _, coinData in ipairs(coins) do
					if not playerState.isCoinTP then break end
					if playerState.coinTPSuspendedByRock then break end
					local coin = coinData.obj
					if coin and coin.Parent then
						if coin == lastCoin then
							if os.clock() - sameCoinStart > 3 then
								pcall(function() coin:Destroy() end)
								lastCoin = nil; sameCoinStart = 0; break
							end
						else
							lastCoin = coin; sameCoinStart = os.clock()
						end
						G.teleportToCoin(coin)
						task.wait(0.1)
					else
						if coin == lastCoin then lastCoin = nil; sameCoinStart = 0 end
					end
				end
				task.wait(0.05)
			end
		end
		local char = player.Character
		if char then
			local hum = char:FindFirstChild("Humanoid")
			if hum then hum.PlatformStand = false end
		end
		G.coinTPCoroutine = nil
	end)
end

function G.stopCoinTPLoop()
	playerState.isCoinTP = false
	if G.coinTPCoroutine then
		task.cancel(G.coinTPCoroutine)
		G.coinTPCoroutine = nil
	end
	G.coinTPOrigin = nil
	local char = player.Character
	if char then
		local hum = char:FindFirstChild("Humanoid")
		if hum then hum.PlatformStand = false end
	end
end

function G.enableCoinTP()
	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			G.coinTPOrigin = hrp.Position
		end
	end
	playerState.isCoinTP = true
	playerState.coinTPSuspendedByRock = false
	G.startCoinTPLoop()
end

function G.disableCoinTP()
	playerState.coinTPSuspendedByRock = false
	G.stopCoinTPLoop()
end

function G.suspendCoinTPForRock()
	if playerState.isCoinTP and not playerState.coinTPSuspendedByRock then
		playerState.coinTPSuspendedByRock = true
		Library:Notify("THEROCK 楼层，金币传送已暂停", 2)
	end
end

function G.resumeCoinTPForRock()
	if playerState.isCoinTP and playerState.coinTPSuspendedByRock then
		playerState.coinTPSuspendedByRock = false
		Library:Notify("已离开 THEROCK，金币传送已恢复", 2)
	end
end

function G.deleteBananas()
	local props = workspace:FindFirstChild("Props")
	if not props then return 0 end
	local toDelete = {}
	for _, obj in ipairs(props:GetDescendants()) do
		if obj.Name == "BananaPeel" or obj.Name == "bananer" or obj.Name == "PurpleBall" then table.insert(toDelete, obj) end
	end
	for _, obj in ipairs(toDelete) do pcall(function() obj:Destroy() end) end
	return #toDelete
end

function G.respawnPlayer()
	local re = ReplicatedStorage:FindFirstChild("RE")
	if re then
		local respawnRemote = re:FindFirstChild("Respawn")
		if respawnRemote then respawnRemote:FireServer(); return true end
	end
	pcall(function() player:LoadCharacter() end)
	return true
end

function G.deleteSuperTunnelCars()
	local target = workspace:FindFirstChild("SuperTunnel")
	if not target then return 0 end
	local active = target:FindFirstChild("ActiveVehicles")
	if not active then return 0 end
	local toDelete = {}
	for _, obj in ipairs(active:GetChildren()) do table.insert(toDelete, obj) end
	for _, obj in ipairs(toDelete) do pcall(function() obj:Destroy() end) end
	return #toDelete
end

function G.deleteRockmanNPCs()
	local target = workspace:FindFirstChild("THEROCK")
	if not target then return 0 end
	local build = target:FindFirstChild("Build")
	if not build then return 0 end
	local npcs = build:FindFirstChild("Npcs")
	if not npcs then return 0 end
	local toDelete = {}
	for _, obj in ipairs(npcs:GetChildren()) do table.insert(toDelete, obj) end
	for _, obj in ipairs(toDelete) do pcall(function() obj:Destroy() end) end
	return #toDelete
end

function G.deleteMines()
	local target = workspace:FindFirstChild("Minefield")
	if not target then return 0 end
	local build = target:FindFirstChild("Build")
	if not build then return 0 end
	local minesFolder = build:FindFirstChild("MinesFolder")
	if not minesFolder then return 0 end
	local mines = minesFolder:FindFirstChild("Mines")
	if not mines then return 0 end
	local toDelete = {}
	for _, obj in ipairs(mines:GetChildren()) do table.insert(toDelete, obj) end
	for _, obj in ipairs(toDelete) do pcall(function() obj:Destroy() end) end
	return #toDelete
end

function G.deleteBallpit()
	local target = workspace:FindFirstChild("FunTimesAtSquishyFlood")
	if not target then return 0 end
	local build = target:FindFirstChild("Build")
	if not build then return 0 end
	local ballpit = build:FindFirstChild("Ballpit")
	if not ballpit then return 0 end
	local toDelete = {}
	for _, obj in ipairs(ballpit:GetChildren()) do
		if obj.Name ~= "BallPitBase" then table.insert(toDelete, obj) end
	end
	for _, obj in ipairs(toDelete) do pcall(function() obj:Destroy() end) end
	return #toDelete
end

function G.deleteCars()
	local target = workspace:FindFirstChild("Superhighway")
	if not target then return 0 end
	local active = target:FindFirstChild("ActiveCars")
	if not active then return 0 end
	local toDelete = {}
	for _, obj in ipairs(active:GetChildren()) do table.insert(toDelete, obj) end
	for _, obj in ipairs(toDelete) do pcall(function() obj:Destroy() end) end
	return #toDelete
end

function G.deleteIncinerator()
	local target = workspace:FindFirstChild("WALL_OF")
	if not target then return 0 end
	local build = target:FindFirstChild("Build")
	if not build then return 0 end
	local incinerator = build:FindFirstChild("incinerator")
	if not incinerator then return 0 end
	incinerator:Destroy()
	return 1
end

function G.deleteWormhole()
	local target = workspace:FindFirstChild("ElevatorInsideAx5")
	if not target then return 0 end
	local build = target:FindFirstChild("Build")
	if not build then return 0 end
	local wormhole = build:FindFirstChild("Wormhole")
	if not wormhole then return 0 end
	wormhole:Destroy()
	return 1
end

function G.deleteElevatorPrompt()
	local elevator = workspace:FindFirstChild("Elevator")
	if not elevator then return 0 end
	local buttonPanel = elevator:FindFirstChild("ButtonPanel")
	if not buttonPanel then return 0 end
	local prompt = buttonPanel:FindFirstChild("ProximityPrompt")
	if prompt then
		pcall(function() prompt:Destroy() end)
		return 1
	end
	return 0
end

function G.deletePestCoin()
	local elevator = workspace:FindFirstChild("Elevator")
	if not elevator then return 0 end
	local npc = elevator:FindFirstChild("Npc")
	if not npc then return 0 end
	local npcs = npc:FindFirstChild("Npcs")
	if not npcs then return 0 end
	local pest = npcs:FindFirstChild("Pest")
	if not pest then return 0 end
	local coin = pest:FindFirstChild("Coin")
	if coin then
		pcall(function() coin:Destroy() end)
		return 1
	end
	return 0
end

function G.enableBananaRemover() playerState.isBananaRemover = true; startLoop("isBananaRemover", "bananaRemoverCoroutine", G.deleteBananas, 0.1) end
function G.disableBananaRemover() stopLoop("isBananaRemover", "bananaRemoverCoroutine") end

function G.enableAutoRespawn()
	if playerState.isAutoRespawn then return end
	playerState.isAutoRespawn = true
	startLoop("isAutoRespawn", "autoRespawnLoop", function()
		local char = player.Character
		local dead = false
		if not char then dead = true
		else
			local hum = char:FindFirstChild("Humanoid")
			if hum then
				if hum.Health <= 0 then dead = true end
			else dead = true end
		end
		if dead then G.respawnPlayer() end
	end, 1)
end
function G.disableAutoRespawn() stopLoop("isAutoRespawn", "autoRespawnLoop") end

function G.enableGPUSpinner()
	if playerState.isGPUSpinner then return end
	playerState.isGPUSpinner = true
	startLoop("isGPUSpinner", "gpuSpinnerCoroutine", function()
		local char = player.Character
		if char then
			local gpu = char:FindFirstChild("Generation Processing Unit")
			if gpu then
				pcall(function()
					local re = ReplicatedStorage:FindFirstChild("RE")
					if re then
						local gpuRemote = re:FindFirstChild("GPU")
						if gpuRemote then gpuRemote:InvokeServer(gpu) end
					end
				end)
			end
		end
	end, 5)
end
function G.disableGPUSpinner() stopLoop("isGPUSpinner", "gpuSpinnerCoroutine") end

local TEA_PATHS = {
	"workspace.TeapotDodgeball.Build.Finish",
	"workspace.TeapotTraversal.Build.Finish",
}

function G.getPartFromPath(path)
	local parts = {}
	for part in path:gmatch("[^%.]+") do
		table.insert(parts, part)
	end
	local obj = workspace
	for i = 2, #parts do
		obj = obj and obj:FindFirstChild(parts[i])
		if not obj then break end
	end
	return obj
end

function G.enableTeapotTP()
	if playerState.isTeapotTP then return end
	if G.teapotTPConnection then return end
	playerState.isTeapotTP = true

	G.teapotTPConnection = RunService.Heartbeat:Connect(function()
		if not playerState.isTeapotTP then
			G.teapotTPConnection:Disconnect()
			G.teapotTPConnection = nil
			return
		end
		local char = player.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		for _, path in ipairs(TEA_PATHS) do
			local target = G.getPartFromPath(path)
			if target and target:IsA("BasePart") then
				pcall(function()
					hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 2, 0))
				end)
			end
		end
	end)
end

function G.disableTeapotTP()
	playerState.isTeapotTP = false
	if G.teapotTPConnection then
		G.teapotTPConnection:Disconnect()
		G.teapotTPConnection = nil
	end
end

function G.enableEatingCompEAT()
	if playerState.isEatingCompEAT then return end
	if G.eatingCompEATConnection then return end
	playerState.isEatingCompEAT = true

	G.eatingCompEATConnection = RunService.Heartbeat:Connect(function()
		if not playerState.isEatingCompEAT then
			G.eatingCompEATConnection:Disconnect()
			G.eatingCompEATConnection = nil
			return
		end
		local floor = workspace:FindFirstChild("EatingComp_DoD_Hot_Dog")
		if floor then
			local eat = floor:FindFirstChild("EAT")
			if eat and type(eat.FireServer) == "function" then
				pcall(function() eat:FireServer() end)
			end
		end
	end)
end

function G.disableEatingCompEAT()
	playerState.isEatingCompEAT = false
	if G.eatingCompEATConnection then
		G.eatingCompEATConnection:Disconnect()
		G.eatingCompEATConnection = nil
	end
end

function G.tpRedBallTemple()
	local target = workspace:FindFirstChild("RedBallTemple")
	if not target then return false end
	local build = target:FindFirstChild("Build")
	if not build then return false end
	local obstacles = build:FindFirstChild("Obstacles")
	if not obstacles then return false end
	local children1 = obstacles:GetChildren()
	local part8 = children1[8]
	if not part8 then return false end
	local children2 = part8:GetChildren()
	local targetPart = children2[3]
	if targetPart and targetPart:IsA("BasePart") then
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(targetPart.Position + Vector3.new(0,2,0))
				return true
			end
		end
	end
	return false
end
function G.enableTPRedBallTemple() playerState.isTPRedBallTemple = true; G.tpRedBallTemple() end
function G.disableTPRedBallTemple() playerState.isTPRedBallTemple = false end

function G.tpObbyEnd()
	local target = workspace:FindFirstChild("Obby")
	if not target then return false end
	local build = target:FindFirstChild("Build")
	if not build then return false end
	local endPlatform = build:FindFirstChild("EndPlatform")
	if endPlatform and endPlatform:IsA("BasePart") then
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(endPlatform.Position + Vector3.new(0,2,0))
				return true
			end
		end
	end
	return false
end
function G.enableTPObbyEnd() playerState.isTPObbyEnd = true; G.tpObbyEnd() end
function G.disableTPObbyEnd() playerState.isTPObbyEnd = false end

function G.enableDeleteSuperTunnelCars() playerState.isDeleteSuperTunnelCars = true; startLoop("isDeleteSuperTunnelCars", "deleteSuperTunnelCarsCoroutine", G.deleteSuperTunnelCars, 0.5) end
function G.disableDeleteSuperTunnelCars() stopLoop("isDeleteSuperTunnelCars", "deleteSuperTunnelCarsCoroutine") end

function G.enableDeleteRockman() playerState.isDeleteRockman = true; startLoop("isDeleteRockman", "deleteRockmanCoroutine", G.deleteRockmanNPCs, 1) end
function G.disableDeleteRockman() stopLoop("isDeleteRockman", "deleteRockmanCoroutine") end

function G.enableDeleteMines() playerState.isDeleteMines = true; startLoop("isDeleteMines", "deleteMinesCoroutine", G.deleteMines, 0.5) end
function G.disableDeleteMines() stopLoop("isDeleteMines", "deleteMinesCoroutine") end

function G.enableDeleteBallpit() playerState.isDeleteBallpit = true; startLoop("isDeleteBallpit", "deleteBallpitCoroutine", G.deleteBallpit, 0.5) end
function G.disableDeleteBallpit() stopLoop("isDeleteBallpit", "deleteBallpitCoroutine") end

function G.enableDeleteCars() playerState.isDeleteCars = true; startLoop("isDeleteCars", "deleteCarsCoroutine", G.deleteCars, 0.5) end
function G.disableDeleteCars() stopLoop("isDeleteCars", "deleteCarsCoroutine") end

function G.enableDeleteIncinerator() playerState.isDeleteIncinerator = true; startLoop("isDeleteIncinerator", "deleteIncineratorCoroutine", G.deleteIncinerator, 0.5) end
function G.disableDeleteIncinerator() stopLoop("isDeleteIncinerator", "deleteIncineratorCoroutine") end

function G.enableDeleteWormhole() playerState.isDeleteWormhole = true; startLoop("isDeleteWormhole", "deleteWormholeCoroutine", G.deleteWormhole, 0.5) end
function G.disableDeleteWormhole() stopLoop("isDeleteWormhole", "deleteWormholeCoroutine") end

function G.enableDeleteElevatorPrompt() playerState.isDeleteElevatorPrompt = true; startLoop("isDeleteElevatorPrompt", "deleteElevatorPromptCoroutine", G.deleteElevatorPrompt, 0.5) end
function G.disableDeleteElevatorPrompt() stopLoop("isDeleteElevatorPrompt", "deleteElevatorPromptCoroutine") end

function G.enableDeletePestCoin() playerState.isDeletePestCoin = true; startLoop("isDeletePestCoin", "deletePestCoinCoroutine", G.deletePestCoin, 0.5) end
function G.disableDeletePestCoin() stopLoop("isDeletePestCoin", "deletePestCoinCoroutine") end

local function safeFireClickDetector(detector)
	if not detector then return false end
	local s, err = pcall(fireclickdetector, detector)
	return s
end

function G.getButtonDetectors()
	local buttonsParent = workspace:FindFirstChild("ButtonCompetition")
	if buttonsParent then
		buttonsParent = buttonsParent:FindFirstChild("Build")
		if buttonsParent then
			buttonsParent = buttonsParent:FindFirstChild("Buttons")
			if buttonsParent then
				local list = {}
				for _, child in ipairs(buttonsParent:GetChildren()) do
					local buttonPart = child:FindFirstChild("Button")
					if buttonPart and buttonPart:IsA("BasePart") then
						local detector = buttonPart:FindFirstChild("ClickDetector")
						if detector and detector:IsA("ClickDetector") then
							table.insert(list, { instance = child, detector = detector })
						end
					end
				end
				return list
			end
		end
	end
	return {}
end

function G.startButtonHarvestLoop()
	if G.buttonHarvestCoroutine then task.cancel(G.buttonHarvestCoroutine); G.buttonHarvestCoroutine = nil end
	G.buttonHarvestCoroutine = task.spawn(function()
		while true do
			if not playerState.isButtonHarvest then task.wait(0.5) continue end
			pcall(function()
				local buttons = G.getButtonDetectors()
				if #buttons == 0 then task.wait(0.5) return end
				for _, info in ipairs(buttons) do
					if not playerState.isButtonHarvest then break end
					local btn = info.instance; local detector = info.detector
					if not G.clickedButtons[btn] then
						safeFireClickDetector(detector)
						G.clickedButtons[btn] = true
						task.wait(0.1)
					end
				end
				task.wait(0.5)
			end)
		end
	end)
end
function G.stopButtonHarvestLoop()
	playerState.isButtonHarvest = false
	if G.buttonHarvestCoroutine then task.cancel(G.buttonHarvestCoroutine); G.buttonHarvestCoroutine = nil end
	G.clickedButtons = {}
end
function G.enableButtonHarvest() playerState.isButtonHarvest = true; G.clickedButtons = {}; G.startButtonHarvestLoop() end
function G.disableButtonHarvest() G.stopButtonHarvestLoop() end

function G.getDoorDetectors()
	local doorsParent = workspace:FindFirstChild("CardboardRoom")
	if doorsParent then
		doorsParent = doorsParent:FindFirstChild("Build")
		if doorsParent then
			doorsParent = doorsParent:FindFirstChild("Doors")
			if doorsParent then
				local list = {}
				for _, child in ipairs(doorsParent:GetChildren()) do
					local detector = child:FindFirstChild("ClickDetector")
					if detector and detector:IsA("ClickDetector") then
						table.insert(list, { instance = child, detector = detector })
					end
				end
				return list
			end
		end
	end
	return {}
end

function G.startDoorHarvestLoop()
	if G.doorHarvestCoroutine then task.cancel(G.doorHarvestCoroutine); G.doorHarvestCoroutine = nil end
	G.doorHarvestCoroutine = task.spawn(function()
		while true do
			if not playerState.isDoorHarvest then task.wait(0.5) continue end
			pcall(function()
				local doors = G.getDoorDetectors()
				if #doors == 0 then task.wait(0.5) return end
				for _, info in ipairs(doors) do
					if not playerState.isDoorHarvest then break end
					local door = info.instance; local detector = info.detector
					if not G.clickedDoors[door] then
						safeFireClickDetector(detector)
						G.clickedDoors[door] = true
						task.wait(0.1)
					end
				end
				task.wait(0.5)
			end)
		end
	end)
end
function G.stopDoorHarvestLoop()
	playerState.isDoorHarvest = false
	if G.doorHarvestCoroutine then task.cancel(G.doorHarvestCoroutine); G.doorHarvestCoroutine = nil end
	G.clickedDoors = {}
end
function G.enableDoorHarvest() playerState.isDoorHarvest = true; G.clickedDoors = {}; G.startDoorHarvestLoop() end
function G.disableDoorHarvest() G.stopDoorHarvestLoop() end

function G.getNoteDetectors()
	local notesParent = workspace:FindFirstChild("FunnyMaze")
	if notesParent then
		notesParent = notesParent:FindFirstChild("Build")
		if notesParent then
			notesParent = notesParent:FindFirstChild("FinalNotes")
			if notesParent then
				local list = {}
				for _, child in ipairs(notesParent:GetChildren()) do
					local detector = child:FindFirstChild("ClickDetector")
					if detector and detector:IsA("ClickDetector") then
						table.insert(list, { instance = child, detector = detector })
					end
				end
				return list
			end
		end
	end
	return {}
end

function G.startNoteHarvestLoop()
	if G.noteHarvestCoroutine then task.cancel(G.noteHarvestCoroutine); G.noteHarvestCoroutine = nil end
	G.noteHarvestCoroutine = task.spawn(function()
		while true do
			if not playerState.isNoteHarvest then task.wait(0.5) continue end
			pcall(function()
				local notes = G.getNoteDetectors()
				if #notes == 0 then task.wait(0.5) return end
				for _, info in ipairs(notes) do
					if not playerState.isNoteHarvest then break end
					local note = info.instance; local detector = info.detector
					if not G.clickedNotes[note] then
						safeFireClickDetector(detector)
						G.clickedNotes[note] = true
						task.wait(0.1)
					end
				end
				task.wait(0.5)
			end)
		end
	end)
end
function G.stopNoteHarvestLoop()
	playerState.isNoteHarvest = false
	if G.noteHarvestCoroutine then task.cancel(G.noteHarvestCoroutine); G.noteHarvestCoroutine = nil end
	G.clickedNotes = {}
end
function G.enableNoteHarvest() playerState.isNoteHarvest = true; G.clickedNotes = {}; G.startNoteHarvestLoop() end
function G.disableNoteHarvest() G.stopNoteHarvestLoop() end

local FLOOR_TOUCH_PATHS = {
	GumballMachine = "workspace.GumballMachine.Build.Generated.EndColumn.WinPart",
	Superhighway = "workspace.Superhighway.WinPoint.TouchInterest",
	SLIDE_9999999999_FEET_DOWN_RAINBOW = "workspace.SLIDE_9999999999_FEET_DOWN_RAINBOW.Build.Target.MiddleRing.TouchInterest",
	FindThePath = "workspace.FindThePath.Build.End.win_zone.TouchInterest",
	Minefield = "workspace.Minefield.Build.Decor.etc.IceCreamTruck.Tube.IcecreamGiver.TouchInterest",
	THEROCK = "workspace.THEROCK.WinPart.TouchInterest",
	FloodFillMine = "workspace.FloodFillMine.Build.Shield.Bubble.TouchInterest",
	IntenseObby = "workspace.IntenseObby.ENDBLOCK.TouchInterest",
	WhoKilledYouObby = "workspace.WhoKilledYouObby.Build.Ending.WinPart.TouchInterest",
	SnowySlope = "workspace.SnowySlope.WinPart.TouchInterest",
}

function G.getTouchTarget(path)
	local parts = {}
	for part in path:gmatch("[^%.]+") do
		table.insert(parts, part)
	end
	local obj = workspace
	for i = 2, #parts do
		obj = obj and obj:FindFirstChild(parts[i])
		if not obj then break end
	end
	if obj then
		if obj:IsA("TouchTransmitter") then
			return obj.Parent
		elseif obj:IsA("BasePart") then
			local transmitter = obj:FindFirstChildWhichIsA("TouchTransmitter")
			if transmitter then
				return obj
			end
			return obj
		end
	end
	return nil
end

function G.startCompleteFloorLoop(floorName)
	if G.completeFloorCoroutines[floorName] then return end

	if floorName == "SLIDE_9999999999_FEET_DOWN_RAINBOW" then
		if G.slideTpConnection then return end
		G.slideTpConnection = RunService.Heartbeat:Connect(function()
			if not G.completeFloorStates[floorName] or G.currentFloor ~= floorName then
				G.slideTpConnection:Disconnect()
				G.slideTpConnection = nil
				return
			end
			local path = FLOOR_TOUCH_PATHS[floorName]
			if path then
				local target = G.getTouchTarget(path)
				if target and target:IsA("BasePart") then
					local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						pcall(function()
							hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 2, 0))
						end)
					end
				end
			end
		end)
		return
	end

	G.completeFloorCoroutines[floorName] = task.spawn(function()
		while G.completeFloorStates[floorName] and G.currentFloor == floorName do
			local path = FLOOR_TOUCH_PATHS[floorName]
			if path then
				local target = G.getTouchTarget(path)
				if target then
					local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						pcall(function() firetouchinterest(hrp, target, 0) end)
					end
				end
			end
			task.wait(1)
		end
		G.completeFloorCoroutines[floorName] = nil
	end)
end

function G.stopCompleteFloorLoop(floorName)
	if floorName == "SLIDE_9999999999_FEET_DOWN_RAINBOW" then
		if G.slideTpConnection then
			G.slideTpConnection:Disconnect()
			G.slideTpConnection = nil
		end
	else
		if G.completeFloorCoroutines[floorName] then
			task.cancel(G.completeFloorCoroutines[floorName])
			G.completeFloorCoroutines[floorName] = nil
		end
	end
	G.completeFloorStates[floorName] = false
end

function G.toggleCompleteFloor(floorName, enabled)
	G.completeFloorStates[floorName] = enabled
	if enabled then
		if G.currentFloor == floorName then
			G.startCompleteFloorLoop(floorName)
		end
	else
		G.stopCompleteFloorLoop(floorName)
	end
end

function G.startCompleteFloorMonitor()
	task.spawn(function()
		while true do
			for floorName, enabled in pairs(G.completeFloorStates) do
				if enabled then
					if G.currentFloor == floorName then
						local hasLoop = (floorName == "SLIDE_9999999999_FEET_DOWN_RAINBOW" and G.slideTpConnection) or G.completeFloorCoroutines[floorName]
						if not hasLoop then
							G.startCompleteFloorLoop(floorName)
						end
					else
						if G.slideTpConnection or G.completeFloorCoroutines[floorName] then
							G.stopCompleteFloorLoop(floorName)
						end
					end
				else
					if G.slideTpConnection or G.completeFloorCoroutines[floorName] then
						G.stopCompleteFloorLoop(floorName)
					end
				end
			end
			task.wait(3)
		end
	end)
end

local FEATURE_ENABLERS = {
	invis = { enable = G.enableInvis, disable = G.disableInvis },
	noclip = { enable = G.enableNoclip, disable = G.disableNoclip },
	infJump = { enable = G.enableInfJump, disable = G.disableInfJump },
	nightVision = { enable = G.enableNightVision, disable = G.disableNightVision },
	interact = { enable = G.enableInteract, disable = G.disableInteract },
	remote = { enable = G.enableRemote, disable = G.disableRemote },
	coinTP = { enable = G.enableCoinTP, disable = G.disableCoinTP },
	bananaRemover = { enable = G.enableBananaRemover, disable = G.disableBananaRemover },
	autoRespawn = { enable = G.enableAutoRespawn, disable = G.disableAutoRespawn },
	gpuSpinner = { enable = G.enableGPUSpinner, disable = G.disableGPUSpinner },
	teapotTP = { enable = G.enableTeapotTP, disable = G.disableTeapotTP },
	tpRedBallTemple = { enable = G.enableTPRedBallTemple, disable = G.disableTPRedBallTemple },
	tpObbyEnd = { enable = G.enableTPObbyEnd, disable = G.disableTPObbyEnd },
	deleteSuperTunnelCars = { enable = G.enableDeleteSuperTunnelCars, disable = G.disableDeleteSuperTunnelCars },
	deleteRockman = { enable = G.enableDeleteRockman, disable = G.disableDeleteRockman },
	deleteMines = { enable = G.enableDeleteMines, disable = G.disableDeleteMines },
	deleteBallpit = { enable = G.enableDeleteBallpit, disable = G.disableDeleteBallpit },
	deleteCars = { enable = G.enableDeleteCars, disable = G.disableDeleteCars },
	deleteIncinerator = { enable = G.enableDeleteIncinerator, disable = G.disableDeleteIncinerator },
	deleteWormhole = { enable = G.enableDeleteWormhole, disable = G.disableDeleteWormhole },
	buttonHarvest = { enable = G.enableButtonHarvest, disable = G.disableButtonHarvest },
	doorHarvest = { enable = G.enableDoorHarvest, disable = G.disableDoorHarvest },
	noteHarvest = { enable = G.enableNoteHarvest, disable = G.disableNoteHarvest },
	deleteElevatorPrompt = { enable = G.enableDeleteElevatorPrompt, disable = G.disableDeleteElevatorPrompt },
	deletePestCoin = { enable = G.enableDeletePestCoin, disable = G.disableDeletePestCoin },
	eatingCompEAT = { enable = G.enableEatingCompEAT, disable = G.disableEatingCompEAT },
}
local function disableAllFeatures()
	for _, funcs in pairs(FEATURE_ENABLERS) do pcall(funcs.disable) end
end

local floorNameLabel, floorFeatureLabel, currentFloorKey

local function applyFloorFeatures(floorKey)
	if not floorFeatureLabel then return end
	if floorKey then
		local floorData = FLOOR_FEATURES[floorKey]
		if floorData then
			if floorData.display then floorFeatureLabel:SetText(floorData.display)
			elseif floorData.features then
				local names = {}
				for _, feat in ipairs(floorData.features) do table.insert(names, FEATURE_DISPLAY[feat] or feat) end
				floorFeatureLabel:SetText(table.concat(names, "、"))
			else floorFeatureLabel:SetText("等待更新") end
		else floorFeatureLabel:SetText("等待更新") end
	else floorFeatureLabel:SetText("电梯时间...") end

	if playerState.autoFloorFeatures and floorKey then
		local floorData = FLOOR_FEATURES[floorKey]
		if floorData and floorData.features then
			disableAllFeatures()
			for _, feat in ipairs(floorData.features) do
				local enabler = FEATURE_ENABLERS[feat]
				if enabler then pcall(enabler.enable) end
			end
		end
	end
end

local FLOOR_NAMES = {
	TeapotDodgeball = "Teapot Dodgeball",
	TeapotTraversal = "Teapot Traversal",
	Subway = "Subway",
	TPOT = "TPOT",
	ToolboxThrift = "Toolbox Thrift",
	InfectionApartment = "Infection Apartment",
	Normal_Dance = "Normal Dance",
	ElevatorInsideAx5 = "Elevator Inside Ax5",
	SlapBattles = "Slap Battles",
	CardboardRoom = "Cardboard Room",
	FollyFight = "Folly Fight",
	SurvivalTheArea51 = "Survival The Area 51",
	["BunsNGuns/DyingMall"] = "BunsNGuns/DyingMall",
	Superhighway = "Superhighway",
	GASA4 = "GASA4",
	JermpopFactory = "Jermpop Factory",
	MozellesCastle = "Mozelles Castle",
	Arcade = "Arcade",
	WoodsmokedDiner = "Woodsmoked Diner",
	WALL_OF = "WALL_OF",
	THEROCK = "THEROCK",
	PestBossFight = "Pest Boss Fight",
	SuperTunnel = "Super Tunnel",
	SlimYim = "Slim Yim",
	ColorTheTiles = "Color The Tiles",
	UES = "UES",
	FourCorners = "Four Corners",
	HotelFloor6 = "Hotel Floor 6",
	DriveThru = "Drive Thru",
	InfectedRacing = "Infected Racing",
	Birthday = "Birthday",
	FindThePath = "FindThePath",
	StatsDomain = "StatsDomain",
	OFFICE_OF = "OFFICE_OF",
	RedBall = "RedBall",
	OnTheHeights = "OnTheHeights",
	ShopSpace = "ShopSpace",
	["3008_Room"] = "3008_Room",
	Undertale = "Undertale",
	CliffsideChaos = "CliffsideChaos",
	FleshCousinBirthday = "FleshCousinBirthday",
	ButtonCompetition = "ButtonCompetition",
	TNTRun = "TNTRun",
	StanelyRoom = "StanelyRoom",
	FunTimesAtSquishyFlood = "FunTimesAtSquishyFlood",
	BrokenSchool = "BrokenSchool",
	RedBallTemple = "RedBallTemple",
	Forest_TwoStudCamp = "Forest_TwoStudCamp",
	Splitsville_Wipeout = "Splitsville_Wipeout",
	GumballMachine = "GumballMachine",
	SuperDropper = "SuperDropper",
	RandomMazeWindows = "RandomMazeWindows",
	OldRobloxHouse = "OldRobloxHouse",
	MozelleSquidGames = "MozelleSquidGames",
	FloodFillMine = "FloodFillMine",
	FunnyMaze = "FunnyMaze",
	SLIDE_9999999999_FEET_DOWN_RAINBOW = "SLIDE_9999999999_FEET_DOWN_RAINBOW",
	PizzaDelivery = "PizzaDelivery",
	TheBackrooms = "TheBackrooms",
	MozellesMuseum = "MozellesMuseum",
	Dance = "Dance",
	HCIcecream = "HCIcecream",
	Minefield = "Minefield",
	ElevatorShaft = "ElevatorShaft",
	KnowledgeOffice = "KnowledgeOffice",
	UnsteadyFloor = "UnsteadyFloor",
	PetCaptureDeluxe = "PetCaptureDeluxe",
	SuperMinesweeper = "SuperMinesweeper",
	RedballDiner = "RedballDiner",
	Obby = "Obby",
	WhoKilledYouObby = "WhoKilledYouObby",
	FloppyShoppy = "FloppyShoppy",
	MarkApartmentHideAndSeek = "MarkApartmentHideAndSeek",
	WHEEL_OF = "WHEEL_OF",
	ElevatorRoom = "ElevatorRoom",
	Dolorems = "Dolorems",
	Jeremy = "Jeremy",
	CurseCove = "CurseCove",
	gm_flatgrass = "gm_flatgrass",
	SuspiciouslyLongRoom = "SuspiciouslyLongRoom",
	PureImagination = "PureImagination",
	Aquarium = "Aquarium",
	CompetitveLobby = "CompetitveLobby",
	TurretRoom = "TurretRoom",
	HALL_OF = "HALL_OF",
	MannequinFashion = "MannequinFashion",
	IntenseObby = "IntenseObby",
	MoonStation = "MoonStation",
	InfiniteMine = "InfiniteMine",
	SnowySlope = "SnowySlope",
	AbandonedCube = "AbandonedCube",
	EatingComp_DoD_Hot_Dog = "EatingComp_DoD_Hot_Dog",
	Normal_CowTipping = "Normal_CowTipping",
	DeltaLakeside = "DeltaLakeside",
	WaltensRoom = "WaltensRoom",
	["SoundOfSci-fi"] = "SoundOfSci-fi"
}

local function detectFloor()
	for _, child in ipairs(workspace:GetChildren()) do
		if FLOOR_NAMES[child.Name] then return child.Name end
	end
	return nil
end

task.spawn(function()
	while true do
		local floorKey = detectFloor()
		if floorKey ~= currentFloorKey then
			currentFloorKey = floorKey
			G.currentFloor = floorKey
			if floorNameLabel then
				floorNameLabel:SetText(floorKey and FLOOR_NAMES[floorKey] or "电梯时间...")
			end
			local floorName = floorKey and FLOOR_NAMES[floorKey] or nil
			if floorName == "THEROCK" then G.suspendCoinTPForRock() else G.resumeCoinTPForRock() end
			applyFloorFeatures(floorKey and FLOOR_NAMES[floorKey] or nil)
		end
		task.wait(0.5)
	end
end)

G.startCompleteFloorMonitor()

steppedConnection = RunService.Stepped:Connect(function()
	if playerState.isNoclip and player.Character then
		for _, part in pairs(player.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				if G.noclipOriginalCollide[part] == nil then G.noclipOriginalCollide[part] = part.CanCollide end
				part.CanCollide = false
			end
		end
	end
end)

jumpRequestConnection = UserInputService.JumpRequest:Connect(function()
	if playerState.isInfJump and player.Character then
		local hum = player.Character:FindFirstChild("Humanoid") :: Humanoid?
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

characterAddedConnection = player.CharacterAdded:Connect(function(char)
	if playerState.isNoclip then
		task.wait(0.1)
		G.storeNoclipState(char)
		G.applyNoclip(true)
	end
end)

player.Idled:Connect(function()
	if not afkSettings.antiAFK then return end
	VirtualUser:Button2Down(Vector2.new(0,0)); task.wait(0.1); VirtualUser:Button2Up(Vector2.new(0,0))
end)
pcall(function() VirtualUser:CaptureController() end)

task.spawn(function()
	while true do
		if afkSettings.antiAFK then
			local now = os.clock()
			if now - afkState.lastAfkTick >= afkSettings.afkClickInterval then
				pcall(function() VirtualUser:Button2Down(Vector2.new(0,0)); task.wait(0.05); VirtualUser:Button2Up(Vector2.new(0,0)) end)
				afkState.lastAfkTick = now
			end
		end
		task.wait(1)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	local inst = 1/math.max(dt, 1/240)
	afkState.fps = afkState.fps + (inst - afkState.fps)*0.2
end)

local statusLabel, sessionLabel
task.spawn(function()
	while true do
		local minutes=math.floor((os.clock()-afkState.startClock)/60)
		local pingItem=StatsSvc.Network.ServerStatsItem["Data Ping"]
		local ping=pingItem and pingItem:GetValue() or 0
		local ram=math.floor(StatsSvc:GetTotalMemoryUsageMb())
		local cpu=math.min(100, math.floor((60/math.max(afkState.fps,1))*25))
		if statusLabel then
			statusLabel:SetText(string.format("状态：%s | FPS: %d | CPU: %d%% | 内存: %dMB | Ping: %dms",
				afkSettings.antiAFK and "运行中" or "已停用",
				math.floor(afkState.fps+0.5), cpu, ram, ping))
		end
		if sessionLabel then
			sessionLabel:SetText(string.format("在线时长：%d 分钟", minutes))
		end
		task.wait(2)
	end
end)

local currentViewTarget = nil
local function updateCamera(target)
	if target and target.Character and target.Character:FindFirstChild("Humanoid") then
		local hum = target.Character:FindFirstChild("Humanoid")
		if hum then workspace.CurrentCamera.CameraSubject = hum; currentViewTarget = target end
	else
		local char = player.Character
		if char then
			local hum = char:FindFirstChild("Humanoid")
			if hum then workspace.CurrentCamera.CameraSubject = hum end
		end
		currentViewTarget = nil
	end
end
local function getPlayerList()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") then
			table.insert(list, p.Name)
		end
	end
	table.sort(list)
	return list
end

local Window = Library:CreateWindow({
	Title = "X6G1 Hub",
	Center = true,
	AutoShow = true,
	TabPadding = 8,
	MenuFadeTime = 0.2
})

local CommonTab = Window:AddTab("常用")
local FloorGroup = CommonTab:AddLeftGroupbox("当前楼层")
floorNameLabel = FloorGroup:AddLabel("电梯时间...", true)

local CommonLeft = CommonTab:AddLeftGroupbox("常用功能")
CommonLeft:AddToggle("隐身", {Text="隐身", Default=false, Tooltip=FEATURE_TOOLTIPS.invis, Callback=function(v) if v then G.enableInvis() else G.disableInvis() end end})
CommonLeft:AddToggle("穿墙", {Text="穿墙", Default=false, Tooltip=FEATURE_TOOLTIPS.noclip, Callback=function(v) if v then G.enableNoclip() else G.disableNoclip() end end})
CommonLeft:AddToggle("无限跳跃", {Text="无限跳跃", Default=false, Tooltip=FEATURE_TOOLTIPS.infJump, Callback=function(v) if v then G.enableInfJump() else G.disableInfJump() end end})
CommonLeft:AddToggle("夜视", {Text="夜视", Default=false, Tooltip=FEATURE_TOOLTIPS.nightVision, Callback=function(v) if v then G.enableNightVision() else G.disableNightVision() end end})
CommonLeft:AddToggle("瞬移交互", {Text="瞬移交互", Default=false, Tooltip=FEATURE_TOOLTIPS.interact, Callback=function(v) if v then G.enableInteract() else G.disableInteract() end end})
CommonLeft:AddToggle("远程交互", {Text="远程交互", Default=false, Tooltip=FEATURE_TOOLTIPS.remote, Callback=function(v) if v then G.enableRemote() else G.disableRemote() end end})
CommonLeft:AddToggle("金币传送", {Text="金币传送", Default=false, Tooltip=FEATURE_TOOLTIPS.coinTP, Callback=function(v) if v then G.enableCoinTP() else G.disableCoinTP() end end})
CommonLeft:AddToggle("自动重生", {Text="自动重生 (1秒检测)", Default=false, Tooltip=FEATURE_TOOLTIPS.autoRespawn, Callback=function(v) if v then G.enableAutoRespawn() else G.disableAutoRespawn() end end})
CommonLeft:AddToggle("GPU 自动旋转", {Text="GPU 自动旋转", Default=false, Tooltip=FEATURE_TOOLTIPS.gpuSpinner, Callback=function(v) if v then G.enableGPUSpinner() else G.disableGPUSpinner() end end})

local CommonRight = CommonTab:AddRightGroupbox("速度控制")
CommonRight:AddSlider("速度", {Text="移动速度", Default=16, Min=16, Max=500, Rounding=0, Callback=function(v)
	v = math.clamp(math.round(v), 16, 500)
	playerState.currentSpeed = v
	applySpeed(v)
end})
CommonRight:AddToggle("速度锁定", {Text="速度锁定", Default=false, Tooltip="锁定当前速度，防止被游戏重置", Callback=function(v) if v then G.enableSpeedLock() else G.disableSpeedLock() end end})
CommonRight:AddSlider("重力", {Text="重力值", Default=196.2, Min=-50, Max=500, Rounding=1, Callback=function(v) v = math.clamp(math.round(v), -50, 500); playerState.currentGravity = v; applyGravity(v) end})
CommonRight:AddToggle("重力锁定", {Text="重力锁定", Default=false, Tooltip="锁定当前重力值，防止被游戏重置", Callback=function(v) if v then G.enableGravityLock() else G.disableGravityLock() end end})

local ViewGroup = CommonTab:AddLeftGroupbox("玩家视角")
local playerDropdown = ViewGroup:AddDropdown("玩家列表", {Text="选择玩家", Values=getPlayerList(), AllowNull=true, Default=nil, Callback=function(v) if v and v~="" then local t=Players:FindFirstChild(v) if t then updateCamera(t) end else updateCamera(nil) end end})
ViewGroup:AddButton("刷新玩家列表", function() local list=getPlayerList() playerDropdown:SetValues(list) if #list>0 then playerDropdown:SetValue(list[1]) else playerDropdown:SetValue(nil) end end)
ViewGroup:AddButton("恢复自身视角", function() updateCamera(nil); playerDropdown:SetValue(nil) end)
ViewGroup:AddButton("传送至玩家", function()
	local selected=playerDropdown.Value
	if selected and selected~="" then
		local target=Players:FindFirstChild(selected)
		if target and target.Character then
			local hrp=target.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local char=player.Character
				if char then
					local myHrp=char:FindFirstChild("HumanoidRootPart")
					if myHrp then
						myHrp.CFrame=CFrame.new(hrp.Position+Vector3.new(0,2,0))
						Library:Notify("已传送到 "..target.Name, 2)
					end
				end
			end
		end
	end
end)
Players.PlayerAdded:Connect(function() local list=getPlayerList() playerDropdown:SetValues(list) end)
Players.PlayerRemoving:Connect(function() local list=getPlayerList() playerDropdown:SetValues(list); if currentViewTarget and not currentViewTarget.Parent then updateCamera(nil); playerDropdown:SetValue(nil) end end)

local AfkGroup = CommonTab:AddRightGroupbox("防挂机")
AfkGroup:AddToggle("防挂机", {Text="启用防挂机", Default=true, Tooltip="空闲时自动触发点击，防止被踢出", Callback=function(v) afkSettings.antiAFK = v end})
statusLabel = AfkGroup:AddLabel("状态：运行中 | FPS: -- | CPU: --% | 内存: --MB | Ping: --ms", true)
sessionLabel = AfkGroup:AddLabel("在线时长：0 分钟", true)
AfkGroup:AddSlider("卡顿阈值", {Text="卡顿阈值（秒）", Default=0.6, Min=0.1, Max=3.0, Rounding=1, Suffix="s", Callback=function(v) afkSettings.heartbeatThreshold = v end})

local FloorTab = Window:AddTab("楼层功能")
local FloorControl = FloorTab:AddLeftGroupbox("楼层功能控制")
FloorControl:AddToggle("自动楼层功能", {Text="自动楼层功能", Default=false, Tooltip="到达对应楼层时自动开启预设功能", Callback=function(v) playerState.autoFloorFeatures = v; if v and currentFloorKey then applyFloorFeatures(FLOOR_NAMES[currentFloorKey]) end end})

local FloorTeleport = FloorTab:AddLeftGroupbox("终点传送")
FloorTeleport:AddToggle("茶壶循环触发终点", {Text="茶壶循环触发终点", Default=false, Tooltip=FEATURE_TOOLTIPS.teapotTP, Callback=function(v) if v then G.enableTeapotTP() else G.disableTeapotTP() end end})
FloorTeleport:AddToggle("红球神庙终点", {Text="红球神庙终点", Default=false, Tooltip=FEATURE_TOOLTIPS.tpRedBallTemple, Callback=function(v) if v then G.enableTPRedBallTemple() else G.disableTPRedBallTemple() end end})
FloorTeleport:AddToggle("Obby终点", {Text="Obby终点", Default=false, Tooltip=FEATURE_TOOLTIPS.tpObbyEnd, Callback=function(v) if v then G.enableTPObbyEnd() else G.disableTPObbyEnd() end end})

local FloorDelete = FloorTab:AddLeftGroupbox("删除类")
FloorDelete:AddToggle("删除车辆", {Text="删除车辆 (Super Tunnel)", Default=false, Tooltip=FEATURE_TOOLTIPS.deleteSuperTunnelCars, Callback=function(v) if v then G.enableDeleteSuperTunnelCars() else G.disableDeleteSuperTunnelCars() end end})
FloorDelete:AddToggle("删除NPC", {Text="删除NPC (THEROCK)", Default=false, Tooltip=FEATURE_TOOLTIPS.deleteRockman, Callback=function(v) if v then G.enableDeleteRockman() else G.disableDeleteRockman() end end})
FloorDelete:AddToggle("删除地雷", {Text="删除地雷", Default=false, Tooltip=FEATURE_TOOLTIPS.deleteMines, Callback=function(v) if v then G.enableDeleteMines() else G.disableDeleteMines() end end})
FloorDelete:AddToggle("球海清理", {Text="球海清理", Default=false, Tooltip=FEATURE_TOOLTIPS.deleteBallpit, Callback=function(v) if v then G.enableDeleteBallpit() else G.disableDeleteBallpit() end end})
FloorDelete:AddToggle("删除车辆", {Text="删除车辆 (Superhighway)", Default=false, Tooltip=FEATURE_TOOLTIPS.deleteCars, Callback=function(v) if v then G.enableDeleteCars() else G.disableDeleteCars() end end})
FloorDelete:AddToggle("删除火墙", {Text="删除火墙", Default=false, Tooltip=FEATURE_TOOLTIPS.deleteIncinerator, Callback=function(v) if v then G.enableDeleteIncinerator() else G.disableDeleteIncinerator() end end})
FloorDelete:AddToggle("删除激光", {Text="删除激光", Default=false, Tooltip=FEATURE_TOOLTIPS.deleteWormhole, Callback=function(v) if v then G.enableDeleteWormhole() else G.disableDeleteWormhole() end end})
FloorDelete:AddToggle("删除紫球和香蕉皮", {Text="删除紫球和香蕉皮", Default=false, Tooltip=FEATURE_TOOLTIPS.bananaRemover, Callback=function(v) if v then G.enableBananaRemover() else G.disableBananaRemover() end end})
FloorDelete:AddToggle("删除电梯交互", {Text="删除电梯交互", Default=false, Tooltip=FEATURE_TOOLTIPS.deleteElevatorPrompt, Callback=function(v) if v then G.enableDeleteElevatorPrompt() else G.disableDeleteElevatorPrompt() end end})
FloorDelete:AddToggle("删除Pest的钱", {Text="删除Pest的钱", Default=false, Tooltip=FEATURE_TOOLTIPS.deletePestCoin, Callback=function(v) if v then G.enableDeletePestCoin() else G.disableDeletePestCoin() end end})

local FloorRight = FloorTab:AddRightGroupbox("楼层功能开关")
FloorRight:AddToggle("按钮收割", {Text="按钮收割", Default=false, Tooltip=FEATURE_TOOLTIPS.buttonHarvest, Callback=function(v) if v then G.enableButtonHarvest() else G.disableButtonHarvest() end end})
FloorRight:AddToggle("门收割", {Text="门收割", Default=false, Tooltip=FEATURE_TOOLTIPS.doorHarvest, Callback=function(v) if v then G.enableDoorHarvest() else G.disableDoorHarvest() end end})
FloorRight:AddToggle("笔记收割", {Text="笔记收割", Default=false, Tooltip=FEATURE_TOOLTIPS.noteHarvest, Callback=function(v) if v then G.enableNoteHarvest() else G.disableNoteHarvest() end end})
FloorRight:AddToggle("EatingComp 触发 EAT", {Text="EatingComp 触发 EAT", Default=false, Tooltip=FEATURE_TOOLTIPS.eatingCompEAT, Callback=function(v) if v then G.enableEatingCompEAT() else G.disableEatingCompEAT() end end})

local FloorComplete = FloorTab:AddRightGroupbox("楼层完成触发")
for floorName, _ in pairs(FLOOR_TOUCH_PATHS) do
	local displayName = FLOOR_NAMES[floorName] or floorName
	FloorComplete:AddToggle("complete_"..floorName, {
		Text = displayName,
		Default = false,
		Tooltip = (floorName == "SLIDE_9999999999_FEET_DOWN_RAINBOW" and "循环传送至终点（无间隔）") or "到达时自动循环触发终点触摸（每1秒）",
		Callback = function(v)
			G.toggleCompleteFloor(floorName, v)
		end
	})
end

local FloorStatus = FloorTab:AddLeftGroupbox("当前楼层功能状态")
floorFeatureLabel = FloorStatus:AddLabel("等待更新...", true)

local ConfigTab = Window:AddTab("配置")
SaveManager:SetLibrary(Library)
SaveManager:BuildConfigSection(ConfigTab)
ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(ConfigTab)
SaveManager:IgnoreThemeSettings()
SaveManager:LoadAutoloadConfig()

Library:Notify("X6G1 Hub 加载完成！按 RightControl 切换菜单", 5)
print("X6G1 Hub 加载完成。QQ群1005801189。此作品为半成品，请勿商用")

task.wait(0.1)
Window:Show()
Window:Focus()