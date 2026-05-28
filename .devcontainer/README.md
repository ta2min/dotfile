# DevContainer でのセットアップ

このdotfile設定はUbuntuベースのdevcontainerでも利用できます。

## 使い方

### 1. VS Codeでリポジトリを開く

```bash
git clone https://github.com/ta2min/dotfile.git
code dotfile
```

### 2. DevContainerで再オープン

VS Codeのコマンドパレット (Cmd+Shift+P / Ctrl+Shift+P) から:
```
Dev Containers: Reopen in Container
```

### 3. 自動セットアップ

コンテナ起動後、自動的に以下が実行されます:
- Nixのセットアップ
- Home Managerによる設定適用
- Zsh、Git、各種ツールのインストール

### 手動適用する場合

```bash
# コンテナ内で実行
nix run home-manager/master -- switch --flake /workspace#x86_64-linux
```

## プラットフォーム別の設定

### macOS (ホスト環境)

```bash
# Apple Silicon
home-manager switch --flake .#aarch64-darwin

# デフォルト (Apple Silicon)
home-manager switch --flake .#default
```

### Linux (DevContainer)

```bash
home-manager switch --flake .#x86_64-linux
```

## プラットフォーム固有の動作

### macOS専用
- `pbcopy`/`pbpaste` エイリアス
- `sed` → `gsed` エイリアス
- Homebrew経由の`/opt/homebrew`パス
- 1Password CLI

### Linux専用
- Nix経由のantidoteパス
- `/home/`配下のホームディレクトリ

### 共通
- Zsh設定、キーバインド
- Git設定、エイリアス
- starship、fzf、zoxide統合
- mise (言語ランタイム管理)
- ghq、gh、gomi、tree等のツール
- Docker、AWS CLI

## トラブルシューティング

### Nixが見つからない

```bash
# Nix環境を再読み込み
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Home Managerの適用失敗

```bash
# Flake.lockを再生成
nix flake update

# 強制適用
home-manager switch --flake .#x86_64-linux --impure
```

### ユーザー名が違う場合

`flake.nix`のusernameを環境に合わせて変更:

```nix
homeConfigurations."x86_64-linux" = mkHomeConfiguration "x86_64-linux" "yourname";
```

適用時:
```bash
home-manager switch --flake .#x86_64-linux
```
