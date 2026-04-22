---@diagnostic disable: undefined-global

return {
	s("date", {
		t(os.date("%Y/%m/%d"))
	}),
	s("(", fmta("(<>)", { i(1) })),
	s("[", fmta("[<>]", { i(1) })),
	s("{", fmta("{<>}", { i(1) })),
	s("$", fmta("$<>$", { i(1) })),
}
