#!/usr/bin/env bash
# Script installer for custom tools

# Get script directory for sourcing colors in help
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Parse command line arguments
FORCE_INSTALL=false
UNINSTALL_MODE=false
UNINSTALL_ALL=false
UNINSTALL_TARGET=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force)
      FORCE_INSTALL=true
      shift
      ;;
    -u|--uninstall)
      UNINSTALL_MODE=true
      if [[ -n "$2" && "$2" != -* ]]; then
        UNINSTALL_TARGET="$2"
        shift 2
      else
        shift
      fi
      ;;
    -a|--all)
      UNINSTALL_ALL=true
      shift
      ;;
    -h|--help)
      # Source colors for help display
      source "$SCRIPT_DIR/lib/colors/colors.sh" 2>/dev/null || true
      
      p4_header "Custom Scripts Installer"
      p4_info "Usage: $0 [OPTIONS]"
      echo
      p4_title "Install mode (default):"
      p4_cmd "-f, --force" "" "Force reinstall even if symlinks already exist"
      echo
      p4_title "Uninstall mode:"
      p4_cmd "-u, --uninstall" "[TOOL]" "Uninstall specific tool or prompt for selection"
      p4_cmd "-a, --all" "" "Uninstall all custom tools (use with -u)"
      echo
      p4_title "General:"
      p4_cmd "-h, --help" "" "Show this help message"
      echo
      p4_title "Examples:"
      p4_example "$0" "Install all tools"
      p4_example "$0 --force" "Force reinstall all tools"
      p4_example "$0 -u p4s" "Uninstall specific tool 'p4s'"
      p4_example "$0 -u" "Interactive uninstall menu"
      p4_example "$0 -u -a" "Uninstall all tools"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Validate argument combinations
if [[ "$UNINSTALL_MODE" == true && "$FORCE_INSTALL" == true ]]; then
  echo "Error: Cannot use --force with --uninstall"
  exit 1
fi

# Source the colors library
source "$SCRIPT_DIR/lib/colors/colors.sh"

# Define paths
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
BIN_DIR="$SCRIPTS_DIR/bin"
LIB_DIR="$SCRIPTS_DIR/lib"
COMPLETIONS_DIR="$SCRIPTS_DIR/completions"

# Destination directory for symlinks (typically in PATH)
INSTALL_DIR="$HOME/.local/bin"
INSTALL_DIR_LIB="$HOME/.local/lib"

# Counters for summary
CREATED_COUNT=0
SKIPPED_COUNT=0
UPDATED_COUNT=0
REMOVED_COUNT=0

# Function to create the installation directory if it doesn't exist
create_install_dir() {
  if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    p4_success "Created installation directory: $INSTALL_DIR"
  else
    p4_info "Installation directory already exists: $INSTALL_DIR"
  fi
}

# Function to create symlinks for scripts and libraries
create_symlinks() {
  local source_dir="$1"
  local force_install="$2"

  if [ ! -d "$source_dir" ]; then
    p4_error "Source directory not found: $source_dir"
    return 1
  fi

  p4_step "Processing scripts in: $source_dir"

  # Find executable files in bin and all .sh files in lib
  local find_pattern="-type f"
  if [[ "$source_dir" == "$BIN_DIR" ]]; then
    find_pattern="-type f -executable"
  fi

  while IFS= read -r script; do
    script_name=$(basename "$script")

    # Remove .sh extension if present
    symlink_name="${script_name%.sh}"

    # Preserve subdirectory structure for lib files
    if [[ "$source_dir" == "$LIB_DIR" ]]; then
      relative_path="${script#"$LIB_DIR/"}"
      target_path="$INSTALL_DIR_LIB/$relative_path"
      display_name="$relative_path"
    else
      target_path="$INSTALL_DIR/$symlink_name"
      display_name="$symlink_name"
    fi

    # Check if target already exists
    if [ -L "$target_path" ] || [ -e "$target_path" ]; then
      if [ "$force_install" = true ]; then
        # Force install - remove existing and create new
        rm -f "$target_path"
        if [[ "$source_dir" == "$LIB_DIR" ]]; then
          mkdir -p "$(dirname "$target_path")"
        fi
        ln -s "$script" "$target_path"
        p4_info "Force updated symlink: $display_name -> $script"
        ((UPDATED_COUNT++))
      elif [ -L "$target_path" ]; then
        # Check if existing symlink points to correct location
        current_target=$(readlink "$target_path")
        if [ "$current_target" = "$script" ]; then
          p4_info "Skipping $display_name (already correctly linked)"
          ((SKIPPED_COUNT++))
        else
          p4_warn "Symlink $display_name exists but points to wrong location:"
          p4_warn "  Current: $current_target"
          p4_warn "  Expected: $script"
          read -p "Update symlink? [y/N]: " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$target_path"
            if [[ "$source_dir" == "$LIB_DIR" ]]; then
              mkdir -p "$(dirname "$target_path")"
            fi
            ln -s "$script" "$target_path"
            p4_success "Updated symlink: $display_name -> $script"
            ((UPDATED_COUNT++))
          else
            p4_info "Skipped updating $display_name"
            ((SKIPPED_COUNT++))
          fi
        fi
      else
        # File exists but is not a symlink
        p4_warn "File $display_name already exists (not a symlink)"
        read -p "Replace with symlink? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          rm -f "$target_path"
          if [[ "$source_dir" == "$LIB_DIR" ]]; then
            mkdir -p "$(dirname "$target_path")"
          fi
          ln -s "$script" "$target_path"
          p4_success "Replaced file with symlink: $display_name -> $script"
          ((UPDATED_COUNT++))
        else
          p4_info "Skipped replacing $display_name"
          ((SKIPPED_COUNT++))
        fi
      fi
    else
      # Create new symlink
      if [[ "$source_dir" == "$LIB_DIR" ]]; then
        mkdir -p "$(dirname "$target_path")"
      fi
      ln -s "$script" "$target_path"
      p4_info "Created symlink: $display_name -> $script"
      ((CREATED_COUNT++))
    fi
  done < <(gfind "$source_dir" $find_pattern -not -path "*/\.*")
}

# Function to get all installed custom tools
get_installed_tools() {
  local tools=()
  
  # Check bin directory tools
  if [ -d "$BIN_DIR" ]; then
    while IFS= read -r script; do
      script_name=$(basename "$script")
      symlink_name="${script_name%.sh}"
      target_path="$INSTALL_DIR/$symlink_name"
      
      if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$script" ]; then
        tools+=("$symlink_name")
      fi
    done < <(gfind "$BIN_DIR" -type f -executable -not -path "*/\.*")
  fi
  
  # Check lib directory tools
  if [ -d "$LIB_DIR" ]; then
    while IFS= read -r script; do
      relative_path="${script#"$LIB_DIR/"}"
      target_path="$INSTALL_DIR_LIB/$relative_path"
      
      if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$script" ]; then
        tools+=("lib/$relative_path")
      fi
    done < <(gfind "$LIB_DIR" -type f -not -path "*/\.*")
  fi
  
  printf '%s\n' "${tools[@]}"
}

# Function to uninstall specific tool or all tools
uninstall_tools() {
  local target="$1"
  local uninstall_all="$2"
  
  if [ "$uninstall_all" = true ]; then
    p4_warn "This will remove ALL custom tools and completions"
    read -p "Are you sure? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      p4_info "Uninstall cancelled"
      return 0
    fi
    
    # Remove all tools
    local tools
    mapfile -t tools < <(get_installed_tools)
    
    if [ ${#tools[@]} -eq 0 ]; then
      p4_info "No custom tools found to uninstall"
      return 0
    fi
    
    for tool in "${tools[@]}"; do
      if [[ "$tool" == lib/* ]]; then
        # Library file
        local lib_path="${tool#lib/}"
        rm -f "$INSTALL_DIR_LIB/$lib_path"
        p4_info "Removed library: $lib_path"
      else
        # Binary tool
        rm -f "$INSTALL_DIR/$tool"
        p4_info "Removed tool: $tool"
      fi
      ((REMOVED_COUNT++))
    done
    
    # Remove completions
    uninstall_completions true
    
  elif [ -n "$target" ]; then
    # Remove specific tool
    local removed=false
    
    # Check if it's a binary tool
    if [ -L "$INSTALL_DIR/$target" ]; then
      local link_target=$(readlink "$INSTALL_DIR/$target")
      if [[ "$link_target" == "$BIN_DIR"/* ]]; then
        rm -f "$INSTALL_DIR/$target"
        p4_success "Removed tool: $target"
        ((REMOVED_COUNT++))
        removed=true
      fi
    fi
    
    # Check if it's a library (support lib/path syntax)
    if [[ "$target" == lib/* ]]; then
      local lib_path="${target#lib/}"
      if [ -L "$INSTALL_DIR_LIB/$lib_path" ]; then
        local link_target=$(readlink "$INSTALL_DIR_LIB/$lib_path")
        if [[ "$link_target" == "$LIB_DIR"/* ]]; then
          rm -f "$INSTALL_DIR_LIB/$lib_path"
          p4_success "Removed library: $lib_path"
          ((REMOVED_COUNT++))
          removed=true
        fi
      fi
    fi
    
    # Remove completion for the tool
    local completion_file="$HOME/.zsh/completions/_$target"
    if [ -f "$completion_file" ]; then
      rm -f "$completion_file"
      p4_info "Removed completion: $target"
    fi
    
    if [ "$removed" = false ]; then
      p4_error "Tool '$target' not found or not installed by this installer"
      return 1
    fi
    
  else
    # Interactive mode - show available tools
    local tools
    mapfile -t tools < <(get_installed_tools)
    
    if [ ${#tools[@]} -eq 0 ]; then
      p4_info "No custom tools found to uninstall"
      return 0
    fi
    
    p4_title "Installed Custom Tools:"
    for i in "${!tools[@]}"; do
      echo "  $((i+1)). ${tools[i]}"
    done
    echo "  $((${#tools[@]}+1)). Remove all tools"
    echo "  $((${#tools[@]}+2)). Cancel"
    
    echo
    read -p "Select tool to remove [1-$((${#tools[@]}+2))]: " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      if [ "$choice" -eq $((${#tools[@]}+1)) ]; then
        # Remove all
        uninstall_tools "" true
        return $?
      elif [ "$choice" -eq $((${#tools[@]}+2)) ] || [ "$choice" -eq 0 ]; then
        # Cancel
        p4_info "Uninstall cancelled"
        return 0
      elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#tools[@]} ]; then
        # Remove specific tool
        local selected_tool="${tools[$((choice-1))]}"
        uninstall_tools "$selected_tool" false
        return $?
      fi
    fi
    
    p4_error "Invalid selection"
    return 1
  fi
}

# Function to uninstall completions
uninstall_completions() {
  local remove_all="$1"
  
  if [ ! -d "$HOME/.zsh/completions" ]; then
    return 0
  fi
  
  if [ "$remove_all" = true ]; then
    # Remove custom script completions
    for completion in "$HOME/.zsh/completions"/_*; do
      if [ -f "$completion" ]; then
        local completion_name=$(basename "$completion")
        local source_completion="$COMPLETIONS_DIR/${completion_name#_}.sh"
        if [ -f "$source_completion" ] || [[ "$completion_name" == _p4* ]]; then
          rm -f "$completion"
          p4_info "Removed completion: ${completion_name#_}"
        fi
      fi
    done
    
    # Ask about removing configuration from .zshrc
    if [ -f "$HOME/.config/zsh/.zshrc" ] && grep -q "Custom script completions" "$HOME/.config/zsh/.zshrc"; then
      read -p "Remove custom script completion configuration from ~/.zshrc? [y/N]: " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Create a backup
        cp "$HOME/.config/zsh/.zshrc" "$HOME/.config/zsh/.zshrc.backup"
        # Remove custom script completion sections
        sed -i '/# Custom script completions/,/^$/d' "$HOME/.config/zsh/.zshrc"
        p4_success "Removed completion configuration from ~/.zshrc (backup saved as ~/.zshrc.backup)"
      fi
    fi
  fi
}

# Function to remove PATH configuration
remove_path_config() {
  if [ -f "$HOME/.config/zsh/.zshrc" ] && grep -q "Custom scripts path" "$HOME/.config/zsh/.zshrc"; then
    read -p "Remove custom scripts PATH configuration from ~/.zshrc? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      # Create a backup if not already created
      if [ ! -f "$HOME/.config/zsh/.zshrc.backup" ]; then
        cp "$HOME/.config/zsh/.zshrc" "$HOME/.config/zsh/.zshrc.backup"
      fi
      # Remove custom scripts PATH sections
      sed -i '/# Custom scripts path/,/^$/d' "$HOME/.config/zsh/.zshrc"
      p4_success "Removed PATH configuration from ~/.zshrc"
    fi
  fi
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

  if ! grep -q "$completion_code" "$HOME/.config/zsh/.zshrc"; then
    p4_step "Adding zsh completions configuration to ~/.zshrc"
    echo "" >>"$HOME/.config/zsh/.zshrc"
    echo "# Custom script completions" >>"$HOME/.config/zsh/.zshrc"
    echo "$completion_code" >>"$HOME/.config/zsh/.zshrc"

    if ! grep -q "compinit" "$HOME/.config/zsh/.zshrc"; then
      echo "$autoload_code" >>"$HOME/.config/zsh/.zshrc"
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

    echo "" >>"$HOME/.config/zsh/.zshrc"
    echo "# Custom scripts path" >>"$HOME/.config/zsh/.zshrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$HOME/.config/zsh/.zshrc"

    p4_tip "Please restart your shell or run 'source ~/.zshrc' to update your PATH"
  else
    p4_info "$INSTALL_DIR is already in your PATH"
  fi
}

# Print installation summary
print_install_summary() {
  p4_title "Installation Summary"
  p4_info "Created: $CREATED_COUNT symlinks"
  p4_info "Skipped: $SKIPPED_COUNT existing files"
  p4_info "Updated: $UPDATED_COUNT symlinks"
  
  local total=$((CREATED_COUNT + SKIPPED_COUNT + UPDATED_COUNT))
  p4_info "Total processed: $total files"
}

# Print uninstall summary
print_uninstall_summary() {
  p4_title "Uninstall Summary"
  p4_info "Removed: $REMOVED_COUNT items"
  
  if [ $REMOVED_COUNT -eq 0 ]; then
    p4_warn "No items were removed"
  fi
}

# Main execution
main() {
  if [ "$UNINSTALL_MODE" = true ]; then
    p4_header "Custom Scripts Uninstaller"
    
    uninstall_tools "$UNINSTALL_TARGET" "$UNINSTALL_ALL"
    
    # Offer to remove config if all tools were removed
    if [ "$UNINSTALL_ALL" = true ]; then
      remove_path_config
    fi
    
    print_uninstall_summary
    p4_success "Uninstall complete!"
    
  else
    p4_header "Custom Scripts Installer"

    if [ "$FORCE_INSTALL" = true ]; then
      p4_warn "Force mode enabled - will overwrite existing symlinks"
    fi

    # Create installation directory
    create_install_dir

    # Create symlinks for scripts in bin directory
    p4_title "Creating script symlinks"
    create_symlinks "$BIN_DIR" "$FORCE_INSTALL"

    create_symlinks "$LIB_DIR" "$FORCE_INSTALL"
    # # Handle subdirectories in bin (like P4ndaMux)
    # for subdir in "$BIN_DIR"/*; do
    #   if [ -d "$subdir" ]; then
    #     create_symlinks "$subdir" "$FORCE_INSTALL"
    #   fi
    # done

    # Install zsh completions
    p4_title "Setting up zsh completions"
    install_completions

    # Check if installation directory is in PATH
    p4_title "Checking PATH configuration"
    check_path

    # Print summary
    print_install_summary

    p4_success "Installation complete!"
  fi
}

# Run the main function
main
