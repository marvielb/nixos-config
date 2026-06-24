# Install-time: replace this with the hardware-specific parts of
#   nixos-generate-config --root /mnt
# Extract boot.initrd/boot.kernel/hardware.cpu sections only.
# Do NOT copy fileSystems — disko handles that.
{ ... }: {
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
}
