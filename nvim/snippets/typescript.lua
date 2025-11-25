---@diagnostic disable: undefined-global

return {
	s({ trig = "cl (.*)", regTrig = true },
		fmta("console.log(<>, <>)", {
			i(1),
			f(function(_, snip) return snip.captures[1] end)
		})
	),
}
