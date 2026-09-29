{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.modules.apps;
in
{
  options.modules.apps = {
    enable = lib.mkEnableOption "system-level apps";
    gaming.enable = lib.mkEnableOption "Gaming (Steam + gamescope)";
    docker.enable = lib.mkEnableOption "Rootless Docker";
    vm.enable = lib.mkEnableOption "VM stack (libvirt + virt-manager)";
    vm-user.enable = lib.mkEnableOption "VM qemu:///session stack (libvirt + virt-manager)";
    llm.enable = lib.mkEnableOption "LLM stack (llama.cpp + ROCm)";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.zsh.enable = true;

        programs.git = {
          enable = true;
          config.init.defaultBranch = "main";
        };

        programs.localsend = {
          enable = true;
          openFirewall = true;
        };

        programs.throne = {
          enable = true;
          tunMode.enable = true;
        };
      }

      (lib.mkIf cfg.gaming.enable {

        # steam is sandboxed and declared in home/sandbox.nix

        programs.gamescope.enable = true;

        services.lact.enable = true;

        hardware.graphics.enable32Bit = true;
      })

      (lib.mkIf cfg.docker.enable {

        virtualisation.docker.rootless = {
          enable = true;
          setSocketVariable = true;
          daemon.settings = {
            dns = [
              "9.9.9.9"
              "149.112.112.112"
            ];
          };
        };
      })

      (lib.mkIf cfg.vm.enable {
        programs.virt-manager.enable = true;
        virtualisation.libvirtd.enable = true;
        virtualisation.spiceUSBRedirection.enable = true;

        users.users.${username}.extraGroups = [
          "libvirtd"
          "kvm"
        ];

        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
        };

        networking.firewall.trustedInterfaces = [ "virbr0" ];

        networking.nat = {
          enable = true;
          internalInterfaces = [ "virbr0" ];
          externalInterface = "throne-tun";
          internalIPs = [ "192.168.122.0/24" ];
        };

        networking.localCommands = ''
          ${pkgs.iproute2}/bin/ip rule del to 192.168.122.0/24 lookup main priority 10 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip rule add to 192.168.122.0/24 lookup main priority 10
        '';
      })

      (lib.mkIf cfg.vm-user.enable {
        programs.virt-manager.enable = true;

        environment.systemPackages = with pkgs; [
          libvirt
          qemu_kvm
          passt
          swtpm
        ];

        environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///session";

        environment.etc."qemu/firmware".source = "${pkgs.qemu_kvm}/share/qemu/firmware";
      })

      (lib.mkIf cfg.llm.enable {
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };

        users.users.${username}.extraGroups = [
          "video"
          "render"
        ];

        environment.sessionVariables = {
          HSA_OVERRIDE_GFX_VERSION = "12.0.1";
        };

        environment.systemPackages = with pkgs; [
          (llama-cpp.override { rocmSupport = true; })
          radeontop
          rocmPackages.rocm-smi
        ];
      })
    ]
  );
}
