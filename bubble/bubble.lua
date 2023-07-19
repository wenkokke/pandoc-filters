---Support speech bubbles.
---
---@module bubble
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local bubble = {}
local logging = require 'logging'

-- Uses `pandoc.template.apply`, which was added in Pandoc 3.0.1.
PANDOC_VERSION:must_be_at_least '3.0.1'

local BUBBLE_CLASS = 'bubble'

-- The bubble templates.
local BUBBLE_TEMPLATES = {
    html = [[
        <p class="bubble${ if(options.style) } bubble-${ style }${ endif }"${ if(options) } style="${ for(options) }${ it.key }:${ it.value };${ endfor }"${ endif }>
          <span class="bubble-name">${ name }</span> ${ content }
        </p>
    ]],
    latex = [[
      \begin{bubble}${ if(options) }[${ for(options) }${ it.key }=${ it.value },${ endfor }]${ endif }{${ name }}
        ${ content }
      \end{bubble}
    ]]
}

-- The mapping from option names to the target format.
local BUBBLE_OPTIONS = {
    html = {},
    latex = {
        ['style'] = 'style',
        ['background-color'] = 'fill',
        ['border-color'] = 'draw',
        ['border-width'] = 'line width',
        ['color'] = 'text',
        ['padding'] = 'inner sep',
        ['border-radius'] = 'rounded corners',
        ['min-width'] = 'text width'
    }
}

-- Get the bubble class name.
local function get_bubble_class()
    return bubble['class'] or BUBBLE_CLASS
end

-- Get a list of the supported formats.
local function get_supported_formats()
    local supported_formats = {}
    for format, template_string in pairs(BUBBLE_TEMPLATES) do
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
    assert(BUBBLE_TEMPLATES[format] ~= nil)
    local indent, template_string = BUBBLE_TEMPLATES[format]:match('^(%s*)(.*)\n%s*$')
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
    assert(BUBBLE_OPTIONS[format] ~= nil)
    local options = pandoc.List({})
    if bubble[name] ~= nil then
        for key, value in pairs(bubble[name]) do
            if BUBBLE_OPTIONS[format][key] ~= nil then
                options:insert({
                    key = BUBBLE_OPTIONS[format][key],
                    value = pandoc.utils.stringify(value)
                })
            end
        end
    end
    if attributes ~= nil then
        for key, value in pairs(attributes) do
            if BUBBLE_OPTIONS[format][key] ~= nil then
                options:insert({
                    key = BUBBLE_OPTIONS[format][key],
                    value = value
                })
            end
        end
    end
    if classes ~= nil then
        if pandoc.List.includes(classes, 'bottom-left') then
            options:insert({
                key = 'style',
                value = 'bottom-left'
            })
        elseif pandoc.List.includes(classes, 'bottom-right') then
            options:insert({
                key = 'style',
                value = 'bottom-right'
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

-- Test whether or not a Div is a bubble.
local function is_bubble(el)
    return el ~= nil and el.attr ~= nil and el.attr.classes ~= nil and el.attr.classes:includes(get_bubble_class())
end

-- Render a single bubble.
local function render_bubbles(el)
    local format = get_target_format()
    local template = get_template(format)
    local bubbles = pandoc.Blocks({})
    for key, para in pairs(el.content or {}) do
        local para_document = pandoc.Pandoc(pandoc.Blocks({pandoc.Plain(para.content)}))
        local para_rendered = pandoc.write(para_document, FORMAT)
        local name, content = para_rendered:match('^(.*):%s*(.*)%s*$')
        logging.temp('name', name)
        if name == nil or content == nil then
            return el
        end
        local attributes = ((el.attr or {}).attributes or {})
        local classes = ((el.attr or {}).classes or {})
        local options = get_options(format, name, attributes, classes)
        local bubble_document = pandoc.template.apply(template, {
            name = name,
            content = content,
            options = options
        })
        local bubble_rendered = pandoc.layout.render(bubble_document)
        bubbles:insert(pandoc.RawBlock(format, bubble_rendered))
    end
    return pandoc.Blocks(bubbles)
end

local resolve_bubble = {
    Div = function(el)
        if is_bubble(el) then
            return render_bubbles(el)
        end
    end,
    BlockQuote = function(el)
        if bubble.blockquote then
            return render_bubbles(el)
        end
    end
}

function Pandoc(doc)
    doc:walk(get_bubble_configuration)
    return doc:walk(resolve_bubble)
end
