-- smear-cursor.nvim: animates the cursor with a smear effect while typing
-- and moving (motion blur style). https://github.com/sphamba/smear-cursor.nvim
--
-- Disabled by default: Ghostty already runs its own cursor-smear shader
-- (common/ghostty/config -> shaders/cursor_smear_gentleman.glsl), so turning
-- this on too would smear the cursor twice (terminal shader + Neovim plugin)
-- for every HatDots user, not just the ones who had it on macOS. Flip
-- `enabled` to true locally if you want the in-editor effect as well.
return {
	{ "sphamba/smear-cursor.nvim", enabled = false, opts = {} },
}
