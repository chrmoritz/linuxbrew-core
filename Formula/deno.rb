class Deno < Formula
  desc "Command-line JavaScript / TypeScript engine"
  homepage "https://deno.land/"
  url "https://github.com/denoland/deno/releases/download/v0.35.0/deno_src.tar.gz"
  sha256 "49a0a0f208c246f08ab5bd00b3d4eb8936b98e19533c164cb11c458f12dde9e5"

  bottle do
    cellar :any_skip_relocation
    sha256 "1b5e20a4443256c530405056712484a6dc47ad487ffcd481c2c341b56793481b" => :catalina
    sha256 "20280ff8d3ceb8928a083efc78015a98a4e040da60f0c1bea78c6caf48b0d47d" => :mojave
    sha256 "036fa380c08bfa1d3490f8a9d151756779c53da79d14010d613f4da9b00b16cc" => :high_sierra
  end

  depends_on "llvm" => :build if OS.linux? || DevelopmentTools.clang_build_version < 1100
  depends_on "ninja" => :build
  depends_on "rust" => :build
  unless OS.mac?
    depends_on "pkg-config" => :build
    depends_on "pypy" => :build # use PyPy2.7 instead of python@2 on Linux
    depends_on "xz" => :build
    depends_on "glib"
  end

  depends_on :xcode => ["10.0", :build] if OS.mac? # required by v8 7.9+

  uses_from_macos "xz"

  # Use older revision on Linux, newer does not work.
  resource "gn" do
    url "https://gn.googlesource.com/gn.git",
      :revision => OS.mac? ? "a5bcbd726ac7bd342ca6ee3e3a006478fd1f00b5" : "152c5144ceed9592c20f0c8fd55769646077569b"
  end

  def install
    # build gn with llvm clang too (g++ is too old)
    ENV["CXX"] = Formula["llvm"].opt_bin/"clang++"
    # use pypy for Python 2 build scripts
    ENV["PYTHON"] = Formula["pypy"].opt_bin/"pypy"
    mkdir "pypyshim" do
      ln_s Formula["pypy"].opt_bin/"pypy", "python"
      ln_s Formula["pypy"].opt_bin/"pypy", "python2"
    end
    ENV.prepend_path "PATH", buildpath/"pypyshim"

    # Build gn from source (used as a build tool here)
    (buildpath/"gn").install resource("gn")
    cd "gn" do
      system Formula["pypy"].opt_bin/"pypy", "build/gen.py"
      system "ninja", "-C", "out/", "gn"
    end

    # env args for building a release build with our clang, ninja and gn
    ENV["GN"] = buildpath/"gn/out/gn"
    ENV["GN_ARGS"] = "no_inline_line_tables=false"
    if OS.linux? || DevelopmentTools.clang_build_version < 1100
      # build with llvm and link against system libc++ (no runtime dep)
      ENV["CLANG_BASE_PATH"] = Formula["llvm"].prefix
      ENV.remove "HOMEBREW_LIBRARY_PATHS", Formula["llvm"].opt_lib
    else # build with system clang
      ENV["CLANG_BASE_PATH"] = "/usr/"
    end

    cd "cli" do
      system "cargo", "install", "-vv", "--locked", "--root", prefix, "--path", "."
    end

    # Install bash and zsh completion
    output = Utils.popen_read("#{bin}/deno completions bash")
    (bash_completion/"deno").write output
    output = Utils.popen_read("#{bin}/deno completions zsh")
    (zsh_completion/"_deno").write output
  end

  test do
    (testpath/"hello.ts").write <<~EOS
      console.log("hello", "deno");
    EOS
    hello = shell_output("#{bin}/deno run hello.ts")
    assert_includes hello, "hello deno"
    cat = shell_output("#{bin}/deno run --allow-read=#{testpath} https://deno.land/std/examples/cat.ts #{testpath}/hello.ts")
    assert_includes cat, "console.log"
  end
end
