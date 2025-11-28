{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.hostfw;
  likelyIpv6 = str: builtins.match "^.*:.*$" str != null;

  tcpRules = if cfg.tcpPortAllowIpList == null then "" else builtins.concatStringsSep "\n" (map (x: (commands "tcp" x.port x.ips)) cfg.tcpPortAllowIpList);
  udpRules = if cfg.udpPortAllowIpList == null then "" else builtins.concatStringsSep "\n" (map (x: (commands "udp" x.port x.ips)) cfg.udpPortAllowIpList);

  commands = mode: port: ips: builtins.concatStringsSep "\n" (map (ip: command mode port ip) ips);

  command = mode: port: ip:
    if likelyIpv6 ip then
      ''
        ip6tables -A nixos-fw -p ${mode} --src ${ip} --dport ${toString port} -j nixos-fw-accept
      ''
    else
      ''
        iptables -A nixos-fw -p ${mode} --src ${ip} --dport ${toString port} -j nixos-fw-accept
      '';
in
{
  options.services.hostfw = {
    enable = mkEnableOption "host firewall";

    tcpPortAllowIpList = mkOption {
      default = null;
      type = types.nullOr (types.listOf (
        types.submodule {
          options = {
            port = mkOption {
              type = types.port;
              description = "Port Number";
            };

            ips = mkOption {
              type = types.listOf lib.types.str;
              description = "IP addresses";
            };
          };
        }
      ));
    };

    udpPortAllowIpList = mkOption {
      default = null;
      type = types.nullOr (types.listOf (
        types.submodule {
          options = {
            port = mkOption {
              type = types.port;
              description = "Port Number";
            };

            ips = mkOption {
              type = types.listOf lib.types.str;
              description = "IP addresses";
            };
          };
        }
      ));
    };

  };

  config = mkIf cfg.enable {
    networking.firewall.extraCommands = tcpRules + udpRules;
  };
}
