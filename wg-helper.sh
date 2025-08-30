#!/usr/bin/env bash
# wg-helper.sh - WireGuard VPN helper for Debian/Ubuntu inside Android "Terminal" App (com.android.virtualization.terminal)
# Author: s4mba
# Version: 1.1
# Project: https://github.com/s4mba-dev/wireguard-virt-terminal

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
WG_IF="wg0"
WG_CONF="/etc/wireguard/${WG_IF}.conf"

# Use wireguard-go if kernel module missing
export WG_QUICK_USERSPACE_IMPLEMENTATION="${WG_QUICK_USERSPACE_IMPLEMENTATION:-wireguard-go}"
export WG_QUICK_USERSPACE_IMPLEMENTATION_PATH="${WG_QUICK_USERSPACE_IMPLEMENTATION_PATH:-$(command -v wireguard-go || true)}"

info() { printf "[INFO] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*" >&2; }
err()  { printf "[ERROR] %s\n" "$*" >&2; exit 1; }

ensure_conf_dir() {
  if ! sudo test -d /etc/wireguard; then
    info "Creating /etc/wireguard ..."
    sudo install -d -m 700 -o root -g root /etc/wireguard
  fi
}

conf_exists() {
  sudo test -f "$WG_CONF"
}

cmd_install() {
  info "Installing dependencies..."
  sudo apt update -y >/dev/null
  sudo apt install -y wireguard-tools wireguard-go resolvconf curl >/dev/null
  info "Done."
  if sudo modprobe wireguard 2>/dev/null; then
    info "Kernel module 'wireguard' loaded."
  else
    warn "Kernel module not available. Using userspace wireguard-go."
    [ -n "${WG_QUICK_USERSPACE_IMPLEMENTATION_PATH:-}" ] || err "wireguard-go not found."
  fi
}

cmd_import() {
  local src="${1:-}"
  [ -n "$src" ] || err "Usage: ${SCRIPT_NAME} import /path/to/file.conf"
  [ -f "$src" ] || err "File not found: $src"

  ensure_conf_dir

  info "Validating config format..."
  grep -q "^\[Interface\]" "$src" || err "Missing [Interface] section."
  grep -q "^\[Peer\]" "$src" || err "Missing [Peer] section."

  info "Installing config to ${WG_CONF} ..."
  sudo install -m 600 -o root -g root "$src" "$WG_CONF"

  if ! systemctl is-enabled resolvconf >/dev/null 2>&1; then
    if systemctl list-unit-files | grep -q '^resolvconf\.service'; then
      sudo systemctl enable --now resolvconf >/dev/null 2>&1 || true
    fi
  fi

  info "Config imported."
}

cmd_up() {
  conf_exists || err "No config found at ${WG_CONF}. Use '${SCRIPT_NAME} import <file>' first."
  info "Bringing up ${WG_IF} ..."
  sudo WG_QUICK_USERSPACE_IMPLEMENTATION="${WG_QUICK_USERSPACE_IMPLEMENTATION}"        WG_QUICK_USERSPACE_IMPLEMENTATION_PATH="${WG_QUICK_USERSPACE_IMPLEMENTATION_PATH:-}"        wg-quick up "${WG_IF}"
  info "${WG_IF} is up."
  cmd_status
}

cmd_down() {
  info "Bringing down ${WG_IF} ..."
  sudo wg-quick down "${WG_IF}" || warn "wg-quick down failed."
  info "${WG_IF} is down."
}

cmd_status() {
  info "WireGuard status:"
  if sudo wg show "${WG_IF}" >/dev/null 2>&1; then
    sudo wg show "${WG_IF}"
    info "IP address on ${WG_IF}:"
    ip addr show "${WG_IF}" | sed -n 's/ *inet6\{0,1\} /inet /p' || true
  else
    warn "Interface ${WG_IF} is not active."
  fi
  info "Public IP (via ipinfo.io):"
  curl -s https://ipinfo.io
}

cmd_enable() {
  info "Enabling autostart for ${WG_IF} ..."
  sudo systemctl enable wg-quick@"${WG_IF}"
  info "Autostart enabled."
}

cmd_logs() {
  info "Logs for wg-quick@${WG_IF}:"
  if command -v journalctl >/dev/null 2>&1; then
    sudo journalctl -u wg-quick@"${WG_IF}" --no-pager -n 200 || true
  else
    warn "journalctl not found."
  fi
}

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} <command> [args]

Commands:
  install                Install dependencies
  import <file.conf>     Import WireGuard config to /etc/wireguard/wg0.conf
  up                     Start the VPN tunnel
  down                   Stop the VPN tunnel
  status                 Show tunnel and public IP status
  enable                 Enable autostart on boot
  logs                   Show recent logs for wg-quick@wg0
EOF
}

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    install) cmd_install "$@";;
    import)  cmd_import "$@";;
    up)      cmd_up "$@";;
    down)    cmd_down "$@";;
    status)  cmd_status "$@";;
    enable)  cmd_enable "$@";;
    logs)    cmd_logs "$@";;
    ""|-h|--help|help) usage;;
    *) err "Unknown command: $cmd";;
  esac
}

main "$@"
