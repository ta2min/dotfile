{ config, pkgs, lib, ... }:

{
  home.stateVersion = "24.05";

  imports = [
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/shell.nix
  ];

  # NixOS 以外の Linux (devcontainer 等) で nix profile の PATH / TERMINFO /
  # zsh の fpath を正しく通すための公式スイッチ。
  targets.genericLinux.enable = pkgs.stdenv.hostPlatform.isLinux;

  xdg.configFile."starship.toml".source = ./.config/starship.toml;

  # 1Password の SSH agent は macOS のパスにしか存在しない。
  home.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  programs.home-manager.enable = true;
}
