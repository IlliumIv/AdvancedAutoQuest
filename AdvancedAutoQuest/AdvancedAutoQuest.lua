local isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED = false
local commonQuestsTable = {["sysNames"] = sysNamesTable, }
for key, val in pairs(localizedQuestsName) do
    commonQuestsTable[key] = val
end
-------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------
function On_EVENT_INTERACTION_STARTED()
    local currentInterlocutor = avatar.GetInterlocutor()
    if currentInterlocutor then
        local idInteractor = avatar.GetInteractorInfo().interactorId
        if not npcExceptions[localization][fromWScore(object.GetName(idInteractor))] then
            if object.IsUnit(idInteractor) then
                local answer = avatar.GetInteractorNextCues()
                if answer[0] and unit.GetRelatedQuestObjectives(currentInterlocutor) then
                    avatar.SelectInteractorCue(0)
                end
            else
                local answer = avatar.GetInteractorNextCues()
                if answer[0] and device.GetRelatedQuestObjectives(currentInterlocutor) then
                    avatar.SelectInteractorCue(#answer)
                end
            end
        end
        local unitQuestsTables = object.GetInteractorQuests(currentInterlocutor)
        if not IsEmpty(unitQuestsTables) then
            if not IsEmpty(unitQuestsTables.readyToAccept) then
                ReturnThisQuests(unitQuestsTables)
                unitQuestsTables = object.GetInteractorQuests(currentInterlocutor)
            end
            if not IsEmpty(unitQuestsTables.readyToGive) then
                local currentQuestTable = {}
                local currentAdditionalQuestsTable = {}
                for _, id in pairs(unitQuestsTables.readyToGive) do
                    local qInf = avatar.GetQuestInfo(id)
                    if ((not qInf.isLowPriority and not qInf.isRepeatable) or qInf.canBeSkipped) and (qInf.level > (unit.GetLevel(avatar.GetId()) - 4)) then
                        table.insert (currentQuestTable, #currentQuestTable + 1, id)
                    else
                        table.insert (currentAdditionalQuestsTable, #currentAdditionalQuestsTable + 1, id)
                    end
                end
                if not IsEmpty(currentAdditionalQuestsTable) then
                    for _, id in pairs(currentAdditionalQuestsTable) do
                        local qInfo = avatar.GetQuestInfo(id)
                        if ThisQuestIsInLists(qInfo) and (qInfo.level > (unit.GetLevel(avatar.GetId()) - 4)) then
                            table.insert (currentQuestTable, #currentQuestTable + 1, id)
                        end
                    end
                end
                if not IsEmpty(currentQuestTable) then
                    DiscardQuests()
                    for _, id in pairs(currentQuestTable) do
                        avatar.AcceptQuest(id)
                    end
                end
            end
        end
    end
end

function ReturnThisQuests(uQT)
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
    local curInter = avatar.GetInterlocutor()
    if qInf.canBeSkipped then
        if avatar.GetSkipQuestCost(qid) <= avatar.GetDestinyPoints().total then
            avatar.SkipQuest(qid)
            if avatar.IsTalking() then
                avatar.StopInteract()
                avatar.StartInteract(curInter)
                return
            end
        else
            if not isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED then
                isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED = true
                common.RegisterEventHandler(On_EVENT_AVATAR_DESTINY_POINTS_CHANGED, "EVENT_AVATAR_DESTINY_POINTS_CHANGED")
            end
        end
        --Отладка
    else
        LogInfo(fromWScore(common.ExtractWStringFromValuedText(qInf.name)), " : ", qInf.sysName)
        --Отладка
    end
    if avatar.IsTalking() then
        On_EVENT_INTERACTION_STARTED()
        return
    end
    if curInter then
        avatar.StopInteract()
        --Отладка
        LogInfo("EVENT_QUEST_RECEIVED, Stop...Start Interact")
        --Отладка
        avatar.StartInteract(curInter)
    end
end

function On_EVENT_AVATAR_DESTINY_POINTS_CHANGED (params)
    local count
    repeat
        count = SkipQuests()
    until (count > avatar.GetDestinyPoints().total) or (count == 0)
    if count == 0 then
        common.UnRegisterEventHandler(On_EVENT_AVATAR_DESTINY_POINTS_CHANGED, "EVENT_AVATAR_DESTINY_POINTS_CHANGED")
        isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED = false
    end
    if avatar.IsTalking() then
        On_EVENT_INTERACTION_STARTED()
    end
end

function SkipQuests()
    local qTable = avatar.GetQuestBook()
    if not qTable then
        return
    end
    local needDestinyPoints = 0
    for _, id in pairs(qTable) do
        if avatar.GetQuestInfo(id).canBeSkipped then
            local currentNeedDestinyPoints = avatar.GetSkipQuestCost(id)
            if currentNeedDestinyPoints <= avatar.GetDestinyPoints().total and avatar.GetQuestProgress(id).state == 0 then
                avatar.SkipQuest(id)
            else
                if avatar.GetQuestProgress(id).state == 0 then
                    needDestinyPoints = needDestinyPoints + currentNeedDestinyPoints
                end
            end
        end
    end
    return needDestinyPoints
end

function DiscardQuests()
    local qTable = avatar.GetQuestBook()
    if not qTable then
        return
    end
    local FiredIt = {}
    for _, id in pairs(qTable) do
        if (avatar.GetQuestInfo(id).level < (unit.GetLevel(avatar.GetId()) - 3)) and avatar.GetQuestProgress(id).state ~= 1 then
            table.insert (FiredIt, #FiredIt + 1, id)
        end
    end
    if not IsEmpty(FiredIt) then
        for _, id in pairs(FiredIt) do
            avatar.DiscardQuest(id)
        end
    end
end

function ThisQuestIsInLists(questInfo)
    local questInfoName = fromWScore(common.ExtractWStringFromValuedText(questInfo.name))
    --Отладка
    if commonQuestsTable[localization][questInfoName] and questInfo.sysName then
        LogInfo("Finded ", questInfo.sysName, " for ", questInfoName)
    end
    --Отладка
    if commonQuestsTable[localization][questInfoName] then
        return commonQuestsTable[localization][questInfoName]
    end
    if commonQuestsTable["sysNames"][questInfo.sysName] then
        return commonQuestsTable["sysNames"][questInfo.sysName]
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
    DiscardQuests()
    if SkipQuests() ~= 0 then
        isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED = true
        common.RegisterEventHandler(On_EVENT_AVATAR_DESTINY_POINTS_CHANGED, "EVENT_AVATAR_DESTINY_POINTS_CHANGED")
    end
end
--------------------------------------------------------------------------------
-- stateMainForm:GetChildChecked("NpcTalk", false):GetChildChecked("QuestPanel", false):GetChildChecked("ButtonsPanel", true):AddChild(mainForm)
common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
if avatar.IsExist() then
    Init()
end
