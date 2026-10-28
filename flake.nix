{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # Pins the nixos version; other flakes follow it via `nixpkgs.follows = "versions/nixpkgs"`
      # and must name this input `versions` for the commands below to work.

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

      # pkgs.mkShell with update-version and check-version, checking on shell entry
      lib.mkShell = pkgs: args:
        let own = self.packages.${pkgs.stdenv.hostPlatform.system}; in
        pkgs.mkShell (args // {
          packages = (args.packages or [ ]) ++ [ own.update-version own.check-version ];
          shellHook = ''
            check-version
          '' + (args.shellHook or "");
        });

      templates.default = {
        path = ./templates/default;
        description = "Flake whose nixpkgs follows nixpkgs-version";
      };
    };
}
