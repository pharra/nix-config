{
  config,
  lib,
  username,
  ...
}:
with lib; let
  cfg = config.services.pharra.user-group;
in {
  options = {
    services.pharra.user-group = {
      enable = mkEnableOption "user group configuration";
    };
  };

  config = mkIf cfg.enable {
    nix.settings.trusted-users = [username];

    users.groups = {
      "${username}" = {
        gid = 1000;
      };
      users = {
        gid = 100;
      };
      docker = {};
      wireshark = {};
    };
    # Define a user account. Don't forget to set a password with 'passwd'.
    users.users."${username}" = {
      home = "/home/${username}";
      isNormalUser = true;
      initialHashedPassword = lib.mkForce "$6$569jdPP15dvw4JDf$enDHnDIKO3UUo3bFdOow5ugnzsksJmAeUpcrKIUKjFh5gB5fZWvknDdVsuYG/n/fPdReo5d3Iw2vKMMXtTq1u.";
      description = username;
      uid = 1000;
      # required for auto start before user login
      linger = true;
      # required for rootless container with multiple users
      autoSubUidGidRange = true;
      extraGroups = [
        username
        "users"
        "networkmanager"
        "wheel"
        "wireshark"
        "adbusers"
        "libvirtd"
        "video"
        "docker"
        "input"
        "uinput"
        "render"
      ];
      openssh.authorizedKeys.keys = [
        # win desktop
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCmgVNooueTbeIrn5trgQEI8Z+hfvYR/mTheAd58vSSYA6DgyQduqdCdiZ9EuQRA48BCwmKlW1n7px8QkNMq9pOldBjhe+8U9xeOc78Pjf2ixVBc9cVQF4sIxm5nWTFcZfzUjKk4jOlL/NMenp94NOyVwuc9a/OugSxYv+8Yz/UY5fT3WHBIdoaUjN7xKesi8gwtRRAOd/X/pXjTnc3a/CpqIoXtw3V+L4GD0JnFNAjjDjrehoVwFfi/WxZNPLQGiDLpO8izwsyJTSwYwLfx7A6pozNwbN4TokWQSY1/o4sqLyIRywHJvM7KZSzBvNYpVrRLh+i87xzsM9RDecnbpG5FDSpZVADSrbpU8iAvV0A6TgcnTIlrSt7payf0A9w0bNKob8LByoTAQEwMGnSQbNGpiQZ5mhcz/KI2EbD0jYxCv7K/aXbkfyZbtepEzvYLkTwBxyL/Y4OvrNxo7XBrwDmdCTk5NtkzSnTkenSf2uGxn2C1Kb753EamH1k/Jqw4+E= bytem@WF-DESKTOP"

        # gs65
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINc9ycN0bbSJAecPk42xXmJhraP6f54eawQ98dhHvNWG wf@gs65"

        # homelab
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsMIjAmPitKTYN83DxrN/D783BTMkknEuwMeO5s0ABw wf@homelab"

        # desktop
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhrg8hAISAafIIPiiUOmcFqH1X26dfUtSssJDEShwsU wf@desktop"

        # zed
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAlUm683W8j3fmwb3akIqDSyfHbbKiqK8OdSb5RTxYYS wf@zed"

        # dot
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJPEM85nVwDf6Gvxj6/VsEy8rZDSCjYMlpck4Ndd43t wf@dot"
      ];
    };

    # DO NOT promote the specified user to input password for `nix-store` and `nix-copy-closure`
    security.sudo.extraRules = [
      {
        users = [username];
        commands = [
          {
            command = "/run/current-system/sw/bin/nix-store";
            options = ["NOPASSWD"];
          }
          {
            command = "/run/current-system/sw/bin/nix-copy-closure";
            options = ["NOPASSWD"];
          }
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
