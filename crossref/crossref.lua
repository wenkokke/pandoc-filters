---Support cross-references.
---
---@module crossref
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local crossref = {
    -- Should the reference names be capitalised?
    capitalise = false,

    -- If true, parse `@identifier.index` as a reference
    -- to `@identifier`, but typeset the reference using
    -- the Child field in the format for `@identifier`,
    -- and pass the index through unchecked.
    enable_unchecked_indexes = false,

    -- If set, shift the level of a reference before
    -- resolving its name.
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
        CodeBlock = {
            name = {'listing', 'listings'}
        },
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

local function tolevel(verbosity)
    -- Normalise verbosity to an uppercase string.
    if type(verbosity) ~= 'string' then
        verbosity = pandoc.utils.stringify(verbosity)
    end
    verbosity = pandoc.text.upper(verbosity)
    -- Return the corresponding level.
    local verbositytolevel = {
        ['INFO'] = 3,
        ['WARNING'] = 2,
        ['ERROR'] = 1
    }
    if verbositytolevel[verbosity] ~= nil then
        return verbositytolevel[verbosity]
    else
        io.stderr:write('[ERROR] crossref: unknown verbosity ' .. verbosity .. '\n')
    end
end

local function log(msg, verbosity)
    assert(type(msg) == 'string')
    assert(verbosity == 'INFO' or verbosity == 'WARNING' or verbosity == 'ERROR')
    local msg_level = tolevel(verbosity)
    local log_level = tolevel(crossref.verbosity or PANDOC_STATE.verbosity) or 2
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
            assert(type(shift_level) == 'number')
        end
        local shifted_level = crossref_type.level + shift_level
        local format_for_shifted_level = crossref.format[crossref_type.type][shifted_level]
        if format_for_shifted_level ~= nil then
            return format_for_shifted_level
        end
    end
    return crossref.format[crossref_type.type]
end

-- Capitalise the input string.
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

-- Parse an identifier to a telescope.
local function parse_identifier(identifier)
    if crossref.enable_unchecked_indexes then
        local identifier_dot_ix = identifier:find('%.')
        if identifier_dot_ix ~= nil then
            return {
                identifier = identifier:sub(1, identifier_dot_ix - 1),
                index = identifier:sub(identifier_dot_ix + 1)
            }
        end
    end
    return {
        identifier = identifier
    }
end

-- Resolve the target for an indentifier.
local function resolve_crossref_target(identifier)
    -- Handle unchecked indexes:
    if crossref.enable_unchecked_indexes and identifier.index ~= nil then
        local parent_target = crossref.targets[identifier.identifier]
        if parent_target ~= nil and parent_target.type ~= nil and parent_target.type.Child ~= nil then
            logging.temp('parent_target', parent_target)
        end
    end
    return crossref.targets[identifier.identifier]
end

local function toanchor(identifier)
    local anchor = '#'
    if type(identifier) == "table" then
        anchor = anchor .. identifier.identifier
        if identifier.index ~= nil then
            anchor = anchor .. '.' .. identifier.index
        end
    end
    if type(identifier) == "string" then
        anchor = anchor .. identifier
    end
    return anchor
end

-- Filter that resolve cross-references.
local resolve_crossref = {
    Cite = function(el)
        if el.citations ~= nil and #el.citations == 1 then
            -- Parse the identifier
            local identifier = parse_identifier(el.citations[1].id)
            -- Find the target for the identifier:
            local target = resolve_crossref_target(identifier)
            if target ~= nil then
                -- Compose the name for the cross-reference.
                local name = resolve_crossref_name(target.type, false)
                local label = name .. ' ' .. target.number
                -- Compose the anchor for the cross-reference target
                return pandoc.Link(label, toanchor(identifier))
            else
                log('target for possible cross-reference ' .. toanchor(identifier) .. ' not found', 'WARNING')
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

