{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { nixpkgs, ... }: {
    # Pins the nixos version; other flakes follow it via `nixpkgs.follows = "versions/nixpkgs"`

    templates.default = {
      path = ./templates/default;
      description = "Flake whose nixpkgs follows nixpkgs-version";
    };
  };
}
