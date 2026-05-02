#!/usr/bin/env bash
# Smoke-test a Verilator install by compiling and running smoke-test/counter.sv.
# Exits 0 if the simulation reaches "PASS:" and $finish; nonzero otherwise.
#
# Usage:
#   ./test-verilator.sh                           # use ./install/bin/verilator
#   VERILATOR_PREFIX=$HOME/.local ./test-verilator.sh
#   VERILATOR=/path/to/verilator   ./test-verilator.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SMOKE_DIR="$SCRIPT_DIR/smoke-test"
SMOKE_SV="$SMOKE_DIR/counter.sv"

VERILATOR_PREFIX="${VERILATOR_PREFIX:-$SCRIPT_DIR/install}"
VERILATOR="${VERILATOR:-$VERILATOR_PREFIX/bin/verilator}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mERR\033[0m %s\n' "$*" >&2; exit 1; }

[[ -x "$VERILATOR" ]] || die "verilator not found or not executable: $VERILATOR"
[[ -f "$SMOKE_SV"  ]] || die "smoke-test source missing: $SMOKE_SV"

# Make sure brew bison/flex are reachable for the C++ build step too. (Verilator
# itself doesn't reinvoke them at use-time, but keeping PATH consistent avoids
# surprises if the user is poking at the source tree.)
if command -v brew >/dev/null 2>&1; then
    export PATH="$(brew --prefix bison)/bin:$(brew --prefix flex)/bin:$PATH"
fi

log "verilator: $("$VERILATOR" --version)"

WORK="$SMOKE_DIR/obj_dir"
rm -rf "$WORK"

cd "$SMOKE_DIR"
log "Verilating + compiling counter.sv"
"$VERILATOR" --binary -j 0 --top-module top counter.sv >/dev/null

log "Running simulation"
OUT="$("$WORK/Vtop")"
echo "$OUT"

if echo "$OUT" | grep -q '^PASS: counter reached 8$'; then
    log "Smoke test PASSED"
    exit 0
fi
die "Smoke test FAILED — did not see expected PASS line"
