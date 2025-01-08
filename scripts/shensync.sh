
#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Navigate to the dotfiles directory
DOTFILES_DIR="$HOME/shenfiles/"
cd "$DOTFILES_DIR" || { echo -e "${RED}Dotfiles directory not found!${RESET}"; exit 1; }

# Check for changes
git fetch origin
CHANGES=$(git status --porcelain)

if [[ -z "$CHANGES" ]]; then
    echo -e "${CYAN}No changes to commit.${RESET}"
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
            echo -e "${GREEN}Committed update for $FILE${RESET}"
            ;;
        "??") # Newly created file
            git add "$FILE"
            git commit -m "Add $FILE"
            echo -e "${YELLOW}Committed addition of $FILE${RESET}"
            ;;
        " D") # Deleted file
            git rm "$FILE"
            git commit -m "Remove $FILE"
            echo -e "${RED}Committed removal of $FILE${RESET}"
            ;;
    esac
done <<< "$CHANGES"

# Push changes to the repository
git push origin master
echo -e "${CYAN}Changes pushed to the repository.${RESET}"

