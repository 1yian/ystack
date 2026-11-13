#!/usr/bin/env bash
# Reconcile pinned global npm CLIs into one prefix; reinstall only on drift.
# The work laptop's Home Manager activation calls this with its pin list.
# No credentials, hooks, daemon control, or account login. --force reinstalls.
set -euo pipefail

usage() {
  echo 'usage: npm-pins.sh [--force] <prefix> <package@version>...' >&2
  exit 1
}

if [[ "$(uname -s)" != Linux && "$(uname -s)" != Darwin ]] || [ "$(id -u)" = 0 ]; then
  echo 'Run npm-pins.sh as your Linux or macOS login user.' >&2
  exit 1
fi
force=0
if [ "${1:-}" = --force ]; then
  force=1
  shift
fi
[ "$#" -ge 2 ] || usage
prefix=$1
shift
case "$prefix" in /*) ;; *) usage ;; esac

# Idempotence comes from the installed tree, not a stamp that survives a
# broken or missing install, so a changed pin is reconciled on the next switch.
installed=$(npm ls --global --prefix "$prefix" --depth=0 --json 2>/dev/null || true)
if [ "$force" = 0 ] && printf '%s' "$installed" | node -e '
let input = "";
process.stdin.on("data", chunk => input += chunk);
process.stdin.on("end", () => {
  try {
    const dependencies = JSON.parse(input).dependencies ?? {};
    const matches = process.argv.slice(1).every(spec => {
      const split = spec.lastIndexOf("@");
      return dependencies[spec.slice(0, split)]?.version === spec.slice(split + 1);
    });
    process.exit(matches ? 0 : 1);
  } catch { process.exit(1); }
});
' "$@"; then
  echo "npm pins already match in $prefix."
else
  npm install --global --prefix "$prefix" "$@"
fi
