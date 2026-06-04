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

  nix run home-manager/master -- switch --flake "$DOTFILES_DIR#$PLATFORM" -b backup

  echo -e "${GREEN}Home Manager のセットアップが完了しました${NC}"
else
  echo -e "${YELLOW}flake.nix が見つかりませんでした。スキップします${NC}"
fi

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
