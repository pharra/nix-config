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
    ./fcitx5.nix
    ./flatpak.nix
  ];

  # to install chrome, you need to enable unfree packages
  nixpkgs.config.allowUnfree = lib.mkForce true;

  # windows dual boot
  time.hardwareClockInLocalTime = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # all fonts are linked to /nix/var/nix/profiles/system/sw/share/X11/fonts
  fonts = {
    # use fonts specified by user rather than default ones
    enableDefaultPackages = false;
    fontDir.enable = true;

    packages = with pkgs; [
      # icon fonts
      material-design-icons
      font-awesome

      # Noto 系列字体是 Google 主导的，名字的含义是「没有豆腐」（no tofu），因为缺字时显示的方框或者方框被叫作 tofu
      # Noto 系列字族名只支持英文，命名规则是 Noto + Sans 或 Serif + 文字名称。
      # 其中汉字部分叫 Noto Sans/Serif CJK SC/TC/HK/JP/KR，最后一个词是地区变种。
      noto-fonts # 大部分文字的常见样式，不包含汉字
      # noto-fonts-cjk # 汉字部分
      noto-fonts-emoji # 彩色的表情符号字体
      noto-fonts-extra # 提供额外的字重和宽度变种

      sarasa-gothic

      # 思源系列字体是 Adobe 主导的。其中汉字部分被称为「思源黑体」和「思源宋体」，是由 Adobe + Google 共同开发的
      source-sans # 无衬线字体，不含汉字。字族名叫 Source Sans 3 和 Source Sans Pro，以及带字重的变体，加上 Source Sans 3 VF
      source-serif # 衬线字体，不含汉字。字族名叫 Source Code Pro，以及带字重的变体
      #source-han-sans # 思源黑体
      #source-han-serif # 思源宋体
      source-han-sans-simplified-chinese
      source-han-sans-traditional-chinese

      # nerdfonts
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "JetBrainsMono"
          "Iosevka"
        ];
      })
    ];

    # user defined fonts
    # the reason there's Noto Color Emoji everywhere is to override DejaVu's
    # B&W emojis that would sometimes show instead of some Color emojis
    fontconfig = {
      defaultFonts = {
        emoji = ["Noto Color Emoji"];
        monospace = [
          "Noto Sans Mono CJK SC"
          "Sarasa Mono SC"
          "DejaVu Sans Mono"
        ];
        sansSerif = [
          "Noto Sans CJK SC"
          "Source Han Sans SC"
          "DejaVu Sans"
        ];
        serif = [
          "Noto Serif CJK SC"
          "Source Han Serif SC"
          "DejaVu Serif"
        ];
      };
      #       localConf = ''
      # <?xml version="1.0"?>
      # <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      # <fontconfig>
      #   <its:rules xmlns:its="http://www.w3.org/2005/11/its" version="1.0">
      #     <its:translateRule
      #       translate="no"
      #       selector="/fontconfig/*[not(self::description)]"
      #     />
      #   </its:rules>

      #   <description>Android Font Config</description>

      #   <!-- Font directory list -->

      #   <dir>/usr/share/fonts</dir>
      #   <dir>/usr/local/share/fonts</dir>
      #   <dir prefix="xdg">fonts</dir>
      #   <!-- the following element will be removed in the future -->
      #   <dir>~/.fonts</dir>

      #   <!-- Disable embedded bitmap fonts -->
      #   <match target="font">
      #     <edit name="embeddedbitmap" mode="assign">
      #       <bool>false</bool>
      #     </edit>
      #   </match>

      #   <!-- English uses Roboto and Noto Serif by default, terminals use DejaVu Sans Mono. -->
      #   <match>
      #     <test qual="any" name="family">
      #       <string>serif</string>
      #     </test>
      #     <edit name="family" mode="prepend" binding="strong">
      #       <string>Noto Serif</string>
      #     </edit>
      #   </match>
      #   <match target="pattern">
      #     <test qual="any" name="family">
      #       <string>sans-serif</string>
      #     </test>
      #     <edit name="family" mode="prepend" binding="strong">
      #       <string>Roboto</string>
      #     </edit>
      #   </match>
      #   <match target="pattern">
      #     <test qual="any" name="family">
      #       <string>monospace</string>
      #     </test>
      #     <edit name="family" mode="prepend" binding="strong">
      #       <string>DejaVu Sans Mono</string>
      #     </edit>
      #   </match>

      #   <!-- Chinese uses Source Han Sans and Source Han Serif by default, not Noto Sans CJK SC, since it will show Japanese Kanji in some cases. -->
      #   <match>
      #     <test name="lang" compare="contains">
      #       <string>zh</string>
      #     </test>
      #     <test name="family">
      #       <string>serif</string>
      #     </test>
      #     <edit name="family" mode="prepend">
      #       <string>Source Han Serif CN</string>
      #     </edit>
      #   </match>
      #   <match>
      #     <test name="lang" compare="contains">
      #       <string>zh</string>
      #     </test>
      #     <test name="family">
      #       <string>sans-serif</string>
      #     </test>
      #     <edit name="family" mode="prepend">
      #       <string>Source Han Sans CN</string>
      #     </edit>
      #   </match>
      #   <match>
      #     <test name="lang" compare="contains">
      #       <string>zh</string>
      #     </test>
      #     <test name="family">
      #       <string>monospace</string>
      #     </test>
      #     <edit name="family" mode="prepend">
      #       <string>Noto Sans Mono CJK SC</string>
      #     </edit>
      #   </match>

      #   <!-- Windows & Linux Chinese fonts. -->
      #   <!-- Map all the common fonts onto Source Han Sans/Serif, so that they will be used when Source Han Sans/Serif are not installed. This solves a situation where some programs asked for a font, and under the non-existance of the font, it will not use the fallback font, which caused abnormal display of Chinese characters. -->
      #   <match target="pattern">
      #     <test qual="any" name="family">
      #       <string>WenQuanYi Zen Hei</string>
      #     </test>
      #     <edit name="family" mode="assign" binding="same">
      #       <string>Source Han Sans CN</string>
      #     </edit>
      #   </match>
      #   <match target="pattern">
      #     <test qual="any" name="family">
      #       <string>WenQuanYi Micro Hei</string>
      #     </test>
      #     <edit name="family" mode="assign" binding="same">
      #       <string>Source Han Sans CN</string>
      #     </edit>
      #   </match>
      #   <match target="pattern">
      #     <test qual="any" name="family">
      #       <string>WenQuanYi Micro Hei Light</string>
      #     </test>
      #     <edit name="family" mode="assign" binding="same">
      #       <string>Source Han Sans CN</string>
      #     </edit>
      #   </match>
      #   <match target="pattern">
      #     <test qual="any" name="family">
      #       <string>Microsoft YaHei</string>
      #     </test>
      #     <edit name="family" mode="assign" binding="same">
      #       <string>Source Han Sans CN</string>
      #     </edit>
      #   </match>
      #   <match target="pattern">
      #     <test qual="any" name="family">
      #       <string>SimHei</string>
      #     </test>
      #     <edit name="family" mode="assign" binding="same">
      #       <string>Source Han Sans CN</string>
      #     </edit>
      #   </match>
      #   <match target="pattern">
      #     <test qual="any" name="family">
      #       <string>SimSun</string>
      #     </test>
      #     <edit name="family" mode="assign" binding="same">
      #       <string>Source Han Serif CN</string>
      #     </edit>
      #   </match>
      #   <match target="pattern">
      #     <test qual="any" name="family">
      #       <string>SimSun-18030</string>
      #     </test>
      #     <edit name="family" mode="assign" binding="same">
      #       <string>Source Han Serif CN</string>
      #     </edit>
      #   </match>

      #   <!-- Load local system customization file -->
      #   <include ignore_missing="yes">conf.d</include>

      #   <!-- Font cache directory list -->

      #   <cachedir>/var/cache/fontconfig</cachedir>
      #   <cachedir prefix="xdg">fontconfig</cachedir>
      #   <!-- the following element will be removed in the future -->
      #   <cachedir>~/.fontconfig</cachedir>

      #   <config>
      #     <!-- Rescan configurations every 30 seconds when FcFontSetList is called -->
      #     <rescan>
      #       <int>30</int>
      #     </rescan>
      #   </config>
      # </fontconfig>
      #       '';
    };
  };

  # dconf is a low-level configuration system.
  programs.dconf.enable = true;

  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # The OpenSSH agent remembers private keys for you
  # so that you don’t have to type in passphrases every time you make an SSH connection.
  # Use `ssh-add` to add a key to the agent.
  programs.ssh.startAgent = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # python, some times I may need to use python with root permission.
    # (python310.withPackages (ps:
    #   with ps; [
    #     ipython
    #     pandas
    #     requests
    #     pyquery
    #     pyyaml
    #   ]))
  ];

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
  # rtkit is optional but recommended
  security.rtkit.enable = true;
  # Remove sound.enable or turn it off if you had it set previously, it seems to cause conflicts with pipewire
  sound.enable = false;
  # Disable pulseaudio, it conflicts with pipewire too.
  hardware.pulseaudio.enable = false;

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
  # services.power-profiles-daemon = {
  #   enable = true;
  # };
  security.polkit.enable = true;
  # security with gnome-kering
  # services.gnome.gnome-keyring.enable = true;
  # security.pam.services.greetd.enableGnomeKeyring = true;

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

  # xdg.portal = {
  #   enable = true;
  #   wlr.enable = true;
  #   # Sets environment variable NIXOS_XDG_OPEN_USE_PORTAL to 1
  #   # This will make xdg-open use the portal to open programs,
  #   # which resolves bugs involving programs opening inside FHS envs or with unexpected env vars set from wrappers.
  #   # xdg-open is used by almost all programs to open a unknown file/uri
  #   # alacritty as an example, it use xdg-open as default, but you can also custom this behavior
  #   # and vscode has open like `External Uri Openers`
  #   xdgOpenUsePortal = false;
  #   extraPortals = with pkgs; [
  #     xdg-desktop-portal-wlr # for wlroots based compositors(hyprland/sway)
  #     # xdg-desktop-portal-gtk # for gtk
  #     # xdg-desktop-portal-kde  # for kde
  #   ];
  # };

  # add user's shell into /etc/shells
  environment.shells = with pkgs; [
    bash
    zsh
  ];
  # set user's default shell system-wide
  users.defaultUserShell = pkgs.zsh;
}
