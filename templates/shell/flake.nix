{
  description = "Shell/DevOps development environment";

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
              # Shell scripting
              bash
              shellcheck

              # DevOps tools
              kubectl
              jq
              yq

              # Utilities
              git
            ];

            shellHook = ''
              echo "🔧 Shell/DevOps environment ready"
              echo "📦 Available tools: kubectl, jq, yq, shellcheck"
            '';
          };
        }
      );
    };
}
