{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # HM は completionInit を antidote (order 550) の後 (order 570) に置くので、
    # プラグイン読み込み後に compinit が走る順序が保たれる。
    completionInit = ''
      : ''${COMPDUMPFILE:=''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump}
      mkdir -p "''${COMPDUMPFILE:h}"
      autoload -U compinit
      compinit -d "''${COMPDUMPFILE}"
    '';

    antidote = {
      enable = true;
      plugins = [
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-completions"
        "Aloxaf/fzf-tab"
        "zdharma-continuum/fast-syntax-highlighting"
        "paulirish/git-open"
      ];
    };

    history = {
      size = 10000;
      save = 100000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      share = true;
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        typeset -g ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE='20'

        setopt correct                  # コマンド訂正
        setopt nobeep                   # ビープ音無効
        setopt notify                   # バックグラウンドジョブ完了通知
        setopt auto_pushd               # cd履歴を自動保存
        setopt auto_cd                  # ディレクトリ名のみでcd
        setopt interactive_comments     # コメント有効化
        setopt hist_no_store            # historyコマンドを履歴に保存しない
        setopt hist_reduce_blanks       # 余分な空白を詰める
        setopt hist_verify              # !!実行時に確認
        setopt ignoreeof                # Ctrl-Dでログアウトしない

        zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

        bindkey -e

        # Ctrl-Yで上のディレクトリに移動
        function cd-up { zle push-line && LBUFFER='builtin cd ..' && zle accept-line }
        zle -N cd-up
        bindkey "^Y" cd-up

        # Ctrl-Wをスラッシュ単位にする
        autoload -U select-word-style
        select-word-style bash

        # Ctrl-[で直前コマンドの単語を挿入
        autoload -Uz smart-insert-last-word
        zstyle :insert-last-word match '*([[:alpha:]/\\]?|?[[:alpha:]/\\])*'
        zle -N insert-last-word smart-insert-last-word
        bindkey '^[' insert-last-word
      '')

      (lib.mkOrder 600 ''
        # cd先のファイル一覧表示
        [ -z "$ENHANCD_ROOT" ] && function chpwd { tree -L 1 }
        [ -z "$ENHANCD_ROOT" ] || export ENHANCD_HOOK_AFTER_CD="tree -L 1"

        # sshコマンド補完
        function _ssh { compadd $(grep -F 'Host ' ~/.ssh/config | grep -v '*' | awk '{print $2}' | sort) }

        function gi() {
          curl -L -s https://www.gitignore.io/api/$@
        }

        function awsp() {
          local profile
          profile=$(aws configure list-profiles | fzf --height 40% --reverse --border --prompt="Select AWS Profile > ")
          if [ -n "$profile" ]; then
            export AWS_PROFILE=$profile
            echo "Switched to AWS Profile: $AWS_PROFILE"
          else
            echo "No profile selected."
          fi
        }

        function awspun() {
          unset AWS_PROFILE
          echo "AWS_PROFILE unset."
        }
      '')

      # 1Password CLI は Nix 管理外 (Homebrew 等) なので存在チェック付きで読む。
      (lib.mkOrder 1500 (lib.optionalString isDarwin ''
        [[ -f ~/.config/op/plugins.sh ]] && source ~/.config/op/plugins.sh
      ''))
    ];

    # Homebrew は Nix 管理外。HM が .zprofile を生成するので、
    # 手書きの .zprofile にあった shellenv をこちらへ移す。
    profileExtra = lib.optionalString isDarwin ''
      [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"
    '';

    shellAliases = {
      g = "cd $(ghq root)/$(ghq list | fzf)";
      kc = "kubectl";
      rm = "gomi";
    } // lib.optionalAttrs isDarwin {
      sed = "gsed";
      pbcopy = "pbcopy && pbpaste";
    };
  };

  # fzf / starship / zoxide / mise は HM モジュールに任せる。
  # 各モジュールが zsh 統合 (eval "$(... init zsh)" 相当) を自前で挿入するので、
  # initContent 側に手書きしない。
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };
}
