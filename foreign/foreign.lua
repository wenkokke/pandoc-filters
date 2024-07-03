---Fix typesetting of "i.e.", "e.g.", "etc", etc.
---
---@module foreign
---@author Wen Kokke
---@license MIT
---@copyright Wen Kokke 2023
local foreign = {}

-- Find and replace rules
local default_rules = {
  ["en_GB"] = {
    ["e.g.,"] = "e.g.",
    ["i.e.,"] = "i.e.",
  },
  ["en_US"] = {
    ["e.g."] = "e.g.,",
    ["i.e."] = "i.e.,",
  }
}

function get_options(meta)
  -- Get language
  if foreign.lang == nil then
    if meta ~= nil and meta.lang ~= nil then
      foreign.lang = tostring(meta.lang)
    else
      foreign.lang = "en_US"
    end
  end
  -- Get rules
  foreign.rules = default_rules[foreign.lang]
end

function find_and_replace(str)
  if str.t == 'Str' then
    local new_text = foreign.rules[str.text]
    if new_text ~= nil then
      local msg_fmt = "foreign: REPLACE '%s' -> '%s'\n"
      io.stderr:write(string.format(msg_fmt, str.text, new_text))
      return pandoc.Str(new_text)
    end
  end
end

function Pandoc(doc)
  get_options(doc.meta)
  doc = doc:walk({ Str = find_and_replace })
  return doc
end