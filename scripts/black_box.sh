#!/bin/bash

set -e

# Default Argon2 parameters
ARGON2_TIME=2      # Number of iterations
ARGON2_MEMORY=16   # Memory usage (MB)
ARGON2_PARALLEL=1  # Number of parallel threads
ARGON2_KEYLEN=32   # Key length (bytes)

# Usage function
usage() {
  cat <<EOF
Usage: $0 [encrypt|decrypt] [options]

Commands:
  encrypt            Encrypt a file
  decrypt            Decrypt a file

Options:
  --password PASS    Password for encryption/decryption (required)
  --salt SALT        Salt for encryption/decryption (required)
  --input FILE       Path to the input file (default: input.txt)
  --output FILE      Path to the output file (default: encrypt: input.enc, decrypt: input without .enc)
  --time T           Argon2 iterations (default: $ARGON2_TIME)
  --memory M         Argon2 memory in MB (default: $ARGON2_MEMORY)
  --parallel P       Argon2 parallelism (default: $ARGON2_PARALLEL)
  --keylen K         Argon2 key length (default: $ARGON2_KEYLEN)
  --delete-original  Delete the original file after processing (default: false)

Examples:
  Encrypt a file:
    $0 encrypt --password mypassword --salt mysalt --input file.txt --output file.enc

  Decrypt a file:
    $0 decrypt --password mypassword --salt mysalt --input file.enc --output file.txt
EOF
  exit 1
}

# Initialize variables
DELETE_ORIGINAL=false
COMMAND=""

# Parse the command (first argument)
if [[ "$#" -gt 0 ]]; then
  case "$1" in
    encrypt|decrypt) COMMAND=$1; shift ;;
    *) echo "Error: First argument must be 'encrypt' or 'decrypt'."; usage ;;
  esac
else
  usage
fi

# Parse options
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --password) PASSWORD=$2; shift ;;
    --salt) SALT=$2; shift ;;
    --input) INPUT_FILE=$2; shift ;;
    --output) OUTPUT_FILE=$2; shift ;;
    --time) ARGON2_TIME=$2; shift ;;
    --memory) ARGON2_MEMORY=$2; shift ;;
    --parallel) ARGON2_PARALLEL=$2; shift ;;
    --keylen) ARGON2_KEYLEN=$2; shift ;;
    --delete-original) DELETE_ORIGINAL=true ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
  shift
done

# Validate inputs
if [[ -z "$PASSWORD" || -z "$SALT" ]]; then
  echo "Error: --password and --salt are required."
  usage
fi

INPUT_FILE=${INPUT_FILE:-"input.txt"}
if [[ "$COMMAND" == "encrypt" ]]; then
  OUTPUT_FILE=${OUTPUT_FILE:-"${INPUT_FILE}.enc"}
elif [[ "$COMMAND" == "decrypt" ]]; then
  OUTPUT_FILE=${OUTPUT_FILE:-"${INPUT_FILE%.enc}"}
fi

encrypt_file() {
  echo "Encrypting $INPUT_FILE..."
  # Validate the salt length
  if [[ ${#SALT} -lt 8 ]]; then
    echo "Error: Salt is too short. It must be at least 8 characters long."
    exit 1
  fi 
  # Generate encryption key using Argon2
  ENCRYPTION_KEY=$(echo -n "$PASSWORD" | argon2 "$SALT" -t "$ARGON2_TIME" -m "$ARGON2_MEMORY" -p "$ARGON2_PARALLEL" -l "$ARGON2_KEYLEN" | cut -d'$' -f7)

  # Encrypt the file using the generated key
  openssl enc -aes-256-cbc -pbkdf2 -salt -in "$INPUT_FILE" -out "$OUTPUT_FILE" -pass pass:"$ENCRYPTION_KEY"
  chmod 600 "$OUTPUT_FILE"

  # Optionally delete the original file
  if [[ "$DELETE_ORIGINAL" == "true" ]]; then
    shred -u "$INPUT_FILE"
    echo "Original file deleted: $INPUT_FILE"
  fi

  echo "Encryption complete. Output saved to $OUTPUT_FILE."
}

decrypt_file() {
  echo "Decrypting $INPUT_FILE..."

  # Generate decryption key using Argon2
  DECRYPTION_KEY=$(echo -n "$PASSWORD" | argon2 "$SALT" -t "$ARGON2_TIME" -m "$ARGON2_MEMORY" -p "$ARGON2_PARALLEL" -l "$ARGON2_KEYLEN" | cut -d'$' -f7)

  # Decrypt the file using the generated key
  openssl enc -d -aes-256-cbc -pbkdf2 -in "$INPUT_FILE" -out "$OUTPUT_FILE" -pass pass:"$DECRYPTION_KEY"
  chmod 600 "$OUTPUT_FILE"
  
  echo "Decryption complete. Output saved to $OUTPUT_FILE."
}

# Execute command
case "$COMMAND" in
  encrypt) encrypt_file ;;
  decrypt) decrypt_file ;;
  *) usage ;;
esac
