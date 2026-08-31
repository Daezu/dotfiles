return {
    {
      'nvim-java/nvim-java',
      config = function()
        require('java').setup({
          -- Startup checks
          checks = {
            nvim_version = true,        -- Check Neovim version
            nvim_jdtls_conflict = true, -- Check for nvim-jdtls conflict
          },

          -- JDTLS configuration
          jdtls = {
--            version = '1.43.0',
            path = nil,
            auto_install = true,
          },

          -- Extensions
          lombok = {
            enable = true,
--            version = '1.18.40',
            path = nil,
            auto_install = true,
          },

          java_test = {
            enable = true,
--            version = '0.40.1',
            path = nil,
            auto_install = true,
          },

          java_debug_adapter = {
            enable = true,
--            version = '0.58.2',
            path = nil,
            auto_install = true,
          },

          spring_boot_tools = {
            enable = true,
--            version = '1.55.1',
            path = nil,
            auto_install = true,
          },

          -- JDK installation
          jdk = {
            auto_install = false,
            version = '25',
            path = nil,
          },

          -- Logging
          log = {
            use_console = true,
            use_file = true,
            level = 'info',
            log_file = vim.fn.stdpath('state') .. '/nvim-java.log',
            max_lines = 1000,
            show_location = false,
          },
        })
        vim.lsp.enable('jdtls')


      end,
    }
}
