{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
  ];
  options.programs.sparkle = {
    enable = lib.mkEnableOption "Sparkle";
    package = lib.mkOption {
      type = lib.types.package;
      description = ''
        The sparkle package to use.
      '';
      default = pkgs.sparkle;
      defaultText = lib.literalExpression "pkgs.sparkle";
    };
    tunMode = lib.mkEnableOption "Setcap for TUN Mode. DNS settings won't work on this way";
    autoStart = lib.mkEnableOption "Sparkle auto launch";
  };

  config = let
    cfg = config.programs.sparkle;
  in
    lib.mkIf cfg.enable {
      environment.systemPackages = [
        cfg.package
        (lib.mkIf cfg.autoStart (
          pkgs.makeAutostartItem {
            name = "sparkle";
            package = cfg.package;
          }
        ))
      ];

      security.wrappers.sparkle = lib.mkIf cfg.tunMode {
        owner = "root";
        group = "root";
        capabilities = "cap_net_bind_service,cap_net_raw,cap_net_admin=+ep";
        source = "${lib.getExe cfg.package}";
      };
    };
}
