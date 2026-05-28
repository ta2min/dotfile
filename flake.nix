{
  description = "ta2min's dotfiles managed with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # デフォルトユーザー名 (必要に応じて変更)
      defaultUser = "sota.tatsumi";

      # 各プラットフォーム用の設定を生成
      mkHomeConfiguration = system: username: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          ./home.nix
          { home.username = username; }
        ];
      };
    in
    {
      # macOS (Apple Silicon)
      homeConfigurations."aarch64-darwin" = mkHomeConfiguration "aarch64-darwin" defaultUser;

      # Linux (devcontainer用)
      homeConfigurations."x86_64-linux" = mkHomeConfiguration "x86_64-linux" defaultUser;

      # デフォルト (macOS ARM64)
      homeConfigurations.default = mkHomeConfiguration "aarch64-darwin" defaultUser;
    };
}
