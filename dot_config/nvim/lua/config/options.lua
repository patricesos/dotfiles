-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
local opt = vim.opt

opt.wrap = true
opt.relativenumber = true
opt.linespace = 3
vim.g.tutor_is_loaded = 1

-- vim.cmd.colorscheme("vague")

if vim.g.neovide then
  vim.o.guifont = "Maple Mono NF:h16"
  vim.g.transparency = 0.5
  vim.g.neovide_opacity = 1.0
  vim.g.neovide_window_blurred = true
  vim.g.neovide_cursor_vfx_mode = "torpedo"
  vim.g.neovide_cursor_vfx_particle_density = 1.0
  vim.g.neovide_show_border = false
  vim.g.neovide_theme = "light"
  vim.g.neovide_title_text_color = "white"
  vim.g.neovide_hide_mouse_when_typing = true

  vim.g.neovide_padding_top = 20
  vim.g.neovide_padding_bottom = 20
  vim.g.neovide_padding_right = 20
  vim.g.neovide_padding_left = 20

  vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "none" })

  vim.g.neovide_scale_factor = 1.0
  local change_scale_factor = function(delta)
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
  end
  vim.keymap.set("n", "<C-=>", function()
    change_scale_factor(1.25)
  end)
  vim.keymap.set("n", "<C-->", function()
    change_scale_factor(1 / 1.25)
  end)

  vim.g.neovide_title_background_color =
    string.format("%x", vim.api.nvim_get_hl(0, { id = vim.api.nvim_get_hl_id_by_name("Normal") }).bg)
end
