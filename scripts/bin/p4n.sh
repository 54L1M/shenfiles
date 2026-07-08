#!/usr/bin/env bash
# P4_DESC: Nix initializer — scaffold new projects with flake.nix and direnv

source "$(dirname "$0")/../lib/colors/colors.sh"

show_help() {
    p4_header "p4n - Nix Project Initializer"
    p4_info "Usage: p4n <project-name> [lang]"
    echo
    p4_title "Languages:"
    p4_cmd "go" "" "Go toolchain (go, gopls, gotools, delve)"
    p4_cmd "python, py" "" "Python (python3, uv, ruff)"
    p4_cmd "ts, typescript" "" "TypeScript/Node (nodejs, pnpm, typescript, ts-lsp)"
    p4_cmd "(none)" "" "Generic dev shell — empty buildInputs"
    echo
    p4_example "p4n my-api go"
    p4_example "p4n my-tool py"
    p4_example "p4n my-app ts"
}

PROJECT_NAME=$1
LANG_CHOICE=$2

case "$PROJECT_NAME" in
    -h | --help | help)
        show_help
        exit 0
        ;;
esac

if [ -z "$PROJECT_NAME" ]; then
    p4_error "Please provide a project name."
    echo "Usage: p4n <project-name> [go|python|ts]"
    exit 1
fi

# Resolve language into flake packages, shellHook body, and extra gitignore lines
BUILD_INPUTS=""
LANG_HOOK=""
EXTRA_GITIGNORE=""

case "$LANG_CHOICE" in
    go)
        BUILD_INPUTS=$(cat <<'PKGS'
            go
            gopls
            gotools
            go-tools
            delve
PKGS
)
        LANG_HOOK='echo "go $(go version | cut -d" " -f3)"'
        EXTRA_GITIGNORE=$(cat <<'GI'
/bin/
vendor/
GI
)
        ;;
    python | py)
        BUILD_INPUTS=$(cat <<'PKGS'
            python3
            uv
            ruff
PKGS
)
        LANG_HOOK=$(cat <<'HOOK'
echo "python $(python3 --version | cut -d" " -f2)"

            # Bootstrap a uv-managed venv; runtime deps live in uv.lock, not the flake
            export UV_PYTHON="${pkgs.python3}/bin/python3"
            [ -d .venv ] || uv venv --quiet
            source .venv/bin/activate
HOOK
)
        EXTRA_GITIGNORE=$(cat <<'GI'
__pycache__/
.venv/
*.pyc
GI
)
        ;;
    ts | typescript)
        BUILD_INPUTS=$(cat <<'PKGS'
            nodejs
            pnpm
            nodePackages.typescript
            nodePackages.typescript-language-server
PKGS
)
        LANG_HOOK='echo "node $(node --version)"'
        EXTRA_GITIGNORE=$(cat <<'GI'
node_modules/
dist/
GI
)
        ;;
    "")
        BUILD_INPUTS="            # Add project-specific packages here"
        LANG_HOOK=""
        ;;
    *)
        p4_error "Unknown language: $LANG_CHOICE"
        p4_tip "Supported: go, python (py), ts (typescript)"
        exit 1
        ;;
esac

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
$BUILD_INPUTS
          ];

          shellHook = ''
            echo "Successfully entered the $PROJECT_NAME development environment"
            ${LANG_HOOK}
          '';
        };
      }
    );
}
EOF

# 1b. Language-specific project files
case "$LANG_CHOICE" in
    python | py)
        cat <<EOF > pyproject.toml
[project]
name = "$PROJECT_NAME"
version = "0.1.0"
description = ""
requires-python = ">=3.11"
dependencies = []
EOF
        ;;
esac

# 2. Create .envrc for direnv
echo "use flake" > .envrc
direnv allow

# 3. Initialize Git repo
git init
cat <<EOF > .gitignore
.direnv/
.env
result
$EXTRA_GITIGNORE
EOF
git add .
git commit -m "initial commit"

p4_success "Project '$PROJECT_NAME' initialized with Nix and direnv${LANG_CHOICE:+ ($LANG_CHOICE)}."
