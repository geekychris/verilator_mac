#!/usr/bin/env bash
# Build & install Verilator on macOS (Apple Silicon or Intel) from source.
#
# Idempotent: rerun safely. Installs all deps via Homebrew (no sudo, no /opt
# tarball builds). Defaults install Verilator to $PWD/install with sources in
# $PWD/verilator-src. Override with the env vars below.
#
# Usage:
#   ./install-verilator-macos.sh                       # build stable, install to ./install
#   VERILATOR_PREFIX=$HOME/.local ./install-verilator-macos.sh
#   VERILATOR_REF=v5.048 ./install-verilator-macos.sh  # specific tag
#   VERILATOR_SRC=/tmp/v ./install-verilator-macos.sh

set -euo pipefail

VERILATOR_SRC="${VERILATOR_SRC:-$PWD/verilator-src}"
VERILATOR_PREFIX="${VERILATOR_PREFIX:-$PWD/install}"
VERILATOR_REF="${VERILATOR_REF:-stable}"   # branch name or tag (e.g. v5.048)
VERILATOR_REPO="${VERILATOR_REPO:-https://github.com/verilator/verilator.git}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERR\033[0m %s\n' "$*" >&2; exit 1; }

# 1. Sanity checks ----------------------------------------------------------
[[ "$(uname -s)" == "Darwin" ]] || die "This script is macOS-only."
[[ "$(uname -m)" == "arm64" ]]  || warn "Not arm64 — script should still work on Intel."

if ! xcode-select -p >/dev/null 2>&1; then
    die "Xcode Command Line Tools missing. Run: xcode-select --install"
fi

if ! command -v brew >/dev/null 2>&1; then
    die "Homebrew missing. Install from https://brew.sh and rerun."
fi

BREW_PREFIX="$(brew --prefix)"
log "Homebrew prefix: $BREW_PREFIX"

# 2. Brew dependencies ------------------------------------------------------
# bison and flex are keg-only on macOS — Apple's bundled versions are too old
# for Verilator. We don't `brew link` them; we put them on PATH for this build.
BREW_PKGS=(autoconf automake libtool bison flex help2man perl ccache)

log "Installing/updating Homebrew packages: ${BREW_PKGS[*]}"
brew install "${BREW_PKGS[@]}"

BISON_BIN="$(brew --prefix bison)/bin"
FLEX_BIN="$(brew --prefix flex)/bin"
[[ -x "$BISON_BIN/bison" ]] || die "brew bison not where expected: $BISON_BIN"
[[ -x "$FLEX_BIN/flex"   ]] || die "brew flex not where expected: $FLEX_BIN"

export PATH="$BISON_BIN:$FLEX_BIN:$PATH"
log "Using bison: $("$BISON_BIN/bison" --version | head -1)"
log "Using flex:  $("$FLEX_BIN/flex"   --version)"

# 3. Source ----------------------------------------------------------------
if [[ -d "$VERILATOR_SRC/.git" ]]; then
    log "Updating existing source tree at $VERILATOR_SRC"
    git -C "$VERILATOR_SRC" fetch --tags origin
    git -C "$VERILATOR_SRC" checkout "$VERILATOR_REF"
    git -C "$VERILATOR_SRC" pull --ff-only origin "$VERILATOR_REF" 2>/dev/null || true
else
    log "Cloning Verilator into $VERILATOR_SRC (ref: $VERILATOR_REF)"
    git clone --branch "$VERILATOR_REF" "$VERILATOR_REPO" "$VERILATOR_SRC"
fi

# 4. Build & install -------------------------------------------------------
cd "$VERILATOR_SRC"

log "Running autoconf"
autoconf

log "Configuring (prefix=$VERILATOR_PREFIX)"
./configure --prefix="$VERILATOR_PREFIX"

JOBS="$(sysctl -n hw.ncpu)"
log "Compiling with $JOBS jobs"
make -j "$JOBS"

log "Installing to $VERILATOR_PREFIX"
make install

# 5. Done ------------------------------------------------------------------
VERILATOR_BIN="$VERILATOR_PREFIX/bin/verilator"
[[ -x "$VERILATOR_BIN" ]] || die "Install failed: $VERILATOR_BIN not found"

log "Installed: $("$VERILATOR_BIN" --version)"
cat <<EOF

Done. To use verilator from a fresh shell, add this to your ~/.zshrc:

    export PATH="$VERILATOR_PREFIX/bin:\$PATH"

Or invoke it directly: $VERILATOR_BIN --help
EOF
