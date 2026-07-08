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

# ── codeburn (AI usage cost/burn cockpit — bucket C) ──────────────────────────
# Local-first: reads Claude Code's own session JSONL, no OTEL required.
# User-authorized auto-install (2026-06-30) — see chassis CHANGELOG.
if ! command -v codeburn >/dev/null 2>&1; then
  echo "→ Installing codeburn …"
  npm install -g codeburn --silent 2>/dev/null \
    || echo "[warn] codeburn install failed (needs npm) — install manually: npm install -g codeburn"
fi

# ── abtop (live session monitor — bucket C) ───────────────────────────────────
# User-authorized auto-install (2026-06-30) — see chassis CHANGELOG.
if ! command -v abtop >/dev/null 2>&1; then
  echo "→ Installing abtop …"
  curl --proto '=https' --tlsv1.2 -LsSf \
    https://github.com/graykode/abtop/releases/latest/download/abtop-installer.sh \
    2>/dev/null | sh 2>/dev/null \
    || echo "[warn] abtop install failed — install manually: cargo install abtop"
fi

# ── AI Engineer Coach (VS Code dashboard — anti-patterns, practice score) ─────
# https://github.com/microsoft/ai-engineering-coach (3.1k★, MIT). No marketplace build —
# build from source. Harness support documents GitHub Copilot; Claude Code session-log
# support is unconfirmed — verify after install. User-authorized unattended build
# (2026-06-30) despite running this repo's own npm lifecycle/build scripts.
if command -v code >/dev/null 2>&1 \
   && ! code --list-extensions 2>/dev/null | grep -qi "ai-engineer-coach"; then
  echo "→ Building AI Engineer Coach (clone + npm ci + package — this takes a minute) …"
  AEC_DIR="$HOME/.local/share/ai-engineering-coach"
  if [ ! -d "$AEC_DIR" ]; then
    git clone --depth 1 https://github.com/microsoft/ai-engineering-coach.git "$AEC_DIR" 2>/dev/null
  fi
  if [ -d "$AEC_DIR" ]; then
    (
      cd "$AEC_DIR"
      npm ci --silent && npm run package --silent
      VSIX=$(find . -maxdepth 1 -name "*.vsix" | head -n1)
      if [ -n "$VSIX" ]; then
        code --install-extension "$VSIX"
        echo "✓ AI Engineer Coach installed — open via Cmd/Ctrl+Shift+P → 'AI Engineer Coach: Open Dashboard'"
      else
        echo "[warn] AI Engineer Coach build produced no .vsix — install manually, see https://github.com/microsoft/ai-engineering-coach"
      fi
    ) || echo "[warn] AI Engineer Coach build failed — install manually, see https://github.com/microsoft/ai-engineering-coach"
  fi
fi

# ── graphify (AI-powered knowledge graph — bucket C) ──────────────────────────
# https://github.com/Graphify-Labs/graphify. Local-first tree-sitter parsing + assistant-
# driven semantic extraction into graph.json/graph.html/GRAPH_REPORT.md. Installs as a uv
# tool + multi-assistant skill (`/graphify` in Claude Code and 15+ other assistants).
# User-authorized auto-install (2026-07-08) — see chassis CHANGELOG.
if command -v uv >/dev/null 2>&1 && ! command -v graphify >/dev/null 2>&1; then
  echo "→ Installing graphify …"
  uv tool install graphifyy --quiet 2>/dev/null \
    && graphify install >/dev/null 2>&1 \
    || echo "[warn] graphify install failed — install manually: uv tool install graphifyy && graphify install"
fi

# ── ctx (cross-session agent history search — bucket C) ───────────────────────
# https://github.com/ctxrs/ctx. Indexes local coding-agent session history into SQLite;
# `ctx search "…"` retrieves prior decisions/failed attempts across sessions instead of
# repeating work. Official installer fetches a prebuilt binary — no Rust toolchain needed
# (building from source requires rust-version 1.81+, heavier than this slot warrants).
# User-authorized auto-install (2026-07-08) — see chassis CHANGELOG.
if ! command -v ctx >/dev/null 2>&1; then
  echo "→ Installing ctx …"
  curl --proto '=https' --tlsv1.2 -fsSL https://ctx.rs/install | sh 2>/dev/null \
    || echo "[warn] ctx install failed — install manually: curl -fsSL https://ctx.rs/install | sh"
fi
if command -v ctx >/dev/null 2>&1; then
  ctx setup >/dev/null 2>&1 || true
fi

# ── lean-ctx (context-compression MCP layer — bucket C) ───────────────────────
# https://github.com/yvgude/lean-ctx. Gates what the agent reads, caches re-reads, and
# compresses shell/tool output — 60-90% token savings, receipts via `lean-ctx gain`. More
# invasive than the other cockpit tools: it sits between the agent and its context, not
# just observing it. Installed via its npm-packaged prebuilt binary — building the Rust
# source directly needs edition-2024 (rustc 1.85+) and OOM'd a 8GB devcontainer via its
# LTO release profile, so npm is both simpler and more reliable here.
# User-authorized auto-install (2026-07-08) — see chassis CHANGELOG.
if ! command -v lean-ctx >/dev/null 2>&1; then
  echo "→ Installing lean-ctx …"
  npm install -g lean-ctx-bin --silent 2>/dev/null \
    || echo "[warn] lean-ctx install failed — install manually: npm install -g lean-ctx-bin"
fi
if command -v lean-ctx >/dev/null 2>&1; then
  lean-ctx onboard >/dev/null 2>&1 || true
fi

# ── Agent memory durability ───────────────────────────────────────────────────
# Canonical memory is git-tracked in-repo (.agents/memory). The conventional Claude
# path lives on the ephemeral home overlay (the ~/.claude bind mount only persists on
# LOCAL devcontainers, not remote/cloud ones), so recreate it as a symlink each build.
# Mirrors the .claude/skills → .agents/skills pattern.
MEM_CANON="$PWD/.agents/memory"
MEM_LINK="$HOME/.claude/projects/${PWD//\//-}/memory"
mkdir -p "$MEM_CANON"
if [ -e "$MEM_LINK" ] && [ ! -L "$MEM_LINK" ]; then
  cp -rn "$MEM_LINK"/. "$MEM_CANON"/ 2>/dev/null || true   # rescue files written before relink
  rm -rf "$MEM_LINK"
fi
mkdir -p "$(dirname "$MEM_LINK")"
ln -sfn "$MEM_CANON" "$MEM_LINK"
echo "→ agent memory linked: $MEM_LINK → $MEM_CANON"

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
