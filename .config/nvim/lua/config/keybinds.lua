vim.g.mapleader = " "
vim.keymap.set("n", "<leader>cd", vim.cmd.Ex, { desc = "Ex" })
vim.keymap.set("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "Find keymaps" })


-- Moving lines --
-- Normal mode
vim.keymap.set("n", "<C-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
vim.keymap.set("n", "<C-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
-- Visual mode (move a whole selection)
vim.keymap.set("x", "<C-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
vim.keymap.set("x", "<C-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
