class Bison < Formula
  desc "Parser generator"
  homepage "https://www.gnu.org/software/bison/"
  url "https://ftp.gnu.org/gnu/bison/bison-3.5.2.tar.xz"
  mirror "https://ftpmirror.gnu.org/bison/bison-3.5.2.tar.xz"
  sha256 "24e273db9eb6da8bbb6f0648284d0724a5cbd6268a163db402f961350a4e50dd"

  bottle do
    sha256 "aaf885edc166234d4dc119cb1a7144dc52bd30398daa3e5e59a8b16e503512a4" => :catalina
    sha256 "d52a881cf554a3b5ff2c11d581d274c054501e0d4fc11158260a52c5ed1529b6" => :mojave
    sha256 "7adf27655fe0838a0ca2d904cef0595a6d7bd186c7ccfd6414dfa7ef626c4709" => :high_sierra
    sha256 "bfec90f1d6e53ada2b283b64949edf7e831bdf4e859315b68bb50a906fc183a2" => :x86_64_linux
  end

  keg_only :provided_by_macos, "some formulae require a newer version of bison"

  uses_from_macos "m4"

  def install
    # https://www.mail-archive.com/bug-guix@gnu.org/msg13512.html
    ENV.deparallelize unless OS.mac?
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.y").write <<~EOS
      %{ #include <iostream>
         using namespace std;
         extern void yyerror (char *s);
         extern int yylex ();
      %}
      %start prog
      %%
      prog:  //  empty
          |  prog expr '\\n' { cout << "pass"; exit(0); }
          ;
      expr: '(' ')'
          | '(' expr ')'
          |  expr expr
          ;
      %%
      char c;
      void yyerror (char *s) { cout << "fail"; exit(0); }
      int yylex () { cin.get(c); return c; }
      int main() { yyparse(); }
    EOS
    system "#{bin}/bison", "test.y"
    system ENV.cxx, "test.tab.c", "-o", "test"
    assert_equal "pass", shell_output("echo \"((()(())))()\" | ./test")
    assert_equal "fail", shell_output("echo \"())\" | ./test")
  end
end
