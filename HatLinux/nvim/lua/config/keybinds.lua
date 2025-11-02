-- Keybindings configuration

-- Copilot Chat keybindings
vim.keymap.set("n", "<leader>cc", "<cmd>CopilotChat<cr>", { desc = "Open Copilot Chat" })
vim.keymap.set("n", "<leader>ce", "<cmd>CopilotChatExplain<cr>", { desc = "Explain with Copilot" })
vim.keymap.set("n", "<leader>cr", "<cmd>CopilotChatReview<cr>", { desc = "Review with Copilot" })
vim.keymap.set("n", "<leader>ct", "<cmd>CopilotChatTests<cr>", { desc = "Generate tests with Copilot" })
vim.keymap.set("n", "<leader>cf", "<cmd>CopilotChatFix<cr>", { desc = "Fix code with Copilot" })