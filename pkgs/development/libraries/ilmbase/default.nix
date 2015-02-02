{stdenv, fetchurl}:

stdenv.mkDerivation rec {
  name = "ilmbase-${version}";
  version = "2.2.0";
  
  src = fetchurl {
    url = "mirror://savannah/openexr/ilmbase-${version}.tar.gz";
    sha256 = "1izddjwbh1grs8080vmaix72z469qy29wrvkphgmqmcm0sv1by7c";
  };

  meta = with stdenv.lib; {
    description = "Base libraries from ILM for OpenEXR";
    homepage = http://www.openexr.com;
    license = licenses.bsd3;
    platforms = platforms.unix;
    maintainers = [ maintainers.spwhitt ];
  };
}
