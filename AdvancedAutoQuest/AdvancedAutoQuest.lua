--------------------------------------------------------------------------------
--- Globals
--------------------------------------------------------------------------------

local interlocutorId

Global("zonesTable", {
    ["Novograd"] = {"IM_HaloRevard", "MegaGoal_L_IslandDaily_07", "GuildQuest_1_1", "GuildQuest_3_1", "GuildQuest_2_17"},
    ["Kingdom Of Elements"] = {"Center_1", "Center_2", "Center_3", "Ice_1", "Ice_2", "Ice_3", "Snow_1", "Snow_2", "Snow_3", "Snow_4", "Snow_5", "Snow_6", "Snow_7", "Snow_8", "Snow_9", "Air_1", "Air_2", "Air_3", "Air_4", "Stone_1", "Water_1", "Water_2", "Water_3", } -- Царство Стихий
})

--------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------

function On_EVENT_INTERACTION_STARTED(params)
    interlocutorId = avatar.GetInterlocutor()
    if interlocutorId then
        local unitQuestsTables = object.GetInteractorQuests(interlocutorId)
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
                        table.insert (currentAdditionalQuestsTable, #currentAdditionalQuestsTable + 1, id)
                    end
                end
                if not IsEmpty(currentAdditionalQuestsTable) then
                    local currentZone = cartographer.GetCurrentZoneInfo().zoneName
                    for key, value in pairs(zonesTable) do
                        if GTL(key) == fromWS(currentZone) then
                            for _, id in pairs(currentAdditionalQuestsTable) do
                                local qInf = avatar.GetQuestInfo(id)
                                for i, v in pairs(zonesTable[key]) do
                                    if v == qInf.sysName then
                                        table.insert (currentQuestTable, #currentQuestTable + 1, id)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                if not IsEmpty(currentQuestTable) then
                    CommonAcceptQuests (currentQuestTable)
                end
            end
        end
    end
end

function On_EVENT_QUEST_RECEIVED(params)
    local qid = params.questId
    local qInf = avatar.GetQuestInfo(qid)
    if qInf.canBeSkipped then
        if avatar.GetSkipQuestCost(qid) <= avatar.GetDestinyPoints().total then
            avatar.SkipQuest(qid)
        else
            common.RegisterEventHandler(On_EVENT_AVATAR_DESTINY_POINTS_CHANGED, "EVENT_AVATAR_DESTINY_POINTS_CHANGED")
        end
        --Отладка
    else
        local currentZone = cartographer.GetCurrentZoneInfo().zoneName
        LogInfo(fromWS(currentZone), " : ", fromWS(common.ExtractWStringFromValuedText(qInf.name)), " - ", qInf.sysName)
        --Отладка
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
