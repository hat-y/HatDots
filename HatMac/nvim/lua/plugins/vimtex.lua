return {
	"lervag/vimtex",
	lazy = true, -- se carga solo con archivos .tex
	init = function()
		vim.g.vimtex_view_method = "zathura"
		vim.g.vimtex_compiler_method = "latexmk"
	end,
}
