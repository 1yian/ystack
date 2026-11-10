# Agent instructions (AGENTS.md for every agent CLI) and the skills directory.
{ config, pkgs, lib, ... }:

let
  cfg = config.ystack;
  link = cfg.link;
  skillNames = [ "axi" "lavish" "no-mistakes" "principles" ];
  # `no-mistakes init` rewrites ~/.agents/skills/no-mistakes/SKILL.md with the text
  # embedded in the installed binary. Linked out-of-store, that write lands in the
  # checkout and dirties the tracked file, so this one skill always links read-only
  # from the store (init's refresh then fails harmlessly) and the tracked text stays.
  skillSource = s: if s == "no-mistakes" then "${cfg.root}/skills/${s}" else link "skills/${s}";
in
{
  options.ystack.agents.enable = lib.mkEnableOption "the ystack agent instructions" // { default = true; };
  options.ystack.skills = {
    enable = lib.mkEnableOption "the ystack skills" // { default = true; };
    only = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf (lib.types.enum skillNames));
      default = null;
      description = "Link only these skills instead of the whole directory.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.agents.enable {
      home.file.".agents/AGENTS.md".source = link "agents/AGENTS.md";
      home.file.".pi/agent/AGENTS.md".source = link "agents/AGENTS.md";
      home.file.".claude/CLAUDE.md".source = link "agents/AGENTS.md";
      home.file.".codex/AGENTS.md".source = link "agents/AGENTS.md";
      home.file.".config/opencode/AGENTS.md".source = link "agents/AGENTS.md";
    })
    # Pi, Claude Code, Codex, and OpenCode all read ~/.agents/skills.
    (lib.mkIf (cfg.skills.enable && cfg.skills.only == null) {
      home.file.".agents/skills".source =
        pkgs.linkFarm "ystack-skills" (map (s: { name = s; path = skillSource s; }) skillNames);
    })
    (lib.mkIf (cfg.skills.enable && cfg.skills.only != null) {
      home.file = lib.listToAttrs (
        map (s: lib.nameValuePair ".agents/skills/${s}" { source = skillSource s; }) cfg.skills.only
      );
    })
  ];
}
