class Istioctl < Formula
  desc "Istio configuration command-line utility"
  homepage "https://github.com/istio/istio"
  url "https://github.com/istio/istio.git",
      :tag      => "1.4.5",
      :revision => "f7b065dac2aee3db82630727c14b8ffdfb5a2713"

  bottle do
    cellar :any_skip_relocation
    sha256 "f18cedfa9df54a0bd504fc44e8725e408b477e606c5f6a0862f2188e824c41bc" => :catalina
    sha256 "f18cedfa9df54a0bd504fc44e8725e408b477e606c5f6a0862f2188e824c41bc" => :mojave
    sha256 "f18cedfa9df54a0bd504fc44e8725e408b477e606c5f6a0862f2188e824c41bc" => :high_sierra
    sha256 "e05780c4ed6f4924d780030028d41eb7fa478c5abbd051e4c0f53438589bcc64" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["TAG"] = version.to_s
    ENV["ISTIO_VERSION"] = version.to_s
    ENV["HUB"] = "docker.io/istio"

    srcpath = buildpath/"src/istio.io/istio"
    if OS.mac?
      outpath = buildpath/"out/darwin_amd64/release"
    else
      outpath = buildpath/"out/linux_amd64/release"
    end
    srcpath.install buildpath.children

    cd srcpath do
      system "make", "istioctl"
      prefix.install_metafiles
      bin.install outpath/"istioctl"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/istioctl version --remote=false")
  end
end
