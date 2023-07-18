---Support speech bubbles.
---
---@module bubble
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local bubble = {}

-- Uses `pandoc.template.apply`, which was added in Pandoc 3.0.1.
PANDOC_VERSION:must_be_at_least '3.0.1'

-- The bubble templates.
local bubble_templates = {
    latex = [[
      \begin{bubble}${ if(options) }[${ for(options) }${ it.key }=${ it.value },${ endfor }]${ endif }{${ name }}
        ${ content }
      \end{bubble}
    ]]
}

-- The option names.
local bubble_options = {
    latex = {
        ['background-color'] = 'fill',
        ['border-color'] = 'draw',
        ['border-width'] = 'line width',
        ['text-color'] = 'text',
        ['padding'] = 'inner sep',
        ['border-radius'] = 'rounded corners',
        ['min-width'] = 'text width'
    }
}

-- Get a list of the supported formats.
local function get_supported_formats()
    local supported_formats = {}
    for format, template_string in pairs(bubble_templates) do
        supported_formats:insert(format)
    end
    return supported_formats
end

-- Get the target format.
local function get_target_format()
    if FORMAT:match('latex') then
        return 'latex'
    elseif FORMAT:match('html') then
        return 'html'
    else
        local supported_formats = get_supported_formats():concat(', ')
        error('Unsupported format ' .. FORMAT .. ', expected one of ' .. supported_formats .. '\n')
    end
end

-- Get the target template.
local function get_template(format)
    assert(bubble_templates[format] ~= nil)
    local indent, template_string = bubble_templates[format]:match('^(%s*)(.*)\n%s*$')
    local template_lines = nil
    for template_line in string.gmatch(template_string, "([^\n]+)") do
        if template_lines == nil then
            template_lines = template_line
        else
            template_lines = template_lines .. template_line:sub(indent:len() + 1)
        end
        template_lines = template_lines .. '\n'
    end
    return pandoc.template.compile(template_lines)
end

-- Get the target options.
local function get_options(format, name, attributes, classes)
    assert(bubble_options[format] ~= nil)
    local options = pandoc.List({})
    if bubble[name] ~= nil then
        for key, value in pairs(bubble[name]) do
            if bubble_options[format][key] ~= nil then
                options:insert({
                    key = bubble_options[format][key],
                    value = pandoc.utils.stringify(value)
                })
            end
        end
    end
    if attributes ~= nil then
        for key, value in pairs(attributes) do
            if bubble_options[format][key] ~= nil then
                options:insert({
                    key = bubble_options[format][key],
                    value = value
                })
            end
        end
    end
    if classes ~= nil then
        if classes:includes('flip') then
            options:insert({
                key = 'flip',
                value = 'true'
            })
        end
    end
    return options
end

--- Filter that gets the bubble configuration from the document.
local get_bubble_configuration = {
    Meta = function(el)
        for key, value in pairs(el) do
            if key == 'bubble' then
                bubble = value
            end
        end
    end
}

local resolve_bubble = {
    Div = function(el)
        if el.attr ~= nil and el.attr.classes ~= nil and el.attr.classes:includes('bubble') then
            local name, content = pandoc.write(pandoc.Pandoc(el), FORMAT, PANDOC_WRITER_OPTIONS):match(
                '^(.*):%s*(.*)%s*$')
            local format = get_target_format()
            local template = get_template(format)
            local options = get_options(format, name, el.attr.attributes, el.attr.classes)
            local document = pandoc.template.apply(template, {
                name = name,
                content = content,
                options = options
            })
            local rendered = pandoc.layout.render(document)
            return pandoc.RawBlock(format, rendered)
        end
    end
}

function Pandoc(doc)
    doc:walk(get_bubble_configuration)
    return doc:walk(resolve_bubble)
end
