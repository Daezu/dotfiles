local nvim_treesitter = require("nvim-treesitter")

local ensure_installed = {
    "lua", 
    "tsx", 
    "typescript", 
    "python", 
    "java", 
    "json",
    "rust", 
    "javascript",
    "angular",
    "arduino",
    "astro",
    "bash",
    "c",
    "c_sharp",
    "cpp",
    "css",
    "csv",
    "dockerfile",
    "git_config",
    "git_rebase",
    "gitcommit",
    "gitignore",
    "helm",
    "html",
    "kitty",
    "nginx",
    "sql",
    "toml",
    "typst",
    "yaml",
    "markdown",
    "markdown_inline",
    "latex",
}

vim.api.nvim_create_autocmd("FileType", {
  pattern = vim.list_extend(vim.deepcopy(ensure_installed), { "mdx" }),

  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    local lang = vim.treesitter.language.get_lang(ft)
    if lang == nil then
      return
    end

    -- check if parser is available
    local is_parser_available = vim.treesitter.language.add(lang)
    if not is_parser_available then
      local available_langs = vim.g.ts_available or nvim_treesitter.get_available()
      if not vim.g.ts_available then
        vim.g.ts_available = available_langs
      end

      if vim.tbl_contains(available_langs, lang) then
        -- install treesitter parsers and queries
        local install_msg = string.format("Installing parsers and queries for %s", lang)
        vim.print(install_msg)
        require("nvim-treesitter").install(lang)
      end
    end

    if vim.treesitter.language.add(lang) then
      -- start treesitter highlighting
      vim.treesitter.start(args.buf, lang)

      -- the following two statements will enable treesitter folding
      -- vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
      -- vim.wo[0][0].foldmethod = "expr"

      -- enable treesitter-based indentation
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})



vim.filetype.add({
    extension = {
        mdx = 'mdx'
    }
})
vim.treesitter.language.register('markdown', 'mdx')

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "html", "json", "yaml", "typescript", "typescriptreact", "javascript", "javascriptreact", "astro" },
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
  end,
})



