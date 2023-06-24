---Support cross-references.
---
---@module crossref
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local logging = require './filters/wenkokke/crossref/logging'

-- Uses `pandoc.template.apply`, which was added in Pandoc 3.0.1.
PANDOC_VERSION:must_be_at_least '3.0.1'

-- List of top-level header names
local default_header_names = {
    [1] = {'part', 'parts'},
    [2] = {'chapter', 'chapters'},
    [3] = {'section', 'sections'},
    [4] = {'subsection', 'subsections'},
    [5] = {'subsubsection', 'subsubsections'},
    [6] = {'paragraph', 'paragraphs'}
}

-- List of other cross-reference target names
local default_element_names = {
    Figure = {'figure', 'figures'},
    CodeBlock = {'listing', 'listings'},
    Table = {'table', 'tables'}
}

-- Merges two tables
local function merge(...)
    local res = {}
    for idx = 1, select('#', ...) do
        local tbl = select(idx, ...)
        assert(type(tbl) == "table")
        for key, val in pairs(tbl) do
            if type(val) == "table" then
                if type(res[key] or nil) == "table" then
                    res[key] = merge(res[key], val)
                else
                    res[key] = val
                end
            else
                res[key] = val
            end
        end
    end
    return res
end

-- Generate the list of header names,
-- shifted according to the top-level division
local function shifted_header_names()
    -- Get the top-level division shift (from 'part')
    local top_level_division_shift = ({
        ['top-level-part'] = 0,
        ['top-level-chapter'] = 1,
        ['top-level-section'] = 2,
        ['top-level-default'] = 0
    })[PANDOC_WRITER_OPTIONS.top_level_division]
    -- Shift the default header names
    local shifted_header_names = {}
    for number = 1, 6 do
        local shifted_number = number + top_level_division_shift
        local header_type = 'Header' .. number
        shifted_header_names[header_type] = {
            name = default_header_names[shifted_number]
        }
    end
    return shifted_header_names
end

local function default_configuration()
    return {
        format = merge(default_element_names, shifted_header_names())
    }
end

local function get_crossref_type(identifier, tag, level)
    local identifier_col_ix = identifier:find(':')
    if identifier_col_ix ~= nil then
        return identifier:sub(1, identifier_col_ix - 1)
    else
        if level ~= nil then
            return tag .. level
        else
            return tag
        end
    end
end

function Pandoc(doc)
    -- Get configuration & identifiers
    local configuration = default_configuration()
    local crossref_number_by_type = {}
    local identifiers = pandoc.List()
    local function get_configuration(el)
        for key, value in pairs(el) do
            if key == 'crossref' then
                configuration = merge(configuration, value)
            end
        end
    end
    local function get_identifier(el)
        if el.attr ~= nil and el.attr.identifier ~= nil and el.attr.identifier ~= '' then
            local crossref_type = get_crossref_type(el.attr.identifier, el.tag, el.level)
            crossref_number_by_type[crossref_type] = (crossref_number_by_type[crossref_type] or 0) + 1
            identifiers[el.attr.identifier] = {
                crossref_type = crossref_type,
                crossref_number = crossref_number_by_type[crossref_type]
            }
        end
    end
    doc:walk({
        Meta = get_configuration,
        Block = get_identifier,
        Inline = get_identifier
    })
    -- Resolve cross-references
    local function resolve_crossref_name(crossref_type, is_plural)
        if type(configuration.format) == "table" then
            local format = configuration.format[crossref_type]
            assert(type(format) == "table")
            if type(format.name) == "string" then
                return format.name
            end
            if type(format.name) == "table" then
                if is_plural then
                    return format.name[2] or format.name[1]
                else
                    return format.name[1]
                end
            end
        end
        return crossref_type
    end
    local function resolve_crossref(el)
        if el.citations ~= nil and #el.citations == 1 then
            local identifier = el.citations[1].id
            if type(identifiers[identifier]) == "table" then
                local crossref_type = identifiers[identifier].crossref_type
                local crossref_name = resolve_crossref_name(crossref_type, false)
                local crossref_number = identifiers[identifier].crossref_number
                return pandoc.Link(crossref_name .. ' ' .. crossref_number, '#' .. identifier)
            end
        end
    end
    return doc:walk({
        Cite = resolve_crossref
    })
end
