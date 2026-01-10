{
  description = "Python development environment with uv";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Support multiple systems
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              python311
              uv
              git
            ];

            shellHook = ''
              echo "🐍 Python $(python --version) with uv"
              echo "📦 Run 'uv init' to initialize a new project"
            '';
          };
        }
      );
    };
}
