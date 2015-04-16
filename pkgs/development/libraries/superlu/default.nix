{stdenv, fetchurl}:

# Notes:
# This only builds a static library
# This does not build matlab or doc
# This does not build blaslib (make blaslib)
# Extra header files may be installed: it's not clear which are needed

stdenv.mkDerivation rec {
  name = "superlu-${version}";
  version = "4.3";

  src = fetchurl {
    url = "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/superlu_${version}.tar.gz";
    sha256 = "10b785s9s4x0m9q7ihap09275pq4km3k2hk76jiwdfdr5qr2168n";
  };

  preBuild = ''
    makeFlagsArray=(
      # Build directory
      SuperLUroot=`pwd`
      # Don't append any suffix to library names
      PLAT=
      # BLAS library to use: use superlu's for now
      BLASLIB=`pwd`/lib/libblas.a
      # Something like -DUSE_VENDOR_PLAS
      BLASDEF=
      # Compiler to use
      CC=clang
    )
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include
    cp lib/libsuperlu_4.3.a $out/lib
    cp SRC/*.h $out/include
  '';

  meta = with stdenv.lib; {
    description = "General purpose library for the direct solution of large, sparse, nonsymmetric systems of linear equations on high performance machines";
    homepage = "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/";
    license = licenses.bsd3;
    maintainers = [ maintainers.spwhitt ];
    platforms = platforms.unix;
  };
}
