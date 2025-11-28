{ config, pkgs, lib, ... }:

{
  # Import community rule sets for external keyboard use
  xdg.configFile = {
    "karabiner/assets/complex_modifications/windows_shortcuts_on_macos.json".source = 
      pkgs.fetchurl {
        url = "https://ke-complex-modifications.pqrs.org/json/windows_shortcuts_on_macos.json";
        sha256 = "61605f7d4e9890cbad3608588477ffdd5e3324c62a3ee9be734507eab836a9c5";
      };
    
    "karabiner/assets/complex_modifications/microsoft_natural_keyboard_4000.json".source = 
      pkgs.fetchurl {
        url = "https://ke-complex-modifications.pqrs.org/json/Microsoft_Natural_keyboard_4000.json";
        sha256 = "f8372146723fe11bf7b0374550ea8b9d8c9f18687de1fa9cbafcba069d72d56c";
      };
  };

  # Karabiner-Elements configuration with profile switching
  xdg.configFile."karabiner/karabiner.json" = {
    force = true;
    text = builtins.toJSON {
      global = {
        ask_for_confirmation_before_quitting = false;
        check_for_updates_on_startup = true;
        show_in_menu_bar = true;
        show_profile_name_in_menu_bar = true;
        unsafe_ui = false;
      };
      
      profiles = [
        {
          name = "Default (Laptop - Native macOS)";
          selected = true;
          virtual_hid_keyboard = {
            keyboard_type = "ansi";
            keyboard_type_v2 = "ansi";
            mouse_key_xy_scale = 100;
          };
          devices = [];
          # No complex modifications = native macOS behavior
          complex_modifications = {
            parameters = {
              "basic.simultaneous_threshold_milliseconds" = 50;
              "basic.to_delayed_action_delay_milliseconds" = 500;
              "basic.to_if_alone_timeout_milliseconds" = 1000;
              "basic.to_if_held_down_threshold_milliseconds" = 500;
              "mouse_motion_to_scroll.speed" = 100;
            };
            rules = [];
          };
          fn_function_keys = [
            {
              from = { key_code = "f1"; };
              to = [ { consumer_key_code = "display_brightness_decrement"; } ];
            }
            {
              from = { key_code = "f2"; };
              to = [ { consumer_key_code = "display_brightness_increment"; } ];
            }
            {
              from = { key_code = "f3"; };
              to = [ { key_code = "mission_control"; } ];
            }
            {
              from = { key_code = "f4"; };
              to = [ { key_code = "launchpad"; } ];
            }
            {
              from = { key_code = "f5"; };
              to = [ { key_code = "illumination_decrement"; } ];
            }
            {
              from = { key_code = "f6"; };
              to = [ { key_code = "illumination_increment"; } ];
            }
            {
              from = { key_code = "f7"; };
              to = [ { consumer_key_code = "rewind"; } ];
            }
            {
              from = { key_code = "f8"; };
              to = [ { consumer_key_code = "play_or_pause"; } ];
            }
            {
              from = { key_code = "f9"; };
              to = [ { consumer_key_code = "fast_forward"; } ];
            }
            {
              from = { key_code = "f10"; };
              to = [ { consumer_key_code = "mute"; } ];
            }
            {
              from = { key_code = "f11"; };
              to = [ { consumer_key_code = "volume_decrement"; } ];
            }
            {
              from = { key_code = "f12"; };
              to = [ { consumer_key_code = "volume_increment"; } ];
            }
          ];
        }
        {
          name = "External Keyboard (Windows Shortcuts)";
          selected = false;
          virtual_hid_keyboard = {
            keyboard_type = "ansi";
            keyboard_type_v2 = "ansi";
            mouse_key_xy_scale = 100;
          };
          devices = [
            {
              # Microsoft Natural Ergonomic Keyboard 4000
              disable_built_in_keyboard_if_exists = true;
              identifiers = { 
                is_keyboard = true; 
                product_id = 219; 
                vendor_id = 1118; 
              };
              ignore = false;
              manipulate_caps_lock_led = true;
              simple_modifications = [];
            }
          ];
          complex_modifications = {
            parameters = {
              "basic.simultaneous_threshold_milliseconds" = 50;
              "basic.to_delayed_action_delay_milliseconds" = 500;
              "basic.to_if_alone_timeout_milliseconds" = 1000;
              "basic.to_if_held_down_threshold_milliseconds" = 500;
              "mouse_motion_to_scroll.speed" = 100;
            };
            rules = [
              # Note: The actual rules will be loaded from the imported JSON files
              # Users need to manually enable them in Karabiner-Elements preferences:
              # 1. Open Karabiner-Elements preferences
              # 2. Go to "Complex Modifications" tab
              # 3. Click "Add rule" 
              # 4. Import from "Windows shortcuts on macOS"
              # 5. Import from "Microsoft Natural keyboard 4000"
              # 6. Make sure they're enabled in the "External Keyboard" profile
            ];
          };
          fn_function_keys = [
            {
              from = { key_code = "f1"; };
              to = [ { consumer_key_code = "display_brightness_decrement"; } ];
            }
            {
              from = { key_code = "f2"; };
              to = [ { consumer_key_code = "display_brightness_increment"; } ];
            }
            {
              from = { key_code = "f3"; };
              to = [ { key_code = "mission_control"; } ];
            }
            {
              from = { key_code = "f4"; };
              to = [ { key_code = "launchpad"; } ];
            }
            {
              from = { key_code = "f5"; };
              to = [ { key_code = "illumination_decrement"; } ];
            }
            {
              from = { key_code = "f6"; };
              to = [ { key_code = "illumination_increment"; } ];
            }
            {
              from = { key_code = "f7"; };
              to = [ { consumer_key_code = "rewind"; } ];
            }
            {
              from = { key_code = "f8"; };
              to = [ { consumer_key_code = "play_or_pause"; } ];
            }
            {
              from = { key_code = "f9"; };
              to = [ { consumer_key_code = "fast_forward"; } ];
            }
            {
              from = { key_code = "f10"; };
              to = [ { consumer_key_code = "mute"; } ];
            }
            {
              from = { key_code = "f11"; };
              to = [ { consumer_key_code = "volume_decrement"; } ];
            }
            {
              from = { key_code = "f12"; };
              to = [ { consumer_key_code = "volume_increment"; } ];
            }
          ];
        }
      ];
    };
  };
}
