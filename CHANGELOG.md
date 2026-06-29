# Changelog

All notable changes to the chassis are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning: [SemVer](https://semver.org/).

---

## [0.1.0] — 2026-06-29

### Added

- Initial chassis: Copier template with A/B/C/D bucket structure (ADR-015).
- Bucket A guardrails: AGENTS.md (AAIF open standard), ruff+mypy, import-linter slot,
  opengrep self-weakening rules, gitleaks, conventional commits, CODEOWNERS, Diátaxis docs,
  pre-commit pipeline, CI calling `just ci-*`.
- Bucket B ratcheting: coverage floor (`fail_under = 0`, ratchet up as coverage grows).
- Bucket C on-demand: codeburn stub in justfile.
- Bucket D wired-but-waiting: eval gate, ADLC, arch-drift slots (documented in AGENTS.md).
- Acceptance test: `just accept` stamps a throwaway project and verifies `just ci` is green.
- Devcontainer standardisation: committed layers, mounted host-state, cache volumes.
