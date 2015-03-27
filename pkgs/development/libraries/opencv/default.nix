{ lib, stdenv, fetchurl, cmake, gtk, libjpeg, libpng, libtiff, jasper, ffmpeg
, fetchpatch, pkgconfig, gstreamer, xineLib, glib, python27, python27Packages, unzip
, enableBloat ? false }:

let v = "2.4.10"; in

stdenv.mkDerivation rec {
  name = "opencv-${v}";

  src = fetchurl {
    url = "mirror://sourceforge/opencvlibrary/opencv-${v}.zip";
    sha256 = "1ilnfm7id8jqg5xmfjhbq81sjxx64av90kwxcs8zv5rp523wpx0v";
  };

  patches = [(fetchpatch {
    url = "https://github.com/Itseez/opencv/commit/ea50be0529c24.diff";
    sha256 = "0nm02v7rmfcndj3jzmv3mrqh3hk5n6axx6gdxndyhabn201hqswn";
  })

  # Fix for bug which clang detects as tautological compare and raises error
  # Has been merged into opencv, so remove this patch on update
  (fetchpatch {
    url = "https://github.com/Itseez/opencv/pull/3488.diff";
    sha256 = "0gvd0agmcrm4yfyf9slwkig6k2ig0rmrsw9kx0civhpnh8yg7k77";
  })
  ];

  buildInputs =
    [ unzip libjpeg libpng libtiff ]
    ++ lib.optionals enableBloat [ gtk glib jasper ffmpeg xineLib gstreamer python27 python27Packages.numpy ];

  nativeBuildInputs = [ cmake pkgconfig ];

  enableParallelBuilding = true;

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"

    # Don't build OpenCV's bundled dependencies
    "-DBUILD_JASPER=OFF"
    "-DBUILD_JPEG=OFF"
    "-DBUILD_OPENEXR=OFF"
    "-DBUILD_PNG=OFF"
    "-DBUILD_TBB=OFF"
    "-DBUILD_TIFF=OFF"
    "-DBUILD_ZLIB=OFF"
  ] ++ lib.optional (!enableBloat) [
    "-DWITH_FFMPEG=OFF"
    "-DBUILD_opencv_python=OFF"
  ];

  meta = {
    description = "Open Computer Vision Library with more than 500 algorithms";
    homepage = http://opencv.org/;
    license = stdenv.lib.licenses.bsd3;
    maintainers = with stdenv.lib.maintainers; [viric flosse];
    platforms = with stdenv.lib.platforms; unix;
  };
}
