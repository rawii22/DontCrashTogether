local assets =
{
    Asset("ANIM", "anim/chester_eyebone.zip"),
    Asset("ANIM", "anim/chester_eyebone_build.zip"),

    Asset("INV_IMAGE", "tamehound_bone"),
    Asset("INV_IMAGE", "tamehound_bone_closed"),
}

local SPAWN_DIST = 30

local function OpenEye(inst)
    if not inst.isOpenEye then
        inst.isOpenEye = true
        inst.components.inventoryitem:ChangeImageName(inst.openEye)
        inst.AnimState:PlayAnimation("idle_loop", true)
    end
end

local function CloseEye(inst)
    if inst.isOpenEye then
        inst.isOpenEye = nil
        inst.components.inventoryitem:ChangeImageName(inst.closedEye)
        inst.AnimState:PlayAnimation("dead", true)
    end
end

local function GetSpawnPoint(pt)
    local theta = math.random() * 2 * PI
    local radius = SPAWN_DIST
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    return offset ~= nil and (pt + offset) or nil
end

local function SpawnTameHound(inst)
    --print("tamehound_bone - SpawnTameHound")

    local pt = inst:GetPosition()
    --print("    near", pt)

    local spawn_pt = GetSpawnPoint(pt)
    if spawn_pt ~= nil then
        --print("    at", spawn_pt)
        local tamehound = SpawnPrefab("tamehound")
        if tamehound ~= nil then
            tamehound.Physics:Teleport(spawn_pt:Get())
            tamehound:FacePoint(pt:Get())

            return tamehound
        end

    --else
        -- this is not fatal, they can try again in a new location by picking up the bone again
        --print("tamehound_bone - SpawnTameHound: Couldn't find a suitable spawn point for a tame hound")
    end
end

local StartRespawn

local function StopRespawn(inst)
    if inst.respawntask ~= nil then
        inst.respawntask:Cancel()
        inst.respawntask = nil
        inst.respawntime = nil
    end
end

local function RebindTameHound(inst, tamehound)
    tamehound = tamehound or TheSim:FindFirstEntityWithTag("tamehound")
    if tamehound ~= nil then
        OpenEye(inst)
        inst:ListenForEvent("death", function() StartRespawn(inst, TUNING.CHESTER_RESPAWN_TIME) end, tamehound)

        if tamehound._playerlink ~= inst then
            tamehound._playerlink = inst
            tamehound.components.follower:SetLeader(inst)
        end
        return true
    end
end

local function RespawnTameHound(inst)
    StopRespawn(inst)
    RebindTameHound(inst, TheSim:FindFirstEntityWithTag("tamehound") or SpawnTameHound(inst))
end

StartRespawn = function(inst, time)
    StopRespawn(inst)

    time = time or 0
    inst.respawntask = inst:DoTaskInTime(time, RespawnTameHound)
    inst.respawntime = GetTime() + time
    CloseEye(inst)
end

local function FixTameHound(inst)
    inst.fixtask = nil
    --take an existing tamehound if there is one
    if not RebindTameHound(inst) then
        CloseEye(inst)
        
        if inst.components.inventoryitem.owner ~= nil then
            local time_remaining = inst.respawntime ~= nil and math.max(0, inst.respawntime - GetTime()) or 0
            StartRespawn(inst, time_remaining)
        end
    end
end

local function OnPutInInventory(inst)
    if inst.fixtask == nil then
        inst.fixtask = inst:DoTaskInTime(1, FixTameHound)
    end
    
end

local function OnSave(inst, data)
    data.EyeboneState = inst.EyeboneState
    if inst.respawntime ~= nil then
        local time = GetTime()
        if inst.respawntime > time then
            data.respawntimeremaining = inst.respawntime - time
        end
    end
end

local function OnLoad(inst, data)
    if data == nil then
        return
    end

    if data.EyeboneState == "SHADOW" then
        --MorphShadowEyebone(inst)
    end

    if data.respawntimeremaining ~= nil then
        inst.respawntime = data.respawntimeremaining + GetTime()
    else
        OpenEye(inst)
    end
end

local function GetStatus(inst)
    return inst.respawntask ~= nil and "WAITING" or nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("chester_eyebone")
    inst:AddTag("irreplaceable")
    inst:AddTag("nonpotatable")

    inst.AnimState:SetBank("eyebone")
    inst.AnimState:SetBuild("chester_eyebone_build")
    inst.AnimState:PlayAnimation("dead", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.EyeboneState = nil
    inst.openEye = "chester_eyebone"
    inst.closedEye = "chester_eyebone_closed"
    inst.isOpenEye = nil

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    inst.components.inventoryitem:ChangeImageName(inst.closedEye)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus
    inst.components.inspectable:RecordViews()

    inst:AddComponent("leader")

    MakeHauntableLaunch(inst)

    --inst.MorphNormalEyebone = MorphNormalEyebone
    --inst.MorphSnowEyebone = MorphSnowEyebone
    --inst.MorphShadowEyebone = MorphShadowEyebone

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    inst.fixtask = inst:DoTaskInTime(1, FixTameHound)

    return inst
end

return Prefab("tamehound_bone", fn, assets)
