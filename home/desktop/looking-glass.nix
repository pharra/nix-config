{
  pkgs,
  config,
  lib,
  ...
}: {
  xdg.configFile."looking-glass/client.ini".text = lib.generators.toINI {} {
    app.shmFile = "/dev/kvmfr0";
    input.escapeKey = 100; # key pause
    # input.rawMouse = "yes";
    # spice.enable = "yes";
    # win.autoScreensaver = "yes";
    win.fullScreen = "yes";
    win.jitRender = "yes";
    win.fpsMin = 120;
    # wayland.fractionScale = "no";
    # wayland.warpSupport = "no";
    # win.quickSplash = "yes";
    audio.micDefault = "allow";
  };
}
