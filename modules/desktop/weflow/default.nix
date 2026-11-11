{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.pharra.weflow;
in {
  options.services.pharra.weflow = {
    enable = mkEnableOption "WeFlow for WeChat";

    package = mkOption {
      type = types.package;
      default = inputs.weflow.packages.${pkgs.system}.default;
      defaultText = literalExpression "inputs.weflow.packages.\${pkgs.system}.default";
      description = "The WeFlow package to install.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package];
  };
}
