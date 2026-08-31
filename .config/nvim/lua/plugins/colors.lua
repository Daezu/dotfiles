local function enable_transparency()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
end
return {
    --[[
    {
	"folke/tokyonight.nvim",
	config = function()
	    vim.cmd.colorscheme "tokyonight"
	    enable_transparency()
	end
    },
    ]]
    {
      "RRethy/base16-nvim",
      config = function()
        -- Optional: disable highlights for specific plugins (these are the defaults)
        require('base16-colorscheme').with_config({
          telescope = true,
          indentblankline = true,
          notify = true,
          ts_rainbow = true,
          cmp = true,
          illuminate = true,
          dapui = true,
        })

        --[[
        require('base16-colorscheme').setup({
          base00 = "{{colors.background.default.hex}}",
          base01 = "{{colors.surface_container_lowest.default.hex}}",
          base02 = "{{colors.surface_container_low.default.hex}}",
          base03 = "{{colors.outline_variant.default.hex}}",
          base04 = "{{colors.on_surface_variant.default.hex}}",
          base05 = "{{colors.on_surface.default.hex}}",
          base06 = "{{colors.inverse_on_surface.default.hex}}",
          base07 = "{{colors.surface_bright.default.hex}}",
          base08 = "{{colors.tertiary.default.hex | lighten: -5}}",
          base09 = "{{colors.tertiary.default.hex}}",
          base0A = "{{colors.secondary.default.hex}}",
          base0B = "{{colors.primary.default.hex}}",
          base0C = "{{colors.tertiary_container.default.hex}}",
          base0D = "{{colors.primary_container.default.hex}}",
          base0E = "{{colors.secondary_container.default.hex}}",
          base0F = "{{colors.secondary.default.hex | lighten: -10}}",
        })

        -- Make selected text stand out more
        vim.api.nvim_set_hl(0, 'Visual', {
          bg = '{{colors.primary_container.default.hex}}',
          fg = '{{colors.background.default.hex}}',
        })

        enable_transparency()
        ]]
      end,
    },
    {
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            --theme = "tokyonight",
            theme = "base16",
        }
    },
}
