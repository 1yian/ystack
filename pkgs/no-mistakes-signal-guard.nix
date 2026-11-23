{ fetchFromGitHub, buildGoModule, lib }:

let
  rev = "150521f8b679cdab75a4ae7f12b526f54e2015fd";
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
    hash = "sha256-I7dFsKMULZo3YcDwz5C2vSQJd5rpPjlCTN4E1Z3uvyc=";
  };
  vendorHash = "sha256-maAVBptEtdrGanJHwAPAmuGBorzIMUgK6T+NmIz1kS0=";
  subPackages = [ "cmd/no-mistakes" ];
  env.CGO_ENABLED = 0;
  ldflags = [
    "-X ${buildinfo}.Version=${finalAttrs.version}"
    "-X ${buildinfo}.Commit=${shortRev}"
    "-X ${buildinfo}.Date=2026-11-23T22:55:00Z"
    "-X ${buildinfo}.TelemetryHost=https://a.kunchenguid.com"
    "-X ${buildinfo}.TelemetryWebsiteID=f959e889-92f5-4121-8a1f-571b10861198"
  ];
  doCheck = false;
  meta.mainProgram = "no-mistakes";
  meta.license = lib.licenses.mit;
})
