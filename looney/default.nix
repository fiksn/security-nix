{ config, lib, pkgs, ... }:

with lib;
{
  config = {
     nixpkgs.overlays = [ (import ./glibc.nix) ];
     environment.systemPackages = [ pkgs.glibc-patched ];
  };

  imports = [ ./workaround ];
  disabledModules = [ "security/wrappers/default.nix" ];
}
