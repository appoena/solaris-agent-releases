#!/usr/bin/env bash
set -euo pipefail

# Solaris install.sh script for Appoena Solaris Agent
# This script prepares the filesystem, deploys the agent, and installs the SMF manifest.
# It expects to be run on a Solaris host with sufficient privileges (typically root).
# IMPORTANT: This installer does NOT build or compile the code. It expects all deployment
# artifacts (agent.jar, solaris_agent.xml, conf.example.yaml) to be in the same
# directory as this script.

# Configuration (can be overridden with environment variables)
BASE_DIR="/etc/appoena"
AGENT_SUBDIR="solaris"
AGENT_DIR="$BASE_DIR/$AGENT_SUBDIR"


# Default to a colocated manifest next to this script
MANIFEST_NAME="solaris_agent.xml"
MANIFEST_DIR="/var/svc/manifest/appoena"
SERVICE_FMRI="/appoena/solaris_agent"
AGENT_JAR="agent.jar"

log() { echo "[install] $*"; }
warn() { echo "[install][WARN] $*" >&2; }
err() { echo "[install][ERROR] $*" >&2; }

require_root() {
  if [ "$(id -u)" != "0" ]; then
    warn "It's recommended to run this script as root to install system service and write to $BASE_DIR."
  fi
}

prepare_fs() {
  log "Preparing filesystem..."
  mkdir -p "$AGENT_DIR"
  mkdir -p "$MANIFEST_DIR"
  local root
  root=$(cd -- "$(dirname -- "$0")" && pwd)
  # Install example config for reference if present
  if [ -f "$root/conf.example.yaml" ]; then
    # Always copy example
    cp -f "$root/conf.example.yaml" "$AGENT_DIR/conf.example.yaml"
    log "Installed example config to $AGENT_DIR/conf.example.yaml"
  fi
}

install_agent_binary() {
  root=$(cd -- "$(dirname -- "$0")" && pwd)
  if [ ! -f "$root/$AGENT_JAR" ]; then
    err "Could not find agent binary. Expected a 'agent.jar' file next to this script (e.g., agent.jar)."
    exit 1
  fi

  log "Using binary: $root/$AGENT_JAR"
  cp -f "$root/$AGENT_JAR" "$AGENT_DIR"

  chmod 0755 "$AGENT_DIR/$AGENT_JAR" || true
  log "Deployed agent to $AGENT_DIR/$AGENT_JAR"
}

install_manifest() {
  local root
  root=$(cd -- "$(dirname -- "$0")" && pwd)
  local manifest_path="$root/$MANIFEST_NAME"

  if [ ! -f "$manifest_path" ]; then
    err "SMF manifest not found next to installer (expected $root/$MANIFEST_NAME)."
    exit 1
  fi

  cp -f "$root/$MANIFEST_NAME" "$MANIFEST_DIR/$MANIFEST_NAME"

 if [ ! -f "$MANIFEST_DIR/$MANIFEST_NAME" ]; then
    err "SMF manifest not found on $MANIFEST_DIR/$MANIFEST_NAME."
    exit 1
  fi

  log "Installed SMF manifest to $MANIFEST_DIR/$MANIFEST_NAME"

 if command -v svcadm >/dev/null 2>&1; then
    log "Restarting manifest-import to (re)import manifests from standard locations..."
    svcadm restart svc:/system/manifest-import || warn "Failed to restart manifest-import; you may need to run as root."
    # Wait for manifest-import to complete (up to ~30s)
    if command -v svcs >/dev/null 2>&1; then
      for i in $(seq 1 30); do
        state=$(svcs -H -o state svc:/system/manifest-import:default 2>/dev/null || true)
        [ "$state" = "online" ] && break
        sleep 1
      done
    fi
  else
    warn "svcadm not available on PATH; cannot restart manifest-import."
  fi

  if command -v svccfg >/dev/null 2>&1; then
    log "Validating SMF manifest..."
    if ! svccfg validate "$MANIFEST_DIR/$MANIFEST_NAME"; then
      err "SMF manifest validation failed. Check $MANIFEST_DIR/$MANIFEST_NAME"
      exit 2
    fi
  fi

  log "Solaris agent installed!"
  log "Service FMRI is $SERVICE_FMRI"
  log "Run with svcadm svc:/$SERVICE_FMRI:default or bash run.sh"
}

main() {
  require_root
  prepare_fs
  install_agent_binary
  install_manifest
  log "Installation complete."
  cat <<EOF

Next steps:
- Ensure your configuration is correct at $BASE_DIR/conf.yaml
- Enable and Start the service with  svcadm enable -s svc:/$SERVICE_FMRI:default
- Check service status with: svcs $SERVICE_FMRI
- Run agent manually for debugging:
    java -jar $AGENT_DIR/agent
EOF
}

main "$@"
