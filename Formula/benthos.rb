class Benthos < Formula
  desc "Stream processor for mundane tasks written in Go"
  homepage "https://www.benthos.dev"
  url "https://github.com/Jeffail/benthos/archive/v3.10.0.tar.gz"
  sha256 "0e0552930a84800921986bf3e9e28f235665ea47b183f127c4402499384b75de"

  bottle do
    cellar :any_skip_relocation
    sha256 "f2dca381f85f5bb049f651787b0eac5ab0282da81c301f55699fea3528799e30" => :catalina
    sha256 "ebc2c56d1e4d96b6f2dab2c3994a62fa70df8e160f6d5a2b93ae414601454c3d" => :mojave
    sha256 "317840cc1ef67e3535845b34067769fc72651eb76f9e0fe07989930545bacd9f" => :high_sierra
    sha256 "f5fe49f1f8acb8bc666d43067d6c7c563f8d4900de9d4ed362411832acbe386c" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath

    src = buildpath/"src/github.com/Jeffail/benthos"
    src.install buildpath.children
    src.cd do
      system "make", "VERSION=#{version}"
      bin.install "target/bin/benthos"
      prefix.install_metafiles
    end
  end

  test do
    (testpath/"sample.txt").write <<~EOS
      QmVudGhvcyByb2NrcyE=
    EOS

    (testpath/"test_pipeline.yaml").write <<~EOS
      ---
      logger:
        level: ERROR
      input:
        type: file
        file:
          path: ./sample.txt
      pipeline:
        threads: 1
        processors:
         - type: decode
           decode:
           scheme: base64
      output:
        type: stdout
    EOS
    output = shell_output("#{bin}/benthos -c test_pipeline.yaml")
    assert_match "Benthos rocks!", output.strip
  end
end
