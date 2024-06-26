# security-nix [![Daily build](https://github.com/fiksn/security-nix/actions/workflows/daily.yml/badge.svg)](https://github.com/fiksn/security-nix/actions/workflows/daily.yml) [![tippin.me](https://badgen.net/badge/%E2%9A%A1%EF%B8%8Ftippin.me/@fiksn/F0918E)](https://tippin.me/@fiksn)
A collection of [nix](https://nixos.org/) modules for running a secure NixOS server

You might want to import:
```
<nixpkgs/nixos/modules/profiles/hardened.nix>
```

## Hostfw

Hostfw is a module for managing the firewall. Using this simple abstraction you can open a certain UDP or TCP port for a list of trusted IPs instead of
having to call low-level code (like directly calling `iptables` or modifying `networking.firewall.extraCommands`)

### Usage

```
imports = [ ./hostfw.nix ];

# networking.firewall.allowedTCPPorts = [ 80 443 ];
services.hostfw = {
  enable = true;
  tcpPortAllowIpList = [
    { port = 80; ips = trustedIps; }
    { port = 443; ips = trustedIps; }
  ];
};
```

## Disablemod

I had trouble with `security.lockKernelModules`. Without that set to false `boot.blacklistedKernelModules` does not prevent
a particular module to be loaded.

### Usage

```
import = [ ./disablemod.nix ];
services.disablemod = {
  enable = true;
  modules = with config.services.disablemod; cisRecommendedModules ++ cisNoUsbRecommendedModules;
};
```

## Nginx [Cloudflare](https://www.cloudflare.com/)

This is used to allow traffic just from [Cloudflare](https://www.cloudflare.com/) [IPs](https://www.cloudflare.com/ips/).

### Usage

```
virtualHosts."demo.local" = {
      locations."/" = {
        extraConfig = ''
          include ${security.lib.nginxCfAllow pkgs};
        ''
      };
};
```

## CVE-2023-4911: Looney Tunables - Local Privilege Escalation workaround

This was forked from https://github.com/NixOS/nixpkgs/pull/259039

### Usage

```
outputs = { self, nixpkgs, security }:
{
  nixosConfigurations = {
    "server" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ... ] ++ [ security.nixosModule.looneyHack ];
    };
  };
};
```
