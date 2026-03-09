#!/bin/bash

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# スクリプトのディレクトリを取得
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfile_backup"

echo -e "${GREEN}Dotfiles のセットアップを開始します${NC}"
echo "Dotfiles ディレクトリ: $DOTFILES_DIR"

# バックアップディレクトリの作成
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p "$BACKUP_DIR"
  echo -e "${GREEN}バックアップディレクトリを作成しました: $BACKUP_DIR${NC}"
fi

# シンボリックリンクを作成する関数
create_symlink() {
  local source="$1"
  local target="$2"

  # ターゲットのディレクトリが存在しない場合は作成
  local target_dir="$(dirname "$target")"
  if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
    echo -e "${GREEN}ディレクトリを作成しました: $target_dir${NC}"
  fi

  # 既存のファイルまたはシンボリックリンクが存在する場合
  if [ -e "$target" ] || [ -L "$target" ]; then
    # 既に正しいシンボリックリンクの場合はスキップ
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
      echo -e "${YELLOW}スキップ: $target (既に正しくリンクされています)${NC}"
      return
    fi

    # バックアップ
    local backup_path="$BACKUP_DIR/$(basename "$target").$(date +%Y%m%d_%H%M%S)"
    mv "$target" "$backup_path"
    echo -e "${YELLOW}バックアップしました: $target -> $backup_path${NC}"
  fi

  # シンボリックリンクを作成
  ln -s "$source" "$target"
  echo -e "${GREEN}リンクを作成しました: $target -> $source${NC}"
}

# ホームディレクトリのファイル
echo ""
echo "=== ホームディレクトリのファイルを設定 ==="
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/zsh_plugins.txt" "$HOME/.zsh_plugins.txt"

# .config ディレクトリのファイル
echo ""
echo "=== .config ディレクトリのファイルを設定 ==="
create_symlink "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

echo ""
echo -e "${GREEN}セットアップが完了しました！${NC}"
echo ""
echo "次のステップ:"
echo "1. シェルを再起動するか、以下を実行してください:"
echo "   source ~/.zshrc"
echo ""
echo "2. Antidoteがプラグインをインストールします（初回起動時）"
echo ""
echo "3. 必要なツールがインストールされているか確認してください:"
echo "   - starship, fzf, zoxide, mise, antidote, tree, ghq, gomi"
