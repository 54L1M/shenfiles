#!/usr/bin/env bash
# Script installer for P4ndaF4ce tools

# Source the colors library
SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR/lib/colors/colors.sh"

# Define paths
DOTFILES_DIR="$HOME/shenfiles"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
BIN_DIR="$SCRIPTS_DIR/bin"
LIB_DIR="$SCRIPTS_DIR/lib"
COMPLETIONS_DIR="$SCRIPTS_DIR/completions"

# Destination directory for symlinks (typically in PATH)
INSTALL_DIR="$HOME/.local/bin"

# Function to create the installation directory if it doesn't exist
create_install_dir() {
  if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    p4_success "Created installation directory: $INSTALL_DIR"
  else
    p4_info "Installation directory already exists: $INSTALL_DIR"
  fi
}

# Function to create symlinks for executable scripts
create_symlinks() {
  local source_dir="$1"

  if [ ! -d "$source_dir" ]; then
    p4_error "Source directory not found: $source_dir"
    return 1
  fi

  p4_step "Processing scripts in: $source_dir"

  # gfind all executable files (excluding directories)
  for script in $(gfind "$source_dir" -type f -executable -not -path "*/\.*"); do
    script_name=$(basename "$script")

    # Remove .sh extension if present
    symlink_name="${script_name%.sh}"

    # Create the symlink
    ln -sf "$script" "$INSTALL_DIR/$symlink_name"
    p4_info "Created symlink: $symlink_name -> $script"
  done
}

# Install zsh completions
install_completions() {
  if [ ! -d "$COMPLETIONS_DIR" ]; then
    p4_warn "Completions directory not found: $COMPLETIONS_DIR"
    return 1
  fi

  # Create zsh completions directory if it doesn't exist
  local zsh_completion_dir="$HOME/.zsh/completions"
  if [ ! -d "$zsh_completion_dir" ]; then
    mkdir -p "$zsh_completion_dir"
    p4_success "Created zsh completions directory: $zsh_completion_dir"
  fi

  # Link all completion files
  for completion in "$COMPLETIONS_DIR"/*; do
    if [ -f "$completion" ]; then
      local completion_name=$(basename "$completion")
      ln -sf "$completion" "$zsh_completion_dir/_${completion_name%.sh}"
      p4_info "Installed completion: $completion_name"
    fi
  done

  # Add zsh completion source to zshrc if not already present
  local completion_code='fpath+=($HOME/.zsh/completions $fpath)'
  local autoload_code='autoload -U compinit && compinit'

  if ! grep -q "$completion_code" "$HOME/.zshrc"; then
    p4_step "Adding zsh completions configuration to ~/.zshrc"
    echo "" >>"$HOME/.zshrc"
    echo "# P4ndaF4ce completions" >>"$HOME/.zshrc"
    echo "$completion_code" >>"$HOME/.zshrc"

    if ! grep -q "compinit" "$HOME/.zshrc"; then
      echo "$autoload_code" >>"$HOME/.zshrc"
    fi

    p4_success "Added zsh completion configuration to ~/.zshrc"
  else
    p4_info "Zsh completion configuration already exists in ~/.zshrc"
  fi
}

# Check if ~/.local/bin is in PATH
check_path() {
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    p4_warn "$INSTALL_DIR is not in your PATH"
    p4_step "Adding to ~/.zshrc..."

    echo "" >>"$HOME/.zshrc"
    echo "# P4ndaF4ce scripts path" >>"$HOME/.zshrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$HOME/.zshrc"

    p4_tip "Please restart your shell or run 'source ~/.zshrc' to update your PATH"
  else
    p4_info "$INSTALL_DIR is already in your PATH"
  fi
}

# Main execution
main() {
  p4_header "P4ndaF4ce Scripts Installer"

  # Create installation directory
  create_install_dir

  # Create symlinks for scripts in bin directory
  p4_title "Creating script symlinks"
  create_symlinks "$BIN_DIR"

  # Handle subdirectories in bin (like P4ndaMux)
  for subdir in "$BIN_DIR"/*; do
    if [ -d "$subdir" ]; then
      create_symlinks "$subdir"
    fi
  done

  # Install zsh completions
  p4_title "Setting up zsh completions"
  install_completions

  # Check if installation directory is in PATH
  p4_title "Checking PATH configuration"
  check_path

  p4_success "Installation complete!"
}

# Run the main function
main
