class Octave < Formula
  desc "High-level interpreted language for numerical computing"
  homepage "https://www.gnu.org/software/octave/index.html"
  url "https://ftp.gnu.org/gnu/octave/octave-5.2.0.tar.xz"
  mirror "https://ftpmirror.gnu.org/octave/octave-5.2.0.tar.xz"
  sha256 "2757b5cc1854c9326d6c99d2900c7cec2909ac7ed500212d170d0df592bfd26b"
  revision 1

  bottle do
    sha256 "e9710c9a9d5c84c708017d839baeebe6324c09d07828f4b6c074fcdca302b7c7" => :catalina
    sha256 "3e99b794c40e48428e3c93258542e4f1e169a90db8e02831ac585475fa09dc60" => :mojave
    sha256 "04738b5855d6d037e416e2a6a594efcc0567a01b7866c80cb470a3f867f78405" => :high_sierra
  end

  head do
    url "https://hg.savannah.gnu.org/hgweb/octave", :branch => "default", :using => :hg

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "bison" => :build
    depends_on "icoutils" => :build
    depends_on "librsvg" => :build
  end

  # Complete list of dependencies at https://wiki.octave.org/Building
  depends_on "gnu-sed" => :build # https://lists.gnu.org/archive/html/octave-maintainers/2016-09/msg00193.html
  depends_on "openjdk" => :build
  depends_on "pkg-config" => :build
  depends_on "arpack"
  depends_on "epstool"
  depends_on "fftw"
  depends_on "fig2dev"
  depends_on "fltk"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gcc" # for gfortran
  depends_on "ghostscript"
  depends_on "gl2ps"
  depends_on "glpk"
  depends_on "gnuplot"
  depends_on "graphicsmagick"
  depends_on "hdf5"
  depends_on "libsndfile"
  depends_on "libtool"
  depends_on "openblas"
  depends_on "pcre"
  depends_on "portaudio"
  depends_on "pstoedit"
  depends_on "qhull"
  depends_on "qrupdate"
  depends_on "qt"
  depends_on "readline"
  depends_on "suite-sparse"
  depends_on "sundials"
  depends_on "texinfo"

  uses_from_macos "curl"

  # Dependencies use Fortran, leading to spurious messages about GCC
  cxxstdlib_check :skip

  # Octave fails to build due to error with java. See also
  # https://github.com/Homebrew/homebrew-core/issues/39848
  # Patch submitted upstream at: https://savannah.gnu.org/patch/index.php?9806
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/master/octave/5.1.0-java-version.patch"
    sha256 "7ea1e9b410a759fa136d153fb8482ecfc3425a39bfe71c1e71b3ff0f7d9a0b54"
  end

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--enable-link-all-dependencies",
                          "--enable-shared",
                          "--disable-static",
                          "--with-hdf5-includedir=#{Formula["hdf5"].opt_include}",
                          "--with-hdf5-libdir=#{Formula["hdf5"].opt_lib}",
                          "--with-java-homedir=#{Formula["openjdk"].opt_prefix}",
                          "--with-x=no",
                          "--with-blas=-L#{Formula["openblas"].opt_lib} -lopenblas",
                          "--with-portaudio",
                          "--with-sndfile"
    system "make", "all"

    # Avoid revision bumps whenever fftw's, gcc's or OpenBLAS' Cellar paths change
    inreplace "src/mkoctfile.cc" do |s|
      s.gsub! Formula["fftw"].prefix.realpath, Formula["fftw"].opt_prefix
      s.gsub! Formula["gcc"].prefix.realpath, Formula["gcc"].opt_prefix
    end

    # Make sure that Octave uses the modern texinfo at run time
    rcfile = buildpath/"scripts/startup/site-rcfile"
    rcfile.append_lines "makeinfo_program(\"#{Formula["texinfo"].opt_bin}/makeinfo\");"

    system "make", "install"
  end

  test do
    system bin/"octave", "--eval", "(22/7 - pi)/pi"
    # This is supposed to crash octave if there is a problem with BLAS
    system bin/"octave", "--eval", "single ([1+i 2+i 3+i]) * single ([ 4+i ; 5+i ; 6+i])"
  end
end
