self: super:
let fetchpatch = (import super.path { }).fetchpatch; in
{
  glibc-patched = super.glibc.overrideAttrs (old: rec {
    pname = builtins.replaceStrings ["glibc"] ["glibc-patched"] old.pname;
    patches = old.patches ++ [
      (fetchpatch {
        name = "CVE-2023-4911.patch";
        url = "https://sourceware.org/git/?p=glibc.git;a=commitdiff_plain;h=1056e5b4c3f2d90ed2b4a55f96add28da2f4c8fa;hp=0d5f9ea97f1b39f2a855756078771673a68497e1";
        hash = "sha256-3J55jF0I7AUHyh8QAFCDcBCpfymmnlgrlMcSM1/dM6I=";
        excludes = [ "*tst-env-setuid-tunables.c*" ];
      })
    ];
  });
}
