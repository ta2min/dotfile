#!/usr/bin/env bash
#
# dotfiles セットアップ。macOS と Linux (devcontainer) の両方で動く。
# Nix 本体のインストールは対象外 (macOS は手動、devcontainer は feature)。

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\033[0;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$1"; }
die() { printf '\033[0;31mエラー:\033[0m %s\n' "$1" >&2; exit 1; }

# --- Nix を PATH に載せる -----------------------------------------------------
# ログインシェルを経由しない実行 (postCreateCommand 等) では nix が PATH に
# 無いことがあるため、既知の場所から読み込む。
if ! command -v nix >/dev/null 2>&1; then
  for profile in \
    /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
    "$HOME/.nix-profile/etc/profile.d/nix.sh"
  do
    # shellcheck disable=SC1090
    [ -f "$profile" ] && . "$profile" && break
  done
fi
export PATH="/nix/var/nix/profiles/default/bin:$PATH"

command -v nix >/dev/null 2>&1 || die "nix が見つかりません。先に Nix をインストールしてください。"
log "nix: $(nix --version)"

# --- flakes を有効にする -----------------------------------------------------
# Determinate Systems 版は既に有効だが、公式インストーラや古い devcontainer
# feature では未設定なことがある。--extra-experimental-features で毎回渡すより
# 設定に書いておく方が、後続の home-manager 実行でも効く。
NIX_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nix"
if ! nix flake --help >/dev/null 2>&1; then
  log "flakes を有効化します ($NIX_CONF_DIR/nix.conf)"
  mkdir -p "$NIX_CONF_DIR"
  if ! grep -qs 'experimental-features.*flakes' "$NIX_CONF_DIR/nix.conf"; then
    echo 'extra-experimental-features = nix-command flakes' >> "$NIX_CONF_DIR/nix.conf"
  fi
fi

# --- home-manager の profile 置き場を用意 ------------------------------------
# home-manager の activation script は profile ディレクトリが存在しないと
# 「Could not find suitable profile directory」で失敗する。
# XDG 側 ($HOME 配下) なら sudo 無しで作れるので、必ずこちらを先に作る。
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"

# --- 適用 --------------------------------------------------------------------
# --impure: flake.nix が $USER / $HOME を読むため必須。
# nix run .#home-manager: flake.lock で固定した home-manager を使う。
# `nix run home-manager/master` だと毎回別バージョンを取得して壊れる。
log "home-manager で環境を構築します (user=$USER home=$HOME)"
nix run "$DOTFILES_DIR#home-manager" -- \
  switch --flake "$DOTFILES_DIR#default" -b backup --impure

log "完了しました。シェルを再起動してください: exec zsh"
