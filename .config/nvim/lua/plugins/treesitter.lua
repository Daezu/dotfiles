return {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    branch = 'main',
    load = function ()
    end,
    config = function()
        local configs = require("nvim-treesitter")
        configs.setup({
            --install_dir = vim.fn.stdpath("data") .. "/site"
        })
        --configs.install(ensure_installed)
    end
}

