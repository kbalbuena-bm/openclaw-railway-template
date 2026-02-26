#!/bin/bash
set -e
# Ensure /data is owned by openclaw user and has restricted permissions
chown openclaw:openclaw /data 2>/dev/null || true
chmod 700 /data 2>/dev/null || true
# Persist Homebrew to Railway volume so it survives container rebuilds
BREW_VOLUME="/data/.linuxbrew"
BREW_SYSTEM="/home/openclaw/.linuxbrew"
if [ -d "$BREW_VOLUME" ]; then
  # Volume already has Homebrew — symlink back to expected location
  if [ ! -L "$BREW_SYSTEM" ]; then
    rm -rf "$BREW_SYSTEM"
    ln -sf "$BREW_VOLUME" "$BREW_SYSTEM"
    echo "[entrypoint] Restored Homebrew from volume symlink"
  fi
else
  # First boot — move Homebrew install to volume for persistence
  if [ -d "$BREW_SYSTEM" ] && [ ! -L "$BREW_SYSTEM" ]; then
    mv "$BREW_SYSTEM" "$BREW_VOLUME"
    ln -sf "$BREW_VOLUME" "$BREW_SYSTEM"
    echo "[entrypoint] Persisted Homebrew to volume on first boot"
  fi
fi

# ===== NEW: Set up GitHub + Railway credentials =====
# This runs every time the container starts, so your tokens are always ready
if [ -n "${GITHUB_TOKEN:-}" ]; then
  gosu openclaw git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
  gosu openclaw git config --global user.email "${GIT_USER_EMAIL:-openclaw@users.noreply.github.com}"
  gosu openclaw git config --global user.name "${GIT_USER_NAME:-OpenClaw}"
  echo "[entrypoint] GitHub credentials configured"
fi
if [ -n "${RAILWAY_TOKEN:-}" ]; then
  echo "[entrypoint] Railway token detected — CLI ready"
fi
# ===== END NEW =====

exec gosu openclaw node src/server.js
