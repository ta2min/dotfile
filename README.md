# dotfile

個人的なシェル環境の設定ファイルを管理するリポジトリです。

## 含まれる設定ファイル

- `.zshrc` - Zshの設定ファイル
- `.gitconfig` - Gitの設定とエイリアス
- `.config/starship.toml` - Starshipプロンプトの設定（Gruvbox Darkテーマ）

## セットアップ

### 前提条件

以下のツールが必要です：

```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 必須ツール
brew install starship fzf zoxide mise antidote tree ghq gomi gnu-sed mysql-client

# 1Password CLI（オプション）
brew install --cask 1password-cli
```

### インストール

```bash
# リポジトリをクローン
git clone https://github.com/ta2min/dotfile.git ~/ghq/github.com/ta2min/dotfile
cd ~/ghq/github.com/ta2min/dotfile

# セットアップスクリプトを実行
./install.sh
```

既存の設定ファイルがある場合は `~/.dotfile_backup` にバックアップされます。