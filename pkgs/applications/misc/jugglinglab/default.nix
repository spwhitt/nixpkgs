{stdenv, fetchurl, makeWrapper, jre}:

stdenv.mkDerivation rec {
  name = "jugglinglab-${version}";
  version = "0.6.2";

  src = fetchurl {
    url = "mirror://sourceforge/jugglinglab/Juggling%20Lab/JugglingLab-${version}_other.tar.gz";
    sha1 = "qy2946i8hz26kd49m8la30szqb0r303y";
  };

  phases = [ "unpackPhase" "installPhase" ];

  buildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/lib $out/share/doc/jugglinglab/patterns

    cp bin/JugglingLab.jar $out/lib/JugglingLab.jar

    cp README.html $out/share/doc/jugglinglab
    ln -s README.html $out/share/doc/jugglinglab/index.html
    cp -r html $out/share/doc/jugglinglab
    cp patterns/* $out/share/doc/jugglinglab/patterns

    makeWrapper "${jre}/bin/java" "$out/bin/jugglinglab" \
      --add-flags "-jar $out/lib/JugglingLab.jar"

    makeWrapper "${jre}/bin/java" "$out/bin/jugglinglab-j2" \
      --add-flags "-cp $out/lib/JugglingLab.jar jugglinglab/generator/siteswapGenerator"
  '';

  meta = with stdenv.lib; {
    description = "An application for creating and animating juggling patterns.";
    homepage = http://jugglinglab.sourceforge.net/;
    license = licenses.gpl2;
    maintainers = [ maintainers.spwhitt ];
    platforms = platforms.all;
  };
}
