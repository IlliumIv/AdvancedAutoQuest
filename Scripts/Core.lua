Global("localization", "eng_eu")

-- +----------------------------------+
-- |AO game Localization detection    |
-- |New conceptual detection by Ciuine|
-- |Aesthetically improved by Ramirez |
-- +----------------------------------+

local function GetGameLocalization()
    local id = options.GetOptionsByCustomType( "interface_option_localization" )[ 0 ]
    if id then
        local values = options.GetOptionInfo( id ).values
        local value = values and values[ 0 ]
        local name = value and value.name
        if name then
            return userMods.FromWString( name )
        else
            return localization
        end
    end
end
localization = GetGameLocalization()

function GTL(strTextName)
    return locales[ localization ][ strTextName ] or locales[ "eng_eu" ][ strTextName ] or strTextName
end

-- +---------------------------------------+
-- |Shortcuts for WString/String conversion|
-- +---------------------------------------+
function toWScore(arg)
    return userMods.ToWString(arg)
end

function fromWScore(arg)
    return userMods.FromWString(arg)
end

---Push-to-Chat

function PushToChat(message, size, color)
    local fsize = size or 18
    local textFormat = string.format('<header color="0x%s" fontsize="%s" outline="1" shadow="1"><rs class="class">%s</rs></header>', color, tostring(fsize), message)
    local VT = common.CreateValuedText()
    VT:SetFormat(toWS(textFormat))
    local chatContainer = stateMainForm:GetChildUnchecked("ChatLog", false):GetChildUnchecked("Area", false):GetChildUnchecked("Panel02", false):GetChildUnchecked("Container", false)
    chatContainer:PushFrontValuedText(VT)
end

function PushToChatSimple(message)
    local textFormat = string.format("<html fontsize='18'><rs class='class'>%s</rs></html>", message)
    local VT = common.CreateValuedText()
    VT:SetFormat(toWS(textFormat))
    VT:SetClassVal("class", "LogColorYellow")
    local chatContainer = stateMainForm:GetChildUnchecked("ChatLog", false):GetChildUnchecked("Area", false):GetChildUnchecked("Panel02", false):GetChildUnchecked("Container", false)
    chatContainer:PushFrontValuedText(VT)

end

---Проверка, пуст ли массив (быстрее, чем получать его размер)
function IsEmpty(t)
    if not t then
        return true
    end
    for _, i in pairs(t) do
        return false
    end
    return true
end
