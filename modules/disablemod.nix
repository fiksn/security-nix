{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.disablemod;
  cisRecommendation = [ "freevxfs" "jffs2" "hfs" "hfsplus" "udf" "sctp" "dccp" "rds" "tipc" ];
  cisNoUsbRecommendation = [ "msdos" "vfat" "fat" ];
in
{
  options.services.disablemod = {
    enable = mkEnableOption {
      type = types.bool;
      default = false;
      description = ''
        Enable disablemod
      '';
    };

    modules = mkOption {
      type = types.listOf types.str;
      default = config.boot.blacklistedKernelModules;
      example = [ "cirrusfb" "i2c_piix4" ];
      description = ''
        List of names of kernel modules that should not be loaded
        automatically by the hardware probing code.
      '';
    };

    cisRecommendedModules = mkOption {
      type = types.listOf types.str;
      readOnly = true;
      description = ''
        Read-only list of names of kernel modules that should not be loaded
        (defaults from CIS benchmark)
      '';
    };

    cisNoUsbRecommendedModules = mkOption {
      type = types.listOf types.str;
      readOnly = true;
      description = ''
        Read-only list of names of kernel modules that should not be loaded
        (defaults from CIS benchmark when disabling USB)
      '';
    };

  };

  config = {
    # Always available
    services.disablemod.cisRecommendedModules = cisRecommendation;
    services.disablemod.cisNoUsbRecommendedModules = cisNoUsbRecommendation;

    # Only when cfg.enable == true (some ugly trickery)
    security.lockKernelModules = mkIf cfg.enable (mkOverride false);
    environment.etc."modprobe.d/disablemod.conf".text =
      if cfg.enable then
        ''
          ${flip concatMapStrings cfg.modules (name: ''
            install ${name} /bin/true
          '')}
          ${
            # Noop - not sure how to else force evaluation, tried builtins.seq, without this readOnly will have no effect
            if length cfg.cisRecommendedModules > 0 then "" else ""
          }
          ${
            # Noop - not sure how to else force evaluation, tried builtins.seq, without this readOnly will have no effect
            if length cfg.cisNoUsbRecommendedModules > 0 then "" else ""
          }
        '' else "";
  };
}
