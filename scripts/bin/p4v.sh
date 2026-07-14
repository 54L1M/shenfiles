#!/usr/bin/env bash
# P4_DESC: VPS status — health, firewall, fail2ban, and running services over SSH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors/colors.sh"

CONFIG_FILE="$HOME/.config/p4/p4v"

# ── Config ──────────────────────────────────────────────────────────────────
# Holds the server IP and (optionally) the sudo password. Gitignored — see
# .gitignore entry `p4/p4v`. Auto-created with a starter template on first run.
function load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        p4_warn "Config not found: $CONFIG_FILE"
        p4_tip "Creating a starter config — edit it to add your server(s)"
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << 'EOF'
# p4v - VPS Status Config
# GITIGNORED — safe place for the server IP and (optionally) the sudo password.
#
# Default server:
P4V_HOST=""
P4V_USER=""
# P4V_PORT="22"
# P4V_SSH_KEY="$HOME/.ssh/id_ed25519"
#
# Sudo password is needed for firewall + fail2ban status. Leave it UNSET to be
# prompted (hidden) each run — nothing is stored on disk. Set it only if you
# want fully non-interactive runs:
# P4V_SUDO_PASS=""
#
# Additional servers use an UPPERCASE alias suffix, e.g. alias WEB:
# P4V_HOST_WEB="1.2.3.4"
# P4V_USER_WEB="salim"
# P4V_PORT_WEB="22"
# P4V_SUDO_PASS_WEB=""
EOF
        p4_success "Created: $CONFIG_FILE"
        p4_tip "Add your server, then re-run: p4v"
        exit 0
    fi
    set -a
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    set +a
}

# List configured server aliases (`default` when P4V_HOST is set, plus any P4V_HOST_<ALIAS>).
function list_aliases() {
    [[ -n "$P4V_HOST" ]] && echo "default"
    printenv | grep "^P4V_HOST_" | sed 's/^P4V_HOST_//' | cut -d= -f1 | tr '[:upper:]' '[:lower:]'
}

# Resolve connection details for an alias into the SSH_* globals.
SSH_HOST="" SSH_USER="" SSH_PORT="" SSH_KEY="" SUDO_PASS_CFG=""
function resolve_server() {
    local alias="${1:-default}"
    if [[ "$alias" == "default" ]]; then
        SSH_HOST="$P4V_HOST"; SSH_USER="$P4V_USER"; SSH_PORT="$P4V_PORT"
        SSH_KEY="$P4V_SSH_KEY"; SUDO_PASS_CFG="$P4V_SUDO_PASS"
    else
        local u; u=$(echo "$alias" | tr '[:lower:]' '[:upper:]')
        SSH_HOST="$(printenv "P4V_HOST_${u}")"
        SSH_USER="$(printenv "P4V_USER_${u}")"
        SSH_PORT="$(printenv "P4V_PORT_${u}")"
        SSH_KEY="$(printenv "P4V_SSH_KEY_${u}")"
        SUDO_PASS_CFG="$(printenv "P4V_SUDO_PASS_${u}")"
    fi

    if [[ -z "$SSH_HOST" ]]; then
        p4_error "No host configured for '${alias}'"
        p4_tip "Edit $CONFIG_FILE (run 'p4 edit')"
        exit 1
    fi
    [[ -z "$SSH_USER" ]] && SSH_USER="$USER"
}

# fzf-select an alias when several are configured; echo the choice.
function pick_alias() {
    local aliases; aliases=$(list_aliases | sort -u)
    local count; count=$(echo "$aliases" | grep -c .)
    if [[ "$count" -le 1 ]]; then
        echo "$aliases"
        return
    fi
    if command -v fzf >/dev/null; then
        echo "$aliases" | fzf --header="Select VPS" --height=30% --reverse \
            --color="header:blue,prompt:yellow,pointer:red"
    else
        echo "$aliases" | head -n1
    fi
}

# ── Sudo password ─────────────────────────────────────────────────────────────
# Use the configured value if present, otherwise prompt (hidden). Echoed on stdout.
function get_sudo_pass() {
    if [[ -n "$SUDO_PASS_CFG" ]]; then
        printf '%s' "$SUDO_PASS_CFG"
        return
    fi
    local p
    read -rs -p "$(printf '%b' "${P4_ICON_QUESTION} ${P4_CYAN}sudo password for ${SSH_USER}@${SSH_HOST} (empty = skip firewall/fail2ban): ${P4_RESET}")" p
    echo >&2
    printf '%s' "$p"
}

# ── SSH ─────────────────────────────────────────────────────────────────────
function ssh_opts() {
    local -n _opts="$1"
    _opts=(-o ConnectTimeout=8 -o BatchMode=yes -o StrictHostKeyChecking=accept-new)
    [[ -n "$SSH_PORT" ]] && _opts+=(-p "$SSH_PORT")
    [[ -n "$SSH_KEY" ]]  && _opts+=(-i "$SSH_KEY")
}

# The remote collector. Emits tagged lines ("SEC|", "KV|", "SVC|", "DOK|",
# "JAIL|", "FW|", "NOTE|") consumed by render(). Sudo password arrives as the
# P4V_SUDO_PASS env var (via printf %q on the ssh command line) so the script
# body below stays a fully-literal, quoted heredoc.
function run_remote() {
    local pass="$1" opts
    ssh_opts opts
    ssh "${opts[@]}" "${SSH_USER}@${SSH_HOST}" \
        "P4V_SUDO_PASS=$(printf '%q' "$pass") bash -s" <<'REMOTE'
_sudo() {
    if [ -n "$P4V_SUDO_PASS" ]; then
        echo "$P4V_SUDO_PASS" | sudo -S -p '' "$@" 2>/dev/null
    else
        sudo -n "$@" 2>/dev/null
    fi
}

# ── Host & uptime ──
echo "SEC|Host & Uptime"
echo "KV|Hostname|$(hostname)"
. /etc/os-release 2>/dev/null; echo "KV|OS|${PRETTY_NAME:-unknown}"
echo "KV|Kernel|$(uname -r)"
echo "KV|Uptime|$(uptime -p 2>/dev/null | sed 's/^up //')"
echo "KV|Load (1/5/15m)|$(cut -d' ' -f1-3 /proc/loadavg)"

# ── System health ──
echo "SEC|System Health"
echo "KV|CPU cores|$(nproc 2>/dev/null)"
free -m 2>/dev/null | awk '/^Mem:/{printf "KV|Memory|%d / %d MB used (%d%%)\n", $3, $2, ($2>0)?($3/$2)*100:0}'
free -m 2>/dev/null | awk '/^Swap:/{if($2>0) printf "KV|Swap|%d / %d MB used\n", $3, $2; else print "KV|Swap|none"}'
df -h / 2>/dev/null | awk 'NR==2{printf "KV|Disk /|%s / %s used (%s)\n", $3, $2, $5}'

# ── Updates & patches ──
echo "SEC|Updates & Patches"
if [ -x /usr/lib/update-notifier/apt-check ]; then
    ac=$(/usr/lib/update-notifier/apt-check 2>&1)   # prints "updates;security" on stderr
    echo "UPD|${ac%;*}|${ac#*;}"
else
    upd=$(apt-get -s -o Debug::NoLocking=true upgrade 2>/dev/null | grep -c '^Inst')
    echo "UPD|${upd:-0}|?"
fi
if [ -f /var/run/reboot-required ]; then
    echo "REBOOT|yes|$(sort -u /var/run/reboot-required.pkgs 2>/dev/null | tr '\n' ' ')"
else
    echo "REBOOT|no|"
fi

# ── Firewall ──
echo "SEC|Firewall (UFW)"
if command -v ufw >/dev/null 2>&1; then
    fw=$(_sudo ufw status verbose)
    if [ -n "$fw" ]; then
        echo "$fw" | while IFS= read -r l; do [ -n "$l" ] && echo "FW|$l"; done
    else
        echo "NOTE|Could not read UFW status (sudo password needed or denied)"
    fi
else
    echo "NOTE|ufw is not installed"
fi

# ── Fail2ban ──
echo "SEC|Fail2ban"
if command -v fail2ban-client >/dev/null 2>&1; then
    echo "SVC|fail2ban (service)|$(systemctl is-active fail2ban 2>/dev/null)"
    jails=$(_sudo fail2ban-client status | awk -F: '/Jail list/{gsub(/[[:space:]]/,"",$2); print $2}' | tr ',' ' ')
    if [ -n "$jails" ]; then
        for j in $jails; do
            st=$(_sudo fail2ban-client status "$j")
            cur=$(echo "$st" | awk -F: '/Currently banned/{gsub(/[[:space:]]/,"",$2); print $2}')
            tot=$(echo "$st" | awk -F: '/Total banned/{gsub(/[[:space:]]/,"",$2); print $2}')
            fail=$(echo "$st" | awk -F: '/Currently failed/{gsub(/[[:space:]]/,"",$2); print $2}')
            echo "JAIL|$j|${cur:-0}|${tot:-0}|${fail:-0}"
        done
    else
        echo "NOTE|Could not read jails (sudo password needed or denied)"
    fi
else
    echo "NOTE|fail2ban is not installed"
fi

# ── Auth & logins ──
echo "SEC|Auth & Logins"
last -w 2>/dev/null | grep -vE '^$|^wtmp begins' | awk '!seen[$0]++' | head -5 | while IFS= read -r l; do
    echo "LOGIN|$l"
done
fb=$(_sudo lastb -w 2>/dev/null)
if [ -n "$fb" ]; then
    echo "KV|Failed attempts|$(echo "$fb" | grep -cvE '^$|^btmp begins') (in btmp)"
    echo "$fb" | grep -vE '^$|^btmp begins' | head -3 | while IFS= read -r l; do echo "LASTB|$l"; done
else
    echo "NOTE|Could not read failed logins (sudo needed, or btmp empty)"
fi

# ── TLS certificates ──
echo "SEC|TLS Certificates"
if command -v certbot >/dev/null 2>&1; then
    certout=$(_sudo certbot certificates 2>/dev/null)
    if echo "$certout" | grep -q "Certificate Name:"; then
        echo "$certout" | awk '
            /Certificate Name:/ { name=$3 }
            /Expiry Date:/ {
                edate=$3" "$4
                days="?"
                if (match($0, /VALID: [0-9]+ day/)) { d=substr($0,RSTART+7); sub(/ day.*/,"",d); days=d }
                else if (match($0, /INVALID|EXPIRED/)) { days="EXPIRED" }
                print "CERT|"name"|"days"|"edate
            }'
    else
        echo "NOTE|Could not read certbot certificates (sudo needed, or none issued)"
    fi
else
    echo "NOTE|certbot is not installed"
fi

# ── System services ──
echo "SEC|System Services"
for svc in ssh docker fail2ban; do
    state=$(systemctl is-active "$svc" 2>/dev/null)
    [ -n "$state" ] && echo "SVC|$svc|$state"
done

# ── Docker containers ──
echo "SEC|Docker Containers"
if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        running=$(docker ps -q | wc -l | tr -d ' ')
        total=$(docker ps -aq | wc -l | tr -d ' ')
        echo "KV|Running|$running / $total"
        docker ps -a --format '{{.Names}}|{{.Status}}' | while IFS='|' read -r name status; do
            echo "DOK|$name|$status"
        done
    else
        echo "NOTE|Docker daemon not reachable for $USER"
    fi
else
    echo "NOTE|docker is not installed"
fi

exit 0
REMOTE
}

# ── Rendering ─────────────────────────────────────────────────────────────────
function render() {
    local G R Y SUB RST BOLD
    if p4_colors_enabled; then
        G=$(printf '%b' "$P4_GREEN"); R=$(printf '%b' "$P4_RED")
        Y=$(printf '%b' "$P4_YELLOW"); SUB=$(printf '%b' "$P4_BLUE")
        RST=$(printf '%b' "$P4_RESET"); BOLD=$(printf '%b' "$P4_BOLD")
    else
        G="" R="" Y="" SUB="" RST="" BOLD=""
    fi

    local tag rest
    while IFS= read -r raw; do
        [[ -z "$raw" ]] && continue
        tag="${raw%%|*}"; rest="${raw#*|}"
        case "$tag" in
            SEC)
                echo
                p4_header " $rest "
                ;;
            KV)
                local label="${rest%%|*}" val="${rest#*|}"
                printf "  ${SUB}%-16s${RST} %s\n" "$label" "$val"
                ;;
            SVC)
                local name="${rest%%|*}" state="${rest#*|}"
                local c="$Y"
                case "$state" in
                    active) c="$G" ;;
                    inactive|failed|dead|unknown|"") c="$R" ;;
                esac
                printf "  ${BOLD}%-22s${RST} ${c}%s${RST}\n" "$name" "${state:-unknown}"
                ;;
            DOK)
                local name="${rest%%|*}" status="${rest#*|}"
                local c="$R"
                [[ "$status" == Up* ]] && c="$G"
                printf "  ${BOLD}%-24s${RST} ${c}%s${RST}\n" "$name" "$status"
                ;;
            JAIL)
                local jname cur tot fail
                IFS='|' read -r jname cur tot fail <<<"$rest"
                local c="$G"; [[ "${cur:-0}" != "0" ]] && c="$R"
                printf "  ${BOLD}%-14s${RST} banned ${c}%s${RST} now  (total %s, failed %s)\n" \
                    "$jname" "${cur:-0}" "${tot:-0}" "${fail:-0}"
                ;;
            FW)
                # Colorize the leading "Status: active/inactive" line, print rest as-is
                if [[ "$rest" == Status:* ]]; then
                    local s="${rest#Status: }"
                    local c="$R"; [[ "$s" == active ]] && c="$G"
                    printf "  ${BOLD}Status${RST} ${c}%s${RST}\n" "$s"
                else
                    printf "  %s\n" "$rest"
                fi
                ;;
            UPD)
                local upd="${rest%%|*}" sec="${rest#*|}"
                local c="$G"
                [[ "${upd:-0}" != "0" ]] && c="$Y"
                [[ "${sec:-0}" != "0" && "$sec" != "?" ]] && c="$R"
                printf "  ${SUB}%-16s${RST} ${c}%s packages (%s security)${RST}\n" \
                    "Updates" "${upd:-0}" "${sec:-0}"
                ;;
            REBOOT)
                local need="${rest%%|*}" pkgs="${rest#*|}"
                if [[ "$need" == "yes" ]]; then
                    printf "  ${SUB}%-16s${RST} ${R}REQUIRED${RST}%s\n" \
                        "Reboot" "${pkgs:+  ($pkgs)}"
                else
                    printf "  ${SUB}%-16s${RST} ${G}not required${RST}\n" "Reboot"
                fi
                ;;
            CERT)
                local cn cdays cexp
                IFS='|' read -r cn cdays cexp <<<"$rest"
                if [[ "$cdays" =~ ^[0-9]+$ ]]; then
                    local c="$G"
                    (( cdays < 30 )) && c="$Y"
                    (( cdays < 14 )) && c="$R"
                    printf "  ${BOLD}%-22s${RST} ${c}%s days${RST}  (%s)\n" "$cn" "$cdays" "$cexp"
                else
                    printf "  ${BOLD}%-22s${RST} ${R}%s${RST}  (%s)\n" "$cn" "${cdays:-?}" "$cexp"
                fi
                ;;
            LOGIN)
                printf "  ${G}✓${RST} %s\n" "$rest"
                ;;
            LASTB)
                printf "  ${R}✗${RST} %s\n" "$rest"
                ;;
            NOTE)
                p4_warn "$rest"
                ;;
            *)
                printf "  %s\n" "$raw"
                ;;
        esac
    done
}

# ── Commands ──────────────────────────────────────────────────────────────────
function do_status() {
    local alias; alias=$(pick_alias)
    [[ -z "$alias" ]] && exit 0
    resolve_server "$alias"

    p4_header "p4v — VPS Status: ${SSH_USER}@${SSH_HOST}${SSH_PORT:+:$SSH_PORT}"

    # Reachability probe first (fast, no sudo).
    local opts; ssh_opts opts
    if ! ssh "${opts[@]}" "${SSH_USER}@${SSH_HOST}" true 2>/tmp/p4v_ssh_err; then
        p4_error "Cannot reach ${SSH_USER}@${SSH_HOST}"
        [[ -s /tmp/p4v_ssh_err ]] && p4_info "$(cat /tmp/p4v_ssh_err)"
        rm -f /tmp/p4v_ssh_err
        exit 1
    fi
    rm -f /tmp/p4v_ssh_err
    p4_success "Reachable"

    local pass; pass=$(get_sudo_pass)

    local out; out=$(run_remote "$pass")
    printf '%s\n' "$out" | render
    echo
}

function show_help() {
    p4_header "p4v - VPS Status Dashboard"
    p4_info "Usage: p4v [command] [server-alias]"
    echo
    p4_title "Commands:"
    p4_cmd "status" "[alias]" "Full dashboard: health, firewall, fail2ban, services (default)"
    p4_cmd "ssh" "[alias]" "Open an interactive SSH session to the server"
    p4_cmd "ls, servers" "" "List configured servers"
    p4_cmd "-h, --help" "" "Show this help"
    echo
    p4_title "Config:"
    p4_info "  $CONFIG_FILE  (gitignored — holds IP + optional sudo password)"
    p4_tip "  Sudo password is prompted (hidden) each run unless P4V_SUDO_PASS is set"
    p4_tip "  Multiple servers: add P4V_HOST_<ALIAS> entries, then 'p4v status <alias>'"
}

function do_ssh() {
    load_config
    local alias; alias=$(pick_alias)
    [[ -z "$alias" ]] && exit 0
    resolve_server "$alias"
    local opts; ssh_opts opts
    # drop BatchMode for interactive session
    opts=("${opts[@]/-o BatchMode=yes/}")
    p4_step "Connecting to ${SSH_USER}@${SSH_HOST}..."
    exec ssh -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new \
        ${SSH_PORT:+-p "$SSH_PORT"} ${SSH_KEY:+-i "$SSH_KEY"} "${SSH_USER}@${SSH_HOST}"
}

case "${1:-status}" in
    status|s)
        load_config
        do_status "$2"
        ;;
    ssh)
        do_ssh "$2"
        ;;
    ls|servers|list)
        load_config
        p4_title "Configured servers:"
        list_aliases | sort -u | while read -r a; do
            [[ -n "$a" ]] && p4_item "  $a" ""
        done
        ;;
    -h|--help)
        show_help
        ;;
    -*)
        p4_error "Unknown flag: $1"
        show_help
        exit 1
        ;;
    *)
        # bare alias → status for that alias
        load_config
        do_status "$1"
        ;;
esac
