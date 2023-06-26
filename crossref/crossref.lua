---Support cross-references.
---
---@module crossref
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local crossref = {
    -- Should the reference names be capitalised?
    capitalise = false,
    -- The shift in level names.
    shift_level = {
        -- The default shift in Header level
        -- is based on the top-level division.
        Header = ({
            ['top-level-part'] = 0,
            ['top-level-chapter'] = 1,
            ['top-level-section'] = 2,
            ['top-level-default'] = 0
        })[PANDOC_WRITER_OPTIONS.top_level_division]
    },

    -- List of default formats
    format = {
        CodeBlock = {{'listing', 'listings'}},
        Figure = {
            name = {'figure', 'figures'}
        },
        Header = {
            [1] = {
                name = {'part', 'parts'}
            },
            [2] = {
                name = {'chapter', 'chapters'}
            },
            [3] = {
                name = {'section', 'sections'}
            },
            [4] = {
                name = {'subsection', 'subsections'}
            },
            [5] = {
                name = {'subsubsection', 'subsubsections'}
            },
            [6] = {
                name = {'paragraph', 'paragraphs'}
            }
        },
        Table = {
            name = {'table', 'tables'}
        }
    }
}

-- Uses topdown traversal, which was added in Pandoc 2.17.
PANDOC_VERSION:must_be_at_least '2.17'

local function normalise_verbosity(verbosity)
    -- Normalise verbosity to string.
    if type(verbosity) ~= "string" then
        verbosity = pandoc.utils.stringify(verbosity)
    end
    -- Normalise verbosity to uppercase
    verbosity = pandoc.text.upper(verbosity)
    return verbosity
end

local function verbosity_to_level(verbosity)
    local v2l = {
        ['INFO'] = 3,
        ['WARNING'] = 2,
        ['ERROR'] = 1
    }
    local verbosity = normalise_verbosity(verbosity)
    if v2l[verbosity] ~= nil then
        return v2l[verbosity]
    else
        io.stderr:write('[ERROR] crossref: unknown verbosity ' .. normal_verbosity .. '\n')
    end
end

local function log(msg, verbosity)
    verbosity = normalise_verbosity(verbosity or 'INFO')
    local msg_level = verbosity_to_level(verbosity) or 3
    local log_level = verbosity_to_level(crossref.verbosity or PANDOC_STATE.verbosity) or 2
    -- Only print the message if the message level is below the log level threshold
    if msg_level <= log_level then
        io.stderr:write('[' .. verbosity .. '] crossref: ' .. msg .. '\n')
    end
end

-- Extend `t1` with the values of `t2`.
local function extend(t1, t2)
    assert(type(t1) == 'table')
    assert(type(t2) == 'table')
    for key, val in pairs(t2) do
        if type(val) == 'table' then
            if type(t1[key] or nil) == 'table' then
                t1[key] = extend(t1[key], val)
            else
                t1[key] = val
            end
        else
            t1[key] = val
        end
    end
    return t1
end

-- Resolve the cross-reference type for a reference.
local function resolve_crossref_type(identifier, tag, level)
    local identifier_col_ix = identifier:find(':')
    if identifier_col_ix ~= nil then
        return {
            type = identifier:sub(1, identifier_col_ix - 1),
            level = level
        }
    else
        return {
            type = tag,
            level = level
        }
    end
end

-- Resolve the format for a cross-reference type.
local function resolve_crossref_format(crossref_type)
    assert(type(crossref_type) == 'table')
    assert(type(crossref) == 'table')
    assert(type(crossref.format) == 'table')
    -- Initialise the format table for this cross-reference type.
    if crossref.format[crossref_type.type] == nil then
        crossref.format[crossref_type.type] = {}
    end
    -- If a level is specified & has a custom format, return it:
    if crossref_type.level ~= nil then
        local shift_level = 0
        if crossref.shift_level ~= nil and crossref.shift_level[crossref_type.type] then
            shift_level = crossref.shift_level[crossref_type.type]
            assert(type(shift_level) == "number")
        end
        local shifted_level = crossref_type.level + shift_level
        local format_for_shifted_level = crossref.format[crossref_type.type][shifted_level]
        if format_for_shifted_level ~= nil then
            return format_for_shifted_level
        end
    end
    return crossref.format[crossref_type.type]
end

local function capitalise(s)
    return pandoc.text.upper(pandoc.text.sub(s, 1, 1)) .. pandoc.text.sub(s, 2)
end

-- Resolve the name for a cross-reference type.
local function resolve_crossref_name(crossref_type, is_plural)
    -- Resolve the format for the cross-reference type.
    local crossref_format = resolve_crossref_format(crossref_type)
    assert(type(crossref_format) == 'table')
    -- Resolve the name for the cross-reference type.
    local crossref_name = nil
    if crossref_format.name ~= nil then
        if type(crossref_format.name) == 'string' then
            crossref_name = crossref_format.name
        end
        if type(crossref_format.name) == 'table' then
            if is_plural then
                crossref_name = crossref_format.name[2] or crossref_format.name[1]
            else
                crossref_name = crossref_format.name[1]
            end
        end
    else
        crossref_name = crossref_type.type
    end
    -- Capitalise the name, if required.
    if crossref.capitalise then
        crossref_name = capitalise(crossref_name)
    end
    return crossref_name
end

-- Filter that gets the cross-reference configuration from the document.
local get_crossref_configuration = {
    Meta = function(el)
        for key, value in pairs(el) do
            if key == 'crossref' then
                extend(crossref, value)
            end
        end
    end
}

-- Filter that gets the cross-reference targets from the document.
local get_crossref_targets = {
    Block = function(el)
        -- Initialise the table for cross-reference targets.
        if crossref.targets == nil then
            crossref.targets = {}
        end
        -- If the element has an identifier:
        if el.attr ~= nil and el.attr.identifier ~= nil and el.attr.identifier ~= '' then
            local crossref_type = resolve_crossref_type(el.attr.identifier, el.tag, el.level)
            assert(type(crossref.format) == 'table')
            -- Retrieve the format for this cross-reference type.
            local crossref_format = resolve_crossref_format(crossref_type)
            -- Increment the count for this cross-reference type.
            crossref_format.count = (crossref_format.count or 0) + 1
            -- Insert an entry for this cross-reference target.
            crossref.targets[el.attr.identifier] = {
                type = crossref_type,
                number = crossref_format.count
            }
        end
    end,
    -- Ensure the document is traversed in top-down depth-first order
    traverse = 'topdown'
}

-- Filter that resolve cross-references.
local resolve_crossref = {
    Cite = function(el)
        if el.citations ~= nil and #el.citations == 1 then
            local identifier = el.citations[1].id
            -- If enabled, parse an optional suffix:
            local opt_suffix = nil
            if crossref.enable_suffix then
                local identifier_dot_ix = identifier:find('.')
                if identifier_dot_ix ~= nil then
                    opt_suffix = identifier:sub(identifier_dot_ix + 1)
                    identifier = identifier:sub(1, identifier_dot_ix - 1)
                end
            end
            -- Find the target for the identifier:
            local target = crossref.targets[identifier]
            if target ~= nil then
                -- Compose the name for the cross-reference.
                local name = resolve_crossref_name(target.type, false)
                local label = name .. ' ' .. target.number
                -- Compose the anchor for the cross-reference target.
                local anchor = '#' .. identifier
                if crossref.enable_suffix and opt_suffix ~= nil then
                    anchor = anchor .. '.' .. opt_suffix
                end
                return pandoc.Link(label, anchor)
            else
                log('target for possible cross-reference @' .. identifier .. ' not found', 'WARNING')
            end
        end
    end,
    -- Ensure the document is traversed in top-down depth-first order
    traverse = 'topdown'
}

function Pandoc(doc)
    doc:walk(get_crossref_configuration)
    doc:walk(get_crossref_targets)
    return doc:walk(resolve_crossref)
end

