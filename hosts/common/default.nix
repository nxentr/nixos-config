{
  pkgs,
  lib,
  username,
  ...
}:
{
  imports = [
    ./nix.nix
    ./locale.nix
    ../../modules/nixos
  ];

  nixpkgs.config.allowUnfree = false;
  nixpkgs.config.allowUnfreePackages = [
    "steam"
    "steam-unwrapped"
    "steam-run"
    "steam-sandboxed"
    "claude-code"
    "claude-sandboxed"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.cleanOnBoot = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  modules = {
    hardware.audio.enable = true;
    desktop.enable = true;
    desktop.hyprland.enable = true;
    networking.enable = true;
    apps.enable = true;

    hardening = {
      kernel.basic.enable = true;
      network.enable = true;
      modules.enable = true;
    };
    hardware.yubikey = {
      enable = true;
      pam.enable = true;
    };
  };

  services.printing.enable = false;
  services.speechd.enable = lib.mkForce false;
  services.geoclue2.enable = false;

  security.sudo.enable = false;
  security.doas = {
    enable = true;
    extraRules = [
      {
        users = [ username ];
        keepEnv = false;
        persist = true;
      }
    ];
  };

  security.protectKernelImage = true;

  programs.command-not-found.enable = false;
  systemd.oomd.enable = false;

  documentation.nixos.enable = false;
  documentation.info.enable = false;

  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
    DefaultTimeoutStartSec = "15s";
  };

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
    ];
  };

  system.stateVersion = "26.11";
}
