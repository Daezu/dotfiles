return {
    {
        'MeanderingProgrammer/render-markdown.nvim',
        ft = {"markdown", "mdx"},
        dependencies = {"nvim-treesitter/nvim-treesitter"},
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        config = function ()
            require("render-markdown").setup({
                file_types = {"markdown", "mdx"}
            })
        end
    },
--    {
--        "davidmh/mdx.nvim",
--        dependencies = {"nvim-treesitter/nvim-treesitter"}
--    }
}
