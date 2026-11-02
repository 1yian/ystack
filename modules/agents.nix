# Agent instructions (AGENTS.md for every agent CLI) and the skills directory.
{ config, lib, ... }:

let
  cfg = config.ystack;
  link = cfg.link;
  skillNames = [ "axi" "lavish" "no-mistakes" "principles" ];
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
      home.file.".agents/skills".source = link "skills";
    })
    (lib.mkIf (cfg.skills.enable && cfg.skills.only != null) {
      home.file = lib.listToAttrs (
        map (s: lib.nameValuePair ".agents/skills/${s}" { source = link "skills/${s}"; }) cfg.skills.only
      );
    })
  ];
}
