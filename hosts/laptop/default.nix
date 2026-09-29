{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";

  services.power-profiles-daemon.enable = true;

  modules = {
    hardware.intel.enable = true;
    hardware.es8336.enable = true;
    hardware.yubikey.lockOnRemove = true;
    desktop.hyprland.monitors = [
      {
        output = "eDP-1";
        mode = "2160x1440@60";
        position = "auto";
        scale = "1";
      }
    ];
    apps.vm-user.enable = true;
    apps.gaming.enable = true;

    hardening.kernel.strict.enable = true;
  };
}
