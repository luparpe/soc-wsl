#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-status}"
LOGTAG="WSL-ANALYSIS"

require_root() {
  [[ "$EUID" -eq 0 ]] || { echo "Run with sudo."; exit 1; }
}

start() {
  require_root

  nft delete table inet wsl_analysis 2>/dev/null || true

  nft -f - <<'EOF'
table inet wsl_analysis {
  chain output {
    type filter hook output priority 0; policy drop;

    oifname "lo" accept

    udp dport 53 log prefix "WSL-DNS-DENY " flags all counter reject
    tcp dport 53 log prefix "WSL-DNS-DENY " flags all counter reject

    log prefix "WSL-OUT-DENY " flags all counter reject
  }

  chain input {
    type filter hook input priority 0; policy drop;

    iifname "lo" accept
    ct state established,related accept

    log prefix "WSL-IN-DENY " flags all counter drop
  }
}
EOF

  echo "WSL network isolation ENABLED via nftables."
}

stop() {
  require_root
  nft delete table inet wsl_analysis 2>/dev/null || true
  echo "WSL network isolation DISABLED."
}

status() {
  sudo nft list table inet wsl_analysis 2>/dev/null || echo "No WSL analysis nftables table active."
}

logs() {
  if command -v journalctl >/dev/null 2>&1; then
    sudo journalctl -k --no-pager | grep -E "WSL-(DNS|OUT|IN)-DENY" || true
  else
    sudo dmesg | grep -E "WSL-(DNS|OUT|IN)-DENY" || true
  fi
}

case "$MODE" in
  start|on|isolate) start ;;
  stop|off) stop ;;
  status) status ;;
  logs) logs ;;
  *)
    echo "Usage: sudo $0 {start|stop|status|logs}"
    exit 1
    ;;
esac
