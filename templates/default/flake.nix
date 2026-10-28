{
  description = "A new flake";

  inputs = {
    versions.url = "github:gverger/nixpkgs-version";
    nixpkgs.follows = "versions/nixpkgs";
  };

  outputs = { self, nixpkgs, versions, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = versions.lib.mkShell pkgs {
          packages = [ ];
        };
      });
    };
}
