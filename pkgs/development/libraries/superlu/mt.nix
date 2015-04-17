{ callPackage, ... } @ args:

callPackage ./generic.nix ( args // {
  name = "superlu_mt";
  version = "2.4";
  hash = "0xv308d3fqc28h230wysxqkk77hrx5fr4k5hrv60h0a0bahlz00p";
})
