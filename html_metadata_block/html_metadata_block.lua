---Support writing HTML with a metadata block.
---
---@module html_metadata_block
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local html_metadata_block = {}

local function write_metadata_block(doc)
    local template = pandoc.template.default('markdown')
    local opts = {
        template = template
    }
    local doc_meta = pandoc.Pandoc(pandoc.Blocks({}), doc.meta)
    return pandoc.write(doc_meta, 'markdown', opts)
end

function Writer(doc, opts)
    local metadata_block = write_metadata_block(doc)
    return metadata_block .. pandoc.write(doc, 'html', opts)
end

function Template()
    return pandoc.template.default('html')
end
