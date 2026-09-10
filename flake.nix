{
  description = "ta2min's dotfiles managed with Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      inherit (nixpkgs) lib;

      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];

      # コンテナごとにユーザー名が変わる (vscode / node / ubuntu / root) ため、
      # username と homeDirectory は評価時に環境から読む。よって --impure が必須。
      # 空のまま既定値にフォールバックすると別ユーザーの home を書き換えて壊れるので、
      # 未設定なら即座に失敗させる。
      envOrThrow = name:
        let value = builtins.getEnv name;
        in
        if value != "" then
          value
        else
          throw ''
            環境変数 ${name} が空です。--impure を付けて実行してください。
            例: nix run .#home-manager -- switch --flake .#default --impure
          '';

      mkHome = system: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          ./home.nix
          {
            home.username = envOrThrow "USER";
            home.homeDirectory = envOrThrow "HOME";
          }
        ];
      };
    in
    {
      # 通常はこれを使う。system も実行環境から判定するので
      # プラットフォームごとにターゲットを指定し分ける必要がない。
      homeConfigurations = lib.genAttrs systems mkHome // {
        default = mkHome builtins.currentSystem;
      };

      # flake.lock で固定した home-manager。`nix run home-manager/master` のように
      # 毎回ネットから別バージョンを取得して壊れるのを避けるためにこちらを使う。
      packages = lib.genAttrs systems (system: {
        home-manager = home-manager.packages.${system}.default;
        default = home-manager.packages.${system}.default;
      });
    };
}
