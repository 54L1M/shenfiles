#!/bin/bash

set -e

# --- Configuration ---
# Find the repository root directory based on the script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

FLAKE_PATH="$REPO_ROOT/nix" # The flake is in the 'nix' directory
CREATE_DIRS_SCRIPT="$REPO_ROOT/scripts/bin/create_dirs.sh"
NIX_CONF="$HOME/.config/nix/nix.conf"

# --- Argument Parsing ---
CREATE_DIRS=true
for arg in "$@"; do
  if [[ "$arg" == "--no-dirs" ]]; then
    CREATE_DIRS=false
    echo "Skipping personal directory and repository setup."
  fi
done

# --- Main Setup Logic ---

# Step 1: Install Nix
echo "Checking for Nix..."
if ! command -v nix &> /dev/null; then
    echo "Installing Nix..."
    curl -L https://nixos.org/nix/install | sh
    # Source Nix environment
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    echo "Nix installed successfully!"
else
    echo "Nix is already installed."
fi

# Step 2: Create and configure nix.conf
echo "Configuring Nix..."
mkdir -p "$(dirname "$NIX_CONF")"
cat <<EOF > "$NIX_CONF"
experimental-features = nix-command flakes
EOF
echo "Nix configured with Flakes support."

# Step 3: Apply the Nix-Darwin configuration from this repository
echo "Applying nix-darwin configuration with your Flake..."
if [ -d "$FLAKE_PATH" ]; then
    # The first time, 'nix run' is needed to install nix-darwin.
    # Subsequent runs can use 'darwin-rebuild'. We'll use a robust command.
    nix run nix-darwin -- switch --flake "$FLAKE_PATH"
    echo "nix-darwin configuration applied successfully!"
else
    echo "Flake directory not found at $FLAKE_PATH. Exiting."
    exit 1
fi

# Step 4: Run the optional directory creation script
if [ "$CREATE_DIRS" = true ]; then
  echo "--- Running personalized directory and repo setup ---"
  if [ -f "$CREATE_DIRS_SCRIPT" ]; then
      chmod +x "$CREATE_DIRS_SCRIPT"
      "$CREATE_DIRS_SCRIPT"
  else
      echo "Warning: create_dirs.sh script not found at $CREATE_DIRS_SCRIPT. Skipping."
  fi
else
  echo "--- Skipping personalized directory and repo setup as requested ---"
fi

echo "Setup complete!"
