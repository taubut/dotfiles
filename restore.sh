#!/bin/bash
# =============================================================================
# restore.sh — compatibility shim.
# The real installer is now the staged fresh-start.sh. This runs all stages.
# For a controlled install (recommended), use:  ./fresh-start.sh
# =============================================================================
exec "$(cd "$(dirname "$0")" && pwd)/fresh-start.sh" --all "$@"
