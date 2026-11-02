# UI: WezTerm (macOS) and fastfetch. Machine-specific WezTerm behavior goes in
# ystack.ui.wezterm.localConfig, a Lua file returning function(config, wezterm, host, hostname).
{ config, pkgs, lib, ... }:

let
  cfg = config.ystack.ui;
  link = config.ystack.link;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  options.ystack.ui = {
    enable = lib.mkEnableOption "the ystack UI setup" // { default = true; };
    wezterm.localConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.anything;
      default = null;
      description = "home.file source for the optional WezTerm host overlay.";
    };
    fastfetchConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.anything;
      default = null;
      description = "Replacement home.file source for the fastfetch config (e.g. another logo).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Older WezTerm builds reliably discover the canonical ~/.wezterm.lua entrypoint.
    home.file.".wezterm.lua" = lib.mkIf isDarwin { source = link "config/wezterm/wezterm.lua"; };
    home.file.".config/wezterm" = lib.mkIf isDarwin { source = link "config/wezterm"; };
    home.file.".config/ystack/wezterm-local.lua" = lib.mkIf (isDarwin && cfg.wezterm.localConfig != null) {
      source = cfg.wezterm.localConfig;
    };
    home.file.".config/fastfetch/config.jsonc".source =
      if cfg.fastfetchConfig != null then cfg.fastfetchConfig else link "config/fastfetch/config.jsonc";
  };
}
