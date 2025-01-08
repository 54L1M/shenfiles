#!/bin/bash

# Navigate to the dotfiles directory
DOTFILES_DIR="$HOME/shenfiles/"
cd "$DOTFILES_DIR" || { echo "Dotfiles directory not found!"; exit 1; }

# Check for changes
git fetch origin
CHANGES=$(git status --porcelain)

if [[ -z "$CHANGES" ]]; then
    echo "No changes to commit."
    exit 0
fi

# Stage, commit, and push changes
while IFS= read -r line; do
    STATUS=${line:0:2}
    FILE=${line:3}

    if [[ $STATUS == " M" || $STATUS == "??" ]]; then
        git add "$FILE"
        git commit -m "Update $FILE"
        echo "Committed changes for $FILE"
    fi
done <<< "$CHANGES"

# Push changes to the repository
git push origin master 
echo "Changes pushed to the repository."

