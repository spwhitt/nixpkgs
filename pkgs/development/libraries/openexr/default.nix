{ stdenv, fetchurl, pkgconfig, zlib, ilmbase }:

stdenv.mkDerivation rec {
  name = "openexr-${version}";
  version = "2.2.0";
  
  src = fetchurl {
    url = "mirror://savannah/openexr/openexr-${version}.tar.gz";
    sha256 = "0ca2j526n4wlamrxb85y2jrgcv0gf21b3a19rr0gh4rjqkv1581n";
  };
  
  buildInputs = [ pkgconfig ];
  
  propagatedBuildInputs = [ zlib ilmbase ];
  
  configureFlags = "--enable-imfexamples";
  
  meta = with stdenv.lib; {
    description = "High dynamic-range image file format developed by Industrial Light & Magic for use in computer imaging applications.";
    homepage = http://www.openexr.com;
    license = licenses.bsd3;
    platforms = platforms.unix;
    maintainers = [ maintainers.swhitt ];
  };
}
