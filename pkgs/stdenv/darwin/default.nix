{ system      ? builtins.currentSystem
, allPackages ? import ../../top-level/all-packages.nix
, platform    ? null
, config      ? {}
}:

let
  fetch = { file, sha256 }: import <nix/fetchurl.nix> {
    url = "https://dl.dropboxusercontent.com/u/361503/${file}";
    inherit sha256;
    executable = true;
  };

  bootstrapFiles = {
    sh    = fetch { file = "sh";    sha256 = "1amnaql1rc6fdsxyav7hmhj8ylf4ccmgsl7v23x4sgw94pkipz78"; };
    bzip2 = fetch { file = "bzip2"; sha256 = "1f4npmrhx37jnv90by8b39727cam3n811lvglsc6da9xm80g2f5l"; };
    mkdir = fetch { file = "mkdir"; sha256 = "0x9jqf4rmkykbpkybp40x4d0v0dq99i0r5yk8096mjn1m7s7xa0p"; };
    cpio  = fetch { file = "cpio";  sha256 = "1a5s8bs14jhhmgrf4cwn92iq8sbz40qhjzj7y35ri84prp9clkc3"; };
  };
  tarball = fetch { file = "bootstrap-tools.7.cpio.bz2"; sha256 = "0yxn6bjiasw28qll6wnsjy3cx5ci069ryrx6mws9zabs6yvv605h"; };
in rec {
  allPackages = import ../../top-level/all-packages.nix;

  commonPreHook = ''
    export NIX_ENFORCE_PURITY=1
    export NIX_IGNORE_LD_THROUGH_GCC=1
    export NIX_DONT_SET_RPATH=1
    export NIX_NO_SELF_RPATH=1
    stripAllFlags=" " # the Darwin "strip" command doesn't know "-s"
    xargsFlags=" "
    export MACOSX_DEPLOYMENT_TARGET=10.8
    export SDKROOT=
    export CMAKE_OSX_ARCHITECTURES=x86_64
    export NIX_CFLAGS_COMPILE+=" --sysroot=/var/empty -Wno-multichar -Wno-deprecated-declarations"
  '';

  # libSystem and its transitive dependencies. Get used to this; it's a recurring theme in darwin land
  libSystemClosure = [
    "/usr/lib/libSystem.dylib"
    "/usr/lib/libSystem.B.dylib"
    "/usr/lib/libobjc.A.dylib"
    "/usr/lib/libobjc.dylib"
    "/usr/lib/libauto.dylib"
    "/usr/lib/libc++abi.dylib"
    "/usr/lib/libc++.1.dylib"
    "/usr/lib/libDiagnosticMessagesClient.dylib"
    "/usr/lib/system"
  ];

  # The one dependency of /bin/sh :(
  binShClosure = [ "/usr/lib/libncurses.5.4.dylib" ];

  bootstrapTools = derivation rec {
    inherit system tarball;

    name    = "bootstrap-tools";
    builder = bootstrapFiles.sh; # Not a filename! Attribute 'sh' on bootstrapFiles
    args    = [ ./unpack-bootstrap-tools.sh ];

    mkdir = bootstrapFiles.mkdir;
    bzip2 = bootstrapFiles.bzip2;
    cpio  = bootstrapFiles.cpio;

    # What are these doing?
    langC  = true;
    langCC = true;

    __impureHostDeps  = binShClosure ++ libSystemClosure;
  };

  bootstrapPreHook = "export LD_DYLD_PATH=${bootstrapTools}/lib/dyld";

  stageFun = step: {cc, shell ? "${bootstrapTools}/bin/sh", overrides ? (pkgs: {}), extraPreHook ? "", extraBuildInputs ? [], allowedRequisites ? null}:
    let
      thisStdenv = import ../generic {
        inherit system config cc shell extraBuildInputs allowedRequisites;
        name    = "stdenv-darwin-boot-${toString step}";
        preHook =
          ''
            # Don't patch #!/interpreter because it leads to retained
            # dependencies on the bootstrapTools in the final stdenv.
            dontPatchShebangs=1
            ${commonPreHook}
            ${extraPreHook}
          '';
        initialPath  = [ bootstrapTools ];
        fetchurlBoot = import ../../build-support/fetchurl {
          stdenv = stage0.stdenv;
          curl   = bootstrapTools;
        };

        # The stdenvs themselves don't use mkDerivation, so I need to specify this here
        __stdenvImpureHostDeps = binShClosure ++ libSystemClosure;
        __extraImpureHostDeps  = binShClosure ++ libSystemClosure;

        extraAttrs = { inherit platform; };
        overrides  = pkgs: (overrides pkgs) // { fetchurl = thisStdenv.fetchurlBoot; };
      };

      thisPkgs = allPackages {
        inherit system platform;
        bootStdenv = thisStdenv;
      };
    in { stdenv = thisStdenv; pkgs = thisPkgs; };

  stage0 = stageFun 0 {
    cc = "/no-such-path";

    # TODO: just make better bootstrap tools next time around!
    overrides = pkgs: with stage0; {
      libSystemBoot = stdenv.mkDerivation {
        name = "bootstrap-libSystem";
        buildCommand = ''
          mkdir -p $out
          ln -s ${bootstrapTools}/lib $out/lib
          ln -s ${bootstrapTools}/include-libSystem $out/include
        '';
      };

      libcxxBoot = stdenv.mkDerivation {
        name = "bootstrap-libcxx";
        buildCommand = ''
          mkdir -p $out/lib $out/include
          ln -s ${bootstrapTools}/lib/libc++.dylib $out/lib/libc++.dylib
          ln -s ${bootstrapTools}/include/c++      $out/include/c++
        '';
      };

      libcxxabiBoot = stdenv.mkDerivation {
        name = "bootstrap-libcxxabi";
        buildCommand = ''
          mkdir -p $out/lib
          ln -s ${bootstrapTools}/lib/libc++abi.dylib $out/lib/libc++abi.dylib
        '';
      };
    };
  };

  stage1 = with stage0; stageFun 1 {
    cc = import ../../build-support/clang-wrapper {
      nativeTools  = true;
      nativePrefix = bootstrapTools;
      nativeLibc   = false;
      libc         = pkgs.libSystemBoot;
      stdenv       = stdenv;
      libcxx       = pkgs.libcxxBoot;
      libcxxabi    = pkgs.libcxxabiBoot;
      shell        = "${bootstrapTools}/bin/bash";
      clang        = { name = "clang-9.9.9"; outPath = bootstrapTools; };
    };

    extraPreHook = bootstrapPreHook;

    allowedRequisites = [ bootstrapTools pkgs.libSystemBoot pkgs.libcxxBoot pkgs.libcxxabiBoot ];
  };

  # Add xz to bootstrap tools
  # TODO: just bundle xz in the bootstrap tools next time around
  stage2 = with stage1; stageFun 2 {
    inherit (stdenv) cc;
    extraBuildInputs = [ pkgs.xz pkgs.darwin.corefoundation ];
    extraPreHook     = bootstrapPreHook;

    allowedRequisites =
      [ bootstrapTools ] ++
      (with stage0.pkgs; [ libSystemBoot libcxxBoot libcxxabiBoot ]) ++
      (with stage1.pkgs; [ xz darwin.corefoundation icu ]);
  };

  # Add a new libSystem
  stage3 = with stage2; stageFun 3 {
    cc = import ../../build-support/clang-wrapper {
      inherit stdenv;
      inherit (pkgs) libcxx libcxxabi;

      nativeTools  = true;
      nativePrefix = bootstrapTools;
      nativeLibc   = false;
      libc         = pkgs.darwin.libSystem;
      shell        = "${bootstrapTools}/bin/bash";
      clang        = { name = "clang-9.9.9"; outPath = bootstrapTools; };
    };

    extraBuildInputs = [ stage1.pkgs.xz pkgs.darwin.corefoundation ];
    extraPreHook     = "export LD_DYLD_PATH=${pkgs.darwin.dyld}/lib/dyld";

    allowedRequisites =
      [ bootstrapTools ] ++
      (with stage1.pkgs; [ xz ]) ++
      (with stage2.pkgs; [ darwin.libSystem libcxx libcxxabi darwin.dyld darwin.corefoundation icu ]);
  };

  #########################

  stage4 = with stage3; stageFun 4 rec {
    cc = import ../../build-support/clang-wrapper {
      inherit stdenv shell;
      inherit (pkgs) libcxx libcxxabi;

      nativeTools  = true;
      nativePrefix = bootstrapTools;
      nativeLibc   = false;
      libc         = stage2.pkgs.darwin.libSystem; # N.B: stage2, so we don't end up with duplicate libSystems floating around
      clang        = { name = "clang-9.9.9"; outPath = bootstrapTools; };
    };

    shell            = "${pkgs.bash}/bin/bash";
    extraBuildInputs = [ stage1.pkgs.xz pkgs.darwin.corefoundation ];
    extraPreHook     = "export LD_DYLD_PATH=${stage2.pkgs.darwin.dyld}/lib/dyld";

    allowedRequisites =
      [ bootstrapTools ] ++
      (with stage1.pkgs; [ xz ]) ++
      (with stage2.pkgs; [ darwin.libSystem darwin.dyld libcxx libcxxabi ]) ++
      (with stage3.pkgs; [ libcxx libcxxabi darwin.dyld darwin.corefoundation icu bash ]);
  };


  stage5 = with stage4; import ../generic rec {
    inherit system config;
    inherit (stdenv) fetchurlBoot;

    name = "stdenv-darwin";

    preHook = ''
      ${commonPreHook}
      export LD_DYLD_PATH=${stage2.pkgs.darwin.dyld}/lib/dyld
    '';

    __stdenvImpureHostDeps = binShClosure ++ libSystemClosure;
    __extraImpureHostDeps  = binShClosure ++ libSystemClosure;

    initialPath = import ../common-path.nix { inherit pkgs; };
    shell       = "${pkgs.bash}/bin/bash";

    cc = import ../../build-support/clang-wrapper {
      inherit stdenv shell;
      nativeTools = false;
      nativeLibc  = false;
      inherit (stage3.pkgs) libcxx libcxxabi;
      inherit (pkgs) coreutils binutils;
      inherit (pkgs.llvmPackages) clang;
      libc = stage2.pkgs.darwin.libSystem;
    };

    extraBuildInputs = [ pkgs.darwin.corefoundation ];

    extraAttrs = {
      inherit platform bootstrapTools;
      shellPackage = pkgs.bash;
    };

    # Way too large, but at least we have a list that we can start whittling down now
    # allowedRequisites = with pkgs; (map (x: lib.traceVal x.outPath) stage4reqs);

    overrides = _: {
      clang = cc;
      inherit cc;
      inherit (pkgs)
        gzip bzip2 xz bash binutils coreutils diffutils findutils gawk
        glibc gnumake gnused gnutar gnugrep gnupatch zlib;
        # TODO: pass llvm, clang (not just the wrappers) through
    };
  };


  stdenvDarwin = stage5;
}
