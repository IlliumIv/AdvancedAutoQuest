Global('ChatLog', {
    capacity = 100,
    separator = ' ',
    format = userMods.ToWString('<html color="0xffccc5b7" fontsize="14"><r name="time"/> [<r name="addonName"/>]: <r name="text"/></html>'),
    timeFormat = userMods.ToWString('<html><r name="h"/>:<r name="m"/>:<r name="s"/>.<r name="ms"/></html>'),
    addonName = userMods.ToWString(common.GetAddonName()),
})
--------------------------------------------------------------------------------
if not table.normalize then
    function table.normalize(t)
        if t[0] ~= nil then
            table.insert(t, 0, nil)
        end
        return t
    end
end

local function argtostring(arg, tostring)
    local result, val, flat = {}
    for i = 1, arg.n do
        val, flat = arg[i], arg.n > i
        if type(val) ~= 'string' then
            val = tostring(val, flat)
        end
        result[#result + 1] = val
    end
    return result
end

local function advtostring(v)
    local vtype = type(v)
    if vtype == 'string' then
        return v
    elseif vtype == 'userdata' then
        return string.format('%s: %s', common.GetApiType(v), string.match(tostring(v), '(0x%x+)'))
    else
        return tostring(v)
    end
end
--------------------------------------------------------------------------------
function ChatLog:CheckContainer()
    if self.wtContainer and self.wtContainer:IsValid() and self.wtContainer:IsVisibleEx() then
        return true
    end
    local wtChatLog = stateMainForm:GetChildUnchecked('ChatLog', false)
    local wtArea = wtChatLog and wtChatLog:GetChildUnchecked('Area', false )
    if wtArea then
        for _, wtPanel in ipairs(table.normalize(wtArea:GetNamedChildren())) do
            self.wtContainer = wtPanel:IsVisibleEx() and wtPanel:GetChildUnchecked('Container', false)
            if self.wtContainer and self.wtContainer:IsVisibleEx() then
                return true
            end
        end
    end
    return false
end

function ChatLog:PushValuedText(valuedText)
    if self:CheckContainer() then
        self.wtContainer:PushFrontValuedText(valuedText)
        for i = 1, (self.wtContainer:GetElementCount() - self.capacity), 1 do
            self.wtContainer:PopBack()
        end
    end
end

function ChatLog:Push(...)
    local tostring = rawget(_G, 'advtostring') or advtostring
    local text = table.concat(argtostring({n = select('#', ...), ...}, tostring), self.separator)

    text = string.gsub(text, '%c', {['\t'] = '  ', ['\n'] = '<br/>'})
    text = string.gsub(text, '#(%x%x%x%x%x%x)', '</html><html color="0xff%1">')
    text = string.gsub(text, '#default', '</html><html color="0xffccc5b7">')

    local time = common.GetLocalDateTime()
    local valuedText = common.CreateValuedText()
    common.SetTextValues(valuedText, {
        format = self.format,
        time = {
            format = self.timeFormat,
            h = common.FormatNumber(time.h, '2'),
            m = common.FormatNumber(time.min, '2'),
            s = common.FormatNumber(time.s, '2'),
            ms = common.FormatNumber(time.ms, '3')
        },
        addonName = self.addonName,
        text = userMods.ToWString('<html><html color="0xffccc5b7">'..text..'</html></html>')
    })
    self:PushValuedText(valuedText)
end

setmetatable(ChatLog, {__call = ChatLog.Push})
--------------------------------------------------------------------------------
function chat(...) return ChatLog:Push(...) end
--------------------------------------------------------------------------------
