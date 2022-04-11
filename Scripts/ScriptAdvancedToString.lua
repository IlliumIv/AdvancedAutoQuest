--------------------------------------------------------------------------------
local tostrlib = {}
local done = {}
local stack = {}
local depth = 0
local tostring = tostring
local apitype = common.GetApiType
local FromWs = userMods.FromWString
local s_format = string.format
local s_rep = string.rep
local s_sub = string.sub
local t_insert = table.insert
local t_remove = table.remove
local t_concat = table.concat
local t_sort = table.sort
local t_getn = table.getn
local m_floor = math.floor
--------------------------------------------------------------------------------
local function comp( tab )
    local v1, v2, tv1, tv2, tk1, tk2

    return function( k1, k2 )
        v1, v2 = tab[ k1 ], tab[ k2 ]
        tv1, tv2 = apitype( v1 ), apitype( v2 )
        tk1, tk2 = apitype( k1 ), apitype( k2 )
        if tv1 ~= tv2 then return tv1 < tv2 end
        if tk1 ~= tk2 then return tk1 < tk2 end

        if tk1 == "number" or tk1 == "string" then
            return k1 < k2
        else
            return tostring( k1 ) < tostring( k2 )
        end
    end
end
--------------------------------------------------------------------------------
local function sortpairs( tab )
    local list = {}
    for k, _ in pairs( tab ) do t_insert( list, k ) end

    t_sort( list, comp( tab ) )

    local first = list[ 1 ]
    local keys = {}

    for i, k in pairs( list ) do keys[ k ] = list[ i + 1 ] end

    return function( tab, key )
        key = key == nil and first or keys[ key ]
        return key, key and tab[ key ]
        end, tab, nil
    end
    --------------------------------------------------------------------------------
    function advtostring( val, flat, brief )
        if val ~= nil then
            flat = flat ~= false
            local method = tostrlib[ apitype( val ) ] or tostrlib[ type( val ) ]
            return method( val, flat, brief )
        end
        return tostring( val )
    end
    --------------------------------------------------------------------------------
    local advtostring = advtostring
    --------------------------------------------------------------------------------
    tostrlib[ "table" ] = function( val, flat, brief )
        if brief and brief <= depth then return tostring( val ) end

        local out = {}
        local nosub, count = true, 0

        for k, v in pairs( val ) do
            count = count + 1

            if ( type( v ) == "table" and next( v ) ~= nil and ( not brief or brief > ( depth + 1 ) ) and stack[ v ] == nil ) or count > 8 then
                nosub = false
                break
            end
        end

        if not done[ val ] then done[ val ] = "self" end
        if not stack[ val ] then stack[ val ] = done[ val ] end

        depth = depth + 1
        local prefix = ( flat or nosub ) and " " or ( "\n" .. s_rep( "\t", depth ) )
        local key, t

        for k, v in sortpairs( val ) do
            t = type( k )
            key = s_format( t == "string" and ((string.find(k, ' ')) and "[ '%s' ] = " or "%s = ") or "[ %s ] = ", t == "string" and k or advtostring( k, true, 0 ) )
            --key = s_format( t == "string" and "%s = " or "[ %s ] = ", t == "string" and k or advtostring( k, true, 0 ) )

            if done[ v ] == nil then
                if type( v ) == "table" then
                    done[ v ] = s_format( t == "string" and "%s.%s" or "%s[ %s ]", done[ val ], tostring( k ) )
                end
            end

            if stack[ v ] == nil then
                t_insert( out, s_format( "%s%s%s", prefix, key, advtostring( v, flat, brief ) ) )
            else
                t_insert( out, s_format( "%s%s%s", prefix, key, stack[ v ] ) )
            end

            t_insert( out, "," )
        end

        depth = depth - 1
        prefix = ( flat or nosub ) and " " or ( "\n" .. s_rep( "\t", depth ) )

        stack[ val ] = nil
        if depth == 0 then done = {} end

        if t_getn( out ) == 0 then
            t_insert( out, "{}" )
        else
            t_remove( out )
            t_insert( out, 1, "{" )
            t_insert( out, prefix .. "}" )
        end

        return t_concat( out )
    end
    --------------------------------------------------------------------------------
    tostrlib[ "number" ] = function( val )
        return tostring( m_floor( val * 1000 + 0.5 ) / 1000 )
    end
    --------------------------------------------------------------------------------
    tostrlib[ "string" ] = function( val )
        return s_format( "\"%s\"", val )
    end
    --------------------------------------------------------------------------------
    tostrlib[ "WString" ] = function( val )
        return s_format( "WString: [[%s]]", FromWs( val ) )
    end
    --------------------------------------------------------------------------------
    local function GetFullName( widget )
        local stack = {}

        repeat
            t_insert( stack, 1, widget:GetName() )
            t_insert( stack, 1, "." )
            widget = widget:GetParent()
        until widget == nil

        t_remove( stack, 1 )
        return t_concat( stack )
    end
    --------------------------------------------------------------------------------
    local function widgettostring( widget )
        local apitype = apitype( widget )
        return s_format( "%s: %s [[%s]]: \"%s\"", apitype, s_sub( tostring( widget ), - 8 ), widget:__towatch(), GetFullName( widget ) )
    end
    --------------------------------------------------------------------------------
    tostrlib[ "FormSafe" ] = widgettostring
    tostrlib[ "PanelSafe" ] = widgettostring
    tostrlib[ "ButtonSafe" ] = widgettostring
    tostrlib[ "TextViewSafe" ] = widgettostring
    tostrlib[ "ScrollableContainerSafe" ] = widgettostring
    --------------------------------------------------------------------------------
    tostrlib[ "ValuedObjectLua" ] = function( val )
        return s_format( "ValuedObjectLua: [[%s]]", FromWs( val:GetText() ) )
    end
    --------------------------------------------------------------------------------
    local a_GetCurrencyInfo = avatar.GetCurrencyInfo
    tostrlib[ "CurrencyId" ] = function( val )
        local currency = a_GetCurrencyInfo( val )
        return s_format( "CurrencyId: [[%s]] %d", FromWs( currency.name ), currency.value )
    end
    --------------------------------------------------------------------------------
    local c_GetTexturePath = common.GetTexturePath
    tostrlib[ "TextureId" ] = function( val )
        return s_format( "TextureId: \"%s\"", c_GetTexturePath( val ) )
    end
    --------------------------------------------------------------------------------
    local a_GetSpellInfo = spellLib.GetDescription
    tostrlib[ "SpellId" ] = function( val )
        local _t = a_GetSpellInfo( val )
        return s_format( "SpellId: \"%s\"", FromWs( _t and _t.name or 'nil' ) )
    end
    --------------------------------------------------------------------------------
    local a_GetActionGroupInfo = avatar.GetActionGroupInfo
    tostrlib[ "ActionGroupId" ] = function( val )
        return s_format( "ActionGroupId: [[%s]]", FromWs( a_GetActionGroupInfo( val ).name ) )
    end
    --------------------------------------------------------------------------------
    local c_ExtractWStringFromValuedText = common.ExtractWStringFromValuedText
    tostrlib[ "ValuedText" ] = function( val )
        return s_format( "ValuedText: [[%s]]", FromWs( c_ExtractWStringFromValuedText( val ) ) )
    end
    --------------------------------------------------------------------------------
    tostrlib[ "BuffId" ] = function( val )
        return s_format( "BuffId: %s [[%s]]", s_sub( tostring( val ), - 8 ), val:__towatch() )
    end
    --------------------------------------------------------------------------------
    tostrlib[ "function" ] = tostring
    tostrlib[ "boolean" ] = tostring
    --------------------------------------------------------------------------------
    tostrlib[ "userdata" ] = function( val )
        return s_format( "%s: %s", apitype( val ), s_sub( tostring( val ), - 8 ) )
    end
    --------------------------------------------------------------------------------
