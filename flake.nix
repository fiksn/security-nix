{
  description = "Nix Security";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs }:
    with nixpkgs;
    let
      getNixFilesInDir = dir: builtins.filter (file: lib.hasSuffix ".nix" file && file != "default.nix") (builtins.attrNames (builtins.readDir dir));
      genKey = str: lib.replaceStrings [ ".nix" ] [ "" ] str;
      genModValue = dir: str: { config, options, lib, ... }: { imports = [ (dir + "/${str}") ]; };
      oneFrom = gen: dir: str: { "${genKey str}" = gen dir str; };

      modulesFromDir = dir: builtins.foldl' (x: y: x // (oneFrom genModValue dir y)) { } (getNixFilesInDir dir);

      # Get Clouflare ips (v4 or v6 parameter)
      getCFips = ip:
        let file = builtins.fetchurl "https://www.cloudflare.com/ips-${ip}"; in
        pkgs.runCommandLocal "cf-${ip}.list" { }
          ''
            cat ${file} | sed "s|^|allow |g" | sed "s|\$|;|g" > $out
          '';

      nginxCfAllow = let
        a = getCFips "v4";
        b = getCFips "v6";
      in
      pkgs.runCommandLocal "cf.config" { }
        ''
          cat ${a} > $out
          cat ${b} >> $out
          echo 'deny all;' >> $out
        '';

      nginxIpAllow = ips: "\n" + builtins.concatStringsSep "\n" (map (ip: "allow ${ip};") ips) + "\ndeny all;";
    in
    {
      # Modules
      nixosModules = modulesFromDir ./modules;
      nixosModule.looneyHack = import ./looney;

      # Lib
      lib =
        {
          inherit
            nginxCfAllow
            nginxIpAllow
            ;
        };
    };
}
