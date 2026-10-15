{ pkgs, lib, ... }:

let
  # 全プラットフォーム共通。コンテナでも軽量に入るシェルツールに絞る。
  commonPackages = with pkgs; [
    tree        # ディレクトリツリー表示
    ghq         # リポジトリ管理
    gh          # GitHub CLI
    git-open    # GitHubをブラウザで開く
    gomi        # rmの安全な代替
    gnused      # GNU sed
    herdr       # コーディングエージェントのTUIマネージャ
  ];

  # macOS 専用。docker / mysql / aws はコンテナ側では
  # devcontainer feature やホストに任せるため、ここに置く。
  darwinPackages = with pkgs; [
    docker
    docker-buildx
    docker-compose
    devcontainer # devcontainer CLI
    awscli2
    mysql84     # MySQLクライアント
  ];
in
{
  # starship / fzf / zoxide / mise / antidote は modules/shell.nix の
  # HM モジュールが home.packages へ追加するのでここには書かない。
  home.packages = commonPackages
    ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin darwinPackages;
}
