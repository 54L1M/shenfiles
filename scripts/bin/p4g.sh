#!/usr/bin/env bash
# P4_DESC: GCloud switcher — fzf project and account switching with tmux integration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

CONFIG_FILE="$HOME/.config/p4/p4g"
export PATH="/Users/54l1m/Downloads/google-cloud-sdk/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

function show_help() {
    p4_header "p4g - GCloud Project & Account Switcher"
    p4_info "Usage: p4g [command]"
    echo
    p4_title "Commands:"
    p4_cmd "proj, project" "" "fzf-select and switch active GCP project (default)"
    p4_cmd "acct, account" "" "fzf-select gcloud account"
    p4_cmd "login" "" "Run gcloud auth login + application-default login"
    p4_cmd "status, s" "" "Show current project and account"
    p4_cmd "-h, --help" "" "Show this help"
    echo
    p4_title "Config:"
    p4_info "  $CONFIG_FILE"
    p4_tip "  Add projects as: P4G_PROJECT_<ALIAS>=<gcp-project-id>"
    p4_tip "  Add accounts as: P4G_ACCOUNT_<ALIAS>=<email>"
}

function load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        p4_warn "Config not found: $CONFIG_FILE"
        p4_tip "Creating a starter config — edit it to add your projects"
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << 'EOF'
# p4g - GCloud Project Config
# Add one line per project alias: P4G_PROJECT_<ALIAS>=<gcp-project-id>
# Optional account override:      P4G_ACCOUNT_<ALIAS>=<email>

P4G_PROJECT_I2D="i2d-cloud"
P4G_ACCOUNT_I2D="salim.siboni@in2dialog.com"

# Default account used when no per-project account is set
P4G_DEFAULT_ACCOUNT="tavakkolisetareh@gmail.com"
EOF
        p4_success "Created: $CONFIG_FILE"
    fi
    set -a
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    set +a
}

function get_project_aliases() {
    printenv | grep "^P4G_PROJECT_" | sed 's/^P4G_PROJECT_//' | cut -d= -f1
}

function get_project_id() {
    local alias_upper
    alias_upper=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    printenv "P4G_PROJECT_${alias_upper}" 2>/dev/null
}

function get_project_account() {
    local alias_upper
    alias_upper=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    printenv "P4G_ACCOUNT_${alias_upper}" 2>/dev/null || printenv "P4G_DEFAULT_ACCOUNT" 2>/dev/null
}

function switch_project() {
    load_config

    local aliases current_project
    aliases=$(get_project_aliases | sort)
    current_project=$(gcloud config get-value project 2>/dev/null)

    if [[ -z "$aliases" ]]; then
        p4_warn "No projects defined in config. Add P4G_PROJECT_<ALIAS>=<id> entries."
        exit 0
    fi

    local selected
    selected=$(echo "$aliases" | fzf \
        --header="Switch GCP Project | Current: ${current_project:-none}" \
        --preview='
            alias_upper=$(echo {} | tr "[:lower:]" "[:upper:]")
            id=$(printenv "P4G_PROJECT_${alias_upper}" 2>/dev/null)
            acct=$(printenv "P4G_ACCOUNT_${alias_upper}" 2>/dev/null || printenv P4G_DEFAULT_ACCOUNT 2>/dev/null)
            echo "Project ID: ${id:-(not set)}"
            echo "Account:    ${acct:-(default)}"
        ' \
        --preview-window=down:3:wrap \
        --height=40% --reverse \
        --color="header:blue,prompt:yellow,pointer:red")

    [[ -z "$selected" ]] && exit 0

    local project_id account
    project_id=$(get_project_id "$selected")
    account=$(get_project_account "$selected")

    if [[ -z "$project_id" ]]; then
        p4_error "No project ID found for alias: $selected"
        exit 1
    fi

    gcloud config set project "$project_id" 2>/dev/null
    if [[ -n "$account" ]]; then
        gcloud config set account "$account" 2>/dev/null
    fi

    p4_success "Project: $selected ($project_id)"
    [[ -n "$account" ]] && p4_info "Account: $account"
    [[ -n "$TMUX" ]] && tmux refresh-client -S
}

function switch_account() {
    local accounts current_account
    accounts=$(gcloud auth list --format='value(account)' 2>/dev/null)
    current_account=$(gcloud config get-value account 2>/dev/null)

    if [[ -z "$accounts" ]]; then
        p4_warn "No authenticated accounts. Run: p4g login"
        exit 0
    fi

    local selected
    selected=$(echo "$accounts" | fzf \
        --header="Switch Account | Current: ${current_account:-none}" \
        --height=30% --reverse \
        --color="header:blue,prompt:yellow,pointer:red")

    [[ -z "$selected" ]] && exit 0

    gcloud config set account "$selected" 2>/dev/null
    p4_success "Account: $selected"
    [[ -n "$TMUX" ]] && tmux refresh-client -S
}

function show_status() {
    local project account
    project=$(gcloud config get-value project 2>/dev/null)
    account=$(gcloud config get-value account 2>/dev/null)
    p4_info "Project: $(p4_highlight "${project:-none}")"
    p4_info "Account: $(p4_highlight "${account:-none}")"
}

function do_login() {
    p4_step "Running gcloud auth login..."
    gcloud auth login
    p4_step "Running application-default login..."
    gcloud auth application-default login
    p4_success "Authentication complete"
}

case "${1:-proj}" in
    proj|project) switch_project ;;
    acct|account) switch_account ;;
    login) do_login ;;
    status|s) show_status ;;
    -h|--help) show_help ;;
    *)
        p4_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
