#!/bin/bash
# FocusBlock Installer

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}✗ Please run installer as root: sudo bash install.sh${RESET}"
    exit 1
fi

echo ""
echo -e "${BOLD}Installing FocusBlock...${RESET}"

# Create state directory
mkdir -p /var/lib/focusblock
chmod 755 /var/lib/focusblock

# Install main script
cp focusblock.sh /usr/local/bin/focusblock
chmod +x /usr/local/bin/focusblock

# Backup original hosts file (once)
if [[ ! -f /var/lib/focusblock/hosts.backup ]]; then
    cp /etc/hosts /var/lib/focusblock/hosts.backup
    echo -e "  ${GREEN}✔${RESET} Backed up /etc/hosts"
fi

echo -e "  ${GREEN}✔${RESET} Installed to /usr/local/bin/focusblock"
echo ""
echo -e "${GREEN}${BOLD}Installation complete!${RESET}"
echo ""
echo -e "Try: ${CYAN}focusblock help${RESET}"
echo ""
