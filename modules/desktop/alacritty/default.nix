{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.alacritty;
  alacrittyConfig = ''
    [general]
    import = [
      "~/.config/alacritty/dank-theme.toml"
    ]

    [window]
    decorations = "None"
    padding = { x = 12, y = 12 }
    opacity = ${builtins.toJSON cfg.opacity}

    [scrolling]
    history = 3023

    [cursor]
    style = { shape = "Block", blinking = "On" }
    blink_interval = 500
    unfocused_hollow = true

    [mouse]
    hide_when_typing = true

    [selection]
    save_to_clipboard = false

    [bell]
    duration = 0

    [keyboard]
    bindings = [
      { key = "C",       mods = "Control|Shift", action = "Copy"  },
      { key = "V",       mods = "Control|Shift", action = "Paste" },
      { key = "N",       mods = "Control|Shift", action = "SpawnNewInstance" },
      { key = "Equals",  mods = "Control|Shift", action = "IncreaseFontSize" },
      { key = "Minus",   mods = "Control",       action = "DecreaseFontSize" },
      { key = "Key0",    mods = "Control",       action = "ResetFontSize" },
      { key = "Enter",   mods = "Shift",         chars = "\n" },
    ]
  '';
in {
  options.services.pharra.alacritty = {
    enable = mkEnableOption "Alacritty configuration";

    opacity = mkOption {
      type = types.addCheck types.float (opacity: opacity >= 0.0 && opacity <= 1.0);
      default = 1.0;
      description = "Alacritty window opacity, between 0.0 and 1.0.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [pkgs.alacritty];

    hjem.extraModules = [
      ({config, ...}:
        mkIf (config.user == username) {
          xdg.config.files."alacritty/alacritty.toml".text = alacrittyConfig;
        })
    ];
  };
}
