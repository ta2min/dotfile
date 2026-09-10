# dotfile

個人的なシェル環境の設定を Nix + Home Manager で管理するリポジトリです。

macOS (ARM64/Intel) と Linux (devcontainer) で同じ定義から環境を構築します。

## セットアップ

### 前提: Nix のインストール

macOS:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

devcontainer: `ghcr.io/devcontainers/features/nix:1` feature を使うか、
`nixos/nix` ベースイメージを使います。

### 適用

```bash
./install.sh
```

macOS でもコンテナでも同じコマンドです。プラットフォームとユーザー名は
実行時に自動判定されるので、ターゲットの指定は不要です。

手動で実行する場合:

```bash
nix run .#home-manager -- switch --flake .#default -b backup --impure
```

`--impure` は必須です。ユーザー名とホームディレクトリを `$USER` / `$HOME` から
読むため（コンテナごとに `vscode` / `node` / `ubuntu` などに変わる）で、
未設定の場合は誤ったホームに書き込まないよう即座に失敗します。

### 他プロジェクトの devcontainer で使う

VS Code の設定に以下を入れると、任意の devcontainer にこの環境が入ります。

```json
{
  "dotfiles.repository": "ta2min/dotfile",
  "dotfiles.installCommand": "install.sh"
}
```

## ファイル構成

```
dotfile/
├── flake.nix              # 入力の固定とエントリポイント
├── home.nix               # Home Manager のトップレベル設定
├── modules/
│   ├── packages.nix       # パッケージ一覧 (共通 / macOS専用)
│   ├── git.nix            # Git 設定
│   └── shell.nix          # Zsh 設定とツール統合
├── .config/
│   └── starship.toml      # Starship プロンプト設定
└── install.sh             # セットアップスクリプト
```

`.zshrc` や `.gitconfig` はリポジトリに置きません。
[modules/shell.nix](modules/shell.nix) と [modules/git.nix](modules/git.nix) から
Home Manager が生成します。

## 管理されるツール

### 全プラットフォーム共通

Nix (`home.packages` および各 HM モジュール) 経由:

- `starship` — プロンプト
- `fzf` — fuzzy finder
- `zoxide` — cd 改善 (`cd` として使う)
- `mise` — 言語ランタイム管理
- `antidote` — zsh プラグイン管理
- `tree`, `ghq`, `gh`, `git-open`, `gomi`, `gnused`

zsh プラグイン (antidote 経由、定義は [modules/shell.nix](modules/shell.nix)):

- `zsh-users/zsh-autosuggestions`
- `zsh-users/zsh-completions`
- `Aloxaf/fzf-tab`
- `zdharma-continuum/fast-syntax-highlighting`
- `paulirish/git-open`

### macOS 専用

- `docker`, `docker-buildx`, `docker-compose`
- `awscli2`
- `mysql84` (MySQL クライアント)
- 1Password SSH agent の `SSH_AUTH_SOCK`
- `sed` → `gsed`、`pbcopy` エイリアス

コンテナでは docker / aws / mysql を入れません。docker は devcontainer feature か
ホスト側に任せる方が軽量で確実です。必要になったら
[modules/packages.nix](modules/packages.nix) の `commonPackages` に移してください。

1Password CLI (`op`) は unfree のため Nix 管理外です。macOS では
`brew install 1password-cli` などで別途入れてください。
`~/.config/op/plugins.sh` があれば zsh から自動で読み込みます。

### mise 経由 (プロジェクトごと)

Go, Node.js, Bun, golangci-lint, staticcheck など。

## 設定を変えたとき

```bash
./install.sh    # または nix run .#home-manager -- switch --flake .#default --impure
exec zsh
```

## 依存の更新

```bash
nix flake update
./install.sh
```

## トラブルシューティング

### 古いシェルで確認すると Homebrew 版が見える

`command -v starship` が `/opt/homebrew/bin/...` を返す場合、そのシェルが
適用前の PATH を継承しています。新しいシェルで確認してください。

```bash
exec zsh
command -v starship    # ~/.nix-profile/bin/starship になる
```

### Could not find suitable profile directory

Home Manager の profile ディレクトリが無いときに出ます。
`install.sh` は事前に作成しますが、手動実行した場合は次を実行してください。

```bash
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles"
```

### 既存ファイルとの競合

`-b backup` を付けているので、既存の `~/.zshrc` などは `.backup` 拡張子を
付けて退避されます。

## 参考リンク

- [Nix](https://nixos.org/)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [Home Manager options](https://nix-community.github.io/home-manager/options.xhtml)
