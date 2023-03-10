---Support possessive citations.
---
---@module possessive_cite
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local possessive_cite = {}

-- Uses `pandoc.Inlines`, which was added in Pandoc 2.17.
PANDOC_VERSION:must_be_at_least '2.17'

---Check whether a value is a Pandoc element with the given tag.
---
---@param el table
---@param t string
---@return boolean
local function is_a(el, t)
    return el ~= nil and el.tag == t
end

---Test whether the element at the given index in a series of inline-like elements is a possessive citation.
---
---@param els table
---@param index number
---@return boolean
local function test(els, index)
    if (els == nil) then
        return false
    else
        local cite = els[index]
        local poss = els[index + 1]
        if not is_a(cite, 'Cite') then
            return false
        elseif not is_a(poss, 'Str') then
            return false
        elseif not poss.text:match("’s") then
            return false
        elseif #cite.citations ~= 1 then
            error("Found possessive citation with multiple citations: " .. pandoc.utils.stringify(cite) .. '\n')
            return false
        else
            return true
        end
    end
end

---Render the possessive citation at the given index in a series of inline-like elements.
---If inline is true, inline the citation content.
---Returns either a singleton table containing the rendered element, or a table containing the content.
---
---@param els table
---@param index number
---@param inline boolean
---@return table
local function render(els, index, inline)
    inline = inline or false
    if els ~= nil then
        local cite = els[index]:clone()
        local poss = els[index + 1]:clone()
        -- Get the citation content
        local cite_content = cite.content
        -- Remove the parenthetical and the final space
        local parenthetical = cite_content[#cite_content]
        local space = cite_content[#cite_content - 1]
        local last_author_name = cite_content[#cite_content - 2]
        if not is_a(parenthetical, 'Str') then
            error("Expected parenthetical, found: '" .. pandoc.utils.stringify(parenthetical))
        elseif not parenthetical.text:match("^%([^)]*%)$") then
            if parenthetical.text:match("^@") then
                io.stderr:write("Warning: unresolved citation '" .. parenthetical.text .. "'. Did you run Pandoc with --citeproc?\n")
                return {cite, poss}
            else
                error("Expected parenthetical, found '" .. pandoc.utils.stringify(parenthetical))
            end
        elseif not is_a(space, "Space") then
            error("Expected space, found: '" .. pandoc.utils.stringify(space))
        elseif not is_a(last_author_name, "Str") then
            error("Expected author name, found '" .. pandoc.utils.stringify(last_author_name))
        else
            -- Remove the last two elements
            cite_content:remove(#cite_content)
            cite_content:remove(#cite_content)
            -- Append "’s"
            if last_author_name.text:match("[sx]$") then
                last_author_name.text = last_author_name.text .. "’"
            else
                last_author_name.text = last_author_name.text .. "’s"
            end
            -- Inline the citation content
            if inline then
                return cite_content
            else
                return {cite}
            end
        end
    end
end

---Render all possessive citation in a series of inline-like elements.
---If inline is true, inline the citation content.
---
---@param els table
---@param index number
---@param inline boolean
---@return table
local function render_all(els, inline)
    local res = pandoc.List()
    local skip = false
    for index = 0, #els do
        if skip then
            skip = false
        elseif test(els, index) then
            res:extend(render(els, index, inline))
            skip = true
        else
            res:insert(els[index])
        end
    end
    return pandoc.Inlines(res)
end

---Render all possessive citations in an series of inline-like elements.
---If we're targeting LaTeX, do not render \cite elements, but inline the content.
---
---@param els table
---@return table
function Inlines(els)
    local inline = FORMAT:match('latex') or FORMAT:match('markdown')
    return render_all(els, inline)
end

