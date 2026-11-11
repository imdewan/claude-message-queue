{
  description = "Claude Message Queue - durable next-turn messages for Claude Code";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      overlays.default = final: _prev: {
        claude-message-queue = final.callPackage ./nix/package.nix { };
      };

      packages = forAllSystems (pkgs: rec {
        claude-message-queue = pkgs.callPackage ./nix/package.nix { };
        default = claude-message-queue;
      });

      apps = forAllSystems (pkgs: rec {
        claude-queue = {
          type = "app";
          program = "${self.packages.${pkgs.system}.default}/bin/claude-queue";
        };
        default = claude-queue;
      });

      checks = forAllSystems (pkgs: {
        package = self.packages.${pkgs.system}.default;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            self.packages.${pkgs.system}.default
            pkgs.git
            pkgs.python3
          ];
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
