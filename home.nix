{ config, pkgs, lib, ... }:

{
  # Home Managerのバージョン設定
  home.stateVersion = "24.05";

  # ユーザー情報 (flake.nixから上書き可能)
  home.username = lib.mkDefault "sota.tatsumi";
  home.homeDirectory = lib.mkDefault (
    if pkgs.stdenv.isDarwin
    then "/Users/${config.home.username}"
    else "/home/${config.home.username}"
  );

  # Unfreeパッケージを許可 (1Password CLI等)
  nixpkgs.config.allowUnfree = true;

  # モジュールのインポート
  imports = [
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/shell.nix
  ];

  # Home Managerによる設定ファイル管理
  home.file = {
    ".config/starship.toml".source = ./.config/starship.toml;
    ".zsh_plugins.txt".source = ./zsh_plugins.txt;
  };

  # Home Manager自体にプログラム管理を任せる
  programs.home-manager.enable = true;
}
