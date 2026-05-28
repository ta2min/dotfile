: "一般的な設定" && {
  typeset -g ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE='20'

  zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert
  zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' #補完で大文字を区別しない

  setopt correct # 入力しているコマンド名が間違っている場合にもしかして：を出す。
  setopt nobeep # ビープを鳴らさない
  setopt no_tify # バックグラウンドジョブが終了したらすぐに知らせる。
  # unsetopt auto_menu # タブによるファイルの順番切り替えをしない
  setopt auto_pushd # cd -[tab]で過去のディレクトリにひとっ飛びできるようにする
  setopt auto_cd # ディレクトリ名を入力するだけでcdできるようにする
  setopt interactive_comments # コマンドラインでも # 以降をコメントと見なす
}

: "ヒストリ関連の設定" && {
  HISTSIZE=10000 # メモリに保存される履歴の件数
  SAVEHIST=100000 # 履歴ファイルに保存される履歴の件数
  HISTFILE=~/.zsh_history # 履歴ファイル
  setopt hist_ignore_dups # 直前と同じコマンドをヒストリに追加しない
  setopt hist_ignore_all_dups # 重複するコマンドは古い法を削除する
  setopt share_history # 異なるウィンドウでコマンドヒストリを共有する
  setopt hist_no_store # historyコマンドは履歴に登録しない
  setopt hist_reduce_blanks # 余分な空白は詰めて記録
  setopt hist_verify # `!!`を実行したときにいきなり実行せずコマンドを見せる
}

: "キーバインディング" && {
  bindkey -e # emacs キーマップを選択

  : "Ctrl-Yで上のディレクトリに移動できる" && {
    function cd-up { zle push-line && LBUFFER='builtin cd ..' && zle accept-line }
    zle -N cd-up
    bindkey "^Y" cd-up
  }

  : "Ctrl-Dでシェルからログアウトしない" && {
    setopt ignoreeof
  }

  : "Ctrl-Wでパスの文字列などをスラッシュ単位でdeleteできる" && {
    autoload -U select-word-style
    select-word-style bash
  }

  : "Ctrl-[で直前コマンドの単語を挿入できる" && {
    autoload -Uz smart-insert-last-word
    zstyle :insert-last-word match '*([[:alpha:]/\\]?|?[[:alpha:]/\\])*'
    zle -N insert-last-word smart-insert-last-word
    bindkey '^[' insert-last-word
    # see http://qiita.com/mollifier/items/1a9126b2200bcbaf515f
  }
}

: "プラグイン (Antidote)" && {
  # Antidote本体（Homebrewなら /opt/homebrew/share/antidote/antidote.zsh になることもあります）
  # ここはあなたの環境の置き場所に合わせてどれか1つを有効化してください。

  # 例1: git cloneで ~/.antidote に入れる場合（おすすめ）
  #   [[ -f ~/.antidote/antidote.zsh ]] && source ~/.antidote/antidote.zsh

  # 例2: Homebrewの例（必要なら）
  [[ -f /opt/homebrew/share/antidote/antidote.zsh ]] && source /opt/homebrew/share/antidote/antidote.zsh

  # プラグイン読み込み（定義ファイルは ~/.zsh_plugins.txt）
  if (( $+functions[antidote] )); then
    antidote load ~/.zsh_plugins.txt
  fi
}

: "compinit（プラグイン読み込み後に実行）" && {
  # compdumpの置き場（あなたの元の変数を尊重）
  : ${COMPDUMPFILE:=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump}
  mkdir -p "${COMPDUMPFILE:h}"

  autoload -U compinit
  compinit -d "${COMPDUMPFILE}"
}

: "cd先のディレクトリのファイル一覧を表示する" && {
  [ -z "$ENHANCD_ROOT" ] && function chpwd { tree -L 1 } # enhancdがない場合
  [ -z "$ENHANCD_ROOT" ] || export ENHANCD_HOOK_AFTER_CD="tree -L 1" # enhancdがあるときはそのHook機構を使う
}

: "sshコマンド補完を~/.ssh/configから行う" && {
  function _ssh { compadd $(fgrep 'Host ' ~/.ssh/config | grep -v '*' |  awk '{print $2}' | sort) }
}

# gitignore生成コマンド
function gi() {
  curl -L -s https://www.gitignore.io/api/$@
}

function awsp() {
  local profile
  # ~/.aws/config からプロファイル名の一覧を取得して fzf で選択
  profile=$(aws configure list-profiles | fzf --height 40% --reverse --border --prompt="Select AWS Profile > ")

  if [ -n "$profile" ]; then
    export AWS_PROFILE=$profile
    echo "Switched to AWS Profile: $AWS_PROFILE"
  else
    echo "No profile selected."
  fi
}

# プロファイルを解除する関数
function awspun() {
  unset AWS_PROFILE
  echo "AWS_PROFILE unset."
}

: "alias" && {
  alias sed='gsed'
  alias g='cd $(ghq root)/$(ghq list | fzf)'
  alias pbcopy='pbcopy && pbpaste'
  alias kc="kubectl"
  alias rm=gomi
}

: "PATH追加": && {
  export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
}

: "セッティング系" && {
  source <(fzf --zsh)
  eval "$(starship init zsh)"
  eval "$(/opt/homebrew/bin/mise activate zsh)"
  eval "$(zoxide init zsh --cmd cd)"
  source ~/.config/op/plugins.sh
}
