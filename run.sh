#!/usr/bin/env bash
set -euo pipefail

SERVICE_FMRI="/appoena/solaris_agent"

if command -v svcadm >/dev/null 2>&1; then
    # Enable specific instance FMRI
    SERVICE_INSTANCE="svc:/$SERVICE_FMRI:default"
    if svcs "$SERVICE_INSTANCE" >/dev/null 2>&1; then

      log "Enabling service instance $SERVICE_INSTANCE ..."
      svcadm enable -s "$SERVICE_INSTANCE" || warn "Failed to enable service; you may need to run as root."

      if command -v svcs >/dev/null 2>&1; then
        svcs -xv "$SERVICE_INSTANCE" || true
      fi
    else
      warn "Service instance $SERVICE_INSTANCE not found after import. Check manifest location and content."
    fi
  else
    warn "svcadm not available; skipping service enable."
  fi