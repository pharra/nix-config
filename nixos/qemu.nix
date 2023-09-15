{
  lib,
  pkgs,
  config,
  libs,
  ...
}: let
  swtpm-scripts = pkgs.writeShellScriptBin "swtpm-scripts" ''
    ${pkgs.swtpm}/bin/swtpm socket --ctrl type=unixio,path=/run/libvirt/qemu/swtpm/18-microsoft-swtpm.sock,mode=0600 --tpmstate dir=/var/lib/libvirt/swtpm/9ff0da6a-1699-4041-81d1-2e4e47e207ba/tpm2,mode=0600 --log file=/var/log/swtpm/libvirt/qemu/microsoft-swtpm.log --terminate --tpm2
  '';

  qemu-scripts = pkgs.writeShellScriptBin "qemu-scripts" ''
    ${pkgs.qemu}/bin/qemu-system-x86_64 -name guest=microsoft,debug-threads=on \
    -cpu host \
    -enable-kvm \
    -smp 4 \
    -m 4G -object memory-backend-file,id=mem0,size=4G,mem-path=/dev/hugepages,share=on,prealloc=yes, -numa node,memdev=mem0 \
    -bios /run/libvirt/nix-ovmf/OVMF_CODE.fd \
    -device vfio-user-pci,socket=/var/run/cntrl \
    -machine pc-q35-8.1 \
    -nic user,model=virtio-net-pci \
    -vnc :0
  '';
in {
  environment.systemPackages = with pkgs; [
    swtpm-scripts
    qemu-scripts
  ];

  #   systemd.services.spdk = {
  #     enable = true;
  #     wantedBy = ["multi-user.target"];
  #     after = ["rdma.service" "network.target"];
  #     requires = ["rdma.service"];
  #     description = "Starts the spdk_tgt";
  #     path = [pkgs.kmod pkgs.gawk pkgs.util-linux];
  #     serviceConfig = {
  #       Type = "simple";
  #       Environment = "PCI_ALLOWED='none'";
  #       ExecStartPre = ''
  #         ${pkgs.spdk}/scripts/setup.sh
  #         ${pkgs.kmod}/bin/modprobe ublk_drv
  #       '';
  #       ExecStart = ''${pkgs.spdk}/bin/spdk_tgt -m 0x30003 -c /home/wf/spdk/rdma_config.json -f /var/run/spdk.pid -S /var/run'';
  #     };
  #   };
}
