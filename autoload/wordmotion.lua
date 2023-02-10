local WordMotion = {}

WordMotion.get = function(key, default)
    local spaces = vim.g[key] or default

    if type(spaces) == "string" then
        spaces = vim.fn.split(spaces, "\zs")
    end

    -- make unique, remove the empty string, and add the backslash
    local spaceSet = {}
    for _, v in pairs(spaces) do
        spaceSet[v] = true
    end
    spaceSet[""] = nil
    spaceSet["\\"] = true

    -- Surround single letters with whatever that regex is
    local out = {}
    for v, _ in pairs(spaceSet) do
        if (#v >= 1) then
            v = "\V" .. v .. "\m"
        out[v] = true
    end
    return out

end

WordMotion._or = function(t)
    -- TODO: This is wrong. t is a SET
    return '\%(\%(' .. table.concat(t, '\)\|\%(' ) .. '\)\)'
end

WordMotion._not = function(v)
    return '\%('.. v ..'\@!.\)'
end

WordMotion.between = function(s, w)
    local before = '\%(' .. w .. s .. '*\)\@<='
    local after = '\%(' .. s .. '*' .. w .. '\)\@='
    return before .. s .. after
end


WordMotion.init = function()
	-- [:alpha:] and [:alnum:] are ASCII only
	local alpha = '[[:lower:][:upper:]]'
	local alnum = '[[:lower:][:upper:][:digit:]]'
	local ss = '[[:space:]]'

	local hyphen = WordMotion.between('-', alpha)
	local underscore = WordMotion.between('_', alnum)
	local spaces = WordMotion.get('wordmotion_spaces', {hyphen, underscore})
    spaces[ss] = true
	local s = call(WordMotion._or, spaces)

	local S = WordMotion._not(s)

	local uspaces = WordMotion.get('wordmotion_uppercase_spaces', [])
	local us = call(WordMotion._or, [[ss] + uspaces])
	local uS = WordMotion._not(us)

	local a = alnum
	local d = '[[:digit:]]'
	local p = '[[:print:]]'
	local l = '[[:lower:]]'
	local u = '[[:upper:]]'
	local x = '[[:xdigit:]]'

	-- set complement
	function _.C(set, ...)
		return '\%(\%('.join(000, '\|').'\)\@!'.set.'\)'
	endfunction

	local words = get(, 'wordmotion_extra', [])
	call add(words, u.l.'\+')              -- CamelCase
	call add(words, u.'\+\ze'.u.l)       -- ACRONYMSBeforeCamelCase
	call add(words, u.'\+')                  -- UPPERCASE
	call add(words, l.'\+')                  -- lowercase
	call add(words, '#'.x.'\+\>')            -- #0F0F0F
	call add(words, '\<0[xX]'.x.'\+\>')      -- 0x00 0Xff
	call add(words, '\<0[oO][0-7]\+\>')        -- 0o00 0O77
	call add(words, '\<0[bB][01]\+\>')         -- 0b00 0B11
	call add(words, d.'\+')                  -- 1234 5678
	call add(words, _.C(p, a, s).'\+') -- other printable characters
	call add(words, '\%^')                     -- start of file
	call add(words, '\%$')                     -- end of file
	local word = call(_.or, [words])
end













