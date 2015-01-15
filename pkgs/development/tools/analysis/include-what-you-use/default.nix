{ stdenv, fetchurl, llvmPackages, ncurses, cmake, makeWrapper, pythonPackages }:

stdenv.mkDerivation rec {
  name    = "include-what-you-use-${version}";
  version = "3.4";

  src = fetchurl {
    url    = "http://include-what-you-use.com/downloads/include-what-you-use-${version}.src.tar.gz";
    sha256 = "196h4v05pqwgpvf0v5wck2bd6b0a45rkg9nh6blc8146biqjrkvk";
  };

  buildInputs = [ cmake ncurses llvmPackages.clang llvmPackages.llvm pythonPackages.wrapPython ];

  patchPhase = ''
    substituteInPlace CMakeLists.txt --replace curses ncurses
  '';

  checkPhase = ''
    pushd ..
    PATH=build:$PATH ${pythonPackages.python}/bin/python run_iwyu_tests.py
    PATH=build:$PATH ${pythonPackages.python}/bin/python fix_includes_test.py
    popd
  '';

  postInstall = ''
    substitute ../fix_includes.py $out/bin/fix_includes.py \
       --replace "#!/usr/bin/python" "#!${pythonPackages.python}/bin/python"
    chmod +x $out/bin/fix_includes.py
  '';

  doCheck = false;

  postFixup = ''
    wrapPythonPrograms
  '';

  cmakeFlags=["-DLLVM_PATH=${llvmPackages.llvm}"];

  meta = {
    description = "A tool for use with clang to analyze #includes in C and C++ source";
    longdescription = ''
      "Include what you use" means this: for every symbol (type, function
      variable, or macro) that you use in foo.cc, either foo.cc or foo.h should
      #include a .h file that exports the declaration of that symbol. The
      include-what-you-use tool is a program that can be built with the clang
      libraries in order to analyze #includes of source files to find
      include-what-you-use violations, and suggest fixes for them.
      
      The main goal of include-what-you-use is to remove superfluous #includes. It
      does this both by figuring out what #includes are not actually needed for this
      file (for both .cc and .h files), and replacing #includes with forward-declares
      when possible.
    '';
    homepage    = "https://code.google.com/p/include-what-you-use/";
    license     = stdenv.lib.licenses.ncsa;
    platforms   = stdenv.lib.platforms.unix;
    maintainers = [ stdenv.lib.maintainers.spwhitt ];
  };
}
