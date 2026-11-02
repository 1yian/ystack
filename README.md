# ystack

A reproducible, clean setup of one person's daily environment, as Home Manager
modules: the terminal UI, the shell, Pi, the agent instructions and skills, and
the fleet prerequisites (Herdr, treehouse, no-mistakes, lavish). No root needed
once Nix exists. Machine identity, hardware, OS config, and work profiles belong
in the consuming repo, which pins ystack by tag.

## Use

```nix
inputs.ystack.url = "github:1yian/ystack/v0.1.0";   # always a tag
inputs.nixpkgs.follows = "ystack/nixpkgs";
inputs.home-manager.follows = "ystack/home-manager";
# ...
home-manager.users.me = {
  imports = [ ystack.homeManagerModules.default ];
  ystack.checkout = "/Users/me/Projects/ystack"; # optional: live editing on the dev machine
};
```

Options (`modules/`): `ystack.{shell,ui,agents,skills,pi,fleet}.enable` (default
on), `ystack.skills.only`, `ystack.pi.{settingsFile,tiersFile,tiersOverlay,extensions.*}`,
`ystack.fleet.{npmPrefix,npmExtra,herdrPiIntegration,linuxBrowser.enable}`,
`ystack.ui.{wezterm.localConfig,fastfetchConfig}`.

## What is in it

| Path | What |
|---|---|
| `modules/shell.nix` | ink + signal palette, zsh, starship, fzf, bat, eza, zoxide, direnv, git behavior |
| `modules/ui.nix`, `config/` | WezTerm (with a host-overlay hook), fastfetch |
| `modules/agents.nix`, `agents/AGENTS.md` | the one AGENTS.md linked for Pi, Claude Code, Codex, OpenCode |
| `modules/pi.nix`, `pi/` | Pi settings, tiers, theme, status line and other extensions |
| `modules/fleet.nix`, `pkgs/` | exact-pinned Herdr, treehouse, no-mistakes, Pi, axi CLIs (lavish-axi included) |
| `skills/` | axi, lavish, no-mistakes, principles |

Fleet brings no-mistakes and lavish as dependencies. Versions are exact pins;
bump them in a release and call out Herdr, no-mistakes, or node changes, which
need all hosts rebuilt before the next fleet update.

## Skills

`principles` is an index: `SKILL.md` lists each principle with a one-line rule
and links its own file, loaded on demand. The layout follows pstack's
principles (cursor/plugins, `pstack/`, MIT).

## Modes

- **Checkout** (`ystack.checkout` set): files link to the working copy out-of-store; edits apply live.
- **Store** (default): files link from the pinned flake input; Pi's `settings.json`, which Pi writes back, is merged on activation (managed keys win, other keys kept).

## Not here

Secrets, tailnet names, company profiles, personal CLIs, and anything needing root.
