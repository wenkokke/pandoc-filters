---Supper header case conversion.
---
---@module title_case
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2024
-- Possible values for 'title_case' option:
local TITLE_CASE_TITLE = 'title'
local TITLE_CASE_SENTENCE = 'sentence'

-- Possible values for 'title_case_style' option:
local TITLE_CASE_STYLE = 'AP'

-- Exceptions for each title case style:
local TITLE_CASE_EXCEPTIONS = {
    AP = {'a', 'for', 'so', 'an', 'in', 'the', 'and', 'nor', 'to', 'at', 'of', 'up', 'but', 'on', 'yet', 'by', 'or'},
    CONTRACTIONS = {'d', 'll', 's'}
}

-- Default options:
local title_case = {
    title_case = TITLE_CASE_TITLE,
    title_case_style = TITLE_CASE_STYLE
}

local function title_case_exceptions()
    if title_case.title_case_exceptions == nil then
        local result = pandoc.List(TITLE_CASE_EXCEPTIONS.CONTRACTIONS)
        if title_case.title_case == TITLE_CASE_TITLE then
            local title_case_exceptions = TITLE_CASE_EXCEPTIONS[title_case.title_case_style]
            if title_case_exceptions ~= nil then
                result = result .. pandoc.List(title_case_exceptions)
            end
        end
        title_case.title_case_exceptions = result
    end
    return title_case.title_case_exceptions
end

local function title_case_exception(word)
    return title_case_exceptions():includes(word)

end

local PATTERN_UNICODE_CHARACTER = "([%z\1-\127\194-\244][\128-\191]*)"
local PATTERN_WORD_CHARACTER = "[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ]"

local function convert_word(word)
    if not title_case_exception(word) then
        if word:len() >= 2 then
            word = word:sub(1, 1):upper() .. word:sub(2):lower()
        else
            word = word:upper()
        end

    end
    return word
end

local function convert_Str(str)
    local text = ""
    local word = ""
    for char in str.text:gmatch(PATTERN_UNICODE_CHARACTER) do
        local is_word_char = char:match(PATTERN_WORD_CHARACTER) ~= nil
        if is_word_char then
            word = word .. char
        else
            if word ~= "" then
                text = text .. convert_word(word)
                word = ""
            end
            text = text .. char
        end
    end
    if word ~= "" then
        text = text .. convert_word(word)
        word = ""
    end
    return pandoc.Str(text)
end

local function convert_Header(header)
    header = pandoc.walk_block(header, {
        Str = convert_Str
    })
    return header
end

function Pandoc(doc)
    doc = doc:walk({
        Header = convert_Header
    })
    return doc
end
