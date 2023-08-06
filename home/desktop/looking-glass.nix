{
  pkgs,
  config,
  lib,
  ...
}:
{
  xdg.configFile."looking-glass/client.ini".text = lib.generators.toINI {} {
    app.shmFile = "/dev/kvmfr0";
    #input.escapeKey = 119;
    input.rawMouse = "yes";
    spice.enable = "yes";
    win.autoScreensaver = "yes";
    win.fullScreen = "yes";
    win.jitRender = "yes";
    wayland.fractionScale="no";
    wayland.warpSupport="no";
    # win.quickSplash = "yes";
  };
}
