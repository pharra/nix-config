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
      # win desktop
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCmgVNooueTbeIrn5trgQEI8Z+hfvYR/mTheAd58vSSYA6DgyQduqdCdiZ9EuQRA48BCwmKlW1n7px8QkNMq9pOldBjhe+8U9xeOc78Pjf2ixVBc9cVQF4sIxm5nWTFcZfzUjKk4jOlL/NMenp94NOyVwuc9a/OugSxYv+8Yz/UY5fT3WHBIdoaUjN7xKesi8gwtRRAOd/X/pXjTnc3a/CpqIoXtw3V+L4GD0JnFNAjjDjrehoVwFfi/WxZNPLQGiDLpO8izwsyJTSwYwLfx7A6pozNwbN4TokWQSY1/o4sqLyIRywHJvM7KZSzBvNYpVrRLh+i87xzsM9RDecnbpG5FDSpZVADSrbpU8iAvV0A6TgcnTIlrSt7payf0A9w0bNKob8LByoTAQEwMGnSQbNGpiQZ5mhcz/KI2EbD0jYxCv7K/aXbkfyZbtepEzvYLkTwBxyL/Y4OvrNxo7XBrwDmdCTk5NtkzSnTkenSf2uGxn2C1Kb753EamH1k/Jqw4+E= bytem@WF-DESKTOP"
      
      # microsoft
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCspSa4xNqqAq+0fgJ5udLDRSgqTEYMVhi03auCPhGBpJC1XDrz49Gp6sO1SujJPbR66KXhUUAmPQgKwveyaTVZYf9g/zZUH0fOljFaZchxYuaRsFdDI1iBak5mqeOtJc84nVXqTGaZIjydz1F5905bJzB+PLAOZUC/79/niJE9FwdKjNN1opAOMmnVvP1PXoYpBwjcqYXBx3kuA/KYztdy8A49iHbDd0JXMp82DQPPA4tHYvvI/aneA0ixXO3EsGn537iX8Z4IrBeSWtneX848a+01A0zcj67AdXdoRlWyVXy7VhGmkfaKIWn3k5dUD9xDMVDhiD213jZrJVaTTAkAmWPp0SZtV89U2rstvmgEGNs2YJq/h/NfNg7sz6f9AQpjub9krU3Hk8keIBLMZkHFhxDHE0w4Oec5/Vf5bwSQqB036bd3Ss7cMsKTrcbr5xxbUuikLzFZ5+/g0WFph1TQANoCCpgpnAclWhqwu1Z3Oi4G2SXRogSZXLeqTEGJaV8= redmond\wangf@WF-MICROSOFT-DESKTOP"

      # microsoft nixos vm
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCIqe5ZtZeyfKNVoqplh9QlnZ2TicQlJzTmnk9oEmmfRU6VsNkVh7B0jdMZ9TBiPKTO53cqDHS0mwquJK8VbhuCTTpLpO7T6EyS1VgHKfU6Do1ogZz3Bo2YbZ9ZW71ao5dGPjGhlk08qI6F078qa4lp/de2uUTiBn8/FtRLZiG7amFWmduDcnRIqu/mczhvqJYbHuh+WH0Ggx90dJ0OZvUk7LyGaRTE6S8fjvF6e0BpHBLPvkvpmOos5x8342INpjls8OezPzLbhEgr0dbMrbINVbwR8XKIwtmALSeZgiAEvdzq/JO3uIhezrfoWr6SqqouwyVuTs76xJJH38u8fXHn"
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
