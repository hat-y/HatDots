return {
	"HakonHarnes/img-clip.nvim",
	event = "User img_clip_event",

	opts = {
		-- Path to your Obsidian vault attachments folder
		-- The vault is at ~/HatNotes, so attachments go in ~/HatNotes/0-Attachments
		dir_path = vim.fn.expand("~/HatNotes/0-Attachments"),

		-- Template for inserted markdown image link
		-- $CURSOR will be replaced with cursor position, $FILE_PATH with current file path
		template = "![$CURSOR]($FILE_PATH)",

		-- Default image file extension
		file_extension = "png",

		-- Configure relative path to vault root
		relative_image_path = true,
	},

	keys = {
		-- Override default Ctrl+V to use img-clip instead of system clipboard
		-- This works automatically when in markdown files
		{
			"<C-v>",
			function()
				-- Ensure we're in a markdown file
				if vim.bo.filetype ~= "markdown" then
					vim.notify("[img-clip] Only works in markdown files", vim.log.levels.WARN)
					return
				end
				-- Call img-clip's paste function
				require("img-clip").paste_image()
			end,
			mode = "n",
			desc = "Paste image from clipboard (markdown)",
		},
	},
}
