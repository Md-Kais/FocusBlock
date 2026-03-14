#!/bin/bash

# FocusBlock - URL Blocking System for Debian
# Usage: focusblock <command> [options]

HOSTS_FILE="/etc/hosts"
STATE_FILE="/var/lib/focusblock/state"
TIMER_FILE="/var/lib/focusblock/timer"
BACKUP_FILE="/var/lib/focusblock/hosts.backup"
BLOCK_START_MARKER="# === FOCUSBLOCK START ==="
BLOCK_END_MARKER="# === FOCUSBLOCK END ==="

# ─── Site Categories ───────────────────────────────────────────────────────────

SOCIAL_MEDIA_SITES=(
    "facebook.com" "www.facebook.com" "m.facebook.com"
    "instagram.com" "www.instagram.com"
    "threads.net" "www.threads.net"
    "twitter.com" "www.twitter.com" "x.com" "www.x.com"
    "kongregate.com" "www.kongregate.com"
    "poki.com" "www.poki.com"
    "miniclip.com" "www.miniclip.com"
    "crazygames.com" "www.crazygames.com"
    "y8.com" "www.y8.com"
    "addictinggames.com" "www.addictinggames.com"
)

PORN_SITES=(
    "pornhub.com" "www.pornhub.com"
    "xvideos.com" "www.xvideos.com"
    "xhamster.com" "www.xhamster.com"
    "redtube.com" "www.redtube.com"
    "youporn.com" "www.youporn.com"
    "xnxx.com" "www.xnxx.com"
    "brazzers.com" "www.brazzers.com"
    "onlyfans.com" "www.onlyfans.com"
    "chaturbate.com" "www.chaturbate.com"
    "livejasmin.com" "www.livejasmin.com"
    "cam4.com" "www.cam4.com"
    "stripchat.com" "www.stripchat.com"
    "spankbang.com" "www.spankbang.com"
    "eporner.com" "www.eporner.com"
    "tube8.com" "www.tube8.com"
    "tnaflix.com" "www.tnaflix.com"
    "drtuber.com" "www.drtuber.com"
    "beeg.com" "www.beeg.com"
    "hentaigasm.com" "www.hentaigasm.com"
    "nhentai.net" "www.nhentai.net"
    "rule34.xxx" "www.rule34.xxx"
)

YOUTUBE_SITES=(
    "youtube.com" "www.youtube.com" "m.youtube.com"
    "youtu.be"
    "youtube-nocookie.com" "www.youtube-nocookie.com"
)

# ─── Helpers ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}✗ This command requires root privileges.${RESET}"
        echo -e "  Run: ${CYAN}sudo focusblock $*${RESET}"
        exit 1
    fi
}

ensure_state_dir() {
    mkdir -p /var/lib/focusblock
}

get_category() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "none"
    fi
}

get_timer_end() {
    if [[ -f "$TIMER_FILE" ]]; then
        cat "$TIMER_FILE"
    else
        echo "0"
    fi
}

format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$((seconds % 60))
    if [[ $hours -gt 0 ]]; then
        printf "%dh %02dm %02ds" $hours $minutes $secs
    elif [[ $minutes -gt 0 ]]; then
        printf "%dm %02ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}

parse_duration() {
    local input="$1"
    local total=0
    # Parse formats like: 30m, 1h, 1h30m, 90m, 3600s, 2h15m30s
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        total=$input  # plain number = seconds
    else
        local h=$(echo "$input" | grep -oP '[0-9]+(?=h)' || echo 0)
        local m=$(echo "$input" | grep -oP '[0-9]+(?=m)' || echo 0)
        local s=$(echo "$input" | grep -oP '[0-9]+(?=s)' || echo 0)
        h=${h:-0}; m=${m:-0}; s=${s:-0}
        total=$((h * 3600 + m * 60 + s))
    fi
    echo $total
}

# ─── Block/Unblock Logic ───────────────────────────────────────────────────────

remove_block_entries() {
    # Remove existing focusblock entries
    sed -i "/$BLOCK_START_MARKER/,/$BLOCK_END_MARKER/d" "$HOSTS_FILE"
    # Clean up any blank lines at end
    sed -i -e '/^$/N;/^\n$/d' "$HOSTS_FILE"
}

apply_block_entries() {
    local sites=("$@")
    {
        echo ""
        echo "$BLOCK_START_MARKER"
        for site in "${sites[@]}"; do
            echo "127.0.0.1    $site"
            echo "::1          $site"
        done
        echo "$BLOCK_END_MARKER"
    } >> "$HOSTS_FILE"
    
    # Flush DNS cache
    systemd-resolve --flush-caches 2>/dev/null || true
    resolvectl flush-caches 2>/dev/null || true
    nscd -i hosts 2>/dev/null || true
}

activate_category() {
    local cat="$1"
    local sites=()

    case "$cat" in
        1|social)
            sites=("${SOCIAL_MEDIA_SITES[@]}" "${PORN_SITES[@]}")
            ;;
        2|full)
            sites=("${SOCIAL_MEDIA_SITES[@]}" "${PORN_SITES[@]}" "${YOUTUBE_SITES[@]}")
            ;;
        3|porn)
            sites=("${PORN_SITES[@]}")
            ;;
        *)
            echo -e "${RED}✗ Unknown category: $cat${RESET}"
            show_help
            exit 1
            ;;
    esac

    remove_block_entries
    apply_block_entries "${sites[@]}"
    echo "$cat" > "$STATE_FILE"
}

# ─── Timer daemon ──────────────────────────────────────────────────────────────

start_timer_daemon() {
    local end_time=$1
    # Write a systemd transient timer or background job
    # Using background subshell + disown for simplicity
    (
        while true; do
            now=$(date +%s)
            remaining=$((end_time - now))
            if [[ $remaining -le 0 ]]; then
                # Unblock
                remove_block_entries
                rm -f "$STATE_FILE" "$TIMER_FILE"
                # Flush DNS
                systemd-resolve --flush-caches 2>/dev/null || true
                resolvectl flush-caches 2>/dev/null || true
                # Log to syslog
                logger "FocusBlock: Timer expired. Sites unblocked."
                break
            fi
            sleep 10
        done
    ) &>/dev/null &
    disown
}

# ─── Commands ──────────────────────────────────────────────────────────────────

cmd_block() {
    require_root "block" "$@"
    ensure_state_dir

    local cat=""
    local duration=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --for|-t) duration="$2"; shift 2 ;;
            *) cat="$1"; shift ;;
        esac
    done

    if [[ -z "$cat" ]]; then
        echo -e "${RED}✗ Please specify a category.${RESET}"
        echo -e "  ${CYAN}focusblock block 1${RESET}   → Social media + porn"
        echo -e "  ${CYAN}focusblock block 2${RESET}   → All of above + YouTube"
        echo -e "  ${CYAN}focusblock block 3${RESET}   → Porn only"
        exit 1
    fi

    activate_category "$cat"

    local cat_name=""
    case "$cat" in
        1|social) cat_name="Category 1 (Social + Porn)" ;;
        2|full)   cat_name="Category 2 (Social + Porn + YouTube)" ;;
        3|porn)   cat_name="Category 3 (Porn only)" ;;
    esac

    if [[ -n "$duration" ]]; then
        local secs
        secs=$(parse_duration "$duration")
        if [[ $secs -le 0 ]]; then
            echo -e "${RED}✗ Invalid duration: $duration${RESET}"
            echo -e "  Examples: 30m, 1h, 2h30m, 90m"
            exit 1
        fi
        local end_time=$(( $(date +%s) + secs ))
        echo "$end_time" > "$TIMER_FILE"
        start_timer_daemon "$end_time"
        echo -e "${GREEN}✔ Blocked${RESET} ${BOLD}$cat_name${RESET}"
        echo -e "  ${YELLOW}⏱  Timer set for $(format_duration $secs)${RESET}"
        echo -e "  Sites will be unblocked automatically."
    else
        rm -f "$TIMER_FILE"
        echo -e "${GREEN}✔ Blocked${RESET} ${BOLD}$cat_name${RESET}"
        echo -e "  No timer set. Run ${CYAN}focusblock unblock${RESET} to remove."
    fi
}

cmd_unblock() {
    require_root "unblock"
    ensure_state_dir
    remove_block_entries
    rm -f "$STATE_FILE" "$TIMER_FILE"
    echo -e "${GREEN}✔ All sites unblocked.${RESET}"
}

cmd_switch() {
    require_root "switch" "$@"
    ensure_state_dir

    local cat="$1"
    local duration="${2}"

    if [[ -z "$cat" ]]; then
        echo -e "${RED}✗ Please specify a category to switch to.${RESET}"
        exit 1
    fi

    # Keep existing timer if no new duration given
    local existing_end
    existing_end=$(get_timer_end)

    activate_category "$cat"

    local cat_name=""
    case "$cat" in
        1|social) cat_name="Category 1 (Social + Porn)" ;;
        2|full)   cat_name="Category 2 (Social + Porn + YouTube)" ;;
        3|porn)   cat_name="Category 3 (Porn only)" ;;
    esac

    echo -e "${GREEN}✔ Switched to${RESET} ${BOLD}$cat_name${RESET}"

    # Check for --for flag
    if [[ "$2" == "--for" || "$2" == "-t" ]]; then
        local secs
        secs=$(parse_duration "$3")
        local end_time=$(( $(date +%s) + secs ))
        echo "$end_time" > "$TIMER_FILE"
        start_timer_daemon "$end_time"
        echo -e "  ${YELLOW}⏱  New timer set for $(format_duration $secs)${RESET}"
    elif [[ $existing_end -gt 0 ]]; then
        local now=$(date +%s)
        local remaining=$((existing_end - now))
        if [[ $remaining -gt 0 ]]; then
            echo -e "  ${YELLOW}⏱  Existing timer: $(format_duration $remaining) remaining${RESET}"
        fi
    fi
}

cmd_status() {
    ensure_state_dir
    local cat
    cat=$(get_category)
    local end_time
    end_time=$(get_timer_end)
    local now
    now=$(date +%s)

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}       FocusBlock Status${RESET}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""

    if [[ "$cat" == "none" || -z "$cat" ]]; then
        echo -e "  Status:   ${GREEN}● INACTIVE${RESET} — No sites blocked"
    else
        local cat_name=""
        case "$cat" in
            1|social) cat_name="Category 1 — Social Media + Porn" ;;
            2|full)   cat_name="Category 2 — Social + Porn + YouTube" ;;
            3|porn)   cat_name="Category 3 — Porn Only" ;;
        esac
        echo -e "  Status:   ${RED}● ACTIVE${RESET}"
        echo -e "  Blocking: ${BOLD}$cat_name${RESET}"

        if [[ $end_time -gt 0 ]]; then
            local remaining=$((end_time - now))
            if [[ $remaining -gt 0 ]]; then
                echo -e "  Timer:    ${YELLOW}⏱  $(format_duration $remaining) remaining${RESET}"
                echo -e "  Ends at:  $(date -d @$end_time '+%H:%M:%S on %b %d')"
            else
                echo -e "  Timer:    ${RED}Expired (unblocking pending)${RESET}"
            fi
        else
            echo -e "  Timer:    No timer set (manual unblock required)"
        fi
    fi

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

cmd_timer() {
    ensure_state_dir
    local end_time
    end_time=$(get_timer_end)
    local now
    now=$(date +%s)

    if [[ $end_time -le 0 ]]; then
        echo -e "${YELLOW}No timer is active.${RESET}"
        exit 0
    fi

    local remaining=$((end_time - now))
    if [[ $remaining -le 0 ]]; then
        echo -e "${YELLOW}Timer has expired.${RESET}"
    else
        echo -e "${CYAN}⏱  Time remaining: ${BOLD}$(format_duration $remaining)${RESET}"
        echo -e "   Unblocks at: $(date -d @$end_time '+%H:%M:%S on %b %d')"
    fi
}

show_help() {
    echo ""
    echo -e "${BOLD}FocusBlock${RESET} — URL Blocking System"
    echo ""
    echo -e "${BOLD}CATEGORIES:${RESET}"
    echo -e "  ${CYAN}1${RESET}  Social Media + Porn"
    echo -e "     Facebook, Instagram, Threads, Twitter/X, Browser Games, Porn sites"
    echo -e "  ${CYAN}2${RESET}  Everything (Cat 1 + YouTube)"
    echo -e "     All of Category 1 + YouTube"
    echo -e "  ${CYAN}3${RESET}  Porn Only"
    echo ""
    echo -e "${BOLD}COMMANDS:${RESET}"
    echo -e "  ${CYAN}focusblock block <1|2|3>${RESET}"
    echo -e "    Block category indefinitely"
    echo ""
    echo -e "  ${CYAN}focusblock block <1|2|3> --for <duration>${RESET}"
    echo -e "    Block for a set time (e.g. 30m, 1h, 2h30m)"
    echo ""
    echo -e "  ${CYAN}focusblock switch <1|2|3>${RESET}"
    echo -e "    Switch to a different category (keeps timer)"
    echo ""
    echo -e "  ${CYAN}focusblock unblock${RESET}"
    echo -e "    Remove all blocks"
    echo ""
    echo -e "  ${CYAN}focusblock status${RESET}"
    echo -e "    Show current blocking status and timer"
    echo ""
    echo -e "  ${CYAN}focusblock timer${RESET}"
    echo -e "    Show time remaining on active timer"
    echo ""
    echo -e "${BOLD}EXAMPLES:${RESET}"
    echo -e "  sudo focusblock block 1             # Block social media + porn"
    echo -e "  sudo focusblock block 2 --for 2h    # Block everything for 2 hours"
    echo -e "  sudo focusblock block 3 --for 30m   # Block porn for 30 minutes"
    echo -e "  sudo focusblock switch 1            # Switch to category 1"
    echo -e "  focusblock timer                    # Check time remaining"
    echo -e "  focusblock status                   # Full status"
    echo ""
}

# ─── Main ──────────────────────────────────────────────────────────────────────

case "${1:-}" in
    block)   shift; cmd_block "$@" ;;
    unblock) cmd_unblock ;;
    switch)  shift; cmd_switch "$@" ;;
    status)  cmd_status ;;
    timer)   cmd_timer ;;
    help|--help|-h|"") show_help ;;
    *)
        echo -e "${RED}✗ Unknown command: $1${RESET}"
        show_help
        exit 1
        ;;
esac
