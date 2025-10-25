{
  lib,
  pkgs,
  ...
}: {
  ###################################################################################
  #
  #  NixOS's core configuration suitable for my desktop computer
  #
  ###################################################################################

  imports = [
    ./core-server.nix
    ./input-method
    ./flatpak.nix
  ];

  # to install chrome, you need to enable unfree packages
  nixpkgs.config.allowUnfree = lib.mkForce true;

  # Select internationalisation properties.
  i18n.defaultLocale = lib.mkForce "zh_CN.UTF-8";

  i18n.extraLocaleSettings = lib.mkForce {
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

  # windows dual boot
  time.hardwareClockInLocalTime = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable vscode server
  programs.nix-ld.enable = true;

  fonts = {
    # use fonts specified by user rather than default ones
    enableDefaultPackages = false;
    fontDir.enable = true;

    packages = with pkgs; [
      # icon fonts
      font-awesome
      noto-fonts-emoji # 彩色的表情符号字体

      # 思源系列字体是 Adobe 主导的。其中汉字部分被称为「思源黑体」和「思源宋体」，是由 Adobe + Google 共同开发的
      source-sans # 无衬线字体，不含汉字。字族名叫 Source Sans 3 和 Source Sans Pro，以及带字重的变体，加上 Source Sans 3 VF
      source-serif # 衬线字体，不含汉字。字族名叫 Source Code Pro，以及带字重的变体

      # nerdfonts
      nerd-fonts.symbols-only
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka

      sarasa-gothic
    ];

    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig.defaultFonts = {
      serif = ["Sarasa UI SC" "Noto Color Emoji"];
      sansSerif = ["Sarasa UI SC" "Noto Color Emoji"];
      monospace = ["Sarasa Mono SC" "JetBrainsMono Nerd Font" "Noto Color Emoji"];
      emoji = ["Noto Color Emoji"];
    };
  };

  # dconf is a low-level configuration system.
  programs.dconf.enable = true;

  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
  systemd.services.NetworkManager-wait-online.enable = false;

  # PipeWire is a new low-level multimedia framework.
  # It aims to offer capture and playback for both audio and video with minimal latency.
  # It support for PulseAudio-, JACK-, ALSA- and GStreamer-based applications.
  # PipeWire has a great bluetooth support, it can be a good alternative to PulseAudio.
  #     https://nixos.wiki/wiki/PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };
  services.audio-relay.enable = true;
  # rtkit is optional but recommended
  security.rtkit.enable = true;
  # Disable pulseaudio, it conflicts with pipewire too.
  services.pulseaudio.enable = false;

  # enable bluetooth & gui paring tools - blueman
  # or you can use cli:
  # $ bluetoothctl
  # [bluetooth] # power on
  # [bluetooth] # agent on
  # [bluetooth] # default-agent
  # [bluetooth] # scan on
  # ...put device in pairing mode and wait [hex-address] to appear here...
  # [bluetooth] # pair [hex-address]
  # [bluetooth] # connect [hex-address]
  # Bluetooth devices automatically connect with bluetoothctl as well:
  # [bluetooth] # trust [hex-address]
  hardware.bluetooth.enable = true;
  # services.blueman.enable = true;

  # security with polkit
  security.polkit.enable = true;
  # security with gnome-kering
  services.gnome.gnome-keyring.enable = true;

  # A key remapping daemon for linux.
  # https://github.com/rvaiya/keyd
  services.keyd = {
    enable = true;
    keyboards.default.settings = {
      main = {
        # overloads the capslock key to function as both escape (when tapped) and control (when held)
        # capslock = "overload(control, esc)";
        home = "pause";
      };
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
      # fix some flatpak apps not apply font config in KDE Plasma
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  environment.systemPackages = with pkgs; [
    # YubiKey
    yubikey-personalization # CLI tools for configuring YubiKey
    yubikey-manager # Manage YubiKey settings
    yubioath-flutter # GUI for managing YubiKey
    yubikey-agent
    libfido2 # Support for FIDO2/WebAuthn
    opensc # Smart card support
    gnupg # If using GPG with YubiKey
    pcsclite
  ];

  hardware.gpgSmartcards.enable = true;

  services = {
    udev.packages = with pkgs; [yubikey-personalization];
    pcscd.enable = true;
    yubikey-agent.enable = true;
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  nix.settings = {
    substituters = [
      # replace official cache with a mirror located in China
      "https://attic.int4byte.org:8443/nix"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
    ];

    trusted-public-keys = [
      "nix:TIuZSOR7smXF/Jz1UKnvY5TW+NvklDypmDEg57QYU08="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
}
