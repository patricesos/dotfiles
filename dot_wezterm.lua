local wezterm = require("wezterm")
local config = {}
local mux = wezterm.mux

wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- config.default_prog = { 'pwsh', '-NoProfileLoadTime' }
config.default_prog = { 'pwsh', '-nol' }

config.color_scheme = "Batman"
config.inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.8,
}
config.window_background_image = "F:/wallpaper/812350.jpg"
config.window_background_opacity = 0.95
config.font_size = 16
config.window_decorations = "RESIZE"
config.window_padding = {
    left = 5,
    right = 5,
    top = 5,
    bottom = 5,
}


-- tab bar
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = true
config.window_frame = {
    font = wezterm.font { family = 'Roboto', weight = 'Bold' },
    font_size = 12.0,
    active_titlebar_bg = '#333333',
    inactive_titlebar_bg = '#333333',
}



    
config.font = wezterm.font("JetBrains Mono")

-- WezTerm Keybindings Documentation by dragonlobster
-- ===================================================
-- Leader Key:
-- The leader key is set to ALT + q, with a timeout of 2000 milliseconds (2 seconds).
-- To execute any keybinding, press the leader key (ALT + q) first, then the corresponding key.

-- Keybindings:
-- 1. Tab Management:
--    - LEADER + c: Create a new tab in the current pane's domain.
--    - LEADER + x: Close the current pane (with confirmation).
--    - LEADER + b: Switch to the previous tab.
--    - LEADER + n: Switch to the next tab.
--    - LEADER + <number>: Switch to a specific tab (0–9).

-- 2. Pane Splitting:
--    - LEADER + |: Split the current pane horizontally into two panes.
--    - LEADER + -: Split the current pane vertically into two panes.

-- 3. Pane Navigation:
--    - LEADER + h: Move to the pane on the left.
--    - LEADER + j: Move to the pane below.
--    - LEADER + k: Move to the pane above.
--    - LEADER + l: Move to the pane on the right.

-- 4. Pane Resizing:
--    - LEADER + LeftArrow: Increase the pane size to the left by 5 units.
--    - LEADER + RightArrow: Increase the pane size to the right by 5 units.
--    - LEADER + DownArrow: Increase the pane size downward by 5 units.
--    - LEADER + UpArrow: Increase the pane size upward by 5 units.

-- 5. Status Line:
--    - The status line indicates when the leader key is active, displaying an ocean wave emoji (🌊).

-- Miscellaneous Configurations:
-- - Tabs are shown even if there's only one tab.
-- - The tab bar is located at the bottom of the terminal window.
-- - Tab and split indices are zero-based.

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
-- if wezterm.config_builder then
--     config = wezterm.config_builder()
-- end

-- tmux
config.leader = { key = "q", mods = "ALT", timeout_milliseconds = 2000 }
config.keys = {
    {
        mods = "LEADER",
        key = "c",
        action = wezterm.action.SpawnTab("CurrentPaneDomain"),
    },
    {
        mods = "LEADER",
        key = "x",
        action = wezterm.action.CloseCurrentPane({ confirm = true }),
    },
    {
        mods = "LEADER",
        key = "b",
        action = wezterm.action.ActivateTabRelative(-1),
    },
    {
        mods = "LEADER",
        key = "n",
        action = wezterm.action.ActivateTabRelative(1),
    },
    {
        mods = "LEADER",
        key = "|",
        action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
    {
        mods = "LEADER",
        key = "-",
        action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    {
        mods = "LEADER",
        key = "h",
        action = wezterm.action.ActivatePaneDirection("Left"),
    },
    {
        mods = "LEADER",
        key = "j",
        action = wezterm.action.ActivatePaneDirection("Down"),
    },
    {
        mods = "LEADER",
        key = "k",
        action = wezterm.action.ActivatePaneDirection("Up"),
    },
    {
        mods = "LEADER",
        key = "l",
        action = wezterm.action.ActivatePaneDirection("Right"),
    },
    {
        mods = "LEADER",
        key = "LeftArrow",
        action = wezterm.action.AdjustPaneSize({ "Left", 5 }),
    },
    {
        mods = "LEADER",
        key = "RightArrow",
        action = wezterm.action.AdjustPaneSize({ "Right", 5 }),
    },
    {
        mods = "LEADER",
        key = "DownArrow",
        action = wezterm.action.AdjustPaneSize({ "Down", 5 }),
    },
    {
        mods = "LEADER",
        key = "UpArrow",
        action = wezterm.action.AdjustPaneSize({ "Up", 5 }),
    },

}

for i = 0, 9 do
    -- leader + number to activate that tab
    table.insert(config.keys, {
        key = tostring(i),
        mods = "LEADER",
        action = wezterm.action.ActivateTab(i),
    })
end

-- tmux status
wezterm.on("update-right-status", function(window, _)
    local SOLID_LEFT_ARROW = ""
    local ARROW_FOREGROUND = { Foreground = { Color = "#c6a0f6" } }
    local prefix = ""

    if window:leader_is_active() then
        prefix = " " .. utf8.char(0x1f30a) -- ocean wave
        SOLID_LEFT_ARROW = utf8.char(0xe0b2)
    end

    if window:active_tab():tab_id() ~= 0 then
        ARROW_FOREGROUND = { Foreground = { Color = "#1e2030" } }
    end -- arrow color based on if tab is first pane

    window:set_left_status(wezterm.format({
        { Background = { Color = "#b7bdf8" } },
        { Text = prefix },
        ARROW_FOREGROUND,
        { Text = SOLID_LEFT_ARROW },
    }))
end)

-- and finally, return the configuration to wezterm

return config
