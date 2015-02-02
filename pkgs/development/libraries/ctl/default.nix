{ stdenv, cmake, fetchFromGitHub, ilmbase, openexr }:

stdenv.mkDerivation rec {
  name = "ctl-${version}";
  version = "1.5.2";

  src = fetchFromGitHub {
    owner = "ampas";
    repo = "CTL";
    rev = "ctl-${version}";
    sha256 = "0a698rd1cmixh3mk4r1xa6rjli8b8b7dbx89pb43xkgqxy67glwx";
  };

  buildInputs = [ cmake ];

  propagatedBuildInputs = [ ilmbase openexr ];

  meta = with stdenv.lib; {
    description = "Color Transformation Language";
    longdescription = ''
    '';
    homepage = https://github.com/ampas/CTL;
    license = licenses.free;
    platforms = platforms.unix;
    maintainers = [ maintainers.spwhitt ];
  };
}
