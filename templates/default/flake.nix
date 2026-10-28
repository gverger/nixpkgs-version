{
  description = "A new flake";

  inputs = {
    versions.url = "github:gverger/nixpkgs-version";
    nixpkgs.follows = "versions/nixpkgs";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        # Aligns nixpkgs on the version pinned by nixpkgs-version
        update-version = pkgs.writeShellApplication {
          name = "update-version";
          text = ''
            nix flake update versions "$@"
          '';
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.update-version ];
        };
      });
    };
}
