class Netcdf < Formula
  desc "Libraries and data formats for array-oriented scientific data"
  homepage "https://www.unidata.ucar.edu/software/netcdf"
  url "https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-c-4.7.3.tar.gz"
  sha256 "8e8c9f4ee15531debcf83788594744bd6553b8489c06a43485a15c93b4e0448b"
  revision 1
  head "https://github.com/Unidata/netcdf-c.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "9e217ac938403f5bf547a3c62984ec2979c5d02af10dd2c2023e180e4a2bd90a" => :catalina
    sha256 "eedecd250d0c0069dc6484685741446fe67fd2d373ef015e2b6de3f228cc388e" => :mojave
    sha256 "e81f0655b42db959dbcbaaf7471a5c2567fdd11cfd1ed159c529c12b2964810a" => :high_sierra
    sha256 "6b579d7357ec8a6e0d1d7c9646a437b9199ce5f0030b206861e24a951099edba" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "gcc" # for gfortran
  depends_on "hdf5"
  uses_from_macos "curl"

  resource "cxx" do
    url "https://github.com/Unidata/netcdf-cxx4/archive/v4.3.0.tar.gz"
    sha256 "25da1c97d7a01bc4cee34121c32909872edd38404589c0427fefa1301743f18f"
  end

  resource "cxx-compat" do
    url "https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-cxx-4.2.tar.gz"
    mirror "https://www.gfd-dennou.org/arch/netcdf/unidata-mirror/netcdf-cxx-4.2.tar.gz"
    sha256 "95ed6ab49a0ee001255eac4e44aacb5ca4ea96ba850c08337a3e4c9a0872ccd1"
  end

  resource "fortran" do
    url "https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-fortran-4.5.2.tar.gz"
    mirror "https://www.gfd-dennou.org/arch/netcdf/unidata-mirror/netcdf-fortran-4.5.2.tar.gz"
    sha256 "b959937d7d9045184e9d2040a915d94a7f4d0185f4a9dceb8f08c94b0c3304aa"
  end

  def install
    ENV.deparallelize

    common_args = std_cmake_args << "-DBUILD_TESTING=OFF" << "-DCMAKE_INSTALL_LIBDIR=#{lib}"

    mkdir "build" do
      args = common_args.dup
      args << "-DNC_EXTRA_DEPS=-lmpi" if Tab.for_name("hdf5").with? "mpi"
      args << "-DENABLE_TESTS=OFF" << "-DENABLE_NETCDF_4=ON" << "-DENABLE_DOXYGEN=OFF"

      system "cmake", "..", "-DBUILD_SHARED_LIBS=ON", *args
      system "make", "install"
      system "make", "clean"
      system "cmake", "..", "-DBUILD_SHARED_LIBS=OFF", *args
      system "make"
      lib.install "liblib/libnetcdf.a"
    end

    # Add newly created installation to paths so that binding libraries can
    # find the core libs.
    args = common_args.dup << "-DNETCDF_C_LIBRARY=#{lib}/libnetcdf.#{OS.mac? ? "dylib" : "so"}"

    cxx_args = args.dup
    cxx_args << "-DNCXX_ENABLE_TESTS=OFF"
    resource("cxx").stage do
      mkdir "build-cxx" do
        system "cmake", "..", "-DBUILD_SHARED_LIBS=ON", *cxx_args
        system "make", "install"
        system "make", "clean"
        system "cmake", "..", "-DBUILD_SHARED_LIBS=OFF", *cxx_args
        system "make"
        lib.install "cxx4/libnetcdf-cxx4.a"
      end
    end

    fortran_args = args.dup
    fortran_args << "-DENABLE_TESTS=OFF"
    resource("fortran").stage do
      mkdir "build-fortran" do
        system "cmake", "..", "-DBUILD_SHARED_LIBS=ON", *fortran_args
        system "make", "install"
        system "make", "clean"
        system "cmake", "..", "-DBUILD_SHARED_LIBS=OFF", *fortran_args
        system "make"
        lib.install "fortran/libnetcdff.a"
      end
    end

    ENV.prepend "CPPFLAGS", "-I#{include}"
    ENV.prepend "LDFLAGS", "-L#{lib}"
    resource("cxx-compat").stage do
      system "./configure", "--disable-dependency-tracking",
                            "--enable-shared",
                            "--enable-static",
                            "--prefix=#{prefix}"
      system "make"
      system "make", "install"
    end

    if OS.mac?
      # SIP causes system Python not to play nicely with @rpath
      libnetcdf = (lib/"libnetcdf.dylib").readlink
      %w[libnetcdf-cxx4.dylib libnetcdf_c++.dylib].each do |f|
        macho = MachO.open("#{lib}/#{f}")
        macho.change_dylib("@rpath/#{libnetcdf}",
                           "#{lib}/#{libnetcdf}")
        macho.write!
      end
    end
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include "netcdf_meta.h"
      int main()
      {
        printf(NC_VERSION);
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}", "-lnetcdf",
                   "-o", "test"
    if head?
      assert_match /^\d+(?:\.\d+)+/, `./test`
    else
      assert_equal version.to_s, `./test`
    end

    (testpath/"test.f90").write <<~EOS
      program test
        use netcdf
        integer :: ncid, varid, dimids(2)
        integer :: dat(2,2) = reshape([1, 2, 3, 4], [2, 2])
        call check( nf90_create("test.nc", NF90_CLOBBER, ncid) )
        call check( nf90_def_dim(ncid, "x", 2, dimids(2)) )
        call check( nf90_def_dim(ncid, "y", 2, dimids(1)) )
        call check( nf90_def_var(ncid, "data", NF90_INT, dimids, varid) )
        call check( nf90_enddef(ncid) )
        call check( nf90_put_var(ncid, varid, dat) )
        call check( nf90_close(ncid) )
      contains
        subroutine check(status)
          integer, intent(in) :: status
          if (status /= nf90_noerr) call abort
        end subroutine check
      end program test
    EOS
    system "gfortran", "test.f90", "-L#{lib}", "-I#{include}", "-lnetcdff",
                       "-o", "testf"
    system "./testf"
  end
end
