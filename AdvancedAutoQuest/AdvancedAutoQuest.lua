--------------------------------------------------------------------------------
--- Globals
--------------------------------------------------------------------------------

Global("zonesTable", {
    ["Test"] = {"Quest1.sysName", "Quest2.sysName"},
    ["Kingdom Of Elements"] = {"Quest1.sysName", "Quest2.sysName"} -- Царство Стихий
})

--------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------

function On_EVENT_INTERACTION_STARTED(params)
    local unitQuestsTables = object.GetInteractorQuests(avatar.GetInterlocutor())
    if not IsEmpty(unitQuestsTables) then
        if not IsEmpty(unitQuestsTables.readyToAccept) then
            for i, id in pairs(unitQuestsTables.readyToAccept) do
                local itemsQuestsReward = avatar.GetQuestReward(id).alternativeItems
                if IsEmpty(itemsQuestsReward) then
                    avatar.ReturnQuest(id, nil)
                else
                    for key, value in pairs(itemsQuestsReward) do
                        avatar.ReturnQuest(id, value)
                        break
                    end
                end
            end
        end
        if not IsEmpty(unitQuestsTables.readyToGive) then
            local currentQuestTable = {}
            local currentAdditionalQuestsTable = {}
            for i, id in pairs(unitQuestsTables.readyToGive) do
                local qInf = avatar.GetQuestInfo(id)
                if (not qInf.isLowPriority and not qInf.isRepeatable) or qInf.canBeSkipped then
                    table.insert (currentQuestTable, #currentQuestTable + 1, id)
                else
                    table.insert (currentAdditionalQuestsTable, #currentQuestTable + 1, id)
                end
            end
            if not IsEmpty(currentAdditionalQuestsTable) then
                local currentZone = cartographer.GetCurrentZoneInfo().zoneName
                for key, value in pairs(zonesTable) do
                    if GTL(key) == fromWS(currentZone) then
                        for i, id in pairs(currentAdditionalQuestsTable) do
                            local qInf = avatar.GetQuestInfo(id)
                            --Отладка
                            LogInfo(fromWS(common.ExtractWStringFromValuedText(qInf.name)), " - ", qInf.sysName)
                            --Отладка
                            for k, v in pairs(zonesTable[key]) do
                                if v == qInf.sysName then
                                    table.insert (currentAdditionalQuestsTable, #currentQuestTable + 1, id)
                                    break
                                end
                            end
                        end
                    end
                end
            end
            if not IsEmpty(currentQuestTable) then
                --Отладка
                LogInfo(currentQuestTable)
                --Отладка
                CommonAcceptQuests (currentQuestTable)
            end
        end
    end
end

function On_EVENT_QUEST_RECEIVED(params)
    local qid = params.questId
    if avatar.GetSkipQuestCost(qid) <= avatar.GetDestinyPoints().total then
        avatar.SkipQuest(qid)
    else
        common.RegisterEventHandler(On_EVENT_AVATAR_DESTINY_POINTS_CHANGED, "EVENT_AVATAR_DESTINY_POINTS_CHANGED")
    end
    if avatar.IsTalking() then
        On_EVENT_INTERACTION_STARTED()
    end
end

function On_EVENT_AVATAR_DESTINY_POINTS_CHANGED (params)
    while SkipAllQuest() < (avatar.GetDestinyPoints().total - 1) do
    end
end

function CommonAcceptQuests(qTable)
    if qTable then
        for i, id in pairs(qTable) do
            avatar.AcceptQuest(id)
        end
    end
end

function SkipAllQuest()
    local qTable = avatar.GetQuestBook()
    if not qTable then
        return
    end
    local needDestinyPoints = 0
    for _, id in pairs(qTable) do
        if avatar.GetQuestInfo(id).canBeSkipped == true then
            local currentNeedDestinyPoints = avatar.GetSkipQuestCost(id)
            if currentNeedDestinyPoints <= avatar.GetDestinyPoints().total then
                avatar.SkipQuest(id)
            else
                needDestinyPoints = needDestinyPoints + currentNeedDestinyPoints
            end
        end
    end
    if needDestinyPoints == 0 then
        common.UnRegisterEventHandler(On_EVENT_AVATAR_DESTINY_POINTS_CHANGED, "EVENT_AVATAR_DESTINY_POINTS_CHANGED")
    end
    return needDestinyPoints
end

--------------------------------------------------------------------------------
--- INITIALIZATION
--------------------------------------------------------------------------------

function Init()
    common.RegisterEventHandler(On_EVENT_QUEST_RECEIVED, "EVENT_QUEST_RECEIVED")
    common.RegisterEventHandler(On_EVENT_INTERACTION_STARTED, "EVENT_INTERACTION_STARTED")
    common.UnRegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end

--------------------------------------------------------------------------------

common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
if avatar.IsExist() then
    Init()
end
