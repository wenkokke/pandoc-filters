local logging = require '../logging'

-- Lexer
local Space = lpeg.S(" \n\t") ^ 0
local Lower = lpeg.R("az")
local Upper = lpeg.R("AZ")
local Sort  = (Lower + Upper) ^ 1

function CodeBlock(el)
    logging.temp('el', el.text)
end
