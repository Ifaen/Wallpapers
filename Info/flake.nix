{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {self, ...} @ inputs: let
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  in {
    devShells."x86_64-linux".default = pkgs.mkShell {
      packages = [pkgs.jq];
    };
  };
}
