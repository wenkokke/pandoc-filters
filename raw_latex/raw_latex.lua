function Reader(input)
    return pandoc.Pandoc({pandoc.RawBlock('latex', tostring(input))})
end
