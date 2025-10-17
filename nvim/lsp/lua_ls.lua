return {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      completion = {
        callSnippet = "Replace",
      },
      workspace = {
        checkThirdParty = false, -- This can also help with performance
      },
    },
  },
}
