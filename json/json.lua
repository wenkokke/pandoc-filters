Extensions = {}

local function get_format(opts)
    return 'html'
end

local function to_doc(el)
    local el_type = pandoc.utils.type(el)
    if el_type == 'Pandoc' then
        return el
    elseif el_type == 'Block' then
        return to_doc(pandoc.Blocks({el}))
    elseif el_type == 'Blocks' then
        return to_doc(pandoc.Pandoc(el))
    elseif el_type == 'Inline' then
        return to_doc(pandoc.Inlines({el}))
    elseif el_type == 'Inlines' then
        return to_doc(pandoc.Plain(el))
    end
    error("ERROR: unexpected type " .. el_type .. "\n")
end

local function to_json_value(el, format, opts)
    local el_type = pandoc.utils.type(el)
    if el_type == 'Meta' then
        local result = {}
        for k, v in pairs(el) do
            result[k] = to_json_value(v)
        end
        return result
    elseif el_type == 'List' then
        local result = {}
        for i, v in ipairs(el) do
            result[i] = to_json_value(v)
        end
        return result
    elseif el_type == 'Inlines' then
        return pandoc.write(to_doc(el), format, opts)
    end
    error("ERROR: unexpected type " .. el_type .. "\n")
end

function Writer(doc, opts)
    local format = get_format(opts)
    local result = to_json_value(doc.meta, format, opts)
    result.body = pandoc.write(doc, format, opts)
    return pandoc.json.encode(result)
end
