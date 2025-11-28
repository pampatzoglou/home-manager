{ config, pkgs, lib, ... }:

{
  # Ghostty terminal configuration
  xdg.configFile."ghostty/config".text = ''
    # Theme and appearance
    theme = tokyonight
    background-opacity = 0.95
    background-blur-radius = 20
    
    # Font configuration
    font-family = JetBrainsMono Nerd Font
    font-size = 13
    font-style = normal
    font-weight = normal
    font-thicken = true
    
    # Window and layout
    window-decoration = true
    window-title-font-family = JetBrainsMono Nerd Font
    window-padding-x = 10
    window-padding-y = 10
    window-padding-balance = false
    window-padding-color = extend
    resize-overlay = never
    resize-overlay-position = center
    resize-overlay-duration = 750
    
    # Tabs
    tab-width = 8
    hide-tabs = true
    tab-title = terminal
    
    # Terminal behavior
    scrollback-limit = 100000
    link-url = true
    copy-on-select = true
    click-repeat-interval = 300
    focus-follows-mouse = false
    mouse-hide-while-typing = true
    
    # Cursor
    cursor-style = block
    cursor-style-blink = false
    cursor-text = terminal
    
    # Shell integration
    shell-integration = zsh
    shell-integration-features = cursor,sudo,title
    osc-color-report-format = 8-bit
    
    # Performance
    macos-non-native-fullscreen = false
    macos-option-as-alt = true
    macos-titlebar-style = tabs
    macos-window-shadow = true
    
    # Keybindings (macOS style)
    keybind = cmd+t=new_tab
    keybind = cmd+w=close_tab
    keybind = cmd+shift+bracket_left=previous_tab
    keybind = cmd+shift+bracket_right=next_tab
    keybind = cmd+1=goto_tab:1
    keybind = cmd+2=goto_tab:2
    keybind = cmd+3=goto_tab:3
    keybind = cmd+4=goto_tab:4
    keybind = cmd+5=goto_tab:5
    keybind = cmd+6=goto_tab:6
    keybind = cmd+7=goto_tab:7
    keybind = cmd+8=goto_tab:8
    keybind = cmd+9=goto_tab:9
    keybind = cmd+plus=increase_font_size:1
    keybind = cmd+minus=decrease_font_size:1
    keybind = cmd+zero=reset_font_size
    keybind = cmd+c=copy_to_clipboard
    keybind = cmd+v=paste_from_clipboard
    keybind = cmd+f=toggle_quick_terminal
    keybind = cmd+k=clear_screen
    keybind = cmd+n=new_window
    keybind = cmd+shift+n=new_window
    
    # Split panes
    keybind = cmd+d=new_split:right
    keybind = cmd+shift+d=new_split:down
    keybind = cmd+shift+w=close_surface
    keybind = cmd+bracket_left=previous_split
    keybind = cmd+bracket_right=next_split
    keybind = cmd+shift+enter=toggle_split_zoom
    
    # Advanced features
    confirm-close-surface = false
    quit-after-last-window-closed = true
    auto-update = check
    auto-update-channel = stable
  '';
}
