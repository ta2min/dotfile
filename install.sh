#!/bin/bash

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ユーザー名の取得（引数 > SUDO_USER > 環境変数 > 現在のユーザー）
# DevContainerでsudo経由で実行された場合、元のユーザーを取得
TARGET_USER="${1:-${SUDO_USER:-${USER:-$(whoami)}}}"

# スクリプトのディレクトリを取得
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfile_backup"

echo -e "${GREEN}Dotfiles のセットアップを開始します${NC}"
echo "Dotfiles ディレクトリ: $DOTFILES_DIR"
echo "対象ユーザー: $TARGET_USER"

# Nix環境の確認とセットアップ
echo ""
echo "=== Nix 環境の確認 ==="

# Nixの環境変数をロード
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  echo -e "${YELLOW}Nix環境変数をロード中 (multi-user)...${NC}"
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
elif [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  echo -e "${YELLOW}Nix環境変数をロード中 (single-user)...${NC}"
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# PATHの設定
if [ -d /nix/store ]; then
  export PATH="/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:$PATH"
fi

# Nixが利用可能か確認
if ! command -v nix &> /dev/null; then
  echo -e "${RED}エラー: Nix がインストールされていません${NC}"
  echo -e "${YELLOW}DevContainerのfeatureでNixをインストールしてください${NC}"
  exit 1
fi

echo -e "${GREEN}Nix が利用可能です ($(nix --version))${NC}"

# Home Managerのセットアップ
echo ""
echo "=== Home Manager のセットアップ ==="
if [ -f "$DOTFILES_DIR/flake.nix" ]; then
  echo -e "${YELLOW}Home Manager で環境を構築します...${NC}"

  # コンテナ環境での事前準備
  if [ -f "/.dockerenv" ] || [ -n "$REMOTE_CONTAINERS" ] || [ -n "$CODESPACES" ]; then
    TARGET_HOME=$(eval echo ~$TARGET_USER)
    echo -e "${YELLOW}Nixプロファイルディレクトリを準備中...${NC}"

    # プロファイルディレクトリを作成
    sudo mkdir -p "/nix/var/nix/profiles/per-user/$TARGET_USER"
    sudo chown -R "$TARGET_USER" "/nix/var/nix/profiles/per-user/$TARGET_USER"

    # ホームディレクトリの所有権を確認・修正
    if [ -d "$TARGET_HOME" ]; then
      echo -e "${YELLOW}ホームディレクトリの所有権を修正中...${NC}"
      sudo chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME"

      # 既存のdotfilesをバックアップ
      for file in .zshrc .gitconfig .zsh_plugins.txt; do
        if [ -f "$TARGET_HOME/$file" ] && [ ! -L "$TARGET_HOME/$file" ]; then
          echo -e "${YELLOW}既存ファイルをバックアップ: $file${NC}"
          sudo mv "$TARGET_HOME/$file" "$TARGET_HOME/$file.backup-$(date +%Y%m%d_%H%M%S)"
        fi
      done
    fi
  fi

  # プラットフォームの検出
  ARCH="$(uname -m)"
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
      PLATFORM="aarch64-linux"
    else
      PLATFORM="x86_64-linux"
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
      PLATFORM="aarch64-darwin"
    else
      PLATFORM="x86_64-darwin"
    fi
  else
    # デフォルトはアーキテクチャを検出
    if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
      PLATFORM="aarch64-linux"
    else
      PLATFORM="x86_64-linux"
    fi
  fi

  echo -e "${YELLOW}プラットフォーム: $PLATFORM${NC}"

  # コンテナ環境では sudo 経由で実行（環境変数を保持）
  if [ -f "/.dockerenv" ] || [ -n "$REMOTE_CONTAINERS" ] || [ -n "$CODESPACES" ]; then
    echo -e "${YELLOW}コンテナ環境: sudo経由で実行します（ユーザー: $TARGET_USER）${NC}"

    # nixコマンドのフルパスを取得
    NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
    if [ ! -f "$NIX_BIN" ]; then
      NIX_BIN="$(command -v nix)"
    fi

    sudo -E env \
      "PATH=/nix/var/nix/profiles/default/bin:$PATH" \
      "USER=$TARGET_USER" \
      "HOME=$(eval echo ~$TARGET_USER)" \
      "TARGET_USER=$TARGET_USER" \
      "$NIX_BIN" run home-manager/master --impure -- switch --flake "$DOTFILES_DIR#$PLATFORM"
  else
    nix run home-manager/master -- switch --flake "$DOTFILES_DIR#$PLATFORM"
  fi

  echo -e "${GREEN}Home Manager のセットアップが完了しました${NC}"
else
  echo -e "${YELLOW}flake.nix が見つかりませんでした。スキップします${NC}"
fi

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
