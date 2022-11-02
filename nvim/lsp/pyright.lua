return {
  capabilities = {
    offsetEncoding = { "utf-8" },
  },
  settings = {
    python = {
      analysis = {
        ignore = { "*" },
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "workspace",
        typeCheckingMode = "off",
        extraPaths = {},
      },
    },
  },
}
