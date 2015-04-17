{ callPackage, ... } @ args:

callPackage ./generic.nix ( args // {
  # Version for sequential machines
  name = "superlu";
  version = "4.3";
  hash = "10b785s9s4x0m9q7ihap09275pq4km3k2hk76jiwdfdr5qr2168n";
})
