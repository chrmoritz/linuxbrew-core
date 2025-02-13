require "language/node"

class Serverless < Formula
  desc "Build applications with serverless architectures"
  homepage "https://serverless.com"
  url "https://github.com/serverless/serverless/archive/v1.65.0.tar.gz"
  sha256 "5746623d39be7733eb6290918a7da2577ea9ddeb303a65b6b0af33cc3f4c170d"

  bottle do
    cellar :any_skip_relocation
    sha256 "a905ea1a17b66738faf8f5d011a58b487e77a5e472d530ce7f866f8d319353a0" => :catalina
    sha256 "4824d163a971c48ad92499cc6dd63ab442294e16614c0214f9388f0989017519" => :mojave
    sha256 "8a3145f4411468ca0364a94937f69fd9ffcace9a26b05f8fa0f40536171cf1a2" => :high_sierra
    sha256 "5559cdcd9f7fd88700ab96a6f83d2732121812248985e19cfbb49e2a53c15ea5" => :x86_64_linux
  end

  depends_on "node"
  depends_on "python" unless OS.mac?

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    (testpath/"serverless.yml").write <<~EOS
      service: homebrew-test
      provider:
        name: aws
        runtime: python3.6
        stage: dev
        region: eu-west-1
    EOS

    system("#{bin}/serverless config credentials --provider aws --key aa --secret xx")
    output = shell_output("#{bin}/serverless package")
    assert_match "Serverless: Packaging service...", output
  end
end
