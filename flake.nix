{
  description = "AOC 2025";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, systems }@inputs:
    let
      systems = import inputs.systems;
      lib = nixpkgs.lib;
      forAllSystems = lib.genAttrs systems;
      pkgsFor = lib.genAttrs systems (system: import nixpkgs { inherit system; });
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              zig
              zls

              scipopt-scip
            ];
          };
        }
      );
    };
}
