return {
    "mason-org/mason-lspconfig.nvim",
    opts = {
	ensure_installed = {
	    "pyright",
	    "ts_ls",
	    "html",
	    "cssls",
	    "tailwindcss",
	    "lua_ls",
	    "eslint",
	},
	automatic_enable = true,
    },
    dependencies = {
        { 
	    "mason-org/mason.nvim", 
	    opts = {
		ui = {
		    icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗"
		    }
		}
	    }
	},
        "neovim/nvim-lspconfig",
    },
}
