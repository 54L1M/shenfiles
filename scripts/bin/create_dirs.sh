#!/bin/bash

# Define the base directory
DOCUMENTS_DIR="$HOME/Documents"

# Define the directory structure
declare -A structure=(
  ["Workstation"]="Freelance Ghaaf In2Dialog Miscellaneous"
  ["TheGreatLibrary"]=""
  ["TheSandBox"]=""
  ["Books"]="Fiction Non-Fiction Technical"
  ["GeneralFiles"]="HTMLTemplates Scripts Miscellaneous"
  ["P4ndaF4ce"]="SharedResources"
)

# Define repositories to clone (supporting multiple repos per directory)
declare -A repos=(
  ["P4ndaF4ce"]="git@github.com:P4ndaF4ce/P4ndaFrame.git git@github.com:P4ndaF4ce/P4ndaBox.git"
  ["Workstation/Freelance"]="git@github.com:54L1M/ceramsite.git git@github.com:54L1M/super-farachoob.git"
  ["Workstation/In2Dialog"]="git@github.com:In2Dialog/I2D_ATS.git"
  ["TheGreatLibrary"]="git@github.com:54L1M/TheGreatLibrary.git"
  ["TheSandBox"]=""
)

# Create directories with existence checks
for folder in "${!structure[@]}"; do
  main_dir="$DOCUMENTS_DIR/$folder"
  if [ ! -d "$main_dir" ]; then
    mkdir -p "$main_dir"
    echo "Created directory: $main_dir"
  else
    echo "Directory already exists: $main_dir"
  fi

  # Clone repositories into the main directory if specified
  if [ -n "${repos[$folder]}" ]; then
    echo "Cloning repositories into: $main_dir"
    for repo in ${repos[$folder]}; do
      git clone "$repo" "$main_dir/$(basename "$repo" .git)"
      echo "Cloned $repo into $main_dir"
    done
  fi

  # Create subdirectories and check for repositories to clone into them
  for subfolder in ${structure[$folder]}; do
    sub_dir="$main_dir/$subfolder"
    if [ ! -d "$sub_dir" ]; then
      mkdir -p "$sub_dir"
      echo "Created subdirectory: $sub_dir"
    else
      echo "Subdirectory already exists: $sub_dir"
    fi

    # Clone repositories into subdirectories if specified
    sub_dir_with_repo="${folder}/${subfolder}"
    if [ -n "${repos[$sub_dir_with_repo]}" ]; then
      echo "Cloning repositories into: $sub_dir"
      for repo in ${repos[$sub_dir_with_repo]}; do
        git clone "$repo" "$sub_dir/$(basename "$repo" .git)"
        echo "Cloned $repo into $sub_dir"
      done
    fi
  done
done

echo "Directory structure setup and repositories cloned!"
