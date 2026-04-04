return {
	"folke/which-key.nvim",
	opts = function(_, opts)
		opts.spec = opts.spec or {}

		local spec = {
			{ "<leader>m", group = "Markdown & Obsidian", icon = "📝" },

			-- Headings (insert mode: ,1 to ,6)
			{ "<leader>m1", desc = "Heading 1  (,1)", icon = "#" },
			{ "<leader>m2", desc = "Heading 2  (,2)", icon = "##" },
			{ "<leader>m3", desc = "Heading 3  (,3)", icon = "###" },
			{ "<leader>m4", desc = "Heading 4  (,4)", icon = "####" },
			{ "<leader>m5", desc = "Heading 5  (,5)", icon = "#####" },
			{ "<leader>m6", desc = "Heading 6  (,6)", icon = "######" },

			-- Formatting via mini.surround (visual mode: select + sa X)
			{ "<leader>mf", group = "Format  (visual: sa)", icon = "✨" },
			{ "<leader>mfb", desc = "Bold  (sa b)", icon = "**" },
			{ "<leader>mfi", desc = "Italic  (sa i)", icon = "*" },
			{ "<leader>mfl", desc = "Link  (sa l)", icon = "[]" },
			{ "<leader>mfc", desc = "Code  (sa c)", icon = "`" },
			{ "<leader>mfC", desc = "Code block  (sa C)", icon = "```" },

			-- Quick insert
			{ "<leader>mq", desc = "Blockquote  (,q)", icon = ">" },
			{ "<leader>mc", desc = "Toggle checkbox  (<leader>mc)", icon = "☑" },
			{ "<leader>mt", desc = "Generate TOC  (<leader>mt)", icon = "📋" },

			-- Tables (buffer-local: ,t)
			{ "<leader>mT", group = "Tables  (,t)", icon = "📊" },
			{ "<leader>mTr", desc = "Add row  (,tr)" },
			{ "<leader>mTR", desc = "Delete row  (,tR)" },
			{ "<leader>mTc", desc = "Add column  (,tc)" },
			{ "<leader>mTC", desc = "Delete column  (,tC)" },
			{ "<leader>mTa", desc = "Align table  (,ta)" },
			{ "<leader>mTj", desc = "Cell down  (,tj)" },
			{ "<leader>mTk", desc = "Cell up  (,tk)" },
			{ "<leader>mTh", desc = "Cell right  (,th)" },
			{ "<leader>mTl", desc = "Cell left  (,tl)" },

			-- Spell & UI
			{ "<leader>ms", desc = "Spell correct  (<leader>sz)", icon = "✓" },
			{ "<leader>mz", desc = "Zen mode  (<leader>zz)", icon = "🧘" },
			{ "<leader>mu", desc = "Toggle Supermaven  (<leader>us)", icon = "🤖" },
			{ "<leader>mp", desc = "Paste image  (Ctrl+V)", icon = "🖼" },
			{ "<leader>mP", desc = "Markdown preview  (:MarkdownPreview)", icon = "👁" },

			-- Obsidian (actual keymaps: <leader>o*)
			{ "<leader>mo", group = "Obsidian  (<leader>o)", icon = "📁" },
			{ "<leader>moo", desc = "Open in Obsidian app  (oo)" },
			{ "<leader>mon", desc = "New note  (on)" },
			{ "<leader>moq", desc = "Quick switch  (oq)" },
			{ "<leader>moQ", desc = "Today's log  (oQ)" },
			{ "<leader>mos", desc = "Search  (os)" },
			{ "<leader>mot", desc = "Insert template  (ot)" },
			{ "<leader>mol", desc = "Buffer links  (ol)" },
			{ "<leader>molT", desc = "Log template  (olT)" },
			{ "<leader>mob", desc = "Backlinks  (ob)" },
			{ "<leader>mod", desc = "Daily (today)  (od)" },
			{ "<leader>moD", desc = "Daily (tomorrow)  (oD)" },
			{ "<leader>moy", desc = "Daily (yesterday)  (oy)" },
			{ "<leader>mor", desc = "Rename note  (or)" },
			{ "<leader>moO", desc = "Force open Obsidian  (oO)" },
		}

		vim.list_extend(opts.spec, spec)
	end,
}
