#!/bin/bash

set -e

# Paths and variables
FLAKE_PATH="$HOME/shenfiles/nix/flake.nix"
CREATE_DIRS_SCRIPT="$HOME/shenfiles/scripts/create_dirs.sh"
NIX_CONF="$HOME/.config/nix/nix.conf"

# Step 1: Install Nix
echo "Checking for Nix..."
if ! command -v nix &> /dev/null; then
    echo "Installing Nix..."
    curl -L https://nixos.org/nix/install | sh
    # Source Nix environment
    . ~/.nix-profile/etc/profile.d/nix.sh
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

# Step 3: Install nix-darwin
echo "Installing nix-darwin..."
if ! command -v darwin-rebuild &> /dev/null; then
    nix run nix-darwin -- switch --flake "$FLAKE_PATH"
    echo "nix-darwin installed successfully!"
else
    echo "nix-darwin is already installed."
fi

# Step 4: Run darwin-rebuild using your Flake configuration
#echo "Applying nix-darwin configuration with your Flake..."
#if [[ -d "$FLAKE_PATH" ]]; then
#    darwin-rebuild switch --impure  --flake "$FLAKE_PATH"
#    echo "nix-darwin configuration applied successfully!"
#else
#    echo "Flake configuration directory not found at $FLAKE_PATH. Exiting."
#    exit 1
#fi

# Step 5: Ensure create_dirs.sh is executable
echo "Ensuring create_dirs.sh is executable..."
if [[ -f "$CREATE_DIRS_SCRIPT" ]]; then
    chmod +x "$CREATE_DIRS_SCRIPT"
    echo "create_dirs.sh made executable."
else
    echo "create_dirs.sh not found in home directory."
    exit 1
fi

# Step 6: Run create_dirs.sh script
echo "Running create_dirs.sh..."
"$CREATE_DIRS_SCRIPT"

echo "Setup complete!"
