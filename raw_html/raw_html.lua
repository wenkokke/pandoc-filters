function Reader(input)
    return pandoc.Pandoc({pandoc.RawBlock('html', tostring(input))})
end
