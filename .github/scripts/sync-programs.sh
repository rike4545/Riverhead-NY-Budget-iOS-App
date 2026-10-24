#!/usr/bin/env bash
# Refresh the bundled Program Budget copy from the published site.
#
# Why this exists separately from the ETL sync: programs.json is not in the web
# repo's shared-data/manifest.json, so sync-shared-data.mjs never copies it and
# the bundled copy froze at whatever was committed by hand. It sat at 22,055
# bytes against a live 38,314, which the app shows whenever the network copy is
# unreachable — a stale population and four years of missing history, offline.
#
# The copy is the offline path for the whole Program Budget screen, so it is
# only replaced by a payload proven to satisfy the decoder. Validation reuses
# the parity drift checker, which derives what the Swift requires from the
# Swift: a payload that would throw gets rejected here rather than shipped.
#
# Neither failure mode fails the job. A fetch that does not arrive leaves the
# existing copy in place, which is correct. A payload that arrives and does not
# validate is annotated loudly and left uninstalled, because the drift check is
# where that alarm belongs and blocking this job would stop the other datasets
# syncing too.
set -euo pipefail

URL="${PROGRAMS_URL:-https://rike4545.github.io/Riverhead-NY-Budget-Web-App/data/programs.json}"
DEST="Riverhead NY Budget App/programs.json"

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

echo "Fetching $URL"
if ! curl -fsSL --max-time 60 -o "$staging/programs.json" "$URL"; then
    echo "::warning title=Program Budget copy not refreshed::Could not fetch $URL. The bundled copy is unchanged, which is the safe outcome."
    exit 0
fi

bytes=$(wc -c < "$staging/programs.json")
echo "Fetched $bytes bytes; checking it against the Swift decoder"

# The checker reads the staging directory as a set of saved payloads. Only
# programs.json is there, so every other endpoint reports "not reached", which
# is a transport finding and never fails. Only this payload can fail the gate.
# Quiet unless it matters: with one payload staged the checker prints a "not
# reached" line for every other endpoint, which buries the one line that counts.
if ! node .github/scripts/check-parity-drift.mjs --offline "$staging" --fail-on break > "$staging/check.log" 2>&1; then
    grep -E '^(BREAK|DRIFT)' -A2 "$staging/check.log" || cat "$staging/check.log"
    echo "::error title=Program Budget copy rejected::The published programs.json no longer satisfies this app's decoder, so it was NOT installed as the offline copy — installing it would break the screen with no network. The bundled copy is unchanged. See the Web parity drift workflow for what moved."
    exit 0
fi
grep -E 'break,' "$staging/check.log" | tail -1

if cmp -s "$staging/programs.json" "$DEST"; then
    echo "Bundled copy already matches the published one."
    exit 0
fi

was=$( [ -f "$DEST" ] && wc -c < "$DEST" || echo 0 )
cp "$staging/programs.json" "$DEST"
echo "Refreshed the bundled copy: ${was} -> ${bytes} bytes."
