{
  lib,
  pkgs,
  config,
  NixVirt,
  ...
} @ args: let
  Windows = import ./Oct.nix args;
  Pat = import ./Pat.nix args;
  Linux = import ./Linux.nix args;
in {
  environment = {
    systemPackages = with pkgs; [
      NixVirt.packages.x86_64-linux.default
    ];
  };

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.verbose = true;
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = [
      Windows
      Pat
      Linux
    ];
  };

  virtualisation.libvirtd.hooks.qemu."10-cpu-manager" = pkgs.writeShellScript "cpu-qemu-hook" ''
    machine=$1
    command=$2
    log_tag="libvirt-hook"

    log() {
      ${pkgs.util-linux}/bin/logger -t "$log_tag" "$1"
    }

    log "qemu hook invoked: machine=$machine command=$command"

    if [ "$machine" == "Pat" ]; then

      if [ "$command" == "prepare" ]; then
        log "Pat: preparing - dynamic hugepages (Mageas style) + GPU detach + CPU mask"

        # 1. GPU detach（先做无影响）
        log "Pat: detaching PCI device pci_0000_03_00_1"
        ${pkgs.libvirt}/bin/virsh nodedev-detach --device pci_0000_03_00_1

        # 2. === Mageas 风格动态 hugepages（核心修复）===
        # 从 stdin 读取当前 domain XML，提取内存大小（单位 KiB）
        XML=$(cat)
        VM_MEMORY_KIB=$(echo "$XML" | ${pkgs.libxml2}/bin/xmllint --xpath 'string(//memory[1])' - 2>/dev/null)
        VM_MEMORY_MIB=$(( VM_MEMORY_KIB / 1024 ))

        # 计算需要多少 2MB hugepages
        HUGEPAGES=$(( (VM_MEMORY_MIB / 2) + 64 ))

        log "Pat: VM memory = $VM_MEMORY_MIB MiB → requesting $HUGEPAGES hugepages"

        echo $HUGEPAGES > /proc/sys/vm/nr_hugepages
        ALLOC_PAGES=$(cat /proc/sys/vm/nr_hugepages)
        TRIES=0

        while [ "$ALLOC_PAGES" -ne "$HUGEPAGES" ] && [ "$TRIES" -lt 1000 ]; do
            ${pkgs.coreutils-full}/bin/echo 1 > /proc/sys/vm/compact_memory
            ${pkgs.coreutils-full}/bin/echo $HUGEPAGES > /proc/sys/vm/nr_hugepages
            ALLOC_PAGES=$(cat /proc/sys/vm/nr_hugepages)
            log "Pat: allocated $ALLOC_PAGES / $HUGEPAGES hugepages (try $TRIES)"
            TRIES=$((TRIES + 1))
            ${pkgs.coreutils-full}/bin/sleep 0.05
        done

        if [ "$ALLOC_PAGES" -ne "$HUGEPAGES" ]; then
            log "Pat: FAILED to allocate all hugepages! Reverting..."
            ${pkgs.coreutils-full}/bin/echo 0 > /proc/sys/vm/nr_hugepages
            exit 1
        fi
        log "Pat: hugepages successfully allocated ($ALLOC_PAGES / $HUGEPAGES)"

        # 3. CPU mask
        log "Pat: applying dedicated CPU mask (8-15,24-31)"
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=8-15,24-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=8-15,24-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=8-15,24-31
        log "Pat: dedicated CPU mask applied"
      elif [ "$command" == "started" ]; then
        log "Pat: started, no action taken"
      elif [ "$command" == "stopped" ]; then
        log "Pat: restoring full CPU mask (0-31)"
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- system.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- user.slice AllowedCPUs=0-31
        ${pkgs.systemd}/bin/systemctl set-property --runtime -- init.scope AllowedCPUs=0-31
        log "Pat: full CPU mask restored"

        log "Pat: reattaching PCI device + hugepages cleanup"
        ${pkgs.libvirt}/bin/virsh nodedev-reattach --device pci_0000_03_00_1
        ${pkgs.coreutils-full}/bin/echo 0 > /proc/sys/vm/nr_hugepages
        log "Pat: cleanup done"

      else
        log "Pat: unhandled command=$command"
      fi
    else
      log "ignoring machine=$machine command=$command"
    fi
  '';
}
