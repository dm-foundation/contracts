{
  description = "UAP - Unstoppable Affiliates Protocol";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    foundry.url = "github:shazow/foundry.nix"; # Use monthly branch for permanent releases
    muKnIOpkgs.url = "github:MuKnIO/nixpkgs/solc"; # solc in master is broken and out of date
  };

  outputs = {
    self,
    nixpkgs,
    utils,
    foundry,
    muKnIOpkgs,
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (self: super: {
            solc = muKnIOpkgs.legacyPackages.${system}.solc;
          })
          foundry.overlay
        ];
      };

          buildInputs = with pkgs; [
            # smart contracct dependencies
            foundry-bin
            solc
          ];
    in {
      devShell = 
        pkgs.mkShell {
          inherit buildInputs;

          # Decorative prompt override so we know when we're in a dev shell
          shellHook = ''
            export PS1="[dev] $PS1"
            export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
          '';
        };
      packages = {
        test = let
          pkgs = nixpkgs.legacyPackages.${system};
        in
          pkgs.stdenv.mkDerivation {
            inherit buildInputs;
            name = "DMP contracts";

            unpackPhase = ":";

            buildPhase = ''
              forge compile --no-auto-detect
            '';

            checkPhase = ''
              forge test --no-auto-detect
            '';

            installPhase = ":";

            doCheck = true;
          };
      };
    });
}
