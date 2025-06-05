#!/usr/bin/env bash
# Script uninstaller for development tools

set -euo pipefail

# Source the colors library
SCRIPT_DIR=$(dirname "$(realpath "$0")")
source "$SCRIPT_DIR/lib/colors/colors.sh"
source "$SCRIPT_DIR/lib/utils/utils.sh"

# Define paths
DOTFILES_DIR="$HOME/shenfiles"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
BIN_DIR="$SCRIPTS_DIR/bin"
LIB_DIR="$SCRIPTS_DIR/lib"
COMPLETIONS_DIR="$SCRIPTS_DIR/completions"

# Destination directories
INSTALL_DIR="$HOME/.local/bin"
INSTALL_DIR_LIB="$HOME/.local/lib"
ZSH_COMPLETION_DIR="$HOME/.zsh/completions"

# Function to remove symlinks that point to our scripts
remove_script_symlinks() {
  p4_step "Removing script symlinks from $INSTALL_DIR"
  
  if [[ ! -d "$INSTALL_DIR" ]]; then
    p4_info "Installation directory doesn't exist: $INSTALL_DIR"
    return 0
  fi

  local removed_count=0
  local symlinks=()
  
  # Collect all symlinks that point to our bin directory
  while IFS= read -r -d '' symlink; do
    symlinks+=("$symlink")
  done < <(find "$INSTALL_DIR" -maxdepth 1 -type l -print0 2>/dev/null)
  
  # Process each symlink
  for symlink in "${symlinks[@]}"; do
    if [[ -L "$symlink" ]]; then
      local target
      target=$(readlink "$symlink")
      
      # Check if symlink points to our bin directory
      if [[ "$target" == "$BIN_DIR"/* ]]; then
        if rm -f "$symlink"; then
          p4_info "Removed: $(basename "$symlink")"
          ((removed_count++))
        else
          p4_warn "Failed to remove: $(basename "$symlink")"
        fi
      fi
    fi
  done
  
  if [[ $removed_count -eq 0 ]]; then
    p4_info "No script symlinks found to remove"
  else
    p4_success "Removed $removed_count script symlinks"
  fi
}

# Function to remove library symlinks
remove_library_symlinks() {
  p4_step "Removing library symlinks from $INSTALL_DIR_LIB"
  
  if [[ ! -d "$INSTALL_DIR_LIB" ]]; then
    p4_info "Library installation directory doesn't exist: $INSTALL_DIR_LIB"
    return 0
  fi

  local removed_count=0
  local symlinks=()
  
  # Collect all symlinks recursively
  while IFS= read -r -d '' symlink; do
    symlinks+=("$symlink")
  done < <(find "$INSTALL_DIR_LIB" -type l -print0 2>/dev/null)
  
  # Process each symlink
  for symlink in "${symlinks[@]}"; do
    if [[ -L "$symlink" ]]; then
      local target
      target=$(readlink "$symlink")
      
      # Check if symlink points to our lib directory
      if [[ "$target" == "$LIB_DIR"/* ]]; then
        if rm -f "$symlink"; then
          local relative_path="${symlink#$INSTALL_DIR_LIB/}"
          p4_info "Removed: $relative_path"
          ((removed_count++))
        else
          p4_warn "Failed to remove: ${symlink#$INSTALL_DIR_LIB/}"
        fi
      fi
    fi
  done
  
  # Remove empty directories
  find "$INSTALL_DIR_LIB" -type d -empty -delete 2>/dev/null || true
  
  if [[ $removed_count -eq 0 ]]; then
    p4_info "No library symlinks found to remove"
  else
    p4_success "Removed $removed_count library symlinks"
  fi
}

# Function to remove zsh completions
remove_completions() {
  p4_step "Removing zsh completions from $ZSH_COMPLETION_DIR"
  
  if [[ ! -d "$ZSH_COMPLETION_DIR" ]]; then
    p4_info "Zsh completions directory doesn't exist: $ZSH_COMPLETION_DIR"
    return 0
  fi

  local removed_count=0
  local completions=()
  
  # Collect all completion files
  while IFS= read -r -d '' completion; do
    completions+=("$completion")
  done < <(find "$ZSH_COMPLETION_DIR" -maxdepth 1 -name "_*" -type l -print0 2>/dev/null)
  
  # Process each completion
  for completion in "${completions[@]}"; do
    if [[ -L "$completion" ]]; then
      local target
      target=$(readlink "$completion")
      
      # Check if completion points to our completions directory
      if [[ "$target" == "$COMPLETIONS_DIR"/* ]]; then
        if rm -f "$completion"; then
          p4_info "Removed completion: $(basename "$completion")"
          ((removed_count++))
        else
          p4_warn "Failed to remove completion: $(basename "$completion")"
        fi
      fi
    fi
  done
  
  if [[ $removed_count -eq 0 ]]; then
    p4_info "No completions found to remove"
  else
    p4_success "Removed $removed_count completions"
  fi
}

# Function to clean up empty directories
cleanup_empty_dirs() {
  p4_step "Cleaning up empty directories"
  
  # Remove empty directories in installation paths
  for dir in "$INSTALL_DIR" "$INSTALL_DIR_LIB" "$ZSH_COMPLETION_DIR"; do
    if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
      if rmdir "$dir" 2>/dev/null; then
        p4_info "Removed empty directory: $dir"
      fi
    fi
  done
}

# Function to show configuration cleanup suggestions
show_cleanup_suggestions() {
  p4_title "Manual cleanup suggestions"
  
  local found_config=false
  local zshrc_path="$HOME/.config/zsh/.zshrc"
  
  # Check for PATH configuration in .zshrc
  if [[ -f "$zshrc_path" ]]; then
    # Look for .local/bin PATH additions
    if grep -q "\.local/bin.*PATH" "$zshrc_path" 2>/dev/null; then
      found_config=true
      p4_warn "Found .local/bin PATH entries in $zshrc_path"
      p4_tip "You may want to manually remove these lines:"
      echo ""
      grep -n "\.local/bin.*PATH" "$zshrc_path" 2>/dev/null | while read -r line; do
        echo "  $line"
      done
      echo ""
    fi
    
    # Look for completion configuration
    if grep -q "\.zsh/completions.*fpath" "$zshrc_path" 2>/dev/null; then
      found_config=true
      p4_warn "Found completion configuration in $zshrc_path"
      p4_tip "You may want to manually remove these lines:"
      echo ""
      grep -n "\.zsh/completions\|compinit" "$zshrc_path" 2>/dev/null | while read -r line; do
        echo "  $line"
      done
      echo ""
    fi
  fi
  
  # Check for orphaned directories
  local dirs_to_check=("$INSTALL_DIR" "$INSTALL_DIR_LIB" "$ZSH_COMPLETION_DIR")
  for dir in "${dirs_to_check[@]}"; do
    if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
      found_config=true
      p4_tip "Empty directory can be removed: $dir"
    fi
  done
  
  if [[ "$found_config" == "false" ]]; then
    p4_info "No additional cleanup needed"
  fi
}

# Function to show what would be removed (dry run)
show_dry_run() {
  p4_header "Scripts Uninstall Preview"
  p4_info "This is what would be removed:"
  echo ""
  
  # Check script symlinks
  local script_count=0
  if [[ -d "$INSTALL_DIR" ]]; then
    for symlink in "$INSTALL_DIR"/*; do
      [[ -e "$symlink" ]] || continue
      if [[ -L "$symlink" ]]; then
        local target
        target=$(readlink "$symlink")
        if [[ "$target" == "$BIN_DIR"/* ]]; then
          echo "  📄 $(basename "$symlink")"
          ((script_count++))
        fi
      fi
    done
  fi
  
  # Check library symlinks
  local lib_count=0
  if [[ -d "$INSTALL_DIR_LIB" ]]; then
    while IFS= read -r symlink; do
      [[ -z "$symlink" ]] && continue
      
      if [[ -L "$symlink" ]]; then
        local target
        target=$(readlink "$symlink")
        if [[ "$target" == "$LIB_DIR"/* ]]; then
          echo "  📚 ${symlink#$INSTALL_DIR_LIB/}"
          ((lib_count++))
        fi
      fi
    done < <(find "$INSTALL_DIR_LIB" -type l 2>/dev/null || true)
  fi
  
  # Check completions
  local completion_count=0
  if [[ -d "$ZSH_COMPLETION_DIR" ]]; then
    for completion in "$ZSH_COMPLETION_DIR"/_*; do
      [[ -e "$completion" ]] || continue
      if [[ -L "$completion" ]]; then
        local target
        target=$(readlink "$completion")
        if [[ "$target" == "$COMPLETIONS_DIR"/* ]]; then
          echo "  🔧 $(basename "$completion")"
          ((completion_count++))
        fi
      fi
    done
  fi
  
  echo ""
  p4_info "Summary: $script_count scripts, $lib_count libraries, $completion_count completions"
  
  if [[ $((script_count + lib_count + completion_count)) -eq 0 ]]; then
    p4_warn "No script installations found"
    return 1
  fi
  
  return 0
}

# Show usage information
show_usage() {
  p4_header "Scripts Uninstaller"
  echo "Usage: $(basename "$0") [OPTIONS]"
  echo ""
  p4_title "Options:"
  p4_cmd "-n, --dry-run" "" "Show what would be removed without actually removing"
  p4_cmd "-f, --force" "" "Remove without confirmation prompts"
  p4_cmd "-h, --help" "" "Show this help message"
  echo ""
  p4_title "Examples:"
  p4_example "$(basename "$0")" "Interactive uninstall with confirmation"
  p4_example "$(basename "$0") --dry-run" "Preview what would be removed"
  p4_example "$(basename "$0") --force" "Remove everything without prompts"
}

# Main uninstall function
main() {
  local dry_run=false
  local force=false
  
  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -n|--dry-run)
        dry_run=true
        shift
        ;;
      -f|--force)
        force=true
        shift
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      *)
        p4_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done
  
  # Handle dry run
  if [[ "$dry_run" == "true" ]]; then
    if ! show_dry_run; then
      exit 0
    fi
    echo ""
    p4_tip "Run without --dry-run to actually remove these items"
    exit 0
  fi
  
  # Show header
  p4_header "Scripts Uninstaller"
  
  # Check if anything is installed
  if ! show_dry_run >/dev/null 2>&1; then
    p4_warn "No script installations found"
    exit 0
  fi
  
  # Confirmation (unless force flag is used)
  if [[ "$force" != "true" ]]; then
    echo ""
    if ! p4_confirm "This will remove all installed scripts, libraries, and completions. Continue?"; then
      p4_info "Uninstall cancelled"
      exit 0
    fi
  fi
  
  echo ""
  
  # Perform uninstall
  remove_script_symlinks
  remove_library_symlinks
  remove_completions
  cleanup_empty_dirs
  
  echo ""
  show_cleanup_suggestions
  
  echo ""
  p4_success "Uninstall complete!"
  p4_tip "You may need to restart your shell for changes to take effect"
}

# Run the main function with all arguments
main "$@"
