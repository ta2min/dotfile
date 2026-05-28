{ config, pkgs, lib, ... }:

let
  # プラットフォーム検出
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Antidoteのパス (プラットフォーム別)
  antidotePath = if isDarwin
    then "/opt/homebrew/share/antidote/antidote.zsh"
    else "${pkgs.antidote}/share/antidote/antidote.zsh";
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # ヒストリ設定
    history = {
      size = 10000;
      save = 100000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      share = true;
    };

    # Zshオプション
    initContent = ''
      # 一般的な設定
      setopt correct                  # コマンド訂正
      setopt nobeep                   # ビープ音無効
      setopt notify                   # バックグラウンドジョブ完了通知
      setopt auto_pushd               # cd履歴を自動保存
      setopt auto_cd                  # ディレクトリ名のみでcd
      setopt interactive_comments     # コメント有効化

      # ヒストリオプション
      setopt hist_no_store            # historyコマンドを履歴に保存しない
      setopt hist_reduce_blanks       # 余分な空白を詰める
      setopt hist_verify              # !!実行時に確認

      # 補完設定
      zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      # キーバインディング
      bindkey -e  # emacsキーマップ

      # Ctrl-Yで上のディレクトリに移動
      function cd-up { zle push-line && LBUFFER='builtin cd ..' && zle accept-line }
      zle -N cd-up
      bindkey "^Y" cd-up

      # Ctrl-Dでログアウトしない
      setopt ignoreeof

      # Ctrl-Wでパスをスラッシュ単位で削除
      autoload -U select-word-style
      select-word-style bash

      # Ctrl-[で直前コマンドの単語を挿入
      autoload -Uz smart-insert-last-word
      zstyle :insert-last-word match '*([[:alpha:]/\\]?|?[[:alpha:]/\\])*'
      zle -N insert-last-word smart-insert-last-word
      bindkey '^[' insert-last-word

      # プラグイン (Antidote)
      [[ -f ${antidotePath} ]] && source ${antidotePath}
      if (( $+functions[antidote] )); then
        antidote load ~/.zsh_plugins.txt
      fi

      # compinit
      : ''${COMPDUMPFILE:=''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump}
      mkdir -p "''${COMPDUMPFILE:h}"
      autoload -U compinit
      compinit -d "''${COMPDUMPFILE}"

      # cd先のファイル一覧表示
      [ -z "$ENHANCD_ROOT" ] && function chpwd { tree -L 1 }
      [ -z "$ENHANCD_ROOT" ] || export ENHANCD_HOOK_AFTER_CD="tree -L 1"

      # sshコマンド補完
      function _ssh { compadd $(fgrep 'Host ' ~/.ssh/config | grep -v '*' | awk '{print $2}' | sort) }

      # カスタム関数
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

      # ツール初期化
      source <(fzf --zsh)
      eval "$(starship init zsh)"
      eval "$(${pkgs.mise}/bin/mise activate zsh)"
      eval "$(zoxide init zsh --cmd cd)"

      # 1Password CLI (存在する場合のみ)
      [[ -f ~/.config/op/plugins.sh ]] && source ~/.config/op/plugins.sh
    '';

    # エイリアス
    shellAliases = {
      g = "cd $(ghq root)/$(ghq list | fzf)";
      kc = "kubectl";
      rm = "gomi";
    } // lib.optionalAttrs isDarwin {
      # macOS専用エイリアス
      sed = "gsed";
      pbcopy = "pbcopy && pbpaste";
    };

    # 環境変数 (macOS専用のPATH設定)
    sessionVariables = lib.optionalAttrs isDarwin {
      PATH = "/opt/homebrew/opt/mysql-client/bin:$PATH";
    };
  };

  # fzf統合
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # starship統合
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # zoxide統合
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };
}
