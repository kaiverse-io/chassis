#!/usr/bin/env bash
# post-create.sh — runs once after the devcontainer is created.
# Installs the full toolchain defined in the chassis spec (Layer 1).
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

# ── uv (Python package/venv manager) ─────────────────────────────────────────
if ! command -v uv >/dev/null 2>&1; then
  echo "→ Installing uv …"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

# ── just (task runner) ────────────────────────────────────────────────────────
if ! command -v just >/dev/null 2>&1; then
  echo "→ Installing just …"
  mkdir -p "$HOME/.local/bin"
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
    | bash -s -- --to "$HOME/.local/bin"
fi

# ── pre-commit ────────────────────────────────────────────────────────────────
if ! command -v pre-commit >/dev/null 2>&1; then
  echo "→ Installing pre-commit …"
  pip install pre-commit --quiet --user
fi

# ── gitleaks (secret scanning) ────────────────────────────────────────────────
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "→ Installing gitleaks …"
  GITLEAKS_VERSION="8.21.2"
  ARCH=$(uname -m)
  case "$ARCH" in arm64|aarch64) GA="arm64" ;; *) GA="x64" ;; esac
  TMP=$(mktemp -d)
  curl -LsSf \
    "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${GA}.tar.gz" \
    | tar -xz -C "$TMP" gitleaks
  mv "$TMP/gitleaks" "$HOME/.local/bin/gitleaks"
  rm -rf "$TMP"
fi

# ── opengrep (semantic lint / self-weakening rules) ───────────────────────────
if ! command -v opengrep >/dev/null 2>&1; then
  echo "→ Installing opengrep …"
  pip install opengrep --quiet --user 2>/dev/null \
    || echo "[warn] opengrep pip install failed — install manually from https://github.com/opengrep/opengrep"
fi

# ── Project setup ─────────────────────────────────────────────────────────────
if [ -f pyproject.toml ]; then
  echo "→ uv sync …"
  uv sync
fi

if [ -f .pre-commit-config.yaml ]; then
  echo "→ pre-commit install …"
  pre-commit install --install-hooks 2>/dev/null || pre-commit install
fi

echo ""
echo "✓ Devcontainer ready. Run 'just ci' to verify."
