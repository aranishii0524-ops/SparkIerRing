-- FireworkSparkler オーラ MOD + クリスマスツリー + Wing + 魔法陣
-- 高さ5の位置にリング状に配置・回転 (形状選択機能付き)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

-- ★ OrionLibをロード ★
local OrionLib = nil
pcall(function()
    OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jadpy/suki/refs/heads/main/orion"))()
end)

if not OrionLib then
    warn("UIライブラリ (OrionLib) のロードに失敗しました。")
    return
end

local Window = OrionLib:MakeWindow({ Name = "FireworkSparkler オーラ", HidePremium = true, SaveConfig = false })
local Tab = Window:MakeTab({ Name = "AURA", Icon = "rbxassetid://448336338" })
local ChristmasTab = Window:MakeTab({ Name = "🎄 Christmas Tree", Icon = "rbxassetid://448336338" })
local WingTab = Window:MakeTab({ Name = "👼 Wing", Icon = "rbxassetid://448336338" })
local CombinedTab = Window:MakeTab({ Name = "🌟 Combined", Icon = "rbxassetid://448336338" })
local MagicCircleTab = Window:MakeTab({ Name = "✨ 円形魔法陣", Icon = "rbxassetid://448336338" }) -- 名前を変更

-- 設定変数 (通常オーラ)
local Enabled = false
local FollowPlayerEnabled = false
local TargetPlayerName = ""
local RingHeight = 5.0
local RingSize = 5.0
local ObjectCount = 30
local RotationSpeed = 20.0
local ShapeType = "Circle"

-- 設定変数 (クリスマスツリー)
local TreeEnabled = false
local TreeFollowPlayerEnabled = false
local TreeTargetPlayerName = ""
local TreeHeight = 15.0
local TreeLayers = 5
local TreeRotationSpeed = 20.0
local TreeObjectCount = 25
local TreeRingSize = 8.0

-- 設定変数 (Wing)
local WingEnabled = false
local WingFollowPlayerEnabled = false
local WingTargetPlayerName = ""
local WingVerticalOffset = 2.0
local WingSpread = 5.0
local WingObjectCount = 10
local WingFlapShape = 2.0
local WingFlapSpeed = 1.0
local WingFlapAmount = 3.0

-- ★ 追加: コンビネーションモード設定 ★
local CombinedEnabled = false
local CombinedFollowPlayerEnabled = false
local CombinedTargetPlayerName = ""
local CombinedRingHeight = 5.0
local CombinedRingSize = 5.0
local CombinedRingObjectCount = 15
local CombinedRotationSpeed = 20.0
local CombinedShapeType = "Circle"
local CombinedWingVerticalOffset = 2.0
local CombinedWingSpread = 5.0
local CombinedWingObjectCount = 8
local CombinedWingFlapShape = 2.0
local CombinedWingFlapSpeed = 1.0
local CombinedWingFlapAmount = 3.0

-- ★ 追加: 円形魔法陣設定 ★
local MagicCircleEnabled = false
local MagicCircleFollowPlayerEnabled = false
local MagicCircleTargetPlayerName = ""
local MagicCircleHeight = 0.0  -- 地面からの高さ
local MagicCircleSize = 10.0   -- 魔法陣のサイズ
local MagicCircleObjectCount = 80  -- 魔法陣のポイント数
local MagicCircleRotationSpeed = 10.0  -- 回転速度
local MagicCirclePulseSpeed = 2.0  -- 脈動速度
local MagicCirclePulseAmount = 0.3  -- 脈動の量
local MagicCircleInnerCircleSize = 0.3  -- 内側の円の大きさ(0-1)
local MagicCirclePatternDensity = 8  -- パターンの密度
local MagicCircleWaveFrequency = 3  -- 波の周波数

local list = {}
local magicCircleList = {}  -- ★ 魔法陣用リスト（Musickeyboardパーツ）★
local loopConn = nil
local magicCircleLoopConn = nil  -- ★ 魔法陣用ループ接続 ★
local tAccum = 0
local wingTimeAccum = 0
local magicCircleTimeAccum = 0  -- ★ 魔法陣用時間カウンタ ★

-- HRP取得
local function HRP()
    local c = LP.Character or LP.CharacterAdded:Wait()
    return c:FindFirstChild("HumanoidRootPart")
end

-- ターゲットプレイヤーのHRP取得
local function getTargetHRP(playerName)
    if playerName == "" then return nil end
    
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer then return nil end
    
    local char = targetPlayer.Character
    if not char then return nil end
    
    return char:FindFirstChild("HumanoidRootPart")
end

-- モデルからパーツ取得
local function getPartFromModel(m)
    if m.PrimaryPart then return m.PrimaryPart end
    for _, child in ipairs(m:GetChildren()) do
        if child:IsA("BasePart") then
            return child
        end
    end
    return nil
end

-- 物理演算アタッチ
local function attachPhysics(rec)
    local model = rec.model
    local part = rec.part
    if not model or not part or not part.Parent then return end
    
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p:SetNetworkOwner(LP) end)
            p.CanCollide = false
            p.CanTouch = false
        end
    end
    
    if not part:FindFirstChild("BodyVelocity") then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "BodyVelocity"
        bv.MaxForce = Vector3.new(1e8, 1e8, 1e8)
        bv.Velocity = Vector3.new()
        bv.P = 1e6
        bv.Parent = part
    end
    
    if not part:FindFirstChild("BodyGyro") then
        local bg = Instance.new("BodyGyro")
        bg.Name = "BodyGyro"
        bg.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
        bg.CFrame = part.CFrame
        bg.P = 1e6
        bg.Parent = part
    end
end

-- 物理演算デタッチ
local function detachPhysics(rec)
    local model = rec.model
    local part = rec.part
    if not model or not part then return end
    
    local bv = part:FindFirstChild("BodyVelocity")
    if bv then bv:Destroy() end
    
    local bg = part:FindFirstChild("BodyGyro")
    if bg then bg:Destroy() end
    
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = true
            p.CanTouch = true
            pcall(function() p:SetNetworkOwner(nil) end)
        end
    end
end

-- FireworkSparklerをスキャン
local function rescan()
    for _, r in ipairs(list) do
        detachPhysics(r)
    end
    list = {}
    
    local maxObjects = 0
    local foundCount = 0
    
    -- 各モードに必要なオブジェクト数を計算
    if CombinedEnabled then
        maxObjects = CombinedRingObjectCount + (CombinedWingObjectCount * 2)
    elseif WingEnabled then
        maxObjects = WingObjectCount * 2  -- 左右の翼
    elseif TreeEnabled then
        maxObjects = TreeObjectCount
    else
        maxObjects = ObjectCount
    end
    
    for _, d in ipairs(Workspace:GetDescendants()) do
        if foundCount >= maxObjects then break end
        
        if d:IsA("Model") and d.Name == "FireworkSparkler" then
            local part = getPartFromModel(d)
            if part and not part.Anchored then
                local rec = { 
                    model = d, 
                    part = part,
                    globalIndex = foundCount + 1,
                    type = "unknown"
                }
                
                if CombinedEnabled then
                    -- コンビネーションモード：最初のCombinedRingObjectCount個はリング、それ以降は翼
                    if foundCount < CombinedRingObjectCount then
                        rec.type = "ring"
                        rec.ringIndex = foundCount + 1
                        rec.totalRings = CombinedRingObjectCount
                    else
                        rec.type = "wing"
                        rec.wingIndex = foundCount - CombinedRingObjectCount + 1
                        rec.totalWings = CombinedWingObjectCount * 2
                    end
                elseif WingEnabled then
                    rec.type = "wing"
                    rec.wingIndex = foundCount + 1
                    rec.totalWings = WingObjectCount * 2
                elseif TreeEnabled then
                    rec.type = "tree"
                else
                    rec.type = "ring"
                    rec.ringIndex = foundCount + 1
                    rec.totalRings = ObjectCount
                end
                
                table.insert(list, rec)
                foundCount = foundCount + 1
            end
        end
    end
    
    for i = 1, #list do
        attachPhysics(list[i])
    end
end

-- ★ Musickeyboardパーツをスキャン (円形魔法陣用) ★
local function rescanMagicCircle()
    for _, r in ipairs(magicCircleList) do
        -- 魔法陣用物理演算をデタッチ
        local part = r.part
        if part then
            local bv = part:FindFirstChild("MagicCircleBodyVelocity")
            if bv then bv:Destroy() end
            
            local bg = part:FindFirstChild("MagicCircleBodyGyro")
            if bg then bg:Destroy() end
            
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.CanTouch = true
                pcall(function() part:SetNetworkOwner(nil) end)
            end
        end
    end
    magicCircleList = {}
    
    local foundCount = 0
    
    -- ★ Musickeyboardパーツのみを検索 ★
    for _, d in ipairs(Workspace:GetDescendants()) do
        if foundCount >= MagicCircleObjectCount then break end
        
        -- ★ Musickeyboardパーツのみを使用 ★
        if (d:IsA("Model") or d:IsA("Part")) and string.find(string.lower(d.Name), "musickeyboard") and not d.Anchored then
            local part = nil
            if d:IsA("Part") then
                part = d
            elseif d:IsA("Model") then
                part = getPartFromModel(d)
            end
            
            if part then
                local rec = { 
                    part = part,
                    model = d:IsA("Model") and d or nil,
                    index = foundCount + 1,
                    type = "magic_circle"
                }
                
                table.insert(magicCircleList, rec)
                foundCount = foundCount + 1
                
                -- 魔法陣用に物理演算をアタッチ
                pcall(function() part:SetNetworkOwner(LP) end)
                part.CanCollide = false
                part.CanTouch = false
                
                if not part:FindFirstChild("MagicCircleBodyVelocity") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "MagicCircleBodyVelocity"
                    bv.MaxForce = Vector3.new(1e8, 1e8, 1e8)
                    bv.Velocity = Vector3.new()
                    bv.P = 1e6
                    bv.Parent = part
                end
                
                if not part:FindFirstChild("MagicCircleBodyGyro") then
                    local bg = Instance.new("BodyGyro")
                    bg.Name = "MagicCircleBodyGyro"
                    bg.MaxTorque = Vector3.new(1e8, 1e8, 1e8)
                    bg.CFrame = part.CFrame
                    bg.P = 1e6
                    bg.Parent = part
                end
            end
        end
    end
end

-- ★ 複雑な円形魔法陣の位置計算関数 ★
local function getComplexMagicCirclePosition(index, total, size, rotation, time)
    local t = (index - 1) / total
    local angle = t * math.pi * 2 + rotation
    
    -- 基本的な半径
    local baseRadius = size / 2
    
    -- 1. メインの円形パターン
    local circlePattern = 1.0
    
    -- 2. 内側の小さな円を表現（魔法陣の中心部）
    local innerCircle = MagicCircleInnerCircleSize * 0.8
    
    -- 3. 魔法陣的な複雑なパターンを追加
    local magicPattern = 0
    
    -- 複数のサイン波を組み合わせて複雑なパターンを作成
    for i = 1, MagicCirclePatternDensity do
        local freq = i * MagicCircleWaveFrequency
        local patternValue = math.sin(angle * freq + time * 0.5) * (1.0 / i)
        magicPattern = magicPattern + patternValue
    end
    magicPattern = magicPattern / MagicCirclePatternDensity
    
    -- 4. 脈動効果を追加
    local pulse = math.sin(time * MagicCirclePulseSpeed) * MagicCirclePulseAmount
    
    -- 5. すべての要素を組み合わせて最終的な半径を計算
    local radiusMultiplier = circlePattern + magicPattern * 0.5 + pulse * 0.3
    
    -- 6. 角度によって内側と外側を切り替える（魔法陣の模様）
    local section = math.floor((angle / (math.pi * 2)) * 8) % 2
    if section == 0 then
        radiusMultiplier = radiusMultiplier * (1.0 - innerCircle)
    else
        radiusMultiplier = radiusMultiplier * (1.0 + innerCircle * 0.3)
    end
    
    -- 7. 波状の高さ変化を追加
    local heightWave = math.sin(angle * 5 + time * 2) * (size * 0.1)
    
    local radius = baseRadius * radiusMultiplier
    
    return Vector3.new(
        radius * math.cos(angle),
        heightWave,  -- Y軸に波状の高さ
        radius * math.sin(angle)
    )
end

-- ★ 形状計算関数 (通常オーラ) ★
local function getShapePosition(index, total, size, rotation, shapeType)
    local t = (index - 1) / total
    
    if shapeType == "Circle" then
        -- 円形
        local angle = t * math.pi * 2 + rotation
        local radius = size / 2
        return Vector3.new(
            radius * math.cos(angle),
            0,
            radius * math.sin(angle)
        )
        
    elseif shapeType == "Heart" then
        -- ハート形
        local angle = (t * 2 * math.pi) + rotation
        local x = 16 * (math.sin(angle))^3
        local y = 13 * math.cos(angle) - 5 * math.cos(2*angle) - 2 * math.cos(3*angle) - math.cos(4*angle)
        local scale = size / 30
        
        return Vector3.new(
            -y * scale,
            0,
            x * scale
        )
    end
    
    return Vector3.new()
end

-- ★ クリスマスツリー形状計算 ★
local function getTreePosition(index, total, rotation)
    -- オブジェクトをレイヤーに分配
    local objectsPerLayer = math.ceil(total / TreeLayers)
    local layerIndex = math.floor((index - 1) / objectsPerLayer)
    local indexInLayer = (index - 1) % objectsPerLayer
    
    -- 層ごとの高さと半径を計算（下から上に向かって小さくなる）
    local layerHeight = (layerIndex / TreeLayers) * TreeHeight
    local radiusAtLayer = (1 - layerIndex / TreeLayers) * TreeRingSize
    
    -- 各層での角度
    local t = indexInLayer / objectsPerLayer
    local angle = t * math.pi * 2 + rotation + (layerIndex * 0.5)
    
    return Vector3.new(
        radiusAtLayer * math.cos(angle),
        layerHeight,
        radiusAtLayer * math.sin(angle)
    )
end

-- ★ Wing形状計算 (羽ばたく翼) ★
local function getWingPosition(index, total, time, verticalOffset, spread, flapShape, flapSpeed, flapAmount)
    local halfTotal = total / 2
    local isLeftWing = index <= halfTotal
    local wingIndex = isLeftWing and index or (index - halfTotal)
    
    -- 翼の位置計算（根元から外側へ均等配置）
    local t = (wingIndex - 1) / (halfTotal - 1)  -- 0から1の範囲
    
    -- 羽ばたき計算（角度として計算）
    local phase = (time * flapSpeed - wingIndex * 0.05) * flapShape
    local sinValue = math.sin(phase)
    
    -- 上下で折りたたみ角度を変える
    local actualFlapAmount
    if sinValue > 0 then
        -- 上に来た時：折りたたみ角度を60%に
        actualFlapAmount = flapAmount * 0.6
    else
        -- 下に来た時：通常の折りたたみ角度
        actualFlapAmount = flapAmount
    end
    
    local flapAngle = sinValue * math.rad(actualFlapAmount)
    
    -- 基本の横位置（等間隔）
    local baseX = t * spread
    
    -- 羽ばたきによる位置変化（角度による回転）
    -- Z軸（前後）とY軸（上下）の両方を計算
    local rotatedY = baseX * math.sin(flapAngle)
    local rotatedX = baseX * math.cos(flapAngle)
    
    -- 左右の位置
    local sideOffset = isLeftWing and -(3 + rotatedX) or (3 + rotatedX)
    
    return Vector3.new(
        sideOffset,
        verticalOffset + rotatedY,  -- 高さ + 羽ばたきによる上下
        0  -- 前後は固定
    ), isLeftWing
end

-- メインループ (FireworkSparkler用)
local function startLoop()
    if loopConn then
        loopConn:Disconnect()
        loopConn = nil
    end
    tAccum = 0
    wingTimeAccum = 0
    
    loopConn = RunService.Heartbeat:Connect(function(dt)
        local root = HRP()
        if not root or #list == 0 then return end
        
        -- ターゲットとなるルートパーツを決定
        local targetRoot = root
        
        if CombinedEnabled then
            if CombinedFollowPlayerEnabled then
                local targetHRP = getTargetHRP(CombinedTargetPlayerName)
                if targetHRP then targetRoot = targetHRP end
            end
        elseif WingEnabled then
            if WingFollowPlayerEnabled then
                local targetHRP = getTargetHRP(WingTargetPlayerName)
                if targetHRP then targetRoot = targetHRP end
            end
        elseif TreeEnabled then
            if TreeFollowPlayerEnabled then
                local targetHRP = getTargetHRP(TreeTargetPlayerName)
                if targetHRP then targetRoot = targetHRP end
            end
        else
            if FollowPlayerEnabled then
                local targetHRP = getTargetHRP(TargetPlayerName)
                if targetHRP then targetRoot = targetHRP end
            end
        end
        
        local rootVelocity = targetRoot.AssemblyLinearVelocity or targetRoot.Velocity or Vector3.new()
        
        -- コンビネーションモード
        if CombinedEnabled then
            tAccum = tAccum + dt * (CombinedRotationSpeed / 10)  -- リングの回転用
            wingTimeAccum = wingTimeAccum + dt  -- 羽ばたき用の時間
            
            for i, rec in ipairs(list) do
                local part = rec.part
                if not part or not part.Parent then continue end
                
                local localPos, isLeftWing
                
                if rec.type == "ring" then
                    -- リングの位置計算（コンビネーションモード用設定を使用）
                    local ringIndex = rec.ringIndex or 1
                    local ringTotal = rec.totalRings or CombinedRingObjectCount
                    
                    localPos = getShapePosition(ringIndex, ringTotal, CombinedRingSize, tAccum * 0.5, CombinedShapeType)
                    localPos = localPos + Vector3.new(0, CombinedRingHeight, 0)
                elseif rec.type == "wing" then
                    -- 翼の位置計算（コンビネーションモード用設定を使用）
                    local wingIndex = rec.wingIndex or 1
                    local wingTotal = rec.totalWings or (CombinedWingObjectCount * 2)
                    
                    localPos, isLeftWing = getWingPosition(
                        wingIndex, 
                        wingTotal, 
                        wingTimeAccum,
                        CombinedWingVerticalOffset,
                        CombinedWingSpread,
                        CombinedWingFlapShape,
                        CombinedWingFlapSpeed,
                        CombinedWingFlapAmount
                    )
                else
                    continue
                end
                
                -- ワールド座標に変換
                local targetCF
                if rec.type == "wing" then
                    -- 翼: Y軸回転のみ
                    local _, yRot, _ = targetRoot.CFrame:ToEulerAnglesYXZ()
                    targetCF = CFrame.new(targetRoot.Position) * CFrame.Angles(0, yRot, 0)
                else
                    -- リング: 通常の回転
                    targetCF = targetRoot.CFrame
                end
                
                local targetPos = targetCF.Position + (targetCF - targetCF.Position):VectorToWorldSpace(localPos)
                
                -- BodyVelocityで移動
                local dir = targetPos - part.Position
                local distance = dir.Magnitude
                local bv = part:FindFirstChild("BodyVelocity")
                
                if bv then
                    if distance > 0.1 then
                        local moveVelocity = dir.Unit * math.min(3000, distance * 50)
                        bv.Velocity = moveVelocity + rootVelocity
                    else
                        bv.Velocity = rootVelocity
                    end
                    bv.P = 1e6
                end
                
                -- BodyGyroで回転
                local bg = part:FindFirstChild("BodyGyro")
                if bg then
                    if rec.type == "wing" and isLeftWing then
                        -- 左翼：逆向き
                        local lookAtCFrame = CFrame.lookAt(targetPos, targetRoot.Position)
                        bg.CFrame = lookAtCFrame
                    else
                        -- 右翼・リング：前向き
                        local lookAtCFrame = CFrame.lookAt(targetPos, targetRoot.Position) * CFrame.Angles(0, math.pi, 0)
                        bg.CFrame = lookAtCFrame
                    end
                    bg.P = 1e6
                end
            end
        else
            -- 通常モード（シングル）
            if WingEnabled then
                wingTimeAccum = wingTimeAccum + dt
            else
                local currentRotationSpeed = TreeEnabled and TreeRotationSpeed or RotationSpeed
                tAccum = tAccum + dt * (currentRotationSpeed / 10)
            end
            
            for i, rec in ipairs(list) do
                local part = rec.part
                if not part or not part.Parent then continue end
                
                -- 形状に応じた位置を計算
                local localPos, isLeftWing
                if WingEnabled then
                    localPos, isLeftWing = getWingPosition(
                        rec.wingIndex or i, 
                        rec.totalWings or (WingObjectCount * 2), 
                        wingTimeAccum,
                        WingVerticalOffset, WingSpread, 
                        WingFlapShape, WingFlapSpeed, WingFlapAmount
                    )
                elseif TreeEnabled then
                    localPos = getTreePosition(i, #list, tAccum * 0.5)
                else
                    localPos = getShapePosition(rec.ringIndex or i, rec.totalRings or ObjectCount, RingSize, tAccum * 0.5, ShapeType)
                    localPos = localPos + Vector3.new(0, RingHeight, 0)
                end
                
                -- ワールド座標に変換
                local targetCF
                if WingEnabled then
                    -- Y軸回転のみを取り出す
                    local _, yRot, _ = targetRoot.CFrame:ToEulerAnglesYXZ()
                    targetCF = CFrame.new(targetRoot.Position) * CFrame.Angles(0, yRot, 0)
                else
                    targetCF = targetRoot.CFrame
                end
                
                local targetPos = targetCF.Position + (targetCF - targetCF.Position):VectorToWorldSpace(localPos)
                
                -- BodyVelocityで移動
                local dir = targetPos - part.Position
                local distance = dir.Magnitude
                local bv = part:FindFirstChild("BodyVelocity")
                
                if bv then
                    if distance > 0.1 then
                        local moveVelocity = dir.Unit * math.min(3000, distance * 50)
                        bv.Velocity = moveVelocity + rootVelocity
                    else
                        bv.Velocity = rootVelocity
                    end
                    bv.P = 1e6
                end
                
                -- BodyGyroで回転
                local bg = part:FindFirstChild("BodyGyro")
                if bg then
                    if WingEnabled and isLeftWing then
                        -- 左翼：逆向き
                        local lookAtCFrame = CFrame.lookAt(targetPos, targetRoot.Position)
                        bg.CFrame = lookAtCFrame
                    else
                        -- 右翼・通常オーラ・ツリー：前向き
                        local lookAtCFrame = CFrame.lookAt(targetPos, targetRoot.Position) * CFrame.Angles(0, math.pi, 0)
                        bg.CFrame = lookAtCFrame
                    end
                    bg.P = 1e6
                end
            end
        end
    end)
end

-- ★ 魔法陣用ループ (Musickeyboardパーツ用) ★
local function startMagicCircleLoop()
    if magicCircleLoopConn then
        magicCircleLoopConn:Disconnect()
        magicCircleLoopConn = nil
    end
    magicCircleTimeAccum = 0
    
    magicCircleLoopConn = RunService.Heartbeat:Connect(function(dt)
        local root = HRP()
        if not root or #magicCircleList == 0 then return end
        
        -- ターゲットとなるルートパーツを決定
        local targetRoot = root
        
        if MagicCircleFollowPlayerEnabled then
            local targetHRP = getTargetHRP(MagicCircleTargetPlayerName)
            if targetHRP then targetRoot = targetHRP end
        end
        
        local rootVelocity = targetRoot.AssemblyLinearVelocity or targetRoot.Velocity or Vector3.new()
        
        -- 魔法陣の時間更新
        magicCircleTimeAccum = magicCircleTimeAccum + dt * MagicCircleRotationSpeed
        
        for i, rec in ipairs(magicCircleList) do
            local part = rec.part
            if not part or not part.Parent then continue end
            
            -- 複雑な円形魔法陣の位置を計算
            local localPos = getComplexMagicCirclePosition(
                rec.index or i, 
                MagicCircleObjectCount, 
                MagicCircleSize, 
                magicCircleTimeAccum * 0.1, 
                magicCircleTimeAccum
            )
            
            -- 地面からの高さを追加
            localPos = localPos + Vector3.new(0, MagicCircleHeight, 0)
            
            -- ワールド座標に変換 (地面に平行に)
            local targetCF = CFrame.new(targetRoot.Position) * CFrame.Angles(0, 0, 0)
            local targetPos = targetCF.Position + (targetCF - targetCF.Position):VectorToWorldSpace(localPos)
            
            -- BodyVelocityで移動
            local dir = targetPos - part.Position
            local distance = dir.Magnitude
            local bv = part:FindFirstChild("MagicCircleBodyVelocity")
            
            if bv then
                if distance > 0.1 then
                    local moveVelocity = dir.Unit * math.min(3000, distance * 50)
                    bv.Velocity = moveVelocity + rootVelocity
                else
                    bv.Velocity = rootVelocity
                end
                bv.P = 1e6
            end
            
            -- BodyGyroで回転 (魔法陣は常に上向き)
            local bg = part:FindFirstChild("MagicCircleBodyGyro")
            if bg then
                local lookAtCFrame = CFrame.lookAt(targetPos, targetPos + Vector3.new(0, 1, 0)) * CFrame.Angles(math.pi/2, 0, 0)
                bg.CFrame = lookAtCFrame
                bg.P = 1e6
            end
        end
    end)
end

-- ループ停止
local function stopLoop()
    if loopConn then
        loopConn:Disconnect()
        loopConn = nil
    end
    for _, rec in ipairs(list) do
        detachPhysics(rec)
    end
    list = {}
end

-- ★ 魔法陣ループ停止 ★
local function stopMagicCircleLoop()
    if magicCircleLoopConn then
        magicCircleLoopConn:Disconnect()
        magicCircleLoopConn = nil
    end
    for _, rec in ipairs(magicCircleList) do
        local part = rec.part
        if part then
            local bv = part:FindFirstChild("MagicCircleBodyVelocity")
            if bv then bv:Destroy() end
            
            local bg = part:FindFirstChild("MagicCircleBodyGyro")
            if bg then bg:Destroy() end
            
            if part:IsA("BasePart") then
                part.CanCollide = true
                part.CanTouch = true
                pcall(function() part:SetNetworkOwner(nil) end)
            end
        end
    end
    magicCircleList = {}
end

-- プレイヤー名リスト取得
local function getPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(names, player.Name)
        end
    end
    return names
end

-- ====================================================================
-- UI要素 (通常オーラ)
-- ====================================================================

Tab:AddSection({ Name = "起動/停止" })

Tab:AddToggle({
    Name = "FireworkSparkler オーラ ON/OFF",
    Default = false,
    Callback = function(v)
        Enabled = v
        if v then
            TreeEnabled = false
            WingEnabled = false
            CombinedEnabled = false
            MagicCircleEnabled = false
            stopMagicCircleLoop()
            rescan()
            startLoop()
        else
            stopLoop()
        end
    end
})

Tab:AddSection({ Name = "Follow Player" })

Tab:AddDropdown({
    Name = "ターゲットプレイヤー選択",
    Default = "",
    Options = getPlayerNames(),
    Callback = function(v)
        TargetPlayerName = v
    end
})

Tab:AddToggle({
    Name = "Follow Player",
    Default = false,
    Callback = function(v)
        FollowPlayerEnabled = v
    end
})

Tab:AddSection({ Name = "形状選択" })

Tab:AddDropdown({
    Name = "オーラの形状",
    Default = ShapeType,
    Options = {"Circle", "Heart"},
    Callback = function(v)
        ShapeType = v
    end
})

Tab:AddSection({ Name = "FireworkSparkler 設定" })

Tab:AddSlider({
    Name = "形状の高さ",
    Min = 1.0,
    Max = 50.0,
    Default = RingHeight,
    Increment = 0.5,
    Callback = function(v)
        RingHeight = v
    end
})

Tab:AddSlider({
    Name = "形状のサイズ",
    Min = 3.0,
    Max = 100.0,
    Default = RingSize,
    Increment = 1.0,
    Callback = function(v)
        RingSize = v
    end
})

Tab:AddSlider({
    Name = "オブジェクト数",
    Min = 3,
    Max = 30,
    Default = ObjectCount,
    Increment = 1,
    Callback = function(v)
        ObjectCount = v
        if Enabled then
            rescan()
        end
    end
})

Tab:AddSlider({
    Name = "回転速度",
    Min = 0.0,
    Max = 1000.0,
    Default = RotationSpeed,
    Increment = 10.0,
    Callback = function(v)
        RotationSpeed = v
    end
})

-- ====================================================================
-- UI要素 (クリスマスツリー)
-- ====================================================================

ChristmasTab:AddSection({ Name = "🎄 Christmas Tree 起動" })

ChristmasTab:AddToggle({
    Name = "🎄 Christmas Tree ON/OFF",
    Default = false,
    Callback = function(v)
        TreeEnabled = v
        if v then
            Enabled = false
            WingEnabled = false
            CombinedEnabled = false
            MagicCircleEnabled = false
            stopMagicCircleLoop()
            rescan()
            startLoop()
        else
            stopLoop()
        end
    end
})

ChristmasTab:AddSection({ Name = "Follow Player (ツリー)" })

ChristmasTab:AddDropdown({
    Name = "ターゲットプレイヤー選択",
    Default = "",
    Options = getPlayerNames(),
    Callback = function(v)
        TreeTargetPlayerName = v
    end
})

ChristmasTab:AddToggle({
    Name = "Follow Player",
    Default = false,
    Callback = function(v)
        TreeFollowPlayerEnabled = v
    end
})

ChristmasTab:AddSection({ Name = "ツリー設定" })

ChristmasTab:AddSlider({
    Name = "ツリーの高さ",
    Min = 5.0,
    Max = 200.0,
    Default = TreeHeight,
    Increment = 5.0,
    Callback = function(v)
        TreeHeight = v
    end
})

ChristmasTab:AddSlider({
    Name = "ツリーの幅 (リング最大半径)",
    Min = 3.0,
    Max = 100.0,
    Default = TreeRingSize,
    Increment = 1.0,
    Callback = function(v)
        TreeRingSize = v
    end
})

ChristmasTab:AddSlider({
    Name = "ツリーの層数",
    Min = 1,
    Max = 30,
    Default = TreeLayers,
    Increment = 1,
    Callback = function(v)
        TreeLayers = v
    end
})

ChristmasTab:AddSlider({
    Name = "オブジェクト数",
    Min = 10,
    Max = 30,
    Default = TreeObjectCount,
    Increment = 1,
    Callback = function(v)
        TreeObjectCount = v
        if TreeEnabled then
            rescan()
        end
    end
})

ChristmasTab:AddSlider({
    Name = "回転速度",
    Min = 0.0,
    Max = 1000.0,
    Default = TreeRotationSpeed,
    Increment = 10.0,
    Callback = function(v)
        TreeRotationSpeed = v
    end
})

-- ====================================================================
-- UI要素 (Wing) - 羽ばたく翼
-- ====================================================================

WingTab:AddSection({ Name = "👼 Wing 起動" })

WingTab:AddToggle({
    Name = "👼 Wing ON/OFF",
    Default = false,
    Callback = function(v)
        WingEnabled = v
        if v then
            Enabled = false
            TreeEnabled = false
            CombinedEnabled = false
            MagicCircleEnabled = false
            stopMagicCircleLoop()
            rescan()
            startLoop()
        else
            stopLoop()
        end
    end
})

WingTab:AddSection({ Name = "Follow Player (Wing)" })

WingTab:AddDropdown({
    Name = "ターゲットプレイヤー選択",
    Default = "",
    Options = getPlayerNames(),
    Callback = function(v)
        WingTargetPlayerName = v
    end
})

WingTab:AddToggle({
    Name = "Follow Player",
    Default = false,
    Callback = function(v)
        WingFollowPlayerEnabled = v
    end
})

WingTab:AddSection({ Name = "Wing 設定" })

WingTab:AddSlider({
    Name = "翼の高さ位置",
    Min = -10.0,
    Max = 20.0,
    Default = WingVerticalOffset,
    Increment = 0.5,
    Callback = function(v)
        WingVerticalOffset = v
    end
})

WingTab:AddSlider({
    Name = "翼の広がり (横の長さ)",
    Min = 3.0,
    Max = 30.0,
    Default = WingSpread,
    Increment = 1.0,
    Callback = function(v)
        WingSpread = v
    end
})

WingTab:AddSlider({
    Name = "羽ばたきの形状 (波の細かさ)",
    Min = 0.5,
    Max = 10.0,
    Default = WingFlapShape,
    Increment = 0.5,
    Callback = function(v)
        WingFlapShape = v
    end
})

WingTab:AddSlider({
    Name = "羽ばたく速さ",
    Min = 0.1,
    Max = 5.0,
    Default = WingFlapSpeed,
    Increment = 0.1,
    Callback = function(v)
        WingFlapSpeed = v
    end
})

WingTab:AddSlider({
    Name = "羽ばたく可動域 (折りたたみ角度)",
    Min = 0.0,
    Max = 100.0,
    Default = WingFlapAmount,
    Increment = 1.0,
    Callback = function(v)
        WingFlapAmount = v
    end
})

WingTab:AddSlider({
    Name = "片翼のオブジェクト数",
    Min = 3,
    Max = 15,
    Default = WingObjectCount,
    Increment = 1,
    Callback = function(v)
        WingObjectCount = v
        if WingEnabled then
            rescan()
        end
    end
})

-- ====================================================================
-- UI要素 (Combined) - リング + 羽 コンビネーションモード
-- ====================================================================

CombinedTab:AddSection({ Name = "🌟 コンビネーションモード起動" })

CombinedTab:AddToggle({
    Name = "🌟 リング + 羽 ON/OFF",
    Default = false,
    Callback = function(v)
        CombinedEnabled = v
        if v then
            Enabled = false
            TreeEnabled = false
            WingEnabled = false
            MagicCircleEnabled = false
            stopMagicCircleLoop()
            rescan()
            startLoop()
        else
            stopLoop()
        end
    end
})

CombinedTab:AddSection({ Name = "Follow Player (コンビネーション)" })

CombinedTab:AddDropdown({
    Name = "ターゲットプレイヤー選択",
    Default = "",
    Options = getPlayerNames(),
    Callback = function(v)
        CombinedTargetPlayerName = v
    end
})

CombinedTab:AddToggle({
    Name = "Follow Player",
    Default = false,
    Callback = function(v)
        CombinedFollowPlayerEnabled = v
    end
})

CombinedTab:AddSection({ Name = "🌟 リング設定 (コンビネーションモード用)" })

CombinedTab:AddDropdown({
    Name = "オーラの形状",
    Default = CombinedShapeType,
    Options = {"Circle", "Heart"},
    Callback = function(v)
        CombinedShapeType = v
    end
})

CombinedTab:AddSlider({
    Name = "形状の高さ",
    Min = 1.0,
    Max = 50.0,
    Default = CombinedRingHeight,
    Increment = 0.5,
    Callback = function(v)
        CombinedRingHeight = v
    end
})

CombinedTab:AddSlider({
    Name = "形状のサイズ",
    Min = 3.0,
    Max = 100.0,
    Default = CombinedRingSize,
    Increment = 1.0,
    Callback = function(v)
        CombinedRingSize = v
    end
})

CombinedTab:AddSlider({
    Name = "リングのオブジェクト数",
    Min = 3,
    Max = 30,
    Default = CombinedRingObjectCount,
    Increment = 1,
    Callback = function(v)
        CombinedRingObjectCount = v
        if CombinedEnabled then
            rescan()
        end
    end
})

CombinedTab:AddSlider({
    Name = "リング回転速度",
    Min = 0.0,
    Max = 1000.0,
    Default = CombinedRotationSpeed,
    Increment = 10.0,
    Callback = function(v)
        CombinedRotationSpeed = v
    end
})

CombinedTab:AddSection({ Name = "🌟 翼設定 (コンビネーションモード用)" })

CombinedTab:AddSlider({
    Name = "翼の高さ位置",
    Min = -10.0,
    Max = 20.0,
    Default = CombinedWingVerticalOffset,
    Increment = 0.5,
    Callback = function(v)
        CombinedWingVerticalOffset = v
    end
})

CombinedTab:AddSlider({
    Name = "翼の広がり (横の長さ)",
    Min = 3.0,
    Max = 30.0,
    Default = CombinedWingSpread,
    Increment = 1.0,
    Callback = function(v)
        CombinedWingSpread = v
    end
})

CombinedTab:AddSlider({
    Name = "羽ばたきの形状 (波の細かさ)",
    Min = 0.5,
    Max = 10.0,
    Default = CombinedWingFlapShape,
    Increment = 0.5,
    Callback = function(v)
        CombinedWingFlapShape = v
    end
})

CombinedTab:AddSlider({
    Name = "羽ばたく速さ",
    Min = 0.1,
    Max = 5.0,
    Default = CombinedWingFlapSpeed,
    Increment = 0.1,
    Callback = function(v)
        CombinedWingFlapSpeed = v
    end
})

CombinedTab:AddSlider({
    Name = "羽ばたく可動域 (折りたたみ角度)",
    Min = 0.0,
    Max = 100.0,
    Default = CombinedWingFlapAmount,
    Increment = 1.0,
    Callback = function(v)
        CombinedWingFlapAmount = v
    end
})

CombinedTab:AddSlider({
    Name = "片翼のオブジェクト数",
    Min = 3,
    Max = 15,
    Default = CombinedWingObjectCount,
    Increment = 1,
    Callback = function(v)
        CombinedWingObjectCount = v
        if CombinedEnabled then
            rescan()
        end
    end
})

-- ====================================================================
-- UI要素 (魔法陣) - 円形魔法陣 ★ Musickeyboardパーツ使用 ★
-- ====================================================================

MagicCircleTab:AddSection({ Name = "✨ 円形魔法陣起動" })

MagicCircleTab:AddToggle({
    Name = "✨ 円形魔法陣 ON/OFF",
    Default = false,
    Callback = function(v)
        MagicCircleEnabled = v
        if v then
            Enabled = false
            TreeEnabled = false
            WingEnabled = false
            CombinedEnabled = false
            stopLoop()
            rescanMagicCircle()
            startMagicCircleLoop()
        else
            stopMagicCircleLoop()
        end
    end
})

MagicCircleTab:AddSection({ Name = "Follow Player (魔法陣)" })

MagicCircleTab:AddDropdown({
    Name = "ターゲットプレイヤー選択",
    Default = "",
    Options = getPlayerNames(),
    Callback = function(v)
        MagicCircleTargetPlayerName = v
    end
})

MagicCircleTab:AddToggle({
    Name = "Follow Player",
    Default = false,
    Callback = function(v)
        MagicCircleFollowPlayerEnabled = v
    end
})

MagicCircleTab:AddSection({ Name = "✨ 魔法陣基本設定" })

MagicCircleTab:AddSlider({
    Name = "魔法陣の高さ",
    Min = -10.0,
    Max = 50.0,
    Default = MagicCircleHeight,
    Increment = 0.5,
    Callback = function(v)
        MagicCircleHeight = v
    end
})

MagicCircleTab:AddSlider({
    Name = "魔法陣のサイズ",
    Min = 5.0,
    Max = 100.0,
    Default = MagicCircleSize,
    Increment = 1.0,
    Callback = function(v)
        MagicCircleSize = v
    end
})

MagicCircleTab:AddSlider({
    Name = "オブジェクト数",
    Min = 20,
    Max = 200,
    Default = MagicCircleObjectCount,
    Increment = 10,
    Callback = function(v)
        MagicCircleObjectCount = v
        if MagicCircleEnabled then
            rescanMagicCircle()
        end
    end
})

MagicCircleTab:AddSlider({
    Name = "回転速度",
    Min = 0.0,
    Max = 50.0,
    Default = MagicCircleRotationSpeed,
    Increment = 0.5,
    Callback = function(v)
        MagicCircleRotationSpeed = v
    end
})

MagicCircleTab:AddSection({ Name = "✨ 魔法陣詳細設定" })

MagicCircleTab:AddSlider({
    Name = "脈動速度",
    Min = 0.0,
    Max = 10.0,
    Default = MagicCirclePulseSpeed,
    Increment = 0.1,
    Callback = function(v)
        MagicCirclePulseSpeed = v
    end
})

MagicCircleTab:AddSlider({
    Name = "脈動の量",
    Min = 0.0,
    Max = 1.0,
    Default = MagicCirclePulseAmount,
    Increment = 0.05,
    Callback = function(v)
        MagicCirclePulseAmount = v
    end
})

MagicCircleTab:AddSlider({
    Name = "内側の円サイズ",
    Min = 0.0,
    Max = 1.0,
    Default = MagicCircleInnerCircleSize,
    Increment = 0.05,
    Callback = function(v)
        MagicCircleInnerCircleSize = v
    end
})

MagicCircleTab:AddSlider({
    Name = "パターン密度",
    Min = 1,
    Max = 20,
    Default = MagicCirclePatternDensity,
    Increment = 1,
    Callback = function(v)
        MagicCirclePatternDensity = v
    end
})

MagicCircleTab:AddSlider({
    Name = "波の周波数",
    Min = 1,
    Max = 10,
    Default = MagicCircleWaveFrequency,
    Increment = 1,
    Callback = function(v)
        MagicCircleWaveFrequency = v
    end
})

OrionLib:Init()
