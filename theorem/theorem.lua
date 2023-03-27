---Support amsthm-style theorems.
---
---@module theorem
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local theorem = {}

-- Uses `pandoc.Blocks`, which was added in Pandoc 2.17.
PANDOC_VERSION:must_be_at_least '2.17'

-- The theorem styles.
local theorem_styles = {
    Definition = {
        classes = {'definition'},
        counter = 1,
        environment = 'definition'
    },
    Lemma = {
        classes = {'lemma'},
        counter = 1,
        environment = 'lemma'
    },
    Theorem = {
        classes = {'theorem'},
        counter = 1,
        environment = 'theorem'
    },
    Proof = {
        classes = {'proof'},
        counter = nil,
        environment = 'proof'
    },
    Claim = {
        classes = {'claim'},
        counter = 1,
        environment = 'claim'
    },
    Example = {
        classes = {'example'},
        counter = 1,
        environment = 'example'
    },
    Assumption = {
        classes = {'assumption'},
        counter = 1,
        environment = 'assumption'
    }
}

local function set_theorem_style(info, value)
    if type(value) == "string" then
        if theorem_styles[value] ~= nil then
            info.style = {
                name = value
            }
            for key, value in pairs(theorem_styles[value]) do
                info.style[key] = value
            end
        else
            error("Unsupported theorem style '" .. value .. "'")
        end
    end
end

local function set_custom_counter(result, value)
    result.custom_counter = value
end

local function add_theorem_name(result, value)
    if result.theorem_name == nil then
        result.theorem_name = {}
    end
    if type(value) == "string" then
        if value ~= "" then
            table.insert(result.theorem_name, pandoc.Str(value))
        end
    else
        table.insert(result.theorem_name, value)
    end
end

local function add_remainder(result, value)
    if result.remainder == nil then
        result.remainder = {}
    end
    if type(value) == "string" then
        if value ~= "" then
            table.insert(result.remainder, pandoc.Str(value))
        end
    else
        table.insert(result.remainder, value)
    end
end

local theorem_header_lexer = {
    if_Str = {{
        match = "(%a+)",
        input_states = {"start"},
        output_state = "after_kw",
        action = set_theorem_style
    }, {
        match = "([%d%.]*%d)",
        input_states = {"after_kw"},
        output_state = "after_num",
        action = set_custom_counter
    }, {
        match = "%(([^)]*)",
        input_states = {"after_kw", "after_num"},
        output_state = "after_lpar",
        action = add_theorem_name
    }, {
        match = "([^)]*)%)",
        input_states = {"after_lpar"},
        output_state = "after_rpar",
        action = add_theorem_name
    }, {
        match = "%.(.*)",
        input_states = {"after_kw", "after_num", "after_rpar"},
        output_state = "after_dot",
        action = add_remainder
    }},
    otherwise = {
        after_lpar = add_theorem_name,
        after_dot = add_remainder
    },
    start_state = "start",
    final_states = {"after_dot"}
}

---Check whether a value is a Pandoc element with the given tag.
---
---@param el table
---@param t string
---@return boolean
local function is_a(el, t)
    return el ~= nil and el.tag == t
end

---Check whether a table includes a given element.
---
---@param list table
---@param value string
---@return boolean
local function table_includes(list, value)
    for _, item in pairs(list) do
        if item == value then
            return true
        end
    end
    return false
end

---Run a lexer on a list of Pandoc elements.
---
---@param lexer table
---@param els table
---@return table
local function run_lexer(lexer, els)
    local result = {}
    local state = lexer.start_state
    local index = 0
    local el = nil
    ::next::
    index = index + 1
    el = els[index]
    ::continue::
    -- io.stderr:write(string.format("%d [%s] %s\n", index, state, el))
    if el == nil then
        -- We have reached the end of the input:
        if table_includes(lexer.final_states, state) then
            return result
        else
            error(string.format("Lexer ended in non-final state '%s'", state))
        end
    elseif is_a(el, 'Str') then
        -- Try every lexer rule, in order:
        for _, rule in pairs(lexer.if_Str) do
            if table_includes(rule.input_states, state) then
                local value, rest = el.text:match("^" .. rule.match .. "(.*)$")
                if value ~= nil then
                    state = rule.output_state
                    rule.action(result, value)
                    if rest == nil or rest == "" then
                        goto next
                    else
                        el = pandoc.Str(rest)
                        goto continue
                    end
                end
            end
        end
    end
    if lexer.otherwise[state] ~= nil then
        -- Try the default action:
        lexer.otherwise[state](result, el)
        goto next
    end
    if is_a(el, 'Space') then
        -- Skip any spaces that don't have a default action:
        goto next
    end
    -- Throw a lexical error:
    error(string.format("Lexical error at token '%s' in state '%s'", el, state))
end

-- Lex a definition list item containing a theorem.
---
---@param head table
---@param body table
---@return table
local function lex_definition_list_item(head, body)
    local success, result = pcall(function()
        return run_lexer(theorem_header_lexer, head)
    end)
    if success then
        assert(#body == 1, "Unexpected number of elements '" .. #body .. "'")
        result.body = body[1]
        if result.custom_counter == nil then
            local theorem_style = theorem_styles[result.style.name]
            if theorem_style.counter ~= nil then
                theorem_style.counter = theorem_style.counter + 1
            end
        end
        return result
    else
        io.stderr:write(string.format("Warning: %s\n", result))
        return nil
    end
end

-- Lex a definition list containing only theorems.
---
---@param head table
---@param body table
---@return table
local function lex_definition_list(el)
    if is_a(el, 'DefinitionList') and el.content ~= nil then
        local result_list = pandoc.List({})
        for index = 1, #el.content do
            local success, result_or_error = pcall(lex_definition_list_item, table.unpack(el.content[index]))
            if success then
                result_list:insert(result_or_error)
            else
                -- If result_list is non-empty, throw an error:
                if index > 1 then
                    error(string.format('item %s in definition list is not a theorem: %s\n', index, result_or_error))
                else
                    return nil
                end
            end
        end
        if #result_list > 0 then
            return result_list
        end
    end
    return nil
end

---Store the previously rendered identifier.
local previous_identifier = "unknown"

---Render the identifier for a theorem.
---
---@param theorem_info table
---@return string
local function render_theorem_identifier(theorem_info)
    local theorem_label = nil
    if theorem_info.theorem_name ~= nil then
        theorem_label = string.gsub("%W", "-", pandoc.utils.stringify(pandoc.Inlines(theorem_info.theorem_name)))
    elseif theorem_info.custom_counter ~= nil then
        theorem_label = theorem_info.custom_counter
    elseif theorem_info.style.counter ~= nil then
        theorem_label = string.format("%d", theorem_info.style.counter)
    else
        theorem_label = "for-" .. previous_identifier
    end
    previous_identifier = string.lower(string.format("%s-%s", theorem_info.style.name, theorem_label))
    return previous_identifier
end

---Render a theorem as a Pandoc element.
---
---@param theorem_info table
---@return table
local function render_theorem(theorem_info)
    -- Header
    local strong = pandoc.Inlines({})
    strong:insert(pandoc.Str(theorem_info.style.name))
    -- Add counter
    if theorem_info.custom_counter ~= nil then
        strong:insert(pandoc.Space())
        strong:insert(pandoc.Str(theorem_info.custom_counter))
    elseif theorem_info.style.counter ~= nil then
        strong:insert(pandoc.Space())
        strong:insert(pandoc.Str(string.format("%d", theorem_info.style.counter)))
    end
    local header = pandoc.Inlines({})
    header:insert(pandoc.Strong(strong))
    if theorem_info.theorem_name ~= nil then
        header:insert(pandoc.Space())
        header:insert(pandoc.Str('('))
        header:extend(theorem_info.theorem_name)
        header:insert(pandoc.Str(')'))
    end
    header:insert(pandoc.Str('.'))
    if theorem_info.remainder ~= nil then
        header:insert(pandoc.Emph(theorem_info.remainder))
    end
    -- Attr
    local blocks = pandoc.Blocks({pandoc.Para(header), table.unpack(theorem_info.body)})
    local attr = pandoc.Attr(render_theorem_identifier(theorem_info), theorem_info.style.classes)
    return pandoc.Div(blocks, attr)
end

---Render a theorem as a Pandoc element for LaTeX.
---
---@param theorem_info table
---@return table
local function render_theorem_latex(theorem_info)
    local header = pandoc.Inlines({})
    local footer = pandoc.Inlines({})
    -- Start group
    header:insert(pandoc.RawInline('latex', '{'))
    -- Custom Counter
    if theorem_info.custom_counter ~= nil then
        header:insert(pandoc.RawInline('latex', string.format('\\renewcommand{\\the%s}{%s}',
            theorem_info.style.environment, theorem_info.custom_counter)))
    end
    -- Header
    if theorem_info.theorem_name ~= nil then
        assert(type(theorem_info.theorem_name) == "table")
        header:insert(pandoc.RawInline('latex', string.format('\\begin{%s}[', theorem_info.style.environment)))
        header:extend(theorem_info.theorem_name)
        header:insert(pandoc.RawInline('latex', ']'))
        if theorem_info.remainder ~= nil then
            assert(type(theorem_info.remainder) == "table")
            header:extend(theorem_info.remainder)
        end
    else
        header:insert(pandoc.RawInline('latex', string.format('\\begin{%s}', theorem_info.style.environment)))
        header:extend(theorem_info.remainder)
    end
    -- Footer
    footer:insert(pandoc.RawInline('latex', string.format('\\end{%s}', theorem_info.style.environment)))
    -- Custom counter
    if theorem_info.custom_counter ~= nil then
        footer:insert(pandoc.RawInline('latex', string.format('\\addtocounter{%s}{-1}', theorem_info.style.environment)))
    end
    -- End group
    footer:insert(pandoc.RawInline('latex', '}'))
    -- Blocks
    return pandoc.Blocks({pandoc.Para(header), table.unpack(theorem_info.body), pandoc.Para(footer)})
end

---Render a list of theorems as a list of Pandoc elements.
---
---@param theorem_info_list table
---@return table
local function render_theorems(theorem_info_list)
    local output = pandoc.Blocks({})
    for index = 1, #theorem_info_list do
        if FORMAT:match('latex') then
            output:extend(render_theorem_latex(theorem_info_list[index]))
        else
            output:insert(render_theorem(theorem_info_list[index]))
        end
    end
    return output
end

DefinitionList = function(el)
    local theorem_info_list = lex_definition_list(el)
    if theorem_info_list ~= nil then
        return render_theorems(theorem_info_list)
    else
        return nil
    end
end

Str = function(el)
    if is_a(el, 'Str') and el.text ~= nil then
        for theorem_style, _ in pairs(theorem_styles) do
            local pattern = string.format('^#%s%%-(%%w*)$', string.lower(theorem_style))
            local identifier = string.match(el.text, pattern)
            if identifier then
                if FORMAT:match('latex') then
                    return pandoc.RawInline('latex', string.format('\\cref{%s}', el.text))
                else
                    return pandoc.Link(string.format("%s %s", theorem_style, identifier), el.text)
                end
            end
        end
    end
end
