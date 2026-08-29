return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.tsc = opts.servers.tsc or {}
      LazyVim.extend(opts.servers.tsc, "settings.typescript.tsserver.globalPlugins", {
        {
          name = "@astrojs/ts-plugin",
          location = LazyVim.get_pkg_path("astro-language-server", "/node_modules/@astrojs/ts-plugin"),
          enableForWorkspaceTypeScriptVersions = true,
        },
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ["astro"] = { "prettierd" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "astro-language-server", -- astro lsp
      },
    },
  },
}
