return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  main = "nvim-treesitter",
  init = function()
    -- Replace ensure_installed: only install missing parsers
    local ensureInstalled = {
      "json",
      "yaml",
      "markdown",
      "markdown_inline",
      "bash",
      "lua",
      "gitignore",
      "c",
      "python",
      "cpp",
    }
    local alreadyInstalled = require("nvim-treesitter.config").get_installed()
    local parsersToInstall = vim
      .iter(ensureInstalled)
      :filter(function(parser)
        return not vim.tbl_contains(alreadyInstalled, parser)
      end)
      :totable()
    require("nvim-treesitter").install(parsersToInstall)

    -- Enable highlighting + indentation via FileType autocmd
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start)
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
  config = function()
    -- autotag still needs its own setup
    require("nvim-ts-autotag").setup()
  end,
}
