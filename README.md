# Verilator on macOS

Scripts to build and install [Verilator](https://verilator.org) (open-source
Verilog/SystemVerilog simulator) from source on macOS, and smoke-test the
result.

Tested on macOS 26.3 (Apple Silicon), Verilator stable = 5.048.

## Quick start

```bash
./install-verilator-macos.sh   # ~5 min on M-series
./test-verilator.sh            # should print "Smoke test PASSED"
```

After installation, add the install dir to your shell:

```bash
echo 'export PATH="'"$PWD"'/install/bin:$PATH"' >> ~/.zshrc
```

## What the install script does

1. Verifies Xcode Command Line Tools and Homebrew are present.
2. `brew install`s the build toolchain: `autoconf automake libtool bison flex
   help2man perl ccache`. The keg-only `bison` and `flex` are put on `PATH`
   for this build only — Apple's bundled versions are too old.
3. Clones `https://github.com/verilator/verilator` (default branch: `stable`).
4. Runs `autoconf && ./configure --prefix=… && make -j$(sysctl -n hw.ncpu) && make install`.

No `sudo`, no manual tarball builds in `/opt`. Everything lives under
`$PWD/verilator-src` (sources) and `$PWD/install` (binaries) by default.

## Customizing

Environment variables understood by `install-verilator-macos.sh`:

| var | default | meaning |
|---|---|---|
| `VERILATOR_PREFIX` | `$PWD/install` | install location |
| `VERILATOR_SRC`    | `$PWD/verilator-src` | source clone location |
| `VERILATOR_REF`    | `stable` | git ref — branch or tag (e.g. `v5.048`, `master`) |
| `VERILATOR_REPO`   | upstream GitHub | clone URL |

Example:

```bash
VERILATOR_PREFIX=$HOME/.local VERILATOR_REF=v5.048 ./install-verilator-macos.sh
```

## What the smoke test does

`smoke-test/counter.sv` is a trivial 8-bit counter testbench. The script
verilates it with `--binary`, compiles the generated C++, runs the simulator,
and checks for the `PASS: counter reached 8` line. Exits non-zero on any
failure.

## Examples

### `examples/barrel_shifter`

Combinational 8-bit barrel shifter (`barrel_shifter.sv`) plus a self-checking
testbench (`tb_barrel_shifter.sv`) that runs 5 directed cases and 200 random
cases, comparing the DUT against SystemVerilog's native `<<`, `>>`, `>>>`.

Run it:

```bash
cd examples/barrel_shifter
PATH="$PWD/../../install/bin:$PATH" \
    verilator --binary -j 0 --top-module top \
        barrel_shifter.sv tb_barrel_shifter.sv
./obj_dir/Vtop
```

Expected last line: `PASS: all cases matched golden model`.

The DUT is parameterized — change `localparam int WIDTH = 8;` in the testbench
(or instantiate with a different `.WIDTH(...)`) to try other widths. `WIDTH`
must be a power of two.

## Why not `brew install verilator`?

You can do that too — it's faster. These scripts exist because the user
wanted to build from source (per the upstream install guide), and because
building from source lets you pin to a specific tag, run the dev branch, or
patch locally.

## References

- Upstream install guide: https://verilator.org/guide/latest/install.html
- k0nze's Apple Silicon notes (older, builds bison/flex from tarballs into
  `/opt` — these scripts use Homebrew instead): https://k0nze.dev/posts/verilog-apple-silicon/
