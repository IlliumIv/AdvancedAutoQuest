-------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------

function On_EVENT_INTERACTION_STARTED()
    local currentInterlocutor = avatar.GetInterlocutor()
    if currentInterlocutor then
        local idInteractor = avatar.GetInteractorInfo().interactorId
        if not IsInList(fromWScore(object.GetName(idInteractor)), NPCLocales) then
            if object.IsUnit(idInteractor) then
                local answer = avatar.GetInteractorNextCues()
                if answer[0] and unit.GetRelatedQuestObjectives(currentInterlocutor) then
                    avatar.SelectInteractorCue(0)
                end
            else
                local answer = avatar.GetInteractorNextCues()
                if answer[0] and device.GetRelatedQuestObjectives(currentInterlocutor) then
                    avatar.SelectInteractorCue(0)
                end
            end
        end
        local unitQuestsTables = object.GetInteractorQuests(currentInterlocutor)
        if not IsEmpty(unitQuestsTables) then
            if not IsEmpty(unitQuestsTables.readyToAccept) then
                returnCurrentQuests(unitQuestsTables)
                unitQuestsTables = object.GetInteractorQuests(currentInterlocutor)
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
                    for _, id in pairs(currentAdditionalQuestsTable) do
                        local qName = fromWScore(common.ExtractWStringFromValuedText(avatar.GetQuestInfo(id).name))
                        if IsInList(qName, QuestsLocales) then
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
        if not avatar.IsTalking() then
            avatar.StopInteract()
            --LogInfo("EVENT_INTERACTION_STARTED, Stop...Start Interact becouse not talking")
            avatar.StartInteract(idInteractor)
        end
    end
end

function returnCurrentQuests(uQT)
    for i, id in pairs(uQT.readyToAccept) do
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

function On_EVENT_QUEST_RECEIVED(params)
    local qid = params.questId
    local qInf = avatar.GetQuestInfo(qid)
    local curInterl = avatar.GetInteractorInfo()
    if qInf.canBeSkipped then
        if avatar.GetSkipQuestCost(qid) <= avatar.GetDestinyPoints().total then
            avatar.SkipQuest(qid)
        else
            --LogInfo("RegisterEventHandler EVENT_AVATAR_DESTINY_POINTS_CHANGED")
            common.RegisterEventHandler(On_EVENT_AVATAR_DESTINY_POINTS_CHANGED, "EVENT_AVATAR_DESTINY_POINTS_CHANGED")
        end
        --Отладка
    else
        --LogInfo(fromWScore(cartographer.GetCurrentZoneInfo().zoneName), " : ", fromWScore(common.ExtractWStringFromValuedText(qInf.name)))
        --Отладка
    end
    if curInterl then
        On_EVENT_INTERACTION_STARTED()
    end
end

function On_EVENT_AVATAR_DESTINY_POINTS_CHANGED (params)
    local count
    repeat
        count = SkipAllQuest()
    until (count > avatar.GetDestinyPoints().total) or (count == 0)
    if count == 0 then
        --LogInfo("UnRegisterEventHandler EVENT_AVATAR_DESTINY_POINTS_CHANGED")
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
        if avatar.GetQuestInfo(id).canBeSkipped then
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

function IsInList (questName, listName)
    if listName[localization][questName] then
        return listName[localization][questName]
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

-- stateMainForm:GetChildChecked("NpcTalk", false):GetChildChecked("QuestPanel", false):GetChildChecked("ButtonsPanel", true):AddChild(mainForm)
common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
if avatar.IsExist() then
    Init()
end
