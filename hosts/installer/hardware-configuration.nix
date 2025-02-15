{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  iscsi-scripts = pkgs.writeShellScriptBin "iscsi-scripts" ''
    ${pkgs.openiscsi}/bin/iscsiadm -m discovery -t sendtargets -p homelab.local
    ${pkgs.openiscsi}/bin/iscsiadm -m node -p homelab.local --targetname=iqn.2016-06.io.spdk:nixos --login
    mount /dev/sda2 /mnt
    mount /dev/sda1 /mnt/boot/efi
  '';

  nvme-scripts = pkgs.writeShellScriptBin "nvme-scripts" ''
    nvme discover -t tcp -a 192.168.29.1 -s 4420
    nvme connect -t tcp -n "nqn.2016-06.io.spdk:nixos" -a 192.168.29.1 -s 4420
    mount /dev/nvme0n1p2 /mnt
    mount /dev/nvme0n1p1 /mnt/boot/efi
  '';
in {
  imports = [
    (modulesPath + "/installer/netboot/netboot-minimal.nix")
  ];

  services = {
    openiscsi = {
      enable = true;
      name = "iqn.2020-08.org.linux-iscsi.initiatorhost:installer";
    };
  };

  hardware.mlx4 = {
    enable = true;
    enableSRIOV = false;
  };

  virtualisation.vfio = {
    enable = true;
    IOMMUType = "intel";
    applyACSpatch = false;
  };

  environment.systemPackages = with pkgs; [
    rsync
    git
    iscsi-scripts
    nvme-cli
    nvme-scripts
  ];

  boot.initrd.kernelModules = ["nvme-rdma" "nvme-tcp"];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."nixos" = {
    initialHashedPassword = lib.mkForce "$6$569jdPP15dvw4JDf$enDHnDIKO3UUo3bFdOow5ugnzsksJmAeUpcrKIUKjFh5gB5fZWvknDdVsuYG/n/fPdReo5d3Iw2vKMMXtTq1u.";
    openssh.authorizedKeys.keys = [
      # win desktop
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCmgVNooueTbeIrn5trgQEI8Z+hfvYR/mTheAd58vSSYA6DgyQduqdCdiZ9EuQRA48BCwmKlW1n7px8QkNMq9pOldBjhe+8U9xeOc78Pjf2ixVBc9cVQF4sIxm5nWTFcZfzUjKk4jOlL/NMenp94NOyVwuc9a/OugSxYv+8Yz/UY5fT3WHBIdoaUjN7xKesi8gwtRRAOd/X/pXjTnc3a/CpqIoXtw3V+L4GD0JnFNAjjDjrehoVwFfi/WxZNPLQGiDLpO8izwsyJTSwYwLfx7A6pozNwbN4TokWQSY1/o4sqLyIRywHJvM7KZSzBvNYpVrRLh+i87xzsM9RDecnbpG5FDSpZVADSrbpU8iAvV0A6TgcnTIlrSt7payf0A9w0bNKob8LByoTAQEwMGnSQbNGpiQZ5mhcz/KI2EbD0jYxCv7K/aXbkfyZbtepEzvYLkTwBxyL/Y4OvrNxo7XBrwDmdCTk5NtkzSnTkenSf2uGxn2C1Kb753EamH1k/Jqw4+E= bytem@WF-DESKTOP"

      # microsoft
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCspSa4xNqqAq+0fgJ5udLDRSgqTEYMVhi03auCPhGBpJC1XDrz49Gp6sO1SujJPbR66KXhUUAmPQgKwveyaTVZYf9g/zZUH0fOljFaZchxYuaRsFdDI1iBak5mqeOtJc84nVXqTGaZIjydz1F5905bJzB+PLAOZUC/79/niJE9FwdKjNN1opAOMmnVvP1PXoYpBwjcqYXBx3kuA/KYztdy8A49iHbDd0JXMp82DQPPA4tHYvvI/aneA0ixXO3EsGn537iX8Z4IrBeSWtneX848a+01A0zcj67AdXdoRlWyVXy7VhGmkfaKIWn3k5dUD9xDMVDhiD213jZrJVaTTAkAmWPp0SZtV89U2rstvmgEGNs2YJq/h/NfNg7sz6f9AQpjub9krU3Hk8keIBLMZkHFhxDHE0w4Oec5/Vf5bwSQqB036bd3Ss7cMsKTrcbr5xxbUuikLzFZ5+/g0WFph1TQANoCCpgpnAclWhqwu1Z3Oi4G2SXRogSZXLeqTEGJaV8= redmond\wangf@WF-MICROSOFT-DESKTOP"

      # microsoft nixos vm
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCIqe5ZtZeyfKNVoqplh9QlnZ2TicQlJzTmnk9oEmmfRU6VsNkVh7B0jdMZ9TBiPKTO53cqDHS0mwquJK8VbhuCTTpLpO7T6EyS1VgHKfU6Do1ogZz3Bo2YbZ9ZW71ao5dGPjGhlk08qI6F078qa4lp/de2uUTiBn8/FtRLZiG7amFWmduDcnRIqu/mczhvqJYbHuh+WH0Ggx90dJ0OZvUk7LyGaRTE6S8fjvF6e0BpHBLPvkvpmOos5x8342INpjls8OezPzLbhEgr0dbMrbINVbwR8XKIwtmALSeZgiAEvdzq/JO3uIhezrfoWr6SqqouwyVuTs76xJJH38u8fXHn"

      # gs65
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINc9ycN0bbSJAecPk42xXmJhraP6f54eawQ98dhHvNWG wf@gs65"

      # homelab
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPsMIjAmPitKTYN83DxrN/D783BTMkknEuwMeO5s0ABw wf@homelab"

      # desktop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPhrg8hAISAafIIPiiUOmcFqH1X26dfUtSssJDEShwsU wf@desktop"
    ];
  };

  boot.kernelParams = lib.mkForce ["nogpumanager" "nvidia_drm.modeset=0" "console=ttyS0"];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkForce false;

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks = {
      # Configure the bridge for its desired function
      "40-eth" = {
        matchConfig.Name = "!enp0s3*";
        bridgeConfig = {};
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;
          MulticastDNS = true;
          Domains = ["local"];
        };
        dhcpV4Config = {
          UseDomains = true;
        };
        ipv6AcceptRAConfig = {
          UseDNS = true;
          UseDomains = true;
        };
        linkConfig = {
          # or "routable" with IP addresses configured
          RequiredForOnline = "routable";
          Multicast = true;
        };
      };
    };
  };

  services.resolved = {
    extraConfig = ''
      MulticastDNS=yes
    '';
    enable = true;
  };
}
