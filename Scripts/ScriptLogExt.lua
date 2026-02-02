local common = common
local LogInfo = common.LogInfo
local LogError = common.LogError
local LogWarning = common.LogWarning
local addonName = common.GetAddonName()
--------------------------------------------------------------------------------
local function argtostring(arg, tostring)
  local result, val, flat = {}
	for i = 1, arg.n do
		val, flat = arg[i], arg.n > i
		if type(val) ~= 'string' then
      val = tostring(val, flat)
		end
		result[#result+1] = val
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

local function divide(s, size, parts)
  if not parts then parts = {} end
  if not size then size = #s end

  if #s > size then
    table.insert(parts, string.sub(s, 1, size))
    return divide(string.sub(s, size + 1), size, parts)
  else
    table.insert(parts, s)
    return parts
  end
end

local function log(f, ...)
  local tostring = rawget(_G, 'advtostring') or advtostring
  local sarg = table.concat(argtostring({n = select('#', ...), ...}, tostring), ' ')
  local arg = divide(sarg, 45000)
  local time = common.GetLocalDateTime()

  f(addonName, string.format('[%02d:%02d:%02d.%03d]: ', time.h, time.min, time.s, time.ms), arg[1])

  for i = 2, #arg do f(addonName, arg[i]) end
end
--------------------------------------------------------------------------------
function common.LogInfo(...) log(LogInfo, ...) end
function common.LogWarning(...) log(LogWarning, ...) end
function common.LogError(...) log(LogError, ...) end
function common.LogMemory() common.LogInfo(string.format('%dKb of memory used', collectgarbage('count'))) end
--------------------------------------------------------------------------------
function print(...) common.LogInfo(...) end
function warning(...) common.LogWarning(...) end
function _G.LogInfo(...) common.LogInfo(...) end
function _G.LogWarning(...) common.LogWarning(...) end
function _G.LogError(...) common.LogError(...) end
function _G.LogMemory() common.LogMemory() end
--------------------------------------------------------------------------------
