local isRegistred_EVENT_AVATAR_DESTINY_POINTS_CHANGED = false
local commonQuestsTable = {["sysNames"] = sysNamesTable, }
for key, val in pairs(localizedQuestsName) do
    commonQuestsTable[key] = val
end
local workedQuests = {
    [ "KingdomOfElements" ] = true,
    [ "GuildQuest" ] = true,
    [ "Repeatable" ] = true,
    [ "Lvling" ] = true,
}
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
-------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------
function On_EVENT_INTERACTION_STARTED()
    local currentInterlocutor = avatar.GetInterlocutor()
    -- если Интерлокатор существует, то
    if currentInterlocutor then
        local idInteractor = avatar.GetInteractorInfo().interactorId
        -- если NPC/Device в таргете НЕ из списка исключений, то
        if not npcExceptions[localization][fromWScore(object.GetName(idInteractor))] then
            Talk(currentInterlocutor, idInteractor)
        else
            -- объявим таблицу текущих специальных квестов (текущие - связанные с NPC/Device в таргете)
            local currentSpecialQuestsTable = {}
            local avatarQuestBook = avatar.GetQuestBook()
            -- обходим таблицу квестов из квест-бука
            for _, id in pairs(avatarQuestBook) do
                -- если квест в списке специальных, то
                if ThisQuestIsSpecial(id) then
                    -- вносим id квеста в таблицу текущих специальных квестов
                    table.insert (currentSpecialQuestsTable, #currentSpecialQuestsTable + 1, id)
                end
            end
            -- если таблица текущих специальных квестов пуста, то
            if IsEmpty(currentSpecialQuestsTable) then
                Talk(currentInterlocutor, idInteractor)
            else
                -- обходим таблицу специальных квестов из квест-бука
                for _, id in pairs(currentSpecialQuestsTable) do
                    -- объявим переменную, чтобы не вычислять три раза
                    local questName = specialQuestsTable[localization][avatar.GetQuestInfo(id).sysName]
                    -- если тип специального квеста - Talk, то
                    if questName[1] == "Talk" then
                        -- если NPC/Device в таргете - нужный для квеста с id, то
                        if (questName[2] == fromWScore(object.GetName(idInteractor))) then
                            Talk(currentInterlocutor, idInteractor, questName["objectivesCues"])
                        end
                    end
                end
            end
        end
        -- объявим таблицу текущих квестов у NPC/Device в таргете
        local unitQuestsTables = object.GetInteractorQuests(currentInterlocutor)
        -- если таблица квестов у NPC/Device в таргете НЕ пуста, то
        if not IsEmpty(unitQuestsTables) then
            -- если таблица квестов у NPC/Device в таргете, которые он может принять, НЕ пуста, то
            if not IsEmpty(unitQuestsTables.readyToAccept) then
                -- сдаём квесты, которые можно сдать
                ReturnThisQuests(unitQuestsTables.readyToAccept)
                -- обновляем таблицу текущих квестов - вдруг появились новые
                unitQuestsTables = object.GetInteractorQuests(currentInterlocutor)
            end
            -- если таблица квестов у NPC/Device в таргете, которые он может выдать, НЕ пуста, то
            if not IsEmpty(unitQuestsTables.readyToGive) then
                -- объявим таблицу текущих квестов (текущие - те, которые мы сейчас будем брать)
                local currentQuestTable = {}
                -- объявим таблицу дополнительных текущих квестов (все, которые НЕ попали в таблицу текущих квестов)
                local currentAdditionalQuestsTable = {}
                -- обходим таблицу квестов у NPC/Device в таргете, которые он может выдать
                for _, id in pairs(unitQuestsTables.readyToGive) do
                    local qInf = avatar.GetQuestInfo(id)
                    -- если (((НЕ необязательные и НЕ повторяемые) или можно сдать за очки судьбы) и уровень квеста выше, чем уровень персонажа - 4) или открывает тайну мира, то
                    if (((not qInf.isLowPriority and not qInf.isRepeatable) or qInf.canBeSkipped) and (qInf.level > (unit.GetLevel(avatar.GetId()) - 4))) or qInf.isInSecretSequence then
                        -- вносим id квеста в таблицу текущих квестов
                        table.insert (currentQuestTable, #currentQuestTable + 1, id)
                    else
                        -- вносим id квеста в таблицу дополнительных текущих квестов
                        table.insert (currentAdditionalQuestsTable, #currentAdditionalQuestsTable + 1, id)
                    end
                end
                -- если таблица дополнительных текущих квестов НЕ пуста, то
                if not IsEmpty(currentAdditionalQuestsTable) then
                    -- обходим таблицу дополнительных текущих квестов
                    for _, id in pairs(currentAdditionalQuestsTable) do
                        local qInfo = avatar.GetQuestInfo(id)
                        -- если квест с id в списке квестов и уровень квеста выше, чем уровень персонажа - 4, то
                        if ThisQuestIsInLists(qInfo) and qInfo.level > (unit.GetLevel(avatar.GetId()) - 4) then
                            -- вносим id квеста в таблицу текущих квестов
                            table.insert (currentQuestTable, #currentQuestTable + 1, id)
                        else
                            -- если квест в списке квсетов, то
                            if commonQuestsTable["sysNames"][qInfo.sysName] then
                                -- если тип квеста - в списке рабочих типов, то
                                if workedQuests[commonQuestsTable["sysNames"][qInfo.sysName][2]] then
                                    table.insert (currentQuestTable, #currentQuestTable + 1, id)
                                end
                            end
                        end
                    end
                end
                -- если таблица текущих квестов НЕ пуста
                if not IsEmpty(currentQuestTable) then
                    -- сожгём неподходящие квесты, чтобы освободить квест-бук
                    DiscardQuests()
                    -- обходим таблицу текущих квестов
                    for _, id in pairs(currentQuestTable) do
                        avatar.AcceptQuest(id)
                    end
                end
            end
        end
    end
end

-- Сдать эти квесты (Таблица готовых к завершению квестов object.GetInteractorQuests(avatar.GetInterlocutor()).readyToAccept)
function ReturnThisQuests(uQTreadyToAccept)
    -- обходим таблицу квестов у NPC/Device в таргете, которые он может принять
    for i, id in pairs(uQTreadyToAccept) do
        -- объявим таблицу наградных предметов
        local itemsQuestsReward = avatar.GetQuestReward(id).alternativeItems
        -- если таблица наградных предметов пуста, то
        if IsEmpty(itemsQuestsReward) then
            avatar.ReturnQuest(id, nil)
        else
            -- Переписать кусок кода. Он работает, но является *** и потенциально не всегда может выбрать корректную награду.
            -- смотрим на первый в списке предмет
            for key, value in pairs(itemsQuestsReward) do
                -- если этот предмет - оружие, то
                if itemLib.GetItemInfo(value).isWeapon then
                    print(itemLib.GetItemInfo(ChooseYourWeapon(itemsQuestsReward)))
                    -- avatar.ReturnQuest(id, ChooseYourWeapon(itemsQuestsReward))
                else
                    avatar.ReturnQuest(id, value)
                end
                -- выходим из цикла, потому что остальные предметы мы проверять не будем и уже сдали квест, выбрав первый попавшийся предмет
                break
            end
        end
    end
end

-- Выбрать оружие (avatar.GetQuestReward(id).alternativeItems)
function ChooseYourWeapon(weaponTable)
    -- обходим таблицу доступных к выбору оружий
    for key, value in pairs(weaponTable) do
        -- если слот предмета совпадает с приоритетным для класса, то
        if itemLib.GetItemInfo(value).dressSlot == weaponPriority[tostring(avatar.GetClass())] then
            -- вернуть id предмета
            return value
        end
    end
    -- вернуть id первого предмета из списка
    return weaponTable[0]
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
            if curInter then
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

function ThisQuestIsSpecial(questId)
    if specialQuestsTable[localization][avatar.GetQuestInfo(questId).sysName] then
        return true
    end
    return false
end

-- Сказать (avatar.GetInterlocutor(), avatar.GetInteractorInfo().interactorId, specialQuestsTable[localization]["sysName"][objectivesCues])
function Talk(cIlr, iId, objectivesCuesTable)
    -- объявим массив ответов у NPC/Device в таргете
    local answers = avatar.GetInteractorNextCues()
    -- если существует хотя бы один, то
    if answers[0] then
        -- если передан массив специальных ответов, то
        if not IsEmpty(objectivesCuesTable) then
            -- обходим массив специальных ответов
            for objectivesCuesTable_key, cueName in pairs(objectivesCuesTable) do
                -- обходим массив ответов у NPC/Device в таргете
                for cueIndex, CueTable in pairs(answers) do
                    -- если название ответа совпадает со специальным ответом по индексу, то
                    if fromWScore(answers[cueIndex].name) == objectivesCuesTable[objectivesCuesTable_key] then
                        avatar.SelectInteractorCue(cueIndex)
                    end
                end
            end
        else
            -- если объект - NPC, то
            if object.IsUnit(iId) then
                -- если NPC связан любым квестом в квест-буке, то
                if unit.GetRelatedQuestObjectives(cIlr) then
                    avatar.SelectInteractorCue(0)
                end
            else
                -- если Device связан любым квестом в квест-буке, то
                if device.GetRelatedQuestObjectives(cIlr) then
                    avatar.SelectInteractorCue(#answers)
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
