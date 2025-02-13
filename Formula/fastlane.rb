class Fastlane < Formula
  desc "Easiest way to build and release mobile apps"
  homepage "https://fastlane.tools"
  url "https://github.com/fastlane/fastlane/archive/2.142.0.tar.gz"
  sha256 "8fa394bc5051a107c899263a92a812f1fe9156c08bca0f84d38594bed43bbee6"
  head "https://github.com/fastlane/fastlane.git"

  bottle do
    cellar :any
    sha256 "efe9e8c2b34ad62ec3a961de72223526b6332dff6a40c2a7f30e1e1a5c7750f8" => :catalina
    sha256 "31c7d5695b2bc4162f193834015468f4e927e447abad584fc43d57c587b71264" => :mojave
    sha256 "7fc5bf9c88d7b836251866bf5ec80a80321b3c5f937f960a080460c50933baa8" => :high_sierra
    sha256 "72d914e8742874621a1bd9d481725b8feba14fda2e103f5ea707baff71765dee" => :x86_64_linux
  end

  depends_on "ruby@2.5"

  def install
    ENV["GEM_HOME"] = libexec
    ENV["GEM_PATH"] = libexec

    system "gem", "build", "fastlane.gemspec"
    system "gem", "install", "fastlane-#{version}.gem", "--no-document"

    (bin/"fastlane").write <<~EOS
      #!/bin/bash
      export PATH="#{Formula["ruby@2.5"].opt_bin}:#{libexec}/bin:$PATH"
      GEM_HOME="#{libexec}" GEM_PATH="#{libexec}" \\
        exec "#{libexec}/bin/fastlane" "$@"
    EOS
    chmod "+x", bin/"fastlane"
  end

  test do
    assert_match "fastlane #{version}", shell_output("#{bin}/fastlane --version")

    actions_output = shell_output("#{bin}/fastlane actions")
    assert_match "gym", actions_output
    assert_match "pilot", actions_output
    assert_match "screengrab", actions_output
    assert_match "supply", actions_output
  end
end
