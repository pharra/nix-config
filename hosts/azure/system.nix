{
  pkgs,
  modulesPath,
  ...
}: let
  username = "wf";
in {
  imports = [
    "${modulesPath}/virtualisation/azure-common.nix"
    "${modulesPath}/virtualisation/azure-image.nix"
  ];

  ## NOTE: This is just an  example of how to hard-code a
  ##       user.
  ##
  ## The  normal Azure  agent  IS included  and
  ## DOES  provision   a  user  based   on  the
  ## information passed at VM creation time.
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
  # nix.settings.trusted-users = [ username ];
  nix.settings.trusted-users = ["@wheel"];

  virtualisation.azureImage.diskSize = 2500;

  system.stateVersion = "23.05";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # test user doesn't have a password
  services.openssh.settings.PasswordAuthentication = false;
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    freeswitch
  ];

  services.freeswitch = {
    enable = true;

    # using `configTemplate` default (i.e., vanilla)
    # https://nixos.org/nixos/options.html#freeswitch.configtemplate

    # Should be named `overrideTemplateConfigFiles`
    # TODO add this comment to freeswitch.nix in nix.land
    # TODO homework: write function that takes an attribute set or list and evaluates it recursively

    # configDir =
    #   # TODO Is this how to properly prefix paths? So confused:
    #   # https://toraritte.github.io/posts/2020-08-13-paths-vs-string-in-nix.html
    #   let fs = ./tr2-image/freeswitch-vanilla-config-overrides;
    #   in
    #   # nix-repl> d = dir: a.mapAttrs' (name: value: a.nameValuePair ( dir + "/${name}" ) (value))
    #   # nix-repl> d "freeswitch" (a.recursiveUpdate { "main.xml" = 9; } (d "auto" { "pre.xml" = 1; "another.conf.xml" = 2; }))
    #   # { "freeswitch/auto/another.conf.xml" = 2; "freeswitch/auto/pre.xml" = 1; "freeswitch/main.xml" = 9; }
    #   {
    #     "autoload_configs/pre_load_modules.conf.xml" = fs + /
    #   }
  };
}
# For the `configDir` option this example is given:
#
# ```text
# {
#   "freeswitch.xml" = ./freeswitch.xml;
#   "dialplan/default.xml" = pkgs.writeText "dialplan-default.xml" ''
#     [xml lines]
#   '';
# }
# ```
#
# How does this evaluate exactly? The first attribute's value is a local path, while the second one creates a file in the store. The way I understand it, the files in the keys will be replaced by the content of the path values.
#
# + where does `pkgs.writeText` create the file?
# + how is the file in the template config dir substituted with the new values?
#
# See the source of `writeText` in `<nixpkgs-root>pkgs/build-support/trivial-builders.nix` (search for `writeText =`).

