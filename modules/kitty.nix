{ ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };

    settings = {
      # Appearance - Solarized Dark with very subtle opacity
      background_opacity = "0.98";
      background_blur = 10;

      # Window
      hide_window_decorations = false;
      window_padding_width = 10;
      confirm_os_window_close = 0;

      # Tabs
      tab_bar_style = "powerline";
      tab_bar_edge = "top";
      tab_title_template = "{index}: {title}";
      tab_bar_min_tabs = 2;
      tab_switch_strategy = "previous";

      # Cursor
      cursor_shape = "block";
      cursor_blink_interval = 0;
      cursor_stop_blinking_after = 15;

      # Performance
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = true;

      # Scrollback
      scrollback_lines = 100000;
      scrollback_pager = "less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER";
      wheel_scroll_multiplier = "5.0";
      touch_scroll_multiplier = "1.0";

      # Mouse
      copy_on_select = true;
      strip_trailing_spaces = "smart";
      mouse_hide_wait = 3;
      url_style = "curly";
      open_url_with = "default";
      detect_urls = true;

      # Shell integration
      shell_integration = "enabled";

      # Bell
      enable_audio_bell = false;
      visual_bell_duration = "0.0";
      window_alert_on_bell = true;
      bell_on_tab = true;

      # Advanced
      allow_remote_control = true;
      update_check_interval = 0;
      clipboard_control = "write-clipboard write-primary";

      # Platform-specific (works on both macOS and Linux)
      macos_option_as_alt = true;
      macos_titlebar_color = "background";
      macos_quit_when_last_window_closed = true;
      linux_display_server = "auto";
    };

    keybindings = {
      # Tab management - Linux style (Ctrl-based)
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+w" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+q" = "close_os_window";

      # Tab navigation by number
      "ctrl+shift+1" = "goto_tab 1";
      "ctrl+shift+2" = "goto_tab 2";
      "ctrl+shift+3" = "goto_tab 3";
      "ctrl+shift+4" = "goto_tab 4";
      "ctrl+shift+5" = "goto_tab 5";
      "ctrl+shift+6" = "goto_tab 6";
      "ctrl+shift+7" = "goto_tab 7";
      "ctrl+shift+8" = "goto_tab 8";
      "ctrl+shift+9" = "goto_tab 9";

      # Font size control
      "ctrl+shift+equal" = "increase_font_size";
      "ctrl+shift+plus" = "increase_font_size";
      "ctrl+shift+minus" = "decrease_font_size";
      "ctrl+shift+backspace" = "restore_font_size";

      # Copy/Paste - Linux style
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "shift+insert" = "paste_from_selection";

      # Scrollback
      "ctrl+shift+up" = "scroll_line_up";
      "ctrl+shift+down" = "scroll_line_down";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";
      "ctrl+shift+h" = "show_scrollback";

      # Window management (splits)
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+n" = "new_os_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+[" = "previous_window";
      "ctrl+shift+f" = "move_window_forward";
      "ctrl+shift+b" = "move_window_backward";

      # Layout management
      "ctrl+shift+l" = "next_layout";
      "ctrl+shift+." = "move_tab_forward";
      "ctrl+shift+," = "move_tab_backward";

      # Search
      "ctrl+shift+/" = "show_scrollback";

      # Miscellaneous
      "ctrl+shift+f11" = "toggle_fullscreen";
      "ctrl+shift+f10" = "toggle_maximized";
      "ctrl+shift+u" = "kitten unicode_input";
      "ctrl+shift+f2" = "edit_config_file";
      "ctrl+shift+escape" = "kitty_shell window";
      "ctrl+shift+delete" = "clear_terminal reset active";

      # Hints (URL opening, file paths, etc.)
      "ctrl+shift+e" = "kitten hints";
      "ctrl+shift+p>f" = "kitten hints --type path --program -";
      "ctrl+shift+p>shift+f" = "kitten hints --type path";
      "ctrl+shift+p>l" = "kitten hints --type line --program -";
      "ctrl+shift+p>w" = "kitten hints --type word --program -";
      "ctrl+shift+p>h" = "kitten hints --type hash --program -";
    };

    extraConfig = ''
      # Solarized Dark Color Scheme
      background              #002b36
      foreground              #839496
      cursor                  #93a1a1
      cursor_text_color       #002b36

      # Black
      color0                  #073642
      color8                  #002b36

      # Red
      color1                  #dc322f
      color9                  #cb4b16

      # Green
      color2                  #859900
      color10                 #586e75

      # Yellow
      color3                  #b58900
      color11                 #657b83

      # Blue
      color4                  #268bd2
      color12                 #839496

      # Magenta
      color5                  #d33682
      color13                 #6c71c4

      # Cyan
      color6                  #2aa198
      color14                 #93a1a1

      # White
      color7                  #eee8d5
      color15                 #fdf6e3

      # Mouse actions
      mouse_map left click ungrabbed mouse_handle_click selection link prompt
      mouse_map ctrl+left click ungrabbed mouse_handle_click link
      mouse_map ctrl+left press ungrabbed mouse_selection normal

      # Layout configurations
      enabled_layouts splits,stack,tall,fat,grid,horizontal,vertical

      # Tab bar colors (Solarized Dark)
      active_tab_foreground   #839496
      active_tab_background   #073642
      active_tab_font_style   bold
      inactive_tab_foreground #586e75
      inactive_tab_background #002b36
      inactive_tab_font_style normal

      # Selection colors
      selection_foreground #93a1a1
      selection_background #073642

      # URL colors
      url_color #268bd2
      url_style curly
    '';
  };
}
