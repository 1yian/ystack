{ pkgs }:

let
  # These three releases are outside nixpkgs. Hashes are from the publishers'
  # release manifest/checksums, not an installer that follows "latest".
  archiveTool =
    name: version: hash:
    pkgs.stdenvNoCC.mkDerivation {
      pname = name;
      inherit version;
      src = pkgs.fetchurl {
        url = "https://github.com/kunchenguid/${name}/releases/download/v${version}/${name}-v${version}-linux-amd64.tar.gz";
        sha256 = hash;
      };
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      buildInputs = [ pkgs.stdenv.cc.cc.lib ];
      sourceRoot = ".";
      installPhase = ''
        runHook preInstall
        install -Dm755 ${name} "$out/bin/${name}"
        runHook postInstall
      '';
    };
in
{
  herdr = pkgs.stdenvNoCC.mkDerivation {
    pname = "herdr";
    version = "0.9.5";
    src = pkgs.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v0.9.5/herdr-linux-x86_64";
      sha256 = "14d9e8bc8b4a9e0118d77c32266f76d461f09b40342eb23752960bd89f59929d";
    };
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    installPhase = ''
      install -Dm755 "$src" "$out/bin/herdr"
    '';
  };
  treehouse =
    archiveTool "treehouse" "3.1.8"
      "bd6227d909ba8046263ae5d4e072ccbcf43010cac9d7289b1262126510edfeed";
  no-mistakes =
    archiveTool "no-mistakes" "1.106.1"
      "fbf131356a278623a509b6b50ecb39c5375b1a82e7dcfc48e42d10e761416d1e";
}
