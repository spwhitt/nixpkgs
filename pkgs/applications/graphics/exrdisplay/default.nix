{ stdenv, fetchurl, pkgconfig, fltk, openexr, mesa, which, ctl}:

assert fltk.glSupport;

stdenv.mkDerivation rec {
  name = "openexr_viewers-${version}";
  version = "2.2.0";

  src = fetchurl {
    url =  "mirror://savannah/openexr/openexr_viewers-${version}.tar.gz";
    sha256 = "1s84vnas12ybx8zz0jcmpfbk9m4ab5bg2d3cglqwk3wys7jf4gzp";
  };

  configurePhase =
    ''
      # don't know why.. adding these flags it works
      #export CXXFLAGS=`fltk-config --use-gl --cxxflags --ldflags`
      ./configure --prefix=$out --with-fltk-config=${fltk}/bin/fltk-config
    '';

  buildInputs = [ openexr fltk pkgconfig mesa which ctl ];

  meta = with stdenv.lib; { 
    description = "Tool to view OpenEXR images";
    homepage = http://openexr.com;
    license = licenses.bsd3;
    maintainers = [ maintainers.spwhitt ];
    platforms = platforms.unix;
  };
}
