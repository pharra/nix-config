{
  config,
  pkgs,
  lib,
  domain ? false,
  deploy-rs ? false,
  ...
}: let
  username = "wf";
in {
  imports = [
    # Include the results of the hardware scan.
    ./system.nix

    ./sever

    ../../secrets/nixos.nix
  ];

  # enable flakes globally
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 1d";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = ["tcp_bbr"];
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # test user doesn't have a password
  services.openssh.settings.PasswordAuthentication = false;
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    # deploy-rs.packages.x86_64-linux.default
  ];

  users.users."${username}" = {
    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    # description = "Azure NixOS Test User";
    openssh.authorizedKeys.keys = [
      # win desktop
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCmgVNooueTbeIrn5trgQEI8Z+hfvYR/mTheAd58vSSYA6DgyQduqdCdiZ9EuQRA48BCwmKlW1n7px8QkNMq9pOldBjhe+8U9xeOc78Pjf2ixVBc9cVQF4sIxm5nWTFcZfzUjKk4jOlL/NMenp94NOyVwuc9a/OugSxYv+8Yz/UY5fT3WHBIdoaUjN7xKesi8gwtRRAOd/X/pXjTnc3a/CpqIoXtw3V+L4GD0JnFNAjjDjrehoVwFfi/WxZNPLQGiDLpO8izwsyJTSwYwLfx7A6pozNwbN4TokWQSY1/o4sqLyIRywHJvM7KZSzBvNYpVrRLh+i87xzsM9RDecnbpG5FDSpZVADSrbpU8iAvV0A6TgcnTIlrSt7payf0A9w0bNKob8LByoTAQEwMGnSQbNGpiQZ5mhcz/KI2EbD0jYxCv7K/aXbkfyZbtepEzvYLkTwBxyL/Y4OvrNxo7XBrwDmdCTk5NtkzSnTkenSf2uGxn2C1Kb753EamH1k/Jqw4+E= bytem@WF-DESKTOP"

      # microsoft
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCspSa4xNqqAq+0fgJ5udLDRSgqTEYMVhi03auCPhGBpJC1XDrz49Gp6sO1SujJPbR66KXhUUAmPQgKwveyaTVZYf9g/zZUH0fOljFaZchxYuaRsFdDI1iBak5mqeOtJc84nVXqTGaZIjydz1F5905bJzB+PLAOZUC/79/niJE9FwdKjNN1opAOMmnVvP1PXoYpBwjcqYXBx3kuA/KYztdy8A49iHbDd0JXMp82DQPPA4tHYvvI/aneA0ixXO3EsGn537iX8Z4IrBeSWtneX848a+01A0zcj67AdXdoRlWyVXy7VhGmkfaKIWn3k5dUD9xDMVDhiD213jZrJVaTTAkAmWPp0SZtV89U2rstvmgEGNs2YJq/h/NfNg7sz6f9AQpjub9krU3Hk8keIBLMZkHFhxDHE0w4Oec5/Vf5bwSQqB036bd3Ss7cMsKTrcbr5xxbUuikLzFZ5+/g0WFph1TQANoCCpgpnAclWhqwu1Z3Oi4G2SXRogSZXLeqTEGJaV8= redmond\wangf@WF-MICROSOFT-DESKTOP"

      # microsoft nixos vm
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCIqe5ZtZeyfKNVoqplh9QlnZ2TicQlJzTmnk9oEmmfRU6VsNkVh7B0jdMZ9TBiPKTO53cqDHS0mwquJK8VbhuCTTpLpO7T6EyS1VgHKfU6Do1ogZz3Bo2YbZ9ZW71ao5dGPjGhlk08qI6F078qa4lp/de2uUTiBn8/FtRLZiG7amFWmduDcnRIqu/mczhvqJYbHuh+WH0Ggx90dJ0OZvUk7LyGaRTE6S8fjvF6e0BpHBLPvkvpmOos5x8342INpjls8OezPzLbhEgr0dbMrbINVbwR8XKIwtmALSeZgiAEvdzq/JO3uIhezrfoWr6SqqouwyVuTs76xJJH38u8fXHn"

      # homelab
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDO/MVQ2jBtTwjqFsr1HpZeAcp9LE14g7FZEH9xaI5jq+9SFoSJF3GcFi15T7HxRtQ9l/CEaTVVbEbvIEynORVIfo9qR6vJYS7OyWt//rorIVCWyYsfEVLkX1vbq/wIe5aaWXHt8ePZy3up2bAewFok8z4wRYq2vhP5yI9/WckqKFWdZQ5+7CXJEdpec3ye5+G3Q+VgkHb4ZzjjgPbeoWp9tpFh5LVw+Trw3gyI9TxsXnWZUKD/v/mirNodAFN6O0owkqbo1fvAAfLM7U02mHIxJ1jc0DrCGUm4hVR9oRGcmPlsjT9D0oILkHt0LDPhmnWw4o0iyZZPtp3AcacJvb33wRy2VOUrkGjn2e8JwLSB68tXrrmk0ashFie3kFkumpf5lMnqSB5RLG1t+C9yP5S7ge7Usndphwe+vUgeNGNKfPmFdV+jEl2gi8GuIX99UGIHZCcwaGCqnELH00rSTPbGmBoGNaAZU6FHDloMrHqwhuR85kpQow7aBMu7APou7B8= wf@homelab"
    ];
  };

  users.defaultUserShell = pkgs.zsh;

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

  networking.firewall.enable = lib.mkForce false;

  # nix.settings.trusted-users = [ username ];
  nix.settings.trusted-users = ["@wheel"];
}
