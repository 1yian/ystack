# ystack: Home Manager modules. Needs no root once Nix exists.
# Every piece is switched with ystack.<piece>.enable (all default on, except
# the opt-in Pi extensions); machine and identity facts stay in the consumer.
{ config, lib, ... }:

let
  cfg = config.ystack;
  root = ../.;
in
{
  imports = [
    ./shell.nix
    ./ui.nix
    ./agents.nix
    ./pi.nix
    ./fleet.nix
  ];

  options.ystack = {
    checkout = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/Users/me/Projects/ystack";
      description = ''
        Absolute path of a ystack working copy. When set, files link to it
        out-of-store so edits apply live (the dev machine). When null, files
        link from the pinned ystack in the Nix store.
      '';
    };
    # Internal: resolves a repo-relative path to a home.file source.
    link = lib.mkOption {
      type = lib.types.anything;
      internal = true;
      readOnly = true;
      default =
        rel:
        if cfg.checkout != null then
          config.lib.file.mkOutOfStoreSymlink "${cfg.checkout}/${rel}"
        else
          "${root}/${rel}";
    };
    root = lib.mkOption {
      type = lib.types.path;
      internal = true;
      readOnly = true;
      default = root;
    };
  };
}
