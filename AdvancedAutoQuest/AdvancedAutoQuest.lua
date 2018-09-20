-------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------

function On_EVENT_INTERACTION_STARTED(params)
    local currentInterlocutor = avatar.GetInterlocutor()
    if currentInterlocutor then
        local unitQuestsTables = object.GetInteractorQuests(currentInterlocutor)
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
                for _, id in pairs(unitQuestsTables.readyToGive) do
                    local qInf = avatar.GetQuestInfo(id)
                    if (not qInf.isLowPriority and not qInf.isRepeatable) or qInf.canBeSkipped then
                        table.insert (currentQuestTable, #currentQuestTable + 1, id)
                    else
                        table.insert (currentAdditionalQuestsTable, #currentAdditionalQuestsTable + 1, id)
                    end
                end
                if not IsEmpty(currentAdditionalQuestsTable) then
                    local lName = fromWS(common.ExtractWStringFromValuedText(cartographer.GetCurrentZoneInfo().zoneName))
                    for _, qId in pairs(currentAdditionalQuestsTable) do
                        local qName = fromWS(common.ExtractWStringFromValuedText(avatar.GetQuestInfo(qId).name))
                        if IsInList(qName, lName, QuestsLocales) then
                            table.insert (currentQuestTable, #currentQuestTable + 1, id)
                        end
                    end
                end
                if not IsEmpty(currentQuestTable) then
                    for _, id in pairs(currentQuestTable) do
                        avatar.AcceptQuest(id)
                    end
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
        LogInfo(fromWS(cartographer.GetCurrentZoneInfo().zoneName), " : ", fromWS(common.ExtractWStringFromValuedText(qInf.name)))
        --Отладка
    end
    if avatar.IsTalking() then
        On_EVENT_INTERACTION_STARTED()
    end
end

function On_EVENT_AVATAR_DESTINY_POINTS_CHANGED (params)
    local count
    repeat
        count = SkipAllQuest()
    until (count > avatar.GetDestinyPoints().total) or (count == 0)
    if count == 0 then
        common.UnRegisterEventHandler(On_EVENT_AVATAR_DESTINY_POINTS_CHANGED, "EVENT_AVATAR_DESTINY_POINTS_CHANGED")
    end
    if avatar.IsTalking() then
        On_EVENT_INTERACTION_STARTED()
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
    return needDestinyPoints
end

function IsInList (questName, locationName, listName)
    if listName[localization][locationName] then
        for i, q in pairs(listName[localization][locationName]) do
            if questName == q then
                return true
            end
            return false
        end
    end
    return false
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
