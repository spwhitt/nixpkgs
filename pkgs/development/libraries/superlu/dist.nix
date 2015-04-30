{ callPackage, lib, ... } @ args:

callPackage ./generic.nix ( args // {
  name = "superlu_dist";
  version = "4.0";
  hash = "09s6r86akm7z41151yrdvlar2iix5py7vyj4fvaab6qp44djn5iq";
  meta.description = "For distributed memory machines";
  # Does not build on Darwin for some reason
  meta.platforms = lib.platforms.linux;
})
