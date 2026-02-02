--------------------------------------------------------------------------------
--- Configuration
--------------------------------------------------------------------------------
-- нужно ли логировать отладочную информацию
local debug = false
-- нужно ли сжигать лоу-лвл квесты
local incinerate = false

-- таблица типов квестов
local workedQuests = {
    [ "KingdomOfElements" ] = false,
    [ "GuildQuest" ] = false,
    [ "Repeatable" ] = false,
    -- [ "Lvling" ] = (not avatar.IsNextLevelLocked()), -- true, если прокачиваемся
    [ "Lvling" ] = false, -- true, если прокачиваемся
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

-- строим текущую таблицу квестов, собирая её из пользовательской и встроенной таблиц
local commonQuestsTable = {["sysNames"] = sysNamesTable, }
for key, val in pairs(localizedQuestsName) do
    commonQuestsTable[key] = val
end

-- строим таблицу NPC-исключений для возможности отдельной обработки их фраз
for key, val in pairs(specialQuestsTable[localization]) do
    npcExceptions[localization][val[2]] = true
end
--------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------
function On_EVENT_INTERACTION_STARTED()
    -- !! Попытка прекратить многократный вызов  функции при разговоре с NPC после каждого действия
    common.UnRegisterEventHandler(On_EVENT_INTERACTION_STARTED, "EVENT_INTERACTION_STARTED")
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
                if Is_SpecialQuest(id) then
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
                    if avatar.GetQuestProgress(id).state == QUEST_READY_TO_RETURN then break end
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
                -- сожгём неподходящие квесты, чтобы освободить квест-бук
                DiscardQuests()
                -- обходим таблицу квестов у NPC/Device в таргете, которые он может выдать
                for _, id in pairs(unitQuestsTables.readyToGive) do
                    -- если квест разрешено взять, то
                    if Is_AllowedQuest(id) then
                        avatar.AcceptQuest(id)
                    end
                end
            end
        end
    end
    -- !! Удалить при удалении отписки на событие в начале функции
    -- подписываемся на событие снова после всех действий
    common.RegisterEventHandler(On_EVENT_INTERACTION_STARTED, "EVENT_INTERACTION_STARTED")
end

-- Разрешено ли брать квест (questId)
function Is_AllowedQuest(Is_AllowedQuestId)
    -- объявим таблицу информации о квесте
    local is_AllowedQuestInfo = avatar.GetQuestInfo(Is_AllowedQuestId)
    -- объявим тип квеста из списка аддона
    local questType = commonQuestsTable["sysNames"][is_AllowedQuestInfo.sysName]

    -- если тип квеста - Царство стихий, Гильдейский или Повторяемый, то
    if questType == ("KingdomOfElements") then return workedQuests["KingdomOfElements"] end
    if questType == ("GuildQuest") then return workedQuests["GuildQuest"] end
    if questType == ("Repeatable") then return workedQuests["Repeatable"] end

    -- если игрок разрешил брать все важные и квест НЕ низкоприоритетный (в API нет понятия "Важный", есть понятие "Не важный")
    if (workedQuests["Important"] and (not is_AllowedQuestInfo.isLowPriority)) then return true end

    -- если игрок разрешил брать тайны мира и квест принадлежит к цепочке на тайну мира, то
    if (workedQuests["Mystery"] and is_AllowedQuestInfo.isInSecretSequence) then return true end

    -- если игрок разрешил брать задания за очки судьбы и квест сдаётся за очки судьбы и персонаж прокачивается и (уровень квеста выше, чем уровень персонажа - 4), то
    if (workedQuests["DestinyPoints"] and workedQuests["Lvling"]
        and (is_AllowedQuestInfo.level > (unit.GetLevel(avatar.GetId()) - 4))) then return true end

    -- если имя квеста есть в юзер.таблице квестов как ключ со значением true
    if commonQuestsTable[localization][fromWScore(common.ExtractWStringFromValuedText(is_AllowedQuestInfo.name))] then
        if debug then ChatLog("Finded ", is_AllowedQuestInfo.sysName, " for ", is_AllowedQuestInfo.name) end
    return true end

return false end

-- Сдать эти квесты (Таблица готовых к завершению квестов object.GetInteractorQuests(avatar.GetInterlocutor()).readyToAccept)
function ReturnThisQuests(uQTreadyToAccept)
    -- обходим таблицу квестов у NPC/Device в таргете, которые он может принять
    for i, id in pairs(uQTreadyToAccept) do
        local returnThisQuestsInfo = avatar.GetQuestInfo(id)
        -- если квест - не из Царства Стихий, то
        if commonQuestsTable["sysNames"][returnThisQuestsInfo.sysName] ~= "KingdomOfElements" then
            -- объявим таблицу наградных предметов
            local itemsQuestsReward = avatar.GetQuestReward(id).alternativeItems
            -- если таблица наградных предметов пуста, то
            if IsEmpty(itemsQuestsReward) then
                avatar.ReturnQuest(id, nil)
            else
                -- сдать квест, выбрав первый предмет из списка наград
                -- !! Проверить, что таблица наградных предметов содержит нулевой индекс
                avatar.ReturnQuest(id, itemsQuestsReward[0])
            end
        end
    end
end

-- Выбрать оружие (avatar.GetQuestReward(id).alternativeItems)
function ChooseYourWeapon(weaponTable)
    -- обходим таблицу доступных к выбору оружий
    for key2, value2 in pairs(weaponTable) do
        -- если слот предмета совпадает с приоритетным для класса, то
        if itemLib.GetItemInfo(value).dressSlot == weaponPriority[tostring(avatar.GetClass())] then
            -- вернуть id предмета
            return value
        end
    end
    -- вернуть id первого предмета из списка
    return weaponTable[0]
end

-- Аватар получил квест
function On_EVENT_QUEST_RECEIVED(params)
    -- если аватар разговаривает, то
    if avatar.IsTalking() then
        On_EVENT_INTERACTION_STARTED()
    end
end

-- Сжечь лоу-лвл квесты
function DiscardQuests()
    -- если игрок указал сжигать лоу-лвл квесты, то
    if incinerate then
        -- объявим таблицу имеющихся у аватара квестов
        local qTable = avatar.GetQuestBook()
        -- если таблица пуста, то
        if not qTable then
            return
        end
        -- объявим таблицу квестов, которые надо сжечь
        local FiredIt = {}
        -- обходим таблицу имеющихся у аватара квестов
        for _, id in pairs(qTable) do
            -- объявим таблицу с информацией о квесте
            local qinform = avatar.GetQuestInfo(id)
            -- если квест не в цепочке тайн мира и не повторяемый и уровень квеста ниже уровня автара на 3 уровня и прогресс квеста не (enum QUEST_READY_TO_RETURN или QUEST_COMPLETED), то
            if (not qinform.isInSecretSequence) and (not qinform.isRepeatable) and (qinform.level < (unit.GetLevel(avatar.GetId()) - 3)) and (avatar.GetQuestProgress(id).state ~= (1 or 2)) then
                -- добавим квест в таблицу квестов, которые надо сжечь
                table.insert (FiredIt, #FiredIt + 1, id)
            end
        end
        -- если таблица квестов, которые нужно сжечь, не пуста, то
        if not IsEmpty(FiredIt) then
            -- обходим таблицу квестов, которые нужно сжечь
            for _, id in pairs(FiredIt) do
                -- сжигаем квест
                avatar.DiscardQuest(id)
            end
        end
    end
end

-- Проверка, специальный ли квест
function Is_SpecialQuest(questId)
    -- если sysName есть в таблице специальных квестов, то
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

-- Найти следующий квест тайны мира
function FindNextMysteryQuest()
    -- обходим таблицу тайн мира
    for _, secretId in pairs(avatar.GetSecrets()) do
        -- обходим таблицу этапов тайны мира
        for i, component in pairs (avatar.GetSecretComponents(secretId)) do
            -- если этап открыт и не закрыт и уровень этапа равен или ниже уровня аватара, то
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
    -- сжигаем лоу-лвл квесты
    DiscardQuests()
end
--------------------------------------------------------------------------------
-- stateMainForm:GetChildChecked("NpcTalk", false):GetChildChecked("QuestPanel", false):GetChildChecked("ButtonsPanel", true):AddChild(mainForm)
common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
if avatar.IsExist() then
    Init()
end
