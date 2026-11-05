# Pi: settings, tiers, theme, and extensions. Pi writes settings.json back (e.g.
# lastChangelogVersion), so outside checkout mode it is merged on activation
# instead of linked read-only: ystack-managed keys win, other keys are kept.
{ config, pkgs, lib, ... }:

let
  cfg = config.ystack.pi;
  link = config.ystack.link;
  root = config.ystack.root;
  checkout = config.ystack.checkout;
  ext = name: ".pi/agent/extensions/${name}";
  # In checkout mode the merge reads the working copy, so a switch applies its edits.
  settingsSrc =
    if cfg.settingsFile != null then cfg.settingsFile
    else if checkout != null then "${checkout}/pi/settings.json"
    else "${root}/pi/settings.json";
  # jq keeps the base file's key order; the overlay replaces whole top-level keys.
  tiersOverlayFile = pkgs.runCommand "tiers.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq --slurpfile overlay ${pkgs.writeText "tiers-overlay.json" (builtins.toJSON cfg.tiersOverlay)} \
      '. + $overlay[0]' ${root}/pi/tiers.json > $out
  '';
in
{
  options.ystack.pi = {
    enable = lib.mkEnableOption "the ystack Pi setup" // { default = true; };
    settingsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Replacement base for settings.json (e.g. a work profile).";
    };
    tiersFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Replacement tiers.json.";
    };
    tiersOverlay = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Top-level keys of tiers.json to replace (e.g. rules).";
    };
    extensions = {
      rateLimitFallback = lib.mkEnableOption "automatic Anthropic rate-limit fallback";
      opencodeZen = lib.mkEnableOption "the OpenCode Zen provider";
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".pi/agent/themes/ink-signal.json".source = link "pi/themes/ink-signal.json";
      ".pi/agent/tiers.json".source =
        if cfg.tiersFile != null then cfg.tiersFile
        else if cfg.tiersOverlay != { } then tiersOverlayFile
        else link "pi/tiers.json";
      # Extra Claude subscriptions (pi-multi-pass providers) get pi-anthropic-auth's request shaping.
      "${ext "pi-anthropic-auth"}/config.json".source = link "pi/pi-anthropic-auth.json";
      "${ext "chunked-compaction.ts"}".source = link "pi/extensions/chunked-compaction.ts";
      "${ext "statusline.ts"}".source = link "pi/extensions/statusline.ts";
      "${ext "fm-readable-ui.ts"}".source = link "pi/extensions/fm-readable-ui.ts";
    }
    // lib.optionalAttrs cfg.extensions.rateLimitFallback {
      "${ext "anthropic-rate-limit-fallback.ts"}".source = link "pi/extensions/anthropic-rate-limit-fallback.ts";
    }
    // lib.optionalAttrs cfg.extensions.opencodeZen {
      "${ext "opencode-zen"}".source = link "pi/extensions/opencode-zen";
    };

    home.activation.ystackPiSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      dest="$HOME/.pi/agent/settings.json"
      if [[ ! -v DRY_RUN ]]; then
        base=$(${pkgs.coreutils}/bin/mktemp)
        # Pi's own bookkeeping keys never come from the managed base.
        ${pkgs.jq}/bin/jq 'del(.lastChangelogVersion, .extensionChangelogVersions)' ${settingsSrc} > "$base"
        mkdir -p "$HOME/.pi/agent"
        if [[ -L "$dest" || ! -e "$dest" ]]; then
          rm -f "$dest"
          install -m 644 "$base" "$dest"
        else
          merged=$(${pkgs.coreutils}/bin/mktemp)
          ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$dest" "$base" > "$merged" && install -m 644 "$merged" "$dest"
          rm -f "$merged"
        fi
        rm -f "$base"
      fi
    '';
  };
}
