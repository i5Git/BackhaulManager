#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${BACKHAUL_MANAGER_REPO:-i5Git/BackhaulManager}"
BRANCH="${BACKHAUL_MANAGER_BRANCH:-master}"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
SOURCE_URL="${RAW_BASE}/backhaul-manager.sh"
TARGET="/usr/local/bin/backhaul-manager"
INSTALL_DIR="/etc/backhaul"

red() { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
blue() { printf '\033[0;36m%s\033[0m\n' "$*"; }

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    red "This installer must be run as root."
    echo
    echo "Use:"
    echo "  sudo bash <(curl -fsSL ${RAW_BASE}/install.sh)"
    echo
    exit 1
  fi
}

install_deps() {
  blue "Installing required packages..."

  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y curl wget tar ca-certificates openssl iproute2
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl wget tar ca-certificates openssl iproute
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl wget tar ca-certificates openssl iproute
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache curl wget tar ca-certificates openssl iproute2
  else
    yellow "Could not detect package manager. Make sure curl/wget/tar/openssl are installed."
  fi
}

download_manager() {
  blue "Downloading BackhaulManager from ${REPO}:${BRANCH}..."

  mkdir -p "$(dirname "$TARGET")" "$INSTALL_DIR"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$SOURCE_URL" -o "$TARGET"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$TARGET" "$SOURCE_URL"
  else
    red "curl or wget is required but not installed."
    exit 1
  fi

  chmod +x "$TARGET"
}

verify_install() {
  if [[ ! -x "$TARGET" ]]; then
    red "Install failed: $TARGET was not created or is not executable."
    exit 1
  fi

  if ! command -v systemctl >/dev/null 2>&1; then
    yellow "Warning: systemctl was not found. BackhaulManager needs a systemd VPS."
  fi

  green "BackhaulManager installed successfully."
  echo
  echo "Run it anytime with:"
  echo "  sudo backhaul-manager"
  echo
}

main() {
  need_root
  install_deps
  download_manager
  verify_install

  if [[ "${BACKHAUL_MANAGER_NO_RUN:-0}" != "1" ]]; then
    blue "Starting BackhaulManager..."
    exec "$TARGET"
  fi
}

main "$@"
