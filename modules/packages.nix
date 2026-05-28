{ pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # 共通パッケージ
  commonPackages = with pkgs; [
    # シェルツール
    starship    # プロンプト
    fzf         # fuzzy finder
    zoxide      # cd改善
    tree        # ディレクトリツリー表示

    # 開発ツール
    ghq         # リポジトリ管理
    gh          # GitHub CLI
    git-open    # GitHubをブラウザで開く

    # コンテナツール
    docker
    docker-buildx
    docker-compose

    # クラウドツール
    awscli2     # AWS CLI v2

    # ユーティリティ
    gomi        # rmの安全な代替
    gnused      # GNU sed

    # 言語ランタイム管理
    mise

    # データベース
    mysql84     # MySQLクライアント

    # Zshプラグイン管理
    antidote
  ];

  # macOS専用パッケージ
  darwinPackages = with pkgs; [
    _1password-cli  # 1Password CLI
  ];

  # Linux専用パッケージ
  linuxPackages = with pkgs; [
    # 必要に応じて追加
  ];
in
{
  # システム全体で使うパッケージ
  home.packages = commonPackages
    ++ lib.optionals isDarwin darwinPackages
    ++ lib.optionals isLinux linuxPackages;
}
