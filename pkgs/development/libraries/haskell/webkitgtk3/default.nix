# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, cairo, glib, gtk2hsBuildtools, gtk3, mtl, pango, text
, webkit
}:

cabal.mkDerivation (self: {
  pname = "webkitgtk3";
  version = "0.13.1.1";
  sha256 = "0lm52xsgf3sayj5d32fyf9fy89zinn7c4z6rq4qw2bsnsdw8hcyb";
  buildDepends = [ cairo glib gtk3 mtl pango text ];
  buildTools = [ gtk2hsBuildtools ];
  pkgconfigDepends = [ webkit ];
  meta = {
    homepage = "http://projects.haskell.org/gtk2hs/";
    description = "Binding to the Webkit library";
    license = self.stdenv.lib.licenses.lgpl21;
    platforms = self.stdenv.lib.platforms.linux;
  };
})
