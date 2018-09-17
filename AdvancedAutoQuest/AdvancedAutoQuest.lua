--------------------------------------------------------------------------------
--- Globals
--------------------------------------------------------------------------------

--Global("CID", 0)
--Global("BID", 0)
Global("ZonesTable", {
    [0] = {"Quest1.sysName", "Quest2.sysName"},
    [29862] = {"Quest1.sysName", "Quest2.sysName"} -- Царство Стихий
})

--------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------

function On_EVENT_INTERACTION_STARTED(params)
    AvatarReturnQuest()
    AvatarAcceptQuests()
    local zoneInfo = cartographer.GetCurrentZoneInfo()
    AvatarAcceptAddQuests (zoneInfo)
end

function On_EVENT_QUEST_RECEIVED(params)
    local qid = params.questId
    if avatar.GetSkipQuestCost( qid) <= avatar.GetDestinyPoints().total then
        avatar.SkipQuest( qid )
    end
    if avatar.IsTalking() then
        On_EVENT_INTERACTION_STARTED()
    end
end

function AvatarReturnQuest()
    local retQuestList = avatar.GetReturnableQuests()
    if retQuestList then
        for i, id in pairs(retQuestList) do
            local ai = avatar.GetQuestReward( id ).alternativeItems
            if #ai == 0 then
                avatar.ReturnQuest( id, nil )
            else
                for key, val in pairs(ai) do
                    avatar.ReturnQuest( id, val )
                    break
                end
            end
        end
    end
end

function AvatarAcceptQuests()
    local availableQuestList = avatar.GetAvailableQuests()
    if availableQuestList then
        for i, id in pairs(availableQuestList) do
            local qInf = avatar.GetQuestInfo( id )
            if (not qInf.isLowPriority and not qInf.isRepeatable) or qInf.canBeSkipped then
                avatar.AcceptQuest( id )
            end
        end
    end
end

function AvatarAcceptAddQuests (zoneInfo)
    local availableQuestList = avatar.GetAvailableQuests()
    if availableQuestList then
        for key, value in pairs(ZonesTable) do
            if zoneInfo.zonesMapId == key then
                --Отладка для получения информации о дополнительных квестах и текущей зоне
                LogInfo(zoneInfo)
                for k, id in pairs(availableQuestList) do
                    local qInf = avatar.GetQuestInfo( id )
                    LogInfo(qInf)
                end
                --Отладка для получения информации о дополнительных квестах и текущей зоне
                for i = 1, #value, 1 do
                    for k, id in pairs(availableQuestList) do
                        local qInf = avatar.GetQuestInfo( id )
                        if qInf.sysName == value[i] then
                            avatar.AcceptQuest( id )
                        end
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
--- INITIALIZATION
--------------------------------------------------------------------------------

function Init()
    common.RegisterEventHandler(On_EVENT_QUEST_RECEIVED, "EVENT_QUEST_RECEIVED")
    common.RegisterEventHandler(On_EVENT_INTERACTION_STARTED, "EVENT_INTERACTION_STARTED")
end

--------------------------------------------------------------------------------

common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
if avatar.IsExist() then
    Init()
end
