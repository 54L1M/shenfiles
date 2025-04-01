#!/bin/bash

set -e

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RESET='\033[0m'

VAULT_DIR="$HOME/Documents/TheGreatLibrary/"
BRANCH="master"
REMOTE="origin"

# Script name for logging
SCRIPT_NAME="tglsync"

# Navigate to the vault directory
cd "$VAULT_DIR" || {
  echo "${RED}[${SCRIPT_NAME}] Obsidian vault directory not found!${RESET}"
  exit 1
}

# Check if the directory is a git repository
if [ ! -d ".git" ]; then
  echo "${RED}[${SCRIPT_NAME}] Not a git repository. Initialize first with: git init${RESET}"
  exit 1
fi

# Print status header
echo "${BLUE}[${SCRIPT_NAME}] Checking Obsidian vault status...${RESET}"

# Check for changes
git fetch $REMOTE
CHANGES=$(git status --porcelain)
if [[ -z "$CHANGES" ]]; then
  echo "${CYAN}[${SCRIPT_NAME}] No changes to commit.${RESET}"
  exit 0
fi

# Count number of changed files
NUM_CHANGES=$(echo "$CHANGES" | wc -l)
echo "${CYAN}[${SCRIPT_NAME}] Found ${NUM_CHANGES} changed files.${RESET}"

# Stage, commit, and push changes
while IFS= read -r line; do
  STATUS=${line:0:2}
  FILE=${line:3}

  case "$STATUS" in
  " M") # Modified file
    git add "$FILE"
    git commit -m "Update note: $FILE"
    echo "${GREEN}[${SCRIPT_NAME}] Committed update for $FILE${RESET}"
    ;;
  "??") # Newly created file
    git add "$FILE"
    git commit -m "Add note: $FILE"
    echo "${YELLOW}[${SCRIPT_NAME}] Committed addition of $FILE${RESET}"
    ;;
  " D") # Deleted file
    git rm "$FILE"
    git commit -m "Remove note: $FILE"
    echo "${RED}[${SCRIPT_NAME}] Committed removal of $FILE${RESET}"
    ;;
  "MM") # Modified in both staging and working directory
    git add "$FILE"
    git commit -m "Update note with staged/unstaged changes: $FILE"
    echo "${BLUE}[${SCRIPT_NAME}] Committed complex update for $FILE${RESET}"
    ;;
  *) # Other status codes
    git add "$FILE"
    git commit -m "Change note: $FILE"
    echo "${CYAN}[${SCRIPT_NAME}] Committed changes for $FILE (status: $STATUS)${RESET}"
    ;;
  esac
done <<<"$CHANGES"

# Push changes to the repository
echo "${BLUE}[${SCRIPT_NAME}] Pushing changes to remote repository...${RESET}"
PUSH_RESULT=$(git push $REMOTE $BRANCH 2>&1)
PUSH_STATUS=$?

if [ $PUSH_STATUS -eq 0 ]; then
  echo "${GREEN}[${SCRIPT_NAME}] Successfully pushed changes to the repository.${RESET}"
else
  echo "${RED}[${SCRIPT_NAME}] Failed to push changes: ${RESET}"
  echo "$PUSH_RESULT"
  exit 1
fi

echo "${CYAN}[${SCRIPT_NAME}] Obsidian vault sync completed.${RESET}"
