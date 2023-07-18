---Support speech bubbles.
---
---@module bubble
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local bubble = {}
local logging = require 'logging'
local type = pandoc.utils.type

-- Uses `pandoc.template.apply`, which was added in Pandoc 3.0.1.
PANDOC_VERSION:must_be_at_least '3.0.1'

-- The bubble templates.
local bubble_templates = {
    latex = [[
      \begin{bubble}{${ name }}
        ${ content }
      \end{bubble}
    ]]
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

function CodeBlock(el)
    if el.attr ~= nil and el.attr.classes ~= nil and el.attr.classes:includes('bubble') then
        local name, content = el.text:match('^(.*):%s*(.*)%s*$')
        local format = get_target_format()
        local template = get_template(format)
        local document = pandoc.template.apply(template, {
            name = name,
            content = content
        })
        local rendered = pandoc.layout.render(document)
        return pandoc.RawBlock(format, rendered)
    end
end
