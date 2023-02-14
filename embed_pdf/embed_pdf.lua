---Support embedded PDFs.
---
---@module embed_pdf
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local embed_pdf = {}

-- The PDF embed templates.
local embed_pdf_templates = {
    html = [[
        <embed src="${ src }" type="application/pdf" ${ for(opts) }${ it.key }="${ it.value }" ${ endfor }/>
    ]],
    latex = [[
        \includepdf[${ for(opts) }${ it.key }=${ it.value },${ endfor }]{${ src }}
    ]]
}

-- Get a list of the supported formats.
local function get_supported_formats()
    local supported_formats = {}
    for format, template_string in pairs(embed_pdf_templates) do
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

-- Check whether the argument is a list with one element.
local function is_singleton_list(els)
    return els ~= nil and #els == 1 and els[1] ~= nil
end

-- Check whether or not an Image element is a PDF embed.
local function is_pdf_embed(el)
    return el ~= nil and el.tag == 'Image' and el.src ~= nil and el.src:match("%.pdf$")
end

-- Get the options for a specific output format.
local function get_format_opts(el)
    local format = get_target_format()
    local opts = pandoc.List()
    if el.attr ~= nil and el.attr.attributes ~= nil then
        for key, value in pairs(el.attr.attributes) do
            if key:match('^' .. format .. ':') then
                opts:insert({
                    key = key:sub(#format + #':' + 1),
                    value = value
                })
            end
        end
    end
    return opts
end

-- Render a PDF embed.
local function render_pdf_embed(el, block)
    local format = get_target_format()
    assert(embed_pdf_templates[format] ~= nil)
    local template_string = embed_pdf_templates[format]:match('^%s*(.*)\n%s*$')
    local template = pandoc.template.compile(template_string)
    local context = {
        src = el.src,
        opts = get_format_opts(el)
    }
    local document = pandoc.template.apply(template, context)
    local rendered = pandoc.layout.render(document)
    if block == true then
        return pandoc.RawBlock(format, rendered)
    else
        return pandoc.RawInline(format, rendered)
    end
end

function Image(el)
    if is_pdf_embed(el) then
        return render_pdf_embed(el)
    else
        return el
    end
end

-- Specialised function to render standalone images as block elements.
function Para(el)
    if is_singleton_list(el.content) then
        local image = el.content[1]
        if is_pdf_embed(image) then
            return render_pdf_embed(image, true)
        end
    end
    return nil
end

-- This ensures that the specialised Para function fires before the general Image function.
-- Requires: Pandoc > 2.17
traverse = 'topdown'
