# dotfile

個人的なシェル環境の設定ファイルをNixで管理するリポジトリです。

**マルチプラットフォーム対応**: macOS (ARM64/Intel) と Linux (devcontainer) で動作します。

## 含まれる設定

- **パッケージ管理**: Nix + Home Manager
- **シェル設定**: Zsh + Starship + Antidote
- **Git設定**: エイリアスとコア設定
- **プロンプト**: Starship (Gruvbox Dark)
- **言語ランタイム**: mise経由で管理
- **DevContainer対応**: Ubuntuベースのコンテナで即座に環境構築

## セットアップ

### 前提条件

#### 1. Nixのインストール

```bash
# Nix (Determinate Systems版・推奨)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# または公式版
sh <(curl -L https://nixos.org/nix/install)
```

#### 2. Flakesの有効化 (公式版Nixの場合)

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### インストール手順

#### 方法1: macOSで使用 (推奨)

```bash
# リポジトリをクローン
git clone https://github.com/ta2min/dotfile.git ~/ghq/github.com/ta2min/dotfile
cd ~/ghq/github.com/ta2min/dotfile

# Apple Silicon Mac
# --impure: flake.nix 内の $USER 参照 (builtins.getEnv) を有効にするため必須
nix run home-manager/master -- switch --flake .#aarch64-darwin --impure

# Linux/DevContainer
nix run home-manager/master -- switch --flake .#x86_64-linux --impure

# デフォルト (Apple Silicon)
nix run home-manager/master -- switch --flake .#default --impure
```

#### 方法2: DevContainerで使用

VS Codeでリポジトリを開き、コマンドパレットから:
```
Dev Containers: Reopen in Container
```

自動的にNix環境がセットアップされます。詳細は [.devcontainer/README.md](.devcontainer/README.md) を参照。

#### 方法3: 既存環境との併用

既存の設定を残したまま段階的に移行する場合:

```bash
# 既存の.zshrcをバックアップ
cp ~/.zshrc ~/.zshrc.backup

# Home Managerで適用 (既存ファイルは上書きされます)
# プラットフォームに応じたターゲットを指定
nix run home-manager/master -- switch --flake .#aarch64-darwin

# 問題があれば元に戻せます
# cp ~/.zshrc.backup ~/.zshrc
```

### 設定の更新

```bash
cd ~/ghq/github.com/ta2min/dotfile

# 設定ファイルを編集後、適用 (プラットフォームに応じて選択)
home-manager switch --flake .#aarch64-darwin  # macOS ARM64
home-manager switch --flake .#x86_64-linux    # Linux/DevContainer
home-manager switch --flake .#default         # デフォルト (macOS ARM64)
```

## ファイル構成

```
dotfile/
├── flake.nix                    # Nix Flake定義 (マルチプラットフォーム対応)
├── home.nix                     # Home Manager設定
├── modules/
│   ├── packages.nix            # パッケージ一覧 (プラットフォーム別)
│   ├── git.nix                 # Git設定
│   └── shell.nix               # Zsh設定 (プラットフォーム別)
├── .devcontainer/
│   ├── devcontainer.json       # DevContainer設定
│   └── README.md               # DevContainer利用ガイド
├── .config/
│   └── starship.toml           # Starshipプロンプト設定
├── zsh_plugins.txt             # Antidoteプラグイン定義
├── .zshrc                      # (レガシー・参照用)
├── .gitconfig                  # (レガシー・参照用)
└── install.sh                  # (レガシー・非推奨)
```

## 管理されるツール

### Nix経由でインストール (全プラットフォーム共通)
- `starship` - プロンプト
- `fzf` - fuzzy finder
- `zoxide` - cd改善
- `tree` - ディレクトリツリー
- `ghq` - リポジトリ管理
- `git-open` - GitHub統合
- `gomi` - 安全なrm代替
- `gnused` - GNU sed
- `mise` - 言語ランタイム管理
- `mysql80` - MySQLクライアント
- `antidote` - Zshプラグイン管理

### macOS専用
- `1password` - 1Password CLI
- `pbcopy`/`pbpaste` エイリアス
- Homebrew経由のMySQL client PATH

### mise経由で管理 (プロジェクトごと)
- Go, Node.js, Bun, golangci-lint, staticcheck など

## トラブルシューティング

### パスが通らない場合

```bash
# Home Managerのパスを確認
echo $PATH | grep nix

# シェルを再起動
exec zsh
```

### 既存ファイルとの競合

Home Managerは`~/.zshrc`や`~/.gitconfig`を管理しようとします。
既存ファイルがある場合は以下の手順:

1. バックアップ: `mv ~/.zshrc ~/.zshrc.backup`
2. 適用: `home-manager switch --flake .#aarch64-darwin`
3. 必要に応じてカスタム設定を[modules/shell.nix](modules/shell.nix)に追記

### Antidoteが見つからない場合

```bash
# Antidoteのパスを確認
which antidote

# Homebrewとの競合を避ける場合
brew uninstall antidote
```

## レガシー環境への切り戻し

```bash
# Nixをアンインストール
/nix/nix-installer uninstall

# バックアップから復元
cp ~/.zshrc.backup ~/.zshrc
cp ~/.gitconfig.backup ~/.gitconfig

# 従来のinstall.shを使用
./install.sh
```

## 参考リンク

- [Nix公式](https://nixos.org/)
- [Home Manager](https://github.com/nix-community/home-manager)
- [Nix Flakes入門](https://nixos.wiki/wiki/Flakes)
