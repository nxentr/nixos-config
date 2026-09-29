{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.hardware.yubikey;
in
{
  options.modules.hardware.yubikey = {
    enable = lib.mkEnableOption "YubiKey support";
    pam.enable = lib.mkEnableOption "U2F login/doas/hyprlock authentication";
    lockOnRemove = lib.mkEnableOption "lock the session when the YubiKey is unplugged";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.pcscd.enable = true;
        services.udev.packages = [
          pkgs.yubikey-personalization
          pkgs.libfido2
        ];

        environment.systemPackages = with pkgs; [
          yubikey-manager
          pam_u2f
        ];
      }

      (lib.mkIf cfg.pam.enable {
        security.pam.u2f = {
          enable = true;
          control = "sufficient";
          settings = {
            cue = true;
            origin = "pam://nixos-config";
            appid = "pam://nixos-config";
          };
        };
      })

      (lib.mkIf cfg.lockOnRemove {
        systemd.services.yubikey-lock = {
          serviceConfig.Type = "oneshot";
          script = "${pkgs.systemd}/bin/loginctl lock-sessions";
        };

        services.udev.extraRules = ''
          ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{PRODUCT}=="1050/*", RUN+="${pkgs.systemd}/bin/systemctl --no-block start yubikey-lock.service"
        '';
      })
    ]
  );
}
