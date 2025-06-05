#!/bin/bash
set -euo pipefail

# Source the libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"
source "$SCRIPT_DIR/../lib/utils/utils.sh"

# Navigate to the dotfiles directory
DOTFILES_DIR="$HOME/shenfiles/"
cd "$DOTFILES_DIR" || p4_die "Dotfiles directory not found!"

# Check if we're in a git repository
if ! git_is_repo; then
    p4_die "Not in a git repository!"
fi

# Check for changes
p4_step "Checking for changes..."
git fetch origin
CHANGES=$(git status --porcelain)

if git_is_clean; then
    p4_info "No changes to commit."
    exit 0
fi

# Stage, commit, and push changes
while IFS= read -r line; do
  STATUS=${line:0:2}
  FILE=${line:3}
  case "$STATUS" in
  " M") # Modified file
    git add "$FILE"
    git commit -m "Update $FILE"
    p4_success "Committed update for $FILE"
    ;;
  "??") # Newly created file
    git add "$FILE"
    git commit -m "Add $FILE"
    p4_warn "Committed addition of $FILE"
    ;;
  " D") # Deleted file
    git rm "$FILE"
    git commit -m "Remove $FILE"
    p4_error "Committed removal of $FILE"
    ;;
  esac
done <<<"$CHANGES"

# Push changes to the repository
p4_step "Pushing changes to repository..."
git push origin "$(git_current_branch)"
p4_success "Changes pushed to the repository."
