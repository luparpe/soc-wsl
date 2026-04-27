#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-status}"

CHAIN_OUT="WSL_ANALYSIS_OUT"
CHAIN_IN="WSL_ANALYSIS_IN"
LOG_PREFIX_DNS="WSL-DNS-DENY "
LOG_PREFIX_OUT="WSL-OUT-DENY "
LOG_PREFIX_IN="WSL-IN-DENY "

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run with sudo."
    exit 1
  fi
}

setup_chains() {
  iptables -N "$CHAIN_OUT" 2>/dev/null || true
  iptables -N "$CHAIN_IN" 2>/dev/null || true

  iptables -C OUTPUT -j "$CHAIN_OUT" 2>/dev/null || iptables -I OUTPUT 1 -j "$CHAIN_OUT"
  iptables -C INPUT  -j "$CHAIN_IN"  2>/dev/null || iptables -I INPUT 1 -j "$CHAIN_IN"
}

flush_chains() {
  iptables -F "$CHAIN_OUT" 2>/dev/null || true
  iptables -F "$CHAIN_IN" 2>/dev/null || true
}

start_isolation() {
  require_root
  setup_chains
  flush_chains

  # Allow loopback so local tools do not break.
  iptables -A "$CHAIN_OUT" -o lo -j ACCEPT
  iptables -A "$CHAIN_IN"  -i lo -j ACCEPT

  # Allow already-established inbound traffic only.
  iptables -A "$CHAIN_IN" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  # Log DNS attempts separately.
  iptables -A "$CHAIN_OUT" -p udp --dport 53 -m limit --limit 12/min --limit-burst 20 -j LOG --log-prefix "$LOG_PREFIX_DNS" --log-level 4
  iptables -A "$CHAIN_OUT" -p tcp --dport 53 -m limit --limit 12/min --limit-burst 20 -j LOG --log-prefix "$LOG_PREFIX_DNS" --log-level 4

  # Block DNS.
  iptables -A "$CHAIN_OUT" -p udp --dport 53 -j REJECT
  iptables -A "$CHAIN_OUT" -p tcp --dport 53 -j REJECT

  # Log all other outbound attempts.
  iptables -A "$CHAIN_OUT" -m limit --limit 12/min --limit-burst 30 -j LOG --log-prefix "$LOG_PREFIX_OUT" --log-level 4

  # Block all other outbound traffic.
  iptables -A "$CHAIN_OUT" -j REJECT

  # Log unexpected inbound attempts.
  iptables -A "$CHAIN_IN" -m limit --limit 12/min --limit-burst 30 -j LOG --log-prefix "$LOG_PREFIX_IN" --log-level 4
  iptables -A "$CHAIN_IN" -j DROP

  echo "WSL analysis isolation ENABLED."
  echo "Outbound network is blocked. DNS attempts are logged separately."
}

stop_isolation() {
  require_root

  iptables -D OUTPUT -j "$CHAIN_OUT" 2>/dev/null || true
  iptables -D INPUT  -j "$CHAIN_IN"  2>/dev/null || true

  iptables -F "$CHAIN_OUT" 2>/dev/null || true
  iptables -F "$CHAIN_IN" 2>/dev/null || true

  iptables -X "$CHAIN_OUT" 2>/dev/null || true
  iptables -X "$CHAIN_IN" 2>/dev/null || true

  echo "WSL analysis isolation DISABLED."
}

show_status() {
  echo "=== OUTPUT chain ==="
  iptables -L "$CHAIN_OUT" -n -v 2>/dev/null || echo "No analysis OUTPUT chain."

  echo
  echo "=== INPUT chain ==="
  iptables -L "$CHAIN_IN" -n -v 2>/dev/null || echo "No analysis INPUT chain."
}

show_logs() {
  echo "Recent WSL network-deny logs:"
  echo

  if command -v journalctl >/dev/null 2>&1; then
    journalctl -k --no-pager | grep -E "WSL-(DNS|OUT|IN)-DENY" || true
  else
    dmesg | grep -E "WSL-(DNS|OUT|IN)-DENY" || true
  fi
}

case "$MODE" in
  start|on|isolate)
    start_isolation
    ;;
  stop|off)
    stop_isolation
    ;;
  status)
    show_status
    ;;
  logs)
    show_logs
    ;;
  *)
    echo "Usage: sudo $0 {start|stop|status|logs}"
    exit 1
    ;;
esac
