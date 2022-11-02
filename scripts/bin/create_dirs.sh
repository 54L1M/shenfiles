#!/bin/bash

# This script sets up a personalized directory structure and clones repositories.

# Define the base directory
DOCUMENTS_DIR="$HOME/Documents"
# Assumes the 'repos' file is in the same root directory as the 'scripts' folder.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPOS_FILE="$REPO_ROOT_DIR/repos"


# Define the base directory structure to be created
declare -A structure=(
  ["Workstation"]="Freelance Ghaaf In2Dialog Miscellaneous"
  ["TheGreatLibrary"]=""
  ["TheSandBox"]=""
  ["Books"]="Fiction Non-Fiction Technical"
  ["GeneralFiles"]="HTMLTemplates Scripts Miscellaneous"
  ["P4ndaF4ce"]="SharedResources"
)

# --- Create Base Directory Structure ---
echo "--- Setting up base directory structure in $DOCUMENTS_DIR ---"
for folder in "${!structure[@]}"; do
  main_dir="$DOCUMENTS_DIR/$folder"
  if [ ! -d "$main_dir" ]; then
    mkdir -p "$main_dir"
    echo "Created directory: $main_dir"
  else
    echo "Directory already exists: $main_dir"
  fi

  for subfolder in ${structure[$folder]}; do
    sub_dir="$main_dir/$subfolder"
    if [ ! -d "$sub_dir" ]; then
      mkdir -p "$sub_dir"
      echo "Created subdirectory: $sub_dir"
    else
      echo "Subdirectory already exists: $sub_dir"
    fi
  done
done
echo "--- Base directory structure setup complete ---"
echo

# --- Clone Repositories ---
if [ ! -f "$REPOS_FILE" ]; then
    echo "Warning: Repository list file not found at '$REPOS_FILE'. Skipping cloning."
    exit 0
fi

echo "--- Cloning repositories from '$REPOS_FILE' ---"
# Read the repos file line by line, skipping comments and empty lines
grep -v '^\s*#' "$REPOS_FILE" | grep -v '^\s*$' | while IFS= read -r line; do
  # Use 'read' to split the line into two parts
  read -r dest_dir repo_url <<< "$line"

  # Expand tilde in destination directory
  dest_dir_expanded="${dest_dir/#\~/$HOME}"
  
  # Get the repository name from the URL to create the final clone path
  repo_name=$(basename "$repo_url" .git)
  clone_path="$dest_dir_expanded/$repo_name"

  if [ -z "$dest_dir" ] || [ -z "$repo_url" ]; then
    echo "Warning: Skipping invalid line in repos file: '$line'"
    continue
  fi

  if [ -d "$clone_path" ]; then
    echo "Repository '$repo_name' already exists in '$dest_dir_expanded'. Skipping."
  else
    echo "Cloning '$repo_url' into '$clone_path'..."
    # Ensure the destination directory exists before cloning
    mkdir -p "$dest_dir_expanded"
    git clone "$repo_url" "$clone_path"
    echo "Cloned successfully."
  fi
done
echo "--- Repository cloning complete ---"

echo
echo "Directory structure and repository setup finished!"
