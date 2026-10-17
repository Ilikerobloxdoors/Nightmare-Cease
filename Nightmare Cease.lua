
-- XENO NIGHTMARE CEASE
-- Model loader + orange lighting + survival achievement

local G = getgenv()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- MODEL LOADER

G.LoadGithubModel = function(url)
    if not (writefile and getcustomasset and request) then
        warn("Required file-loading functions unavailable.")
        return nil
    end

    local function generateFileName(sourceUrl)
        local hash = 0
        for i = 1, #sourceUrl do
            hash = (hash * 31 + string.byte(sourceUrl, i)) % 2^32
        end
        return "nightmare_cease_" .. tostring(hash) .. ".rbxm"
    end

    local fileName = generateFileName(url)

    local function loadModel()
        local assetId = getcustomasset(fileName)
        return game:GetObjects(assetId)[1]
    end

    if isfile and isfile(fileName) then
        local ok, model = pcall(loadModel)
        if ok and model then
            return model
        end
    end

    local ok, response = pcall(function()
        return request({
            Url = url,
            Method = "GET"
        })
    end)

    if not ok or not response or response.StatusCode ~= 200 then
        warn("Nightmare Cease download failed.")
        return nil
    end

    local saved = pcall(function()
        writefile(fileName, response.Body)
    end)

    if not saved then
        warn("Unable to save Nightmare Cease model.")
        return nil
    end

    local loaded, model = pcall(loadModel)
    if loaded and model then
        return model
    end

    warn("Nightmare Cease model could not be loaded.")
    return nil
end

-- ACHIEVEMENT

local function GrantNightmareCeaseAchievement()
    local ok, err = pcall(function()
        local source = game:HttpGet(
            "https://raw.githubusercontent.com/RegularVynixu/DOORS-Custom-Achievements/main/init.luau"
        )

        local loader = loadstring(source)
        assert(loader, "Achievement library could not be compiled")

        local achievements = loader()
        assert(achievements, "Achievement library returned nil")

        achievements:Grant({
            Identifier = "NightmareCeaseSurvivor",
            Title = "DONT MOVE!",
            Desc = "Dont Hide or either Walk...",
            Reason = "Survive And Encounter Nightmare Cease",
            Image = "rbxassetid://139156530722271"
        }, {
            CheckOwned = true,
            Remember = true
        })
    end)

    if ok then
        print("DONT MOVE!: achievement grant attempted.")
    else
        warn("DONT MOVE! achievement error: " .. tostring(err))
    end
end

-- NIGHTMARE CEASE

local function ceasetheroom()
    local normalSpeed = 45
    local entitySpeed = 9999
    local currentSpeed = normalSpeed
    local entityHeight = Vector3.new(0, 3.4, 0)

    local gameData = ReplicatedStorage:WaitForChild("GameData")
    local latestRoom = gameData:WaitForChild("LatestRoom")
    local currentRooms = workspace:WaitForChild("CurrentRooms")

    local rawUrl =
        "https://raw.githubusercontent.com/Ilikerobloxdoors/Nightmare-Cease/main/NIGHTMARE%20CEASE.rbxm"

    local entity = G.LoadGithubModel(rawUrl)
    if not entity then
        return
    end

    entity.Parent = workspace

    local entityPart = entity:FindFirstChildWhichIsA("BasePart", true)
    if not entityPart then
        entity:Destroy()
        warn("No BasePart found in Nightmare Cease model.")
        return
    end

    local silence = entity:FindFirstChild("Silence", true)
    if silence and silence:IsA("Sound") then
        silence:Play()
    end

    -- CAMERA SHAKE

    local camShake
    local cameraModule = ReplicatedStorage:FindFirstChild("CameraShaker")

    if cameraModule then
        local ok, module = pcall(require, cameraModule)

        if ok then
            local camera = workspace.CurrentCamera

            camShake = module.new(
                Enum.RenderPriority.Camera.Value,
                function(cf)
                    camera.CFrame = camera.CFrame * cf
                end
            )

            camShake:Start()
            camShake:Shake(module.Presets.Earthquake)
        end
    end

    -- ORANGE LIGHTING

    local lightTween = TweenInfo.new(1)

    local function changeRoomLights(color)
        for _, object in ipairs(currentRooms:GetDescendants()) do
            if object:IsA("Light") then
                TweenService:Create(object, lightTween, {
                    Color = color
                }):Play()

                if object.Parent
                    and object.Parent.Name == "LightFixture"
                    and object.Parent:IsA("BasePart") then

                    TweenService:Create(object.Parent, lightTween, {
                        Color = color
                    }):Play()
                end
            end
        end
    end

    changeRoomLights(Color3.fromRGB(255, 140, 0))

    task.delay(3, function()
        if entity and entity.Parent then
            changeRoomLights(Color3.fromRGB(180, 70, 0))
        end
    end)

    task.wait(2)

    -- BOSS / CUTSCENE CHECK

    local function isBossActive()
        local roomNumber = latestRoom.Value

        if roomNumber == 50 or roomNumber == 100 then
            return true
        end

        for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
            if object:IsA("Sound")
                and object.IsPlaying
                and (object.Name:find("Music") or object.Name == "Shade") then
                return true
            end
        end

        return false
    end

    -- VISIBILITY CHECK

    local killed = false

    local function canSeeTarget(character, distance)
        if killed or isBossActive() then
            return false
        end

        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then
            return false
        end

        local origin = entityPart.Position
        local direction = root.Position - origin

        if direction.Magnitude > distance then
            return false
        end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {entity}

        local result = workspace:Raycast(origin, direction, params)

        return result ~= nil
            and result.Instance:IsDescendantOf(character)
    end

    -- PLAYER MONITOR

    local encounterFinished = false

    task.spawn(function()
        while entity and entity.Parent and not encounterFinished do
            task.wait(0.01)

            local character = player.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")
            local root = character
                and character:FindFirstChild("HumanoidRootPart")

            if humanoid and root and humanoid.Health > 0 then
                if canSeeTarget(character, 60)
                    and humanoid.MoveDirection.Magnitude > 0 then

                    killed = true
                    humanoid:TakeDamage(100)

                    local stats = ReplicatedStorage:FindFirstChild("GameStats")
                    local playerStats = stats
                        and stats:FindFirstChild("Player_" .. character.Name)

                    local total = playerStats
                        and playerStats:FindFirstChild("Total")

                    local deathCause = total
                        and total:FindFirstChild("DeathCause")

                    if deathCause then
                        deathCause.Value = "Cease"
                    end

                    local hints = {
                        "You died to Nightmare Cease...",
                        "Don't move when he's nearby!"
                    }

                    local remotes =
                        ReplicatedStorage:FindFirstChild("RemotesFolder")
                        or ReplicatedStorage:FindFirstChild("Bricks")

                    local deathHint = remotes
                        and remotes:FindFirstChild("DeathHint")

                    if deathHint then
                        pcall(function()
                            firesignal(
                                deathHint.OnClientEvent,
                                hints,
                                "Orange"
                            )
                        end)
                    end
                end

                if camShake
                    and (entityPart.Position - root.Position).Magnitude <= 60 then
                    camShake:ShakeOnce(2.4, 25, 0.5, 2, 1, 6)
                end
            end
        end
    end)

    -- MOVE THROUGH ROOM NODES

    currentSpeed = entitySpeed

    for i = 1, latestRoom.Value do
        if not entity or not entity.Parent then
            break
        end

        local room = currentRooms:FindFirstChild(tostring(i))
        local nodes = room and room:FindFirstChild("Nodes")

        if nodes then
            for v = 1, #nodes:GetChildren() do
                if not entity or not entity.Parent then
                    break
                end

                local node = nodes:FindFirstChild(tostring(v))

                if node and node:IsA("BasePart") then
                    local distance =
                        (entityPart.Position - node.Position).Magnitude

                    local duration = math.max(distance / currentSpeed, 0.01)

                    local tween = TweenService:Create(
                        entityPart,
                        TweenInfo.new(duration, Enum.EasingStyle.Linear),
                        {
                            CFrame = node.CFrame + entityHeight
                        }
                    )

                    tween:Play()
                    tween.Completed:Wait()

                    currentSpeed = normalSpeed
                end
            end
        end
    end

    -- ENCOUNTER FINISHED

    encounterFinished = true

    local character = player.Character
    local humanoid = character
        and character:FindFirstChildOfClass("Humanoid")

    if humanoid and humanoid.Health > 0 then
        GrantNightmareCeaseAchievement()
    else
        print("DONT MOVE!: player did not survive.")
    end

    -- CLEANUP

    if entity and entity.Parent then
        entityPart.Anchored = false
        entityPart.CanCollide = false
        Debris:AddItem(entity, 5)
    end
end

local ok, err = pcall(ceasetheroom)

if not ok then
    warn("Nightmare Cease error: " .. tostring(err))
end
