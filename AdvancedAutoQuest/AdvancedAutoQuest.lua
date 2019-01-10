local isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED = false
local commonQuestsTable = {["sysNames"] = sysNamesTable, }
for key, val in pairs(localizedQuestsName) do
    commonQuestsTable[key] = val
end
local workedQuests = {
    [ "KingdomOfElements" ] = true,
    [ "GuildQuest" ] = true,
    [ "Repeatable" ] = true,
}
-------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------
function On_EVENT_INTERACTION_STARTED()
    local currentInterlocutor = avatar.GetInterlocutor()
    if currentInterlocutor then
        local idInteractor = avatar.GetInteractorInfo().interactorId
        if not npcExceptions[localization][fromWScore(object.GetName(idInteractor))] then
            Talk(currentInterlocutor, idInteractor)
            --        else
            --            local currentSpecialQuestsTable = {}
            --            local currentQuestTable = avatar.GetQuestBook()
            --            for _, id in pairs(currentQuestTable) do
            --                local qInfo = avatar.GetQuestInfo(id)
            --                if ThisQuestIsSpecial(qInfo) then
            --                    table.insert (currentSpecialQuestsTable, #currentSpecialQuestsTable + 1, id)
            --                end
            --            end
            --            if currentSpecialQuestsTable[0] then
            --                Talk(currentInterlocutor, idInteractor)
            --            else
            --                for _, id in pairs(currentSpecialQuestsTable) do
            --                    if (specialQuestsTable[questInfo.sysName][2] == fromWScore(object.GetName(idInteractor))) then
            --                        if specialQuestsTable[questInfo.sysName][1] == "Talk" then
            --                            if object.IsUnit(idInteractor) then
            --                                local answers = avatar.GetInteractorNextCues()
            --                                if answers[0] and unit.GetRelatedQuestObjectives(currentInterlocutor) then
            --                                    avatar.SelectInteractorCue(0)
            --                                end
            --                            else
            --                                local answers = avatar.GetInteractorNextCues()
            --                                if answers[0] and device.GetRelatedQuestObjectives(currentInterlocutor) then
            --                                    avatar.SelectInteractorCue(#answers)
            --                                end
            --                            end
            --                        end
            --                    end
            --                end
            ---                local qInfo = avatar.GetQuestInfo(currentSpecialQuestsTable)
            --            end
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
                --if itemLib.GetItemInfo(value).isWeapon then
                --    avatar.ReturnQuest(id, ChooseYourWeapon(itemsQuestsReward))
                --else
                avatar.ReturnQuest(id, value)
                --end
                break
            end
        end
    end
end

function ChooseYourWeapon (weaponTable)
    local dualwieldWeapons
    local weaponTable = {
        DRESS_SLOT_TWOHANDED
    }
    local twohandedWeapons
    for key, value in pairs(weaponTable) do
        if itemLib.GetItemInfo(value).dressSlot == DRESS_SLOT_TWOHANDED then
            table.insert (twohandedWeapons, #twohandedWeapons + 1, value)
        else
            if itemLib.GetItemInfo(value).dressSlot == DRESS_SLOT_DUALWIELD then
            end
        end
    end
end

function On_EVENT_QUEST_RECEIVED(params)
    local qid = params.questId
    local qInf = avatar.GetQuestInfo(qid)
    --Отладка
    if not ThisQuestIsInLists(qInf) then
        LogInfo(fromWScore(common.ExtractWStringFromValuedText(qInf.name)), " : ", qInf.sysName, " : ", qInf.plotLine, " : ", qInf.canBeSkipped, " : ", qInf.isInSecretSequence)
    end
    --Отладка
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
        local qinform = avatar.GetQuestInfo(id)
        if workedQuests[commonQuestsTable["sysNames"][qinform.sysName]] then
            if (qinform.level < (unit.GetLevel(avatar.GetId()) - 3)) and avatar.GetQuestProgress(id).state ~= 1 and not workedQuests[commonQuestsTable["sysNames"][qinform.sysName][2]] then
                table.insert (FiredIt, #FiredIt + 1, id)
            end
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
    if commonQuestsTable["sysNames"][questInfo.sysName] then
        if commonQuestsTable["sysNames"][questInfo.sysName][1] then
            if workedQuests[commonQuestsTable["sysNames"][questInfo.sysName][2]] then
                return true
            end
        end
    end
    if commonQuestsTable[localization][questInfoName] then
        --Отладка
        LogInfo("Finded ", questInfo.sysName, " for ", questInfoName)
        --Отладка
        return commonQuestsTable[localization][questInfoName]
    end
    return false
end

function ThisQuestIsSpecial(questInfo)
    if specialQuestsTable[questInfo.sysName] then
        return true
    end
    return false
end

function Talk (cIlr, iId)
    if object.IsUnit(iId) then
        local answer = avatar.GetInteractorNextCues()
        if answer[0] and unit.GetRelatedQuestObjectives(cIlr) then
            avatar.SelectInteractorCue(0)
        end
    else
        local answer = avatar.GetInteractorNextCues()
        if answer[0] and device.GetRelatedQuestObjectives(cIlr) then
            avatar.SelectInteractorCue(#answer)
        end
    end
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
