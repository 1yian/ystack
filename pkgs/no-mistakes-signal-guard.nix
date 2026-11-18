{ fetchFromGitHub, buildGoModule, lib }:

let
  rev = "980a45cff3b6b6de4461524327539b377ceda04e";
  shortRev = builtins.substring 0 8 rev;
  buildinfo = "github.com/kunchenguid/no-mistakes/internal/buildinfo";
in
buildGoModule (finalAttrs: {
  pname = "no-mistakes";
  version = "fork-${shortRev}";
  src = fetchFromGitHub {
    owner = "1yian";
    repo = "no-mistakes";
    inherit rev;
    hash = "sha256-QSkFMMf5kcF4GFW2g1ZFk8m6jIe8xADXWDq0NR4d1sY=";
  };
  vendorHash = "sha256-maAVBptEtdrGanJHwAPAmuGBorzIMUgK6T+NmIz1kS0=";
  subPackages = [ "cmd/no-mistakes" ];
  env.CGO_ENABLED = 0;
  ldflags = [
    "-X ${buildinfo}.Version=${finalAttrs.version}"
    "-X ${buildinfo}.Commit=${shortRev}"
    "-X ${buildinfo}.Date=2026-11-18T03:52:20Z"
    "-X ${buildinfo}.TelemetryHost=https://a.kunchenguid.com"
    "-X ${buildinfo}.TelemetryWebsiteID=f959e889-92f5-4121-8a1f-571b10861198"
  ];
  doCheck = false;
  meta.mainProgram = "no-mistakes";
  meta.license = lib.licenses.mit;
})
