#!/usr/bin/env bash
# bbox - File encryption/decryption using AES-256-CBC with PBKDF2 key derivation
# P4_DESC: Encryption tool — encrypt and decrypt files with AES-256 + PBKDF2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

BBOX_EXT=".bbox"
PBKDF2_ITER=600000

show_help() {
    p4_header "bbox - File Encryption"
    p4_info "Usage: bbox <command> <file> [-o output]"
    echo
    p4_title "Commands:"
    p4_cmd "e, encrypt" "<file>" "Encrypt file → <file>.bbox"
    p4_cmd "d, decrypt" "<file>" "Decrypt file → strips .bbox extension"
    p4_cmd "-h, --help" ""       "Show this help"
    echo
    p4_title "Options:"
    p4_cmd "-o" "<output>" "Override output file path"
    echo
    p4_title "Examples:"
    p4_example "bbox e secrets.txt"          "→ secrets.txt.bbox"
    p4_example "bbox d secrets.txt.bbox"     "→ secrets.txt"
    p4_example "bbox e notes.txt -o safe"    "→ safe"
}

check_deps() {
    if ! command -v openssl >/dev/null 2>&1; then
        p4_die "openssl is required but not installed."
    fi
}

read_passphrase() {
    local prompt="$1"
    local pass
    read -r -s -p "$prompt" pass </dev/tty
    echo >&2
    printf '%s' "$pass"
}

cmd_encrypt() {
    local input="$1" output="$2"

    if [[ ! -f "$input" ]]; then
        p4_die "File not found: $input"
    fi

    if [[ -z "$output" ]]; then
        output="${input}${BBOX_EXT}"
    fi

    local pass confirm
    pass=$(read_passphrase "Passphrase: ")
    confirm=$(read_passphrase "Confirm:    ")

    if [[ "$pass" != "$confirm" ]]; then
        p4_die "Passphrases do not match."
    fi

    if [[ -z "$pass" ]]; then
        p4_die "Passphrase cannot be empty."
    fi

    p4_step "Encrypting $input..."

    printf '%s\n' "$pass" | openssl enc -aes-256-cbc -pbkdf2 -iter "$PBKDF2_ITER" \
        -pass stdin -in "$input" -out "$output" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        p4_die "Encryption failed."
    fi

    chmod 600 "$output"
    p4_success "Encrypted → $output"
}

cmd_decrypt() {
    local input="$1" output="$2"

    if [[ ! -f "$input" ]]; then
        p4_die "File not found: $input"
    fi

    if [[ -z "$output" ]]; then
        output="${input%${BBOX_EXT}}"
        if [[ "$output" == "$input" ]]; then
            p4_die "Input has no .bbox extension. Specify output with -o."
        fi
    fi

    local pass
    pass=$(read_passphrase "Passphrase: ")

    p4_step "Decrypting $input..."

    printf '%s\n' "$pass" | openssl enc -d -aes-256-cbc -pbkdf2 -iter "$PBKDF2_ITER" \
        -pass stdin -in "$input" -out "$output" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        rm -f "$output"
        p4_die "Decryption failed. Wrong passphrase or corrupt file."
    fi

    chmod 600 "$output"
    p4_success "Decrypted → $output"
}

# ── Argument parsing ──────────────────────────────────────────────────────────

check_deps

COMMAND="${1:-}"
shift || true

INPUT=""
OUTPUT=""

case "$COMMAND" in
    e|encrypt|d|decrypt) ;;
    -h|--help) show_help; exit 0 ;;
    "") show_help; exit 1 ;;
    *) p4_error "Unknown command: $COMMAND"; show_help; exit 1 ;;
esac

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o) OUTPUT="$2"; shift 2 ;;
        -*) p4_error "Unknown option: $1"; show_help; exit 1 ;;
        *)  [[ -z "$INPUT" ]] && INPUT="$1" || { p4_error "Unexpected argument: $1"; exit 1; }; shift ;;
    esac
done

if [[ -z "$INPUT" ]]; then
    p4_error "No input file specified."
    show_help
    exit 1
fi

case "$COMMAND" in
    e|encrypt) cmd_encrypt "$INPUT" "$OUTPUT" ;;
    d|decrypt) cmd_decrypt "$INPUT" "$OUTPUT" ;;
esac
