{ stdenv, fetchurl, name, version, hash, meta ? {}, ... }:

# Notes:
# This only builds a static library
# This does not build matlab
# Extra header files may be installed: it's not clear which are needed

stdenv.mkDerivation {
  name = "${name}-${version}";

  src = fetchurl {
    url = "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/${name}_${version}.tar.gz";
    sha256 = hash;
  };

  preBuild = ''
    makeFlagsArray=(
      # Build directory
      SuperLUroot=`pwd`
      # Don't append any suffix to library names
      PLAT=
      # BLAS library to use: use superlu's for now
      BLASLIB=`pwd`/lib/libblas.a
      # Use builtin blas. Something like -DUSE_VENDOR_PLAS
      BLASDEF=
      # Compiler to use
      CC=clang

      # Targets
      all blaslib
    )
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include $out/share/doc
    cp lib/*.a $out/lib
    cp SRC/*.h $out/include
    cp -r DOC/* $out/share/doc/
  '';

  meta = with stdenv.lib; {
    description = "Solver of large, sparse, nonsymmetric linear equations";

    longDescription = ''
      General purpose library for the direct solution of large, sparse,
      nonsymmetric systems of linear equations on high performance
      machines
    '';

    homepage = "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/";
    license = licenses.bsd3;
    maintainers = [ maintainers.spwhitt ];
    platforms = platforms.unix;
  } // meta;
}
