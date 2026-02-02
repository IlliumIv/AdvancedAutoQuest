--------------------------------------------------------------------------------
--- Configuration
--------------------------------------------------------------------------------
local debug = false
local incinerate = false

local maxLevel = 120

local workedQuests = {
    [ "KingdomOfElements" ] = false,
    [ "GuildQuest" ] = false,
    [ "Repeatable" ] = false,
    [ "Important" ] = true,
    [ "Mystery" ] = true, -- всегда должно быть true, если "Important" = true
    [ "DestinyPoints" ] = true,
}

-- таблица типов оружия по классам
-- !! Надо проверить в игре соответствие оружия классам
local weaponPriority = {
    [ "paladin" ] = "DRESS_SLOT_TWOHANDED",
    [ "warrior" ] = "DRESS_SLOT_TWOHANDED",
    [ "priest" ] = "DRESS_SLOT_TWOHANDED",
    [ "engineer" ] = "DRESS_SLOT_DUALWIELD",
    [ "stalker" ] = "DRESS_SLOT_DUALWIELD",
    [ "bard" ] = "DRESS_SLOT_DUALWIELD",
    [ "psionic" ] = "DRESS_SLOT_DUALWIELD",
    [ "druid" ] = "DRESS_SLOT_ONEHANDED",
    [ "mage" ] = "DRESS_SLOT_ONEHANDED",
    [ "necromancer" ] = "DRESS_SLOT_ONEHANDED",
    [ "demonolog" ] = "DRESS_SLOT_ONEHANDED",
}
--------------------------------------------------------------------------------
--- Locales
--------------------------------------------------------------------------------
local isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED = false

local commonQuestsTable = {["sysNames"] = sysNamesTable, }
for key, val in pairs(localizedQuestsName) do
    commonQuestsTable[key] = val
end

for _, questName in pairs(specialQuestsTable[localization]) do
    for objectName, _ in pairs(questName.objects) do
        npcExceptions[localization][objectName] = true
    end
end

--------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------
function On_EVENT_INTERACTION_STARTED()
    common.UnRegisterEventHandler(On_EVENT_INTERACTION_STARTED, "EVENT_INTERACTION_STARTED")
    local currentInterlocutor = avatar.GetInterlocutor()
    if currentInterlocutor then
        local idInteractor = avatar.GetInteractorInfo().interactorId
        if not npcExceptions[localization][fromWScore(object.GetName(idInteractor))] then
            Talk(currentInterlocutor, idInteractor)
        else
            local currentSpecialQuestsTable = {}
            local avatarQuestBook = avatar.GetQuestBook()
            for _, id in pairs(avatarQuestBook) do
                if Is_SpecialQuest(id) then
                    table.insert(currentSpecialQuestsTable, #currentSpecialQuestsTable + 1, id)
                end
            end

            if IsEmpty(currentSpecialQuestsTable) then
                Talk(currentInterlocutor, idInteractor)
            else
                for _, id in pairs(currentSpecialQuestsTable) do
                    local questActions = specialQuestsTable[localization][userMods.FromValuedText(avatar.GetQuestInfo(id).name, true)]
                    for objectName, objectAction in pairs(questActions.objects) do
                        -- LogInfo(objectName)
                        if (objectName == fromWScore(object.GetName(idInteractor))) then
                            if objectAction.type == "Talk" then
                                Talk(currentInterlocutor, idInteractor, objectAction.objectivesCues)
                            end
                        end
                    end
                end
            end
        end

        local unitQuestsTables = object.GetInteractorQuests(currentInterlocutor)

        if not IsEmpty(unitQuestsTables) then
            if not IsEmpty(unitQuestsTables.readyToAccept) then
                ReturnThisQuests(unitQuestsTables.readyToAccept)
                unitQuestsTables = object.GetInteractorQuests(currentInterlocutor)
            end

            if not IsEmpty(unitQuestsTables.readyToGive) then
                DiscardQuests()
                for _, id in pairs(unitQuestsTables.readyToGive) do
                    if Is_AllowedQuest(id) then
                        avatar.AcceptQuest(id)
                    end
                end
            end
        end
    end
    -- !! Удалить при удалении отписки на событие в начале функции
    common.RegisterEventHandler(On_EVENT_INTERACTION_STARTED, "EVENT_INTERACTION_STARTED")
end

function IsMaxLevelReached()
    local id = avatar.GetId()
    local level = unit.GetLevel(id)
    return level < maxLevel
end

function Is_AllowedQuest(questId)
    local questInfo = avatar.GetQuestInfo(questId)
    local questType = commonQuestsTable["sysNames"][questInfo.sysName]

    if debug then
        LogInfo(userMods.FromValuedText(questInfo.name, true))
        for k, v in pairs(questInfo) do
            LogInfo(k, ": ", v)
        end
    end

    if questType == ("KingdomOfElements") then return workedQuests["KingdomOfElements"] end
    if questType == ("GuildQuest") then return workedQuests["GuildQuest"] end
    if questInfo.isRepeatable then
        return workedQuests["Repeatable"]
               or commonQuestsTable[localization][userMods.FromValuedText(questInfo.name, true)]
    end

    if (workedQuests["Important"] and (not questInfo.isLowPriority)) then return true end
    if (workedQuests["Mystery"] and questInfo.isInSecretSequence) then return true end
    if (workedQuests["DestinyPoints"] and questInfo.canBeSkipped and not IsMaxLevelReached()
        and (questInfo.level > (unit.GetLevel(avatar.GetId()) - 4))) then return true end
    if commonQuestsTable[localization][userMods.FromValuedText(questInfo.name, true)] then
        if debug then LogInfo("Finded ", questInfo.sysName, " for ", questInfo.name) end
    return true end

return false end

function ReturnThisQuests(uQTreadyToAccept)
    for _, id in pairs(uQTreadyToAccept) do
        local questInfo = avatar.GetQuestInfo(id)
        if not zoneExceptions[localization][fromWScore(questInfo.zoneName)] then
            local itemsQuestsReward = avatar.GetQuestReward(id).alternativeItems
            if IsEmpty(itemsQuestsReward) then
                avatar.ReturnQuest(id, nil)
            else
                avatar.ReturnQuest(id, itemsQuestsReward[0])
            end
        end
    end
end

function ChooseYourWeapon(weaponTable)
    for _, _ in pairs(weaponTable) do
        if itemLib.GetItemInfo(value).dressSlot == weaponPriority[tostring(avatar.GetClass())] then
            return value
        end
    end
    -- вернуть id первого предмета из списка
    return weaponTable[0]
end

function On_EVENT_QUEST_RECEIVED(params)
    local qid = params.questId
    if false and avatar.GetQuestInfo(qid).canBeSkipped then
        if avatar.GetSkipQuestCost(qid) <= avatar.GetDestinyPoints().total then
            avatar.SkipQuest(qid)
        else
            if not isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED then
                isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED = true
                common.RegisterEventHandler(On_EVENT_AVATAR_DESTINY_POINTS_CHANGED, "EVENT_AVATAR_DESTINY_POINTS_CHANGED")
            end
        end
    end

    if avatar.IsTalking() then
        On_EVENT_INTERACTION_STARTED()
    end
end

function On_EVENT_AVATAR_DESTINY_POINTS_CHANGED (params)
    isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED = false
    common.UnRegisterEventHandler(On_EVENT_AVATAR_DESTINY_POINTS_CHANGED, "EVENT_AVATAR_DESTINY_POINTS_CHANGED")
    if SkipQuests() ~= (0 or null) then
        isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED = true
        common.RegisterEventHandler(On_EVENT_AVATAR_DESTINY_POINTS_CHANGED, "EVENT_AVATAR_DESTINY_POINTS_CHANGED")
    end
end

function SkipQuests()
    if true then return end
    local qTable = avatar.GetQuestBook()
    if not qTable then
        return
    else
        local needDestinyPoints = 0
        for _, id in pairs(qTable) do
            if avatar.GetQuestInfo(id).canBeSkipped then
                local currentNeedDestinyPoints = avatar.GetSkipQuestCost(id)
                if currentNeedDestinyPoints <= avatar.GetDestinyPoints().total and avatar.GetQuestProgress(id).state == 0 then
                    -- !! Хорошо было бы выполнять за очки судьбы не все подряд квесты, а по приоритету - сначала тайны мира, потом по уровню.
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
end

function DiscardQuests()
    if incinerate then
        local qTable = avatar.GetQuestBook()
        if not qTable then
            return
        end

        local FiredIt = {}
        for _, id in pairs(qTable) do
            local qinform = avatar.GetQuestInfo(id)
            if (not qinform.isInSecretSequence) and (not qinform.isRepeatable) and (qinform.level < (unit.GetLevel(avatar.GetId()) - 3)) and (avatar.GetQuestProgress(id).state ~= (1 or 2)) then
                table.insert (FiredIt, #FiredIt + 1, id)
            end
        end

        if not IsEmpty(FiredIt) then
            for _, id in pairs(FiredIt) do
                avatar.DiscardQuest(id)
            end
        end
    end
end

function Is_SpecialQuest(questId)
    if specialQuestsTable[localization][userMods.FromValuedText(avatar.GetQuestInfo(questId).name, true)] then
        return true
    end

    return false
end

function Talk(cIlr, iId, objectivesCuesTable)
    local answers = avatar.GetInteractorNextCues()
    if answers[0] then
        -- LogInfo(answers)
        if not IsEmpty(objectivesCuesTable) then
            for objectivesCuesTable_key, _ in pairs(objectivesCuesTable) do
                for cueIndex, _ in pairs(answers) do
                    -- LogInfo(fromWScore(answers[cueIndex].name))
                    if fromWScore(answers[cueIndex].name) == objectivesCuesTable[objectivesCuesTable_key] then
                        avatar.SelectInteractorCue(cueIndex)
                    end
                end
            end
        else
            if object.IsUnit(iId) then
                if unit.GetRelatedQuestObjectives(cIlr) then
                    avatar.SelectInteractorCue(0)
                    return
                end
                if IsCueTextMentionAQuest(answers[0]) then
                    avatar.SelectInteractorCue(0)
                    return
                end
            else
                if device.GetRelatedQuestObjectives(cIlr) then
                    avatar.SelectInteractorCue(#answers)
                    return
                end
                if IsCueTextMentionAQuest(answers[#answers]) then
                    avatar.SelectInteractorCue(#answers)
                    return
                end
            end
        end
    end
end

function IsCueTextMentionAQuest(cue)
    local questsIs = avatar.GetQuestBook()
    -- LogInfo(cue.name)
    -- LogInfo(cue.text)
    for _, qid in pairs(questsIs) do
        local mtch = string.match(userMods.FromValuedText(cue.text, true), userMods.FromValuedText(avatar.GetQuestInfo(qid).name, true))
        -- LogInfo(cue)
        if mtch then return mtch end
    end
end

function FindNextMysteryQuest()
    for _, secretId in pairs(avatar.GetSecrets()) do
        for _, component in pairs (avatar.GetSecretComponents(secretId)) do
            if component.opened and (not component.closed) and (component.level <= unit.GetLevel(avatar.GetId())) then
                chat('#f0c419', 'Finded available quest of stage of Mystery ', avatar.GetQuestInfo(avatar.GetSecretInfo(secretId).questId).name)
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
    common.UnRegisterEventHandler(Init, "EVENT_AVATAR_CREATED")

    DiscardQuests()

    -- local questsIs = avatar.GetQuestBook()
    -- for _, questId in pairs(questsIs) do
    --    local mtch = string.match(userMods.FromValuedText(cue.text, true), userMods.FromValuedText(avatar.GetQuestInfo(qid).name, true))
    --     LogInfo(avatar.GetQuestInfo(qid))
    --     local progress = avatar.GetQuestProgress(questId)
    --     if progress and progress.objectives then
    --         for _, objectiveId in pairs(progress.objectives) do
    --             local objectiveInfo = avatar.GetQuestObjectiveInfo(objectiveId)
    --             LogInfo(objectiveInfo)
    --         end
    --     end
    -- end

    if SkipQuests() ~= (0 or null) then
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
