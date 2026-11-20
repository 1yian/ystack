# Fleet host prerequisites: Herdr, treehouse, no-mistakes, Pi, and the axi CLIs
# (lavish-axi included), all at exact pinned versions. Fleet needs no-mistakes
# and lavish, so enabling fleet brings both.
{ config, pkgs, lib, specialArgs, ... }:

let
  cfg = config.ystack.fleet;
  root = config.ystack.root;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  tools = import ../pkgs/fleet-tools.nix { inherit pkgs; };
  p620 = isLinux && (specialArgs.hostname or null) == "p620";
  noMistakes = if p620 then pkgs.callPackage ../pkgs/no-mistakes-signal-guard.nix { } else tools.no-mistakes;
  daemonRoot = "${config.home.homeDirectory}/.no-mistakes";
  daemonInstance = builtins.substring 0 8 (builtins.hashString "sha256" daemonRoot);
  # Exact pins. Bump deliberately; Herdr, no-mistakes, and node changes need a
  # coordinated all-host rollout (herdr machine add refuses a mismatched server).
  corePins = [
    "@earendil-works/pi-coding-agent@1.6.0"
    "gh-axi@0.1.52"
    "lavish-axi@0.1.98"
    "tasks-axi@0.2.6"
    "quota-axi@0.1.69"
  ];
in
{
  options.ystack.fleet = {
    enable = lib.mkEnableOption "the ystack fleet prerequisites" // { default = true; };
    npmPrefix = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.local";
      description = "Global npm prefix for the pinned CLIs (Linux).";
    };
    npmExtra = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "vercel@64.2.0" ];
      description = "Extra exact npm pins reconciled together with the core pins (Linux).";
    };
    herdrPiIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Herdr's own Pi integration when missing (Linux).";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.activation.ystackNpmPins = lib.mkIf isLinux (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run env PATH="${pkgs.nodejs}/bin:${pkgs.bash}/bin:$PATH" \
            ${pkgs.bash}/bin/bash ${root}/bin/npm-pins.sh \
            ${lib.escapeShellArgs ([ cfg.npmPrefix ] ++ corePins ++ cfg.npmExtra)}
        ''
      );
      home.sessionPath = lib.mkIf (cfg.npmPrefix != "${config.home.homeDirectory}/.local") [ "${cfg.npmPrefix}/bin" ];
      home.activation.ystackHerdrDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [[ ! -e "$HOME/.config/herdr/config.toml" ]]; then
          run mkdir -p "$HOME/.config/herdr"
          run install -m 644 ${root}/config/herdr.defaults.toml "$HOME/.config/herdr/config.toml"
        fi
      '';
    }
    (lib.mkIf isDarwin {
      home.packages = [ pkgs.nodejs ];
    })
    (lib.mkIf isLinux {
      home.packages = [
        tools.herdr
        tools.treehouse
        noMistakes
        pkgs.nodejs
        pkgs.gh
        pkgs.zstd
      ];
      # Fleet reads Pi pane state from Herdr's own Pi integration (herdr-agent-state.ts).
      home.activation.ystackHerdrPiIntegration = lib.mkIf cfg.herdrPiIntegration (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if ! ${tools.herdr}/bin/herdr integration status 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q '^pi: current'; then
            run ${tools.herdr}/bin/herdr integration install pi
          fi
        ''
      );
      programs.tmux = {
        enable = true;
        terminal = "tmux-256color";
        extraConfig = ''
          # Preserve modified Enter keys for Pi and other terminal agents.
          set -g extended-keys on
          set -g extended-keys-format csi-u
        '';
      };
      programs.zsh.envExtra = ''
        if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        fi
      '';
    })
    (lib.mkIf p620 {
      home.file.".config/systemd/user/no-mistakes-daemon-${daemonInstance}.service.d/10-ystack-package.conf".text = ''
        [Service]
        ExecStart=
        ExecStart=${lib.getExe noMistakes} daemon run --root "${daemonRoot}"
      '';
    })
  ]);
}
