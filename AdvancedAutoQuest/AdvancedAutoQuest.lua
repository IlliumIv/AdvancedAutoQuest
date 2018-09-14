--------------------------------------------------------------------------------
--- Globals
--------------------------------------------------------------------------------

Global( "CID", 0 )
Global( "BID", 0 )

--------------------------------------------------------------------------------
--- Functions
--------------------------------------------------------------------------------

function On_EVENT_INTERACTION_STARTED(params)
    local retQuestList = avatar.GetReturnableQuests()
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

    local availableQuestList = avatar.GetAvailableQuests()
    for i, id in pairs(availableQuestList) do
        local qInf = avatar.GetQuestInfo( id )
        if (not qInf.isLowPriority and not qInf.isRepeatable) or qInf.canBeSkipped then
            avatar.AcceptQuest( id )
        end
    end
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
