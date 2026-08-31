return {
--    { "antosha417/nvim-lsp-file-operations", config = true },
--    { "folke/lazydev.nvim", opts = {} },
    {
      "saghen/blink.cmp",
      dependencies = {
        "saghen/blink.lib",
        "rafamadriz/friendly-snippets",
      },
      event = { "InsertEnter", "CmdlineEnter" },

      ---@module 'blink.cmp'
      ---@type blink.cmp.Config
      opts = {
        snippets = {
          preset = "default",
        },

        appearance = {
          use_nvim_cmp_as_default = false,
          nerd_font_variant = "mono",
        },

        completion = {
          accept = {
            auto_brackets = {
              enabled = true,
            },
          },
          menu = {
            draw = {
              treesitter = { "lsp" },
            },
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
          },
        },

        signature = { enabled = true },

        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
        },

        cmdline = {
          enabled = true,
          keymap = {
            preset = "cmdline",
            ["<Right>"] = false,
            ["<Left>"] = false,
          },
          completion = {
            list = { selection = { preselect = false } },
            menu = {
              auto_show = function(ctx)
                return vim.fn.getcmdtype() == ":"
              end,
            },
            ghost_text = { enabled = true },
          },
        },

        keymap = { preset = "default" },

        fuzzy = { implementation = "lua" },
      },
    },
}
