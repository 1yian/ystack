# Shell: ink + signal palette, core CLI, zsh, starship, fzf, bat, eza, zoxide, direnv, git behavior.
{ config, pkgs, lib, ... }:

let
  cfg = config.ystack.shell;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  ink = {
    base = "#101014";
    mantle = "#0c0c10";
    surface = "#16161d";
    overlay = "#5c5c6a";
    subtext = "#8b8b96";
    text = "#e6e6ea";
    signal = "#3dffc0";
    signalDim = "#1a9e74";
    soft = "#9b8cff";
    info = "#6eb6ff";
    warn = "#ffb454";
    error = "#ff5c7a";
  };
in
{
  options.ystack.shell.enable = lib.mkEnableOption "the ystack shell setup" // { default = true; };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # `pi` on the Nix profile's PATH, for launches whose PATH lacks ~/.local/bin
      # (Herdr session restore, non-interactive shells).
      (writeShellScriptBin "pi" ''
        exec "$HOME/.local/bin/pi" "$@"
      '')
      ripgrep
      fd
      fzf
      jq
      lazygit
      tree
      bat
      eza
      zoxide
      delta
      glow
      fastfetch
      nerd-fonts.jetbrains-mono
    ];

    fonts.fontconfig.enable = true;

    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BAT_THEME = "ansi";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      MANROFFOPT = "-c";
      FZF_DEFAULT_OPTS = lib.concatStringsSep " " [
        "--height=45%"
        "--layout=reverse"
        "--border=rounded"
        "--info=inline"
        "--prompt=❯ "
        "--pointer=▶"
        "--marker=■"
        "--color=bg:${ink.base},bg+:${ink.surface},fg:${ink.text},fg+:${ink.text}"
        "--color=hl:${ink.signal},hl+:${ink.signal},info:${ink.overlay},prompt:${ink.signal}"
        "--color=pointer:${ink.signal},marker:${ink.signalDim},spinner:${ink.soft},header:${ink.subtext}"
        "--color=border:${ink.overlay},gutter:${ink.base},query:${ink.text}"
      ];
      FZF_CTRL_T_OPTS = "--preview 'bat --color=always --style=plain --line-range=:200 {} 2>/dev/null || eza -la --color=always {}'";
      FZF_ALT_C_OPTS = "--preview 'eza -la --color=always --tree --level=2 {}'";
      EZA_COLORS = "uu=0:gu=0:sn=32:sb=32:da=36:ur=37:uw=37:ux=37:ue=37:gr=37:gw=37:gx=37:tr=37:tw=37:tx=37";
      BUN_INSTALL = "$HOME/.bun";
    };

    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.bun/bin"
    ] ++ lib.optional isDarwin "/Applications/WezTerm.app/Contents/MacOS";

    programs.git = {
      enable = true;
      lfs.enable = true;
      settings = {
        push.autoSetupRemote = true;
        pull.rebase = true;
        rebase.updateRefs = true;
        color.ui = true;
        init.defaultBranch = "main";
        core.pager = "delta";
        interactive.diffFilter = "delta --color-only";
        delta = {
          navigate = true;
          side-by-side = false;
          line-numbers = true;
          syntax-theme = "ansi";
          plus-style = "syntax #0d2a22";
          minus-style = "syntax #2a1218";
          plus-emph-style = "syntax #1a9e74";
          minus-emph-style = "syntax #ff5c7a";
          map-styles = "bold purple => syntax #9b8cff, bold blue => syntax #6eb6ff, bold cyan => syntax #3dffc0, bold yellow => syntax #ffb454";
        };
      };
    };

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
        command_timeout = 1000;
        palette = "ink_signal";
        format = lib.concatStrings [
          "[](fg:surface)"
          "$os"
          "$directory"
          "[](fg:surface bg:mantle)"
          "$git_branch"
          "$git_status"
          "[](fg:mantle)"
          "$fill"
          "$cmd_duration"
          "$hostname"
          "$line_break"
          "$character"
        ];
        palettes.ink_signal = {
          ink = ink.base;
          mantle = ink.mantle;
          surface = ink.surface;
          overlay = ink.overlay;
          subtext = ink.subtext;
          text = ink.text;
          signal = ink.signal;
          soft = ink.soft;
          error = ink.error;
          warn = ink.warn;
        };
        fill = {
          symbol = " ";
          style = "fg:overlay";
        };
        os = {
          disabled = false;
          style = "fg:signal bg:surface";
          format = "[ $symbol ]($style)";
        };
        os.symbols = {
          Macos = "󰀵";
          Ubuntu = "󰕈";
        };
        directory = {
          style = "fg:text bg:surface";
          format = "[ $path ]($style)";
          truncation_length = 3;
          truncate_to_repo = true;
          truncation_symbol = "…/";
        };
        git_branch = {
          symbol = "";
          style = "fg:subtext bg:mantle";
          format = "[ $symbol$branch ]($style)";
        };
        git_status = {
          style = "fg:signal bg:mantle";
          format = "[$all_status$ahead_behind]($style)";
          conflicted = "⇕";
          ahead = "⇡\${count} ";
          behind = "⇣\${count} ";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count} ";
          untracked = "?";
          stashed = "≡";
          modified = "!";
          staged = "+";
          renamed = "»";
          deleted = "✘";
        };
        cmd_duration = {
          min_time = 1500;
          style = "fg:overlay";
          format = "[  $duration ]($style)";
        };
        hostname = {
          ssh_only = true;
          style = "fg:soft";
          format = "[  $hostname ]($style)";
        };
        character = {
          success_symbol = "[❯](bold signal)";
          error_symbol = "[❯](bold error)";
          vimcmd_symbol = "[❮](bold soft)";
        };
      };
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.bat = {
      enable = true;
      config = {
        style = "plain";
        paging = "never";
      };
    };

    programs.eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
      extraOptions = [ "--group-directories-first" ];
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    programs.zsh = {
      enable = true;
      dotDir = "${config.home.homeDirectory}/.config/zsh";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history = {
        size = 60000;
        save = 60000;
        path = "${config.home.homeDirectory}/.local/share/zsh/history";
        ignoreDups = true;
        ignoreSpace = true;
        share = true;
      };
      shellAliases = {
        ".." = "cd ..";
        "..." = "cd ../..";
        g = "git";
        ga = "git add";
        gc = "git commit";
        gs = "git status -sb";
        gd = "git diff";
        gl = "git log --oneline -20";
        push = "git push";
        pull = "git pull";
        m = "git switch main";
        add = "git add .";
        lg = "lazygit";
        ff = "fastfetch";
        cat = "bat --paging=never";
      };
      initContent = ''
        # --- ink + signal line editor ------------------------------------------
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#5c5c6a'
        ZSH_AUTOSUGGEST_STRATEGY=(history completion)
        bindkey '^f' autosuggest-accept
        bindkey '^[[Z' reverse-menu-complete

        # self-heal leaked Kitty keyboard protocol (e.g. a TUI killed with ctrl+c
        # never pops its pushed flags, which breaks ctrl+c at the shell prompt).
        autoload -Uz add-zsh-hook
        _fix_kitty_kbd() { printf '\e[<u\e[=0;1u' }
        add-zsh-hook precmd _fix_kitty_kbd

        typeset -A ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_STYLES[command]='fg=#3dffc0'
        ZSH_HIGHLIGHT_STYLES[builtin]='fg=#3dffc0'
        ZSH_HIGHLIGHT_STYLES[alias]='fg=#3dffc0'
        ZSH_HIGHLIGHT_STYLES[function]='fg=#3dffc0'
        ZSH_HIGHLIGHT_STYLES[precommand]='fg=#3dffc0,underline'
        ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ff5c7a,underline'
        ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#ffb454'
        ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#ffb454'
        ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#9b8cff'
        ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#9b8cff'
        ZSH_HIGHLIGHT_STYLES[path]='fg=#6eb6ff'
        ZSH_HIGHLIGHT_STYLES[comment]='fg=#5c5c6a'
        ZSH_HIGHLIGHT_STYLES[redirection]='fg=#9b8cff'
        ZSH_HIGHLIGHT_STYLES[arg0]='fg=#3dffc0'

        # completion UI
        zstyle ':completion:*' menu select
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*:descriptions' format '%F{#5c5c6a}%d%f'
        zstyle ':completion:*:messages' format '%F{#9b8cff}%d%f'
        zstyle ':completion:*:warnings' format '%F{#ff5c7a}no matches%f'

        # paths: user tooling first
        typeset -U path
        path=("$HOME/.local/bin" $path)
        export PATH

        # cargo / bun when present
        [ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
        [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
      '';
    };
  };
}
