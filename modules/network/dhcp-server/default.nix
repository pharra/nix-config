# DHCP 服务器（dnsmasq）：选项在 options.nix，实现在 config.nix。
{...}: {
  imports = [
    ./options.nix
    ./config.nix
  ];
}
