#!/usr/bin/env bash

source "$(dirname "$0")/../lib/colors/colors.sh"

PROJECT_NAME=$1

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Please provide a project name.${NC}"
    echo "Usage: p4n <project-name>"
    exit 1
fi

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

# 1. Create Nix Flake boilerplate
cat <<EOF > flake.nix
{
  description = "$PROJECT_NAME development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Add project-specific packages here
          ];

          shellHook = ''
            echo "Successfully entered the $PROJECT_NAME development environment"
          '';
        };
      }
    );
}
EOF

# 2. Create .envrc for direnv
echo "use flake" > .envrc
direnv allow

# 3. Initialize Git repo
git init
cat <<EOF > .gitignore
.direnv/
.env
result
EOF
git add .
git commit -m "initial commit"

echo -e "${GREEN}Project '$PROJECT_NAME' initialized with Nix and direnv.${NC}"
