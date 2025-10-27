{
  lib,
  pkgs,
  deploy-rs,
  config,
  ...
}: {
  ###################################################################################
  #
  #  NixOS's core configuration suitable for all my machines
  #
  ###################################################################################

  # for nix server, we do not need to keep too much generations
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
  # boot.loader.grub.configurationLimit = 10;

  boot.kernelPackages = lib.mkOverride 1400 pkgs.linuxPackages_6_16;

  hardware.enableRedistributableFirmware = true;
  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # enable ccache in sandbox
  # nix.settings.extra-sandbox-paths = ["/var/cache/ccache"];

  # Manual optimise storage: nix-store --optimise
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  nix.settings.auto-optimise-store = true;

  # enable flakes globally
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = lib.mkDefault true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = lib.mkDefault true;
  # allow all incoming ipv4 traffic, since this is a homelab behind a router firewall
  networking.firewall.extraCommands = lib.mkIf (config.networking.nftables.enable != true) "iptables -A INPUT -j ACCEPT";
  networking.nftables.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "no"; # disable root login
      PasswordAuthentication = true; # enable password login
    };
    openFirewall = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    deploy-rs.packages.x86_64-linux.default
    nmap
    wget
    curl
    lshw
    git # used by nix flakes
    git-lfs # used by huggingface models
    fastfetch
    pv
    pciutils # lspci
    usbutils # lsusb
    nvme-cli # nvme tools
    rclone
    # create a fhs environment by command `fhs`, so we can run non-nixos packages in nixos!
    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
        pkgs.buildFHSEnv (base
          // {
            name = "fhs";
            targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [pkgs.pkg-config];
            profile = "export FHS=1";
            runScript = "zsh";
            extraOutputsToInstall = ["dev"];
          })
    )
  ];

  security.pam.loginLimits = [
    {
      domain = "*";
      item = "memlock";
      type = "soft";
      value = "unlimited";
    }
    {
      domain = "*";
      item = "memlock";
      type = "hard";
      value = "unlimited";
    }
    {
      domain = "root";
      item = "memlock";
      type = "soft";
      value = "unlimited";
    }
    {
      domain = "root";
      item = "memlock";
      type = "hard";
      value = "unlimited";
    }
  ];

  # add user's shell into /etc/shells
  environment.shells = with pkgs; [
    bash
    zsh
  ];
  # set user's default shell system-wide
  users.defaultUserShell = pkgs.zsh;

  networking.timeServers = ["ntp.aliyun.com"];

  # zsh configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    vteIntegration = true;
    histSize = 1048576;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      plugins = [
        "docker"
        "git"
        "golang"
        "systemd"
        "git-auto-fetch"
        "history-substring-search"
      ];
      theme = "candy";
    };
  };

  # for power management
  # services.upower.enable = true;
  # powerManagement.enable = true;
}
