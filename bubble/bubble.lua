---Support speech bubbles.
---
---@module bubble
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local bubble = {}

-- Load logging module:
local filters_directory = pandoc.path.directory(pandoc.path.directory(PANDOC_SCRIPT_FILE))
local current_directory = pandoc.system.get_working_directory()
local logging_directory = pandoc.path.make_relative(pandoc.path.join({filters_directory, 'logging'}), current_directory)
local logging_file_path = pandoc.path.join({logging_directory, 'logging'})
local logging = require(logging_file_path:gsub(pandoc.path.separator, '.'))

-- Uses `pandoc.template.apply`, which was added in Pandoc 3.0.1.
PANDOC_VERSION:must_be_at_least '3.0.1'

local BUBBLE_CLASS = 'bubble'

-- The bubble templates.
local BUBBLE_TEMPLATES = {
    html = [[
        <p class="bubble bubble-${ name } bubble-${ style } bubble-${ hash }">
          <strong class="bubble-name">${ name }:</strong> ${ content }
        </p>
    ]],
    css = [[
        .bubble-${ hash } {
            position: relative;
            padding: ${ padding };
            color: ${ color };
            background-color: ${ background-color };
            border-color: ${ border-color };
            border-style: solid;
            border-width: ${ border-width };
            -webkit-border-radius: ${ border-radius } ${ border-radius } ${ border-radius } ${ border-radius };
            -moz-border-radius: ${ border-radius } ${ border-radius } ${ border-radius } ${ border-radius };
            border-radius: ${ border-radius } ${ border-radius } ${ border-radius } ${ border-radius };
          }
          .bubble-bottom-left {
            -webkit-border-radius: ${ border-radius } ${ border-radius } ${ border-radius } 0;
            -moz-border-radius: ${ border-radius } ${ border-radius } ${ border-radius } 0;
            border-radius: ${ border-radius } ${ border-radius } ${ border-radius } 0;
          }
          .bubble-bottom-left.bubble-${ hash }:after {
            content: "";
            position: absolute;
            bottom: calc(-1em + 2 * ${ border-width } + 1px);
            left: 0px;
            border-width: 0 0 calc(1em - 2 * ${ border-width } + 1px) calc(1em - 2 * ${ border-width } + 1px);
            border-style: solid;
            border-color: transparent ${ background-color };
            display: block;
            width: 0;
          }
          .bubble-bottom-left.bubble-${ hash }:before {
            content: "";
            position: absolute;
            bottom: -1em;
            left: -${ border-width };
            border-width: 0 0 1em 1em;
            border-style: solid;
            border-color: transparent ${ border-color };
            display: block;
            width: 0;
          }
          .bubble-bottom-right {
            -webkit-border-radius: ${ border-radius } ${ border-radius } 0 ${ border-radius };
            -moz-border-radius: ${ border-radius } ${ border-radius } 0 ${ border-radius };
            border-radius: ${ border-radius } ${ border-radius } 0 ${ border-radius };
          }
          .bubble-bottom-right.bubble-${ hash }:after {
            content: "";
            position: absolute;
            bottom: calc(-1em + 2 * ${ border-width });
            right: 0px;
            border-width: calc(1em - 2 * ${ border-width }) 0 0 calc(1em - 2 * ${ border-width });
            border-style: solid;
            border-color: ${ background-color } transparent;
            display: block;
            width: 0;
          }
          .bubble-bottom-right.bubble-${ hash }:before {
            content: "";
            position: absolute;
            bottom: -1em;
            right: calc(0px - ${ border-width });
            border-width: 1em 0 0 1em;
            border-style: solid;
            border-color: ${ border-color } transparent;
            display: block;
            width: 0;
          }
    ]],
    latex = [[
      \begin{bubble}${ if(options) }[${ for(options) }${ it.key }=${ it.value },${ endfor }]${ endif }{${ name }}
        ${ content }
      \end{bubble}
    ]]
}

-- The mapping from option names to the target format.
local BUBBLE_options = {
    html_names = {
        ['style'] = 'style',
        ['background-color'] = 'background-color',
        ['border-color'] = 'border-color',
        ['border-width'] = 'border-width',
        ['color'] = 'color',
        ['padding'] = 'padding',
        ['border-radius'] = 'border-radius'
    },
    latex_names = {
        ['style'] = 'style',
        ['background-color'] = 'fill',
        ['border-color'] = 'draw',
        ['border-width'] = 'line width',
        ['color'] = 'text',
        ['padding'] = 'inner sep',
        ['border-radius'] = 'rounded corners'
    },
    defaults = {
        ['style'] = 'bottom-left',
        ['background-color'] = 'lightgray',
        ['border-color'] = 'darkgray',
        ['border-width'] = '0.125em',
        ['color'] = 'black',
        ['padding'] = '0.5em',
        ['border-radius'] = '0.5em'
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
local function get_context(format, name, attributes, classes)
    local option_names = BUBBLE_options[format .. '_names']
    assert(option_names ~= nil)
    -- Load the default options
    local options = pandoc.List({})
    for key, value in pairs(BUBBLE_options.defaults) do
        if option_names[key] ~= nil then
            options[option_names[key]] = value
        end
    end
    -- Load the options by name
    if bubble[name] ~= nil then
        for key, value in pairs(bubble[name]) do
            if option_names[key] ~= nil then
                options[option_names[key]] = pandoc.utils.stringify(value)
            end
        end
    end
    if attributes ~= nil then
        for key, value in pairs(attributes) do
            if option_names[key] ~= nil then
                options[option_names[key]] = value
            end
        end
    end
    if classes ~= nil then
        if pandoc.List.includes(classes, 'bottom-left') then
            options.style = 'bottom-left'
        elseif pandoc.List.includes(classes, 'bottom-right') then
            options.style = 'bottom-right'
        end
    end
    -- Make list of key-value pairs
    local option_list = pandoc.List({})
    for key, value in pairs(options) do
        option_list:insert({
            key = key,
            value = value
        })
    end
    -- Insert hash
    local hash_input = ''
    for key, value in pairs(options) do
        hash_input = hash_input .. key .. '=' .. value .. ','
    end
    -- Insert list and hash
    options.hash = pandoc.utils.sha1(hash_input)
    options.options = option_list
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

-- Global table tracking bubble styles
local bubble_styles = {}

-- Render a single bubble.
local function render_bubbles(el)
    local format = get_target_format()
    local bubbles = pandoc.Blocks({})
    for key, para in pairs(el.content or {}) do
        local para_rendered = pandoc.write(pandoc.Pandoc(pandoc.Blocks({pandoc.Plain(para.content)})), FORMAT)
        local name, content = para_rendered:match('^(.*):%s*(.*)%s*$')
        if name == nil or content == nil then
            return el
        end
        -- Create context
        local attributes = ((el.attr or {}).attributes or {})
        local classes = ((el.attr or {}).classes or {})
        local context = get_context(format, name, attributes, classes)
        context.name = name
        context.content = content
        -- Render bubble
        local bubble_rendered = pandoc.layout.render(pandoc.template.apply(get_template(format), context))
        bubbles:insert(pandoc.RawBlock(format, bubble_rendered))
        -- If format is HTML, render CSS
        if FORMAT:match('html') then
            local bubble_style_rendered = pandoc.layout.render(pandoc.template.apply(get_template('css'), context))
            bubble_styles[context.hash] = bubble_style_rendered
        end
    end
    return pandoc.Div(pandoc.Blocks(bubbles), pandoc.Attr(nil, {'bubbles'}))
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
    end,
    Meta = function(el)
        for key, value in pairs(bubble_styles) do
            el['highlighting-css'] = (el['highlighting-css'] or '') .. value .. '\n'
        end
        return el
    end
}

function Pandoc(doc)
    doc:walk(get_bubble_configuration)
    return doc:walk(resolve_bubble)
end
