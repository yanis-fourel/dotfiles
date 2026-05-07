local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local rep = require("luasnip.extras").rep

ls.add_snippets("typescript", {
	s("call", {
		t("const "),
		i(1, "res"),
		t(" = await session.call({"),
		t({ "", '    command: "' }),
		i(2, "CREATE"),
		t({ '",' , "    " }),
		i(3),
		t({ "", "  });", "  if (" }),
		rep(1),
		t({ ".isError()) {", '    console.error("Failed to create entity:", ' }),
		rep(1),
		t({ ".err);", '    throw new Error("Failed to create entity");', "  }" }),
	}),
})
