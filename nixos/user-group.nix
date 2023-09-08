{
  username,
  lib,
  ...
}: {
  nix.settings.trusted-users = [username];

  users.groups = {
    "${username}" = {};
    docker = {};
    wireshark = {};
  };
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${username}" = {
    home = "/home/${username}";
    isNormalUser = true;
    hashedPassword = lib.mkForce "$6$dascadwafasca$fIzpXuQBxDXeCwWKuPgNP/SmIDXtYVcrupQuqcXyeXHGftBFUFWleXPuCsT.rr4FWmZX4QINfrvzh.qtzXS7u0";
    initialHashedPassword = lib.mkForce "$6$dascadwafasca$fIzpXuQBxDXeCwWKuPgNP/SmIDXtYVcrupQuqcXyeXHGftBFUFWleXPuCsT.rr4FWmZX4QINfrvzh.qtzXS7u0";
    description = username;
    extraGroups = [
      username
      "users"
      "networkmanager"
      "wheel"
      "docker"
      "wireshark"
      "adbusers"
      "libvirtd"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCmgVNooueTbeIrn5trgQEI8Z+hfvYR/mTheAd58vSSYA6DgyQduqdCdiZ9EuQRA48BCwmKlW1n7px8QkNMq9pOldBjhe+8U9xeOc78Pjf2ixVBc9cVQF4sIxm5nWTFcZfzUjKk4jOlL/NMenp94NOyVwuc9a/OugSxYv+8Yz/UY5fT3WHBIdoaUjN7xKesi8gwtRRAOd/X/pXjTnc3a/CpqIoXtw3V+L4GD0JnFNAjjDjrehoVwFfi/WxZNPLQGiDLpO8izwsyJTSwYwLfx7A6pozNwbN4TokWQSY1/o4sqLyIRywHJvM7KZSzBvNYpVrRLh+i87xzsM9RDecnbpG5FDSpZVADSrbpU8iAvV0A6TgcnTIlrSt7payf0A9w0bNKob8LByoTAQEwMGnSQbNGpiQZ5mhcz/KI2EbD0jYxCv7K/aXbkfyZbtepEzvYLkTwBxyL/Y4OvrNxo7XBrwDmdCTk5NtkzSnTkenSf2uGxn2C1Kb753EamH1k/Jqw4+E= bytem@WF-DESKTOP"
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
      ];
    }
  ];
}
