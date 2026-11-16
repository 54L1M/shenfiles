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
    read -rs -p "$(printf '%b' "${P4_ICON_QUESTION} ${P4_CYAN}sudo password for ${SSH_USER}@${SSH_HOST} (empty = skip firewall rules, fail2ban, failed logins): ${P4_RESET}")" p
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
up=$(uptime -p 2>/dev/null | sed 's/^up //')
if [ -z "$up" ]; then   # uptime on NixOS has no -p
    s=$(cut -d. -f1 /proc/uptime)
    up="$((s/86400)) days, $((s%86400/3600)) hours, $((s%3600/60)) minutes"
fi
echo "KV|Uptime|$up"
echo "KV|Load (1/5/15m)|$(cut -d' ' -f1-3 /proc/loadavg)"

# ── System health ──
echo "SEC|System Health"
echo "KV|CPU cores|$(nproc 2>/dev/null)"
free -m 2>/dev/null | awk '/^Mem:/{printf "KV|Memory|%d / %d MB used (%d%%)\n", $3, $2, ($2>0)?($3/$2)*100:0}'
free -m 2>/dev/null | awk '/^Swap:/{if($2>0) printf "KV|Swap|%d / %d MB used\n", $3, $2; else print "KV|Swap|none"}'
df -h / 2>/dev/null | awk 'NR==2{printf "KV|Disk /|%s / %s used (%s)\n", $3, $2, $5}'

# ── Updates & patches ──
if [ -e /etc/NIXOS ]; then
    # NixOS has no pending-updates list: the system is whatever the last deploy
    # built. Show how old that is, and whether the running kernel is behind it.
    echo "SEC|NixOS System"
    ver=$(nixos-version 2>/dev/null | cut -d' ' -f1)
    echo "KV|Version|${ver:-unknown}"
    pin=$(echo "$ver" | cut -d. -f3)          # nixpkgs commit date, YYYYMMDD
    case "$pin" in
        [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])
            pin_s=$(date -d "$pin" +%s 2>/dev/null)
            [ -n "$pin_s" ] && echo "AGE|$(( ($(date +%s) - pin_s) / 86400 ))" ;;
    esac
    prof=/nix/var/nix/profiles/system
    gen=$(readlink "$prof" 2>/dev/null | sed 's/^system-\([0-9]*\)-link$/\1/')
    echo "KV|Generation|${gen:-?} (deployed $(stat -c %y "$prof" 2>/dev/null | cut -d: -f1,2))"
    kver() { readlink "$1/kernel" 2>/dev/null | sed 's/.*-linux-\([0-9][0-9.]*\).*/\1/'; }
    changed=""
    for part in kernel initrd kernel-modules; do
        [ "$(readlink /run/booted-system/$part)" != "$(readlink $prof/$part)" ] && changed="$changed$part "
    done
    if [ -n "$changed" ]; then
        b=$(kver /run/booted-system); n=$(kver "$prof")
        if [ "$b" != "$n" ]; then echo "REBOOT|yes|kernel $b running, $n installed"
        else echo "REBOOT|yes|changed: $changed"; fi
    else
        echo "REBOOT|no|"
    fi
else
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
fi

# ── Firewall ──
if command -v ufw >/dev/null 2>&1; then
    echo "SEC|Firewall (UFW)"
    fw=$(_sudo ufw status verbose)
    if [ -n "$fw" ]; then
        echo "$fw" | while IFS= read -r l; do [ -n "$l" ] && echo "FW|$l"; done
    else
        echo "NOTE|Could not read UFW status (sudo password needed or denied)"
    fi
elif [ -e /etc/NIXOS ]; then
    # NixOS firewall: firewall.service (iptables, chain nixos-fw) or nftables.service.
    echo "SEC|Firewall (NixOS)"
    if [ "$(systemctl is-active firewall 2>/dev/null)" = active ]; then
        echo "FW|Status: active"
        rules=$(_sudo iptables -S nixos-fw)
        if [ -n "$rules" ]; then
            echo "$rules" | awk '/ -j nixos-fw-accept/ {
                proto=""; port=""; iface=""
                for (i = 1; i <= NF; i++) {
                    if ($i == "-p") proto = $(i+1)
                    if ($i == "--dport" || $i == "--dports") port = $(i+1)
                    if ($i == "-i") iface = $(i+1)
                }
                if (port != "") printf "FW|allow %-4s %s%s\n", proto, port, (iface != "" ? " on " iface : "")
                else if (iface != "" && iface != "lo") print "FW|allow all  on " iface
            }'
        else
            echo "NOTE|Could not read firewall rules (sudo password needed or denied)"
        fi
    elif [ "$(systemctl is-active nftables 2>/dev/null)" = active ]; then
        echo "FW|Status: active"
        rules=$(_sudo nft list ruleset)
        if [ -n "$rules" ]; then
            echo "$rules" | grep -E 'dport|iifname' | sed 's/^[[:space:]]*/FW|/'
        else
            echo "NOTE|Could not read firewall rules (sudo password needed or denied)"
        fi
    else
        echo "FW|Status: inactive"
    fi
else
    echo "SEC|Firewall"
    echo "NOTE|No supported firewall found (ufw or the NixOS firewall)"
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
# NixOS ACME: one directory per certificate under /var/lib/acme. The files are
# not readable without root, so ask the local web server what it actually serves.
# Prints "name|days|expiry-date" per certificate.
acme_certs() {
    for d in /var/lib/acme/*/; do
        name=$(basename "$d")
        [ "$name" = acme-challenge ] && continue
        exp=$(curl -svI --max-time 8 --resolve "$name:443:127.0.0.1" "https://$name" 2>&1 \
            | sed -n 's/^\*  *expire date: //p' | head -1)
        exp_s=$(date -d "$exp" +%s 2>/dev/null)
        if [ -n "$exp" ] && [ -n "$exp_s" ]; then
            echo "$name|$(( (exp_s - $(date +%s)) / 86400 ))|$(date -d "$exp" +%Y-%m-%d)"
        else
            echo "$name|?|not served on port 443"
        fi
    done
}
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
elif [ -d /var/lib/acme ]; then
    acme_certs | while IFS= read -r l; do echo "CERT|$l"; done
    timers=$(systemctl list-timers 'acme-renew-*' --no-legend --no-pager 2>/dev/null | grep -c .)
    echo "KV|Renewal|automatic, $timers timers active"
else
    echo "NOTE|No certificates found (certbot or NixOS ACME)"
fi

# ── System services ──
echo "SEC|System Services"
for svc in ssh sshd nginx docker fail2ban tailscaled gitea; do
    # Only units that exist on this host (ssh on Debian, sshd on NixOS, ...).
    systemctl list-unit-files "$svc.service" --no-legend 2>/dev/null | grep -q . || continue
    echo "SVC|$svc|$(systemctl is-active "$svc" 2>/dev/null)"
done
failed=$(systemctl --failed --no-legend --plain --no-pager 2>/dev/null | awk '{print $1}')
if [ -n "$failed" ]; then
    for u in $failed; do echo "SVC|$u|failed"; done
else
    echo "KV|Failed units|none"
fi

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

# Remote cert renewal. Lists certbot certs, renews any expired or expiring
# within $THRESHOLD days, then re-lists. Emits the same tagged lines as
# run_remote() plus "RENEW|name|status|msg".
function run_remote_certs() {
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
# Same as _sudo but keeps stderr — certbot reports renewal errors there.
_sudo_err() {
    if [ -n "$P4V_SUDO_PASS" ]; then
        echo "$P4V_SUDO_PASS" | sudo -S -p '' "$@" 2>&1
    else
        sudo -n "$@" 2>&1
    fi
}

THRESHOLD=30

# NixOS ACME: one directory per certificate under /var/lib/acme. The files are
# not readable without root, so ask the local web server what it actually serves.
# Prints "name|days|expiry-date" per certificate.
acme_certs() {
    for d in /var/lib/acme/*/; do
        name=$(basename "$d")
        [ "$name" = acme-challenge ] && continue
        exp=$(curl -svI --max-time 8 --resolve "$name:443:127.0.0.1" "https://$name" 2>&1 \
            | sed -n 's/^\*  *expire date: //p' | head -1)
        exp_s=$(date -d "$exp" +%s 2>/dev/null)
        if [ -n "$exp" ] && [ -n "$exp_s" ]; then
            echo "$name|$(( (exp_s - $(date +%s)) / 86400 ))|$(date -d "$exp" +%Y-%m-%d)"
        else
            echo "$name|?|not served on port 443"
        fi
    done
}

echo "SEC|TLS Certificates"
if ! command -v certbot >/dev/null 2>&1 && [ -d /var/lib/acme ]; then
    # NixOS: renewal is a systemd service per certificate, normally run by its
    # timer. Starting it by hand is safe: it only orders a new certificate when
    # the current one is close to expiry, and reloads the web server itself.
    certs=$(acme_certs)
    due=""
    while IFS='|' read -r name days edate; do
        [ -z "$name" ] && continue
        echo "CERT|$name|$days|$edate"
        case "$days" in
            ''|*[!0-9-]*) due="$due$name " ;;
            *) [ "$days" -lt "$THRESHOLD" ] && due="$due$name " ;;
        esac
    done <<EOF
$certs
EOF
    echo "SEC|Renewal"
    if [ -z "$due" ]; then
        echo "NOTE|All certificates valid for ${THRESHOLD}+ days — nothing to renew"
        exit 0
    fi
    for name in $due; do
        before=$(echo "$certs" | awk -F'|' -v n="$name" '$1 == n {print $3}')
        out=$(_sudo_err systemctl start "acme-order-renew-$name.service")
        rc=$?
        after=$(acme_certs | awk -F'|' -v n="$name" '$1 == n {print $3}')
        if [ $rc -ne 0 ]; then
            echo "RENEW|$name|failed|${out:-see: journalctl -u acme-order-renew-$name}"
        elif [ "$after" = "$before" ]; then
            echo "RENEW|$name|skipped|the ACME service ran but kept the current certificate"
        else
            echo "RENEW|$name|ok|"
        fi
    done
    echo "SEC|After Renewal"
    acme_certs | while IFS= read -r l; do echo "CERT|$l"; done
    exit 0
fi
if ! command -v certbot >/dev/null 2>&1; then
    echo "NOTE|No certificates found (certbot or NixOS ACME)"
    exit 0
fi

list_certs() {
    _sudo certbot certificates 2>/dev/null | awk '
        /Certificate Name:/ { name=$3 }
        /Expiry Date:/ {
            edate=$3" "$4
            days="?"
            if (match($0, /VALID: [0-9]+ day/)) { d=substr($0,RSTART+7); sub(/ day.*/,"",d); days=d }
            else if (match($0, /INVALID|EXPIRED/)) { days="EXPIRED" }
            print name"|"days"|"edate
        }'
}

certs=$(list_certs)
if [ -z "$certs" ]; then
    echo "NOTE|Could not read certbot certificates (sudo needed, or none issued)"
    exit 0
fi

due=""
while IFS='|' read -r name days edate; do
    echo "CERT|$name|$days|$edate"
    case "$days" in
        EXPIRED) due="$due$name " ;;
        ''|*[!0-9]*) ;;
        *) [ "$days" -lt "$THRESHOLD" ] && due="$due$name " ;;
    esac
done <<EOF
$certs
EOF

echo "SEC|Renewal"
if [ -z "$due" ]; then
    echo "NOTE|All certificates valid for ${THRESHOLD}+ days — nothing to renew"
    exit 0
fi

# Standalone auth needs to bind port 80. If a docker container (reverse
# proxy) holds it, stop it for the duration of the renewals and restart it
# after — the restart also makes it pick up the renewed certs.
PROXY=""
if command -v docker >/dev/null 2>&1; then
    PROXY=$(docker ps --filter "publish=80" --format '{{.Names}}' 2>/dev/null | head -1)
fi
if [ -n "$PROXY" ]; then
    echo "NOTE|Port 80 held by container '$PROXY' — stopping it during renewal (brief downtime)"
    if ! docker stop "$PROXY" >/dev/null 2>&1; then
        echo "NOTE|Could not stop '$PROXY' — renewals will likely fail to bind port 80"
        PROXY=""
    else
        trap 'docker start "$PROXY" >/dev/null 2>&1' EXIT
    fi
elif ss -tln 2>/dev/null | grep -qE ':80\b'; then
    echo "NOTE|Port 80 is in use by a non-docker process — standalone renewal may fail"
fi

renewed=0
for name in $due; do
    out=$(_sudo_err certbot renew --cert-name "$name" --no-random-sleep-on-renew)
    rc=$?
    if [ $rc -ne 0 ]; then
        err=$(echo "$out" | grep -iE 'error|failed|problem' | head -1)
        echo "RENEW|$name|failed|${err:-see /var/log/letsencrypt/letsencrypt.log}"
    elif echo "$out" | grep -q "No renewals were attempted"; then
        echo "RENEW|$name|skipped|certbot considers it not yet due (renew_before_expiry)"
    else
        renewed=$((renewed+1))
        echo "RENEW|$name|ok|"
    fi
done

if [ -n "$PROXY" ]; then
    trap - EXIT
    if docker start "$PROXY" >/dev/null 2>&1; then
        echo "NOTE|Restarted '$PROXY'"
    else
        echo "NOTE|FAILED to restart '$PROXY' — run manually: docker start $PROXY"
    fi
fi

if [ "$renewed" -gt 0 ]; then
    echo "SEC|After Renewal"
    list_certs | while IFS= read -r l; do echo "CERT|$l"; done
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
            AGE)
                # Days since the nixpkgs revision the system was built from.
                local c="$G"
                (( rest > 30 )) && c="$Y"
                (( rest > 90 )) && c="$R"
                printf "  ${SUB}%-16s${RST} ${c}%s days old${RST}\n" "nixpkgs" "$rest"
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
            RENEW)
                local rname rstat rmsg
                IFS='|' read -r rname rstat rmsg <<<"$rest"
                case "$rstat" in
                    ok)      printf "  ${BOLD}%-22s${RST} ${G}renewed${RST}\n" "$rname" ;;
                    skipped) printf "  ${BOLD}%-22s${RST} ${Y}skipped${RST}  %s\n" "$rname" "$rmsg" ;;
                    *)       printf "  ${BOLD}%-22s${RST} ${R}FAILED${RST}  %s\n" "$rname" "$rmsg" ;;
                esac
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

function do_certs() {
    local alias="${1:-}"
    [[ -z "$alias" ]] && alias=$(pick_alias)
    [[ -z "$alias" ]] && exit 0
    resolve_server "$alias"

    p4_header "p4v — TLS Cert Renewal: ${SSH_USER}@${SSH_HOST}${SSH_PORT:+:$SSH_PORT}"

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

    p4_step "Checking certificates and renewing any expiring within 30 days..."
    local out; out=$(run_remote_certs "$pass")
    printf '%s\n' "$out" | render
    echo
}

function show_help() {
    p4_header "p4v - VPS Status Dashboard"
    p4_info "Usage: p4v [command] [server-alias]"
    echo
    p4_title "Commands:"
    p4_cmd "status" "[alias]" "Full dashboard: health, firewall, fail2ban, services (default)"
    p4_cmd "certs, renew" "[alias]" "Renew TLS certs expiring within 30 days (certbot, or NixOS ACME)"
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
    certs|renew|c)
        load_config
        do_certs "$2"
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
