---Support cross-references.
---
---@module crossref
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local logging = require './filters/wenkokke/crossref/logging'

-- Uses `pandoc.template.apply`, which was added in Pandoc 3.0.1.
PANDOC_VERSION:must_be_at_least '3.0.1'

-- function Cite(el)
--   logging.temp('cite', el)
--   return el
-- end

local identifiers = pandoc.List()

local function gather_identifier(el)
    if el.attr ~= nil and el.attr.identifier ~= nil and el.attr.identifier ~= '' then
        logging.temp('identifier', el.attr.identifier)
        identifiers:insert(el.attr.identifier)
    end
end

local gather_identifiers = {
    Block = gather_identifier,
    Inline = gather_identifier
}

function Pandoc(doc)
    doc:walk(gather_identifiers)
    return doc
end
