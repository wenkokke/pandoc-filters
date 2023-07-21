function Reader(input)
    input = tostring(input)

    -- Read an optional metadata block
    local meta = nil
    local start, startEnd = input:find("^%-%-%-\n")
    if start ~= nil then
        local stop, stopEnd = input:find("\n%-%-%-\n", startEnd + 1)
        local metadata_block = input:sub(start, stopEnd)
        meta = pandoc.read(metadata_block, 'markdown').meta
        input = input:sub(stopEnd + 1)
    end

    -- Make a document from the input with optional metadata
    return pandoc.Pandoc({pandoc.RawBlock('html', input)}, meta)
end
