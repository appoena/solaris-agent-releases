# Appoena Solaris Agent — Installation, Manual Configuration, and Run Guide

This document explains how to install and run the Appoena Solaris Agent on a Solaris host using the artifacts in the `deploy/` folder. It also provides a step-by-step guide to manually configure the agent without running the installer script.

The installer does not build or compile code. It expects that the deployment artifacts are already present alongside the installer script.

## Contents
- Prerequisites
- Files in `deploy/`
- Quick install (recommended)
- Manual configuration (without installer)
- Configuration file reference
- Running the agent (service and manual)
- Service management (SMF)
- Logs and diagnostics
- Upgrade, reinstall, uninstall
- Building locally (optional)

---

## Prerequisites
- Solaris with SMF (Service Management Facility)
- Java Runtime Environment (JRE) 11+ available on PATH
- Root (or sufficient privileges) to install service and write to system directories

## Files in `deploy/`
- `install.sh` — installer script for Solaris. Prepares directories, deploys the agent JAR, and installs/imports the SMF manifest.
- `agent.jar` — agent binary JAR to be installed.
- `solaris_agent.xml` — SMF service manifest used by the installer.
- `conf.example.yaml` — example configuration (for reference).

Default paths used by the installer (can be overridden via environment variables shown in parentheses):
- Base directory: `/etc/appoena` (`BASE_DIR`)
- Agent subdirectory: `solaris` (`AGENT_SUBDIR`) → full agent dir: `/etc/appoena/solaris`
- Installed agent binary: `/etc/appoena/solaris/agent.jar`
- SMF manifest destination: `/var/svc/manifest/appoena/solaris_agent.xml` (`MANIFEST_DIR`)
- SMF service FMRI: `/appoena/solaris_agent` (instance is `svc:/appoena/solaris_agent:default`)

## Quick install (recommended)
1) Copy the entire `deploy/` folder to your Solaris host.
   - Ensure `install.sh`, `agent.jar`, `solaris_agent.xml`, and `conf.example.yaml` are together in the same directory.

2) (Optional) Adjust environment variables if you want non-default paths:
   - Example: `export BASE_DIR=/opt/appoena` or `export MANIFEST_DIR=/var/svc/manifest/appoena`

3) Run the installer as root (recommended):
   - `chmod +x ./install.sh`
   - `sudo ./install.sh`

What the installer does:
- Creates required folders under `/etc/appoena/solaris` (by default)
- Copies `agent.jar` → `/etc/appoena/solaris/agent.jar`
- Installs `conf.example.yaml` to `/etc/appoena/solaris/conf.example.yaml` (if present next to the installer)
- Copies SMF manifest to `/var/svc/manifest/appoena/solaris_agent.xml`, restarts manifest-import, and validates the manifest
- Prints the FMRI and hints for enabling the service and running manually

If `svccfg`/`svcadm` aren’t available on PATH, the installer will skip service steps and print warnings.

## Manual configuration (without installer)
If you prefer not to run `install.sh`, follow these steps to configure the agent manually. Commands below assume root privileges.

1) Create directories:
- `mkdir -p /etc/appoena/solaris`
- `mkdir -p /var/svc/manifest/appoena`

2) Deploy files:
- Copy the agent JAR into place:
  - `cp ./agent.jar /etc/appoena/solaris/agent.jar`
- (Optional) Copy the example config for reference:
  - `cp ./conf.example.yaml /etc/appoena/solaris/conf.example.yaml`

3) Create your runtime configuration file:
- The agent reads: `/etc/appoena/solaris/conf.yaml`
- Start from the example and adjust values:
  - `cp /etc/appoena/solaris/conf.example.yaml /etc/appoena/solaris/conf.yaml`
  - Edit `/etc/appoena/solaris/conf.yaml`
  - Configure api-key and app-key

4) Install the SMF manifest:
- `cp ./solaris_agent.xml /var/svc/manifest/appoena/solaris_agent.xml`
- Import the manifest: `svcadm restart svc:/system/manifest-import`

5) Enable and manage the service:
- Service instance: `svc:/appoena/solaris_agent:default`
- Enable (start): `svcadm enable -s svc:/appoena/solaris_agent:default`
- Check status: `svcs svc:/appoena/solaris_agent:default`
- Troubleshoot: `svcs -xv svc:/appoena/solaris_agent:default`

6) Run manually (for debugging):
- `java -jar /etc/appoena/solaris/agent.jar`

## Configuration file reference
The agent reads YAML from `/etc/appoena/solaris/conf.yaml`.

A quick overview (see `deploy/conf.example.yaml` for full details):
- `log_level`: debug | info | warn | error | fatal (default: info)
- `output_method`: api | dogstatsd(unavailable) | logger (default: api)
- `agent_host`: host for DogStatsD (when `output_method: dogstatsd`)
- `agent_port`: port for DogStatsD (when `output_method: dogstatsd`)(default: 8125)
- `api_key`: Datadog API key (for `output_method: api`)
- `app_key`: Datadog APP key (optional)
- `site`: Datadog site (e.g., `datadoghq.com`, `datadoghq.eu`)
- `metric_prefix`: optional metric prefix
- `tags`: list of global tags (e.g., `env:prod`)
- `schedules`: collection intervals per collector in seconds (e.g., `cpu: 10`, `memory: 10`, `disk: 30`, `network: 30`, `uptime: 60`)

### Disabling a Collector

To disable a collector from being executed, set the collector schedule to 0 or a nagative value!

## Running the agent
- As a service (via SMF): see Service management below.
- Manually (for debugging):
  - `java -jar /etc/appoena/solaris/agent.jar`

## Service management (SMF)
Service FMRI (base): `/appoena/solaris_agent`
- Instance: `svc:/appoena/solaris_agent:default`

Useful commands:
- Check status: `svcs svc:/appoena/solaris_agent:default`
- Show details and faults: `svcs -xv svc:/appoena/solaris_agent:default`
- Enable (start): `svcadm enable -s svc:/appoena/solaris_agent:default`
- Disable (stop): `svcadm disable -s svc:/appoena/solaris_agent:default`
- Restart: `svcadm restart svc:/appoena/solaris_agent:default`
- Refresh: `svcadm refresh svc:/appoena/solaris_agent:default`

If you customize manifest or paths, validate and import:
- Validate: `svccfg validate /var/svc/manifest/appoena/solaris_agent.xml`
- Import: `svccfg import /var/svc/manifest/appoena/solaris_agent.xml`

## Logs and diagnostics
Under SMF, service output is typically available at:
- `/var/svc/log/appoena-solaris_agent:default.log` (path format may vary by platform/version)

Additionally, use:
- `svcs -xv svc:/appoena/solaris_agent:default` for diagnostic information
- Run manually (`java -jar ...`) during troubleshooting to see logs directly in the terminal

## Upgrade / Reinstall
- To upgrade the agent, replace `agent.jar` in the `deploy/` folder.
- Your existing `/etc/appoena/solaris/conf.yaml` is preserved if present.

## Uninstall
1) Stop and disable the service:
   - `svcadm disable -s svc:/appoena/solaris_agent:default`
2) Remove manifest (optional):
   - `svccfg delete -f svc:/appoena/solaris_agent:default`
   - Remove file: `/var/svc/manifest/appoena/solaris_agent.xml`
3) Remove agent files and config (if desired):
   - `/etc/appoena/solaris/`
   - `/etc/appoena/solaris/conf.yaml` and `/etc/appoena/solaris/conf.example.yaml`

Use caution: removing config may affect future upgrades.
