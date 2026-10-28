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

        # Warns when nixpkgs-version has moved since flake.lock was written
        check-version = pkgs.writeShellApplication {
          name = "check-version";
          runtimeInputs = [ pkgs.jq pkgs.git pkgs.coreutils ];
          text = ''
            [ -f flake.lock ] || exit 0
            locked=$(jq -r '.nodes[.nodes.root.inputs.versions].locked.rev' flake.lock)
            latest=$(timeout 3 git ls-remote https://github.com/gverger/nixpkgs-version HEAD | cut -f1) || exit 0
            if [ -n "$latest" ] && [ "$locked" != "$latest" ]; then
              echo "warning: nixpkgs-version has moved (''${locked:0:7} -> ''${latest:0:7}), run update-version" >&2
            fi
          '';
        };
      });

      devShells = forAllSystems (pkgs:
        let own = self.packages.${pkgs.stdenv.hostPlatform.system}; in {
          default = pkgs.mkShell {
            packages = [ own.update-version own.check-version ];
            shellHook = ''
              check-version
            '';
          };
        });
    };
}
