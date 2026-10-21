#!/usr/bin/env bash
# /verify gate for macos-tcc-preflight. Linux-safe: mock mode only, never touches TCC.
set -uo pipefail
cd "$(dirname "$0")/.."
F=0; p(){ echo "PASS $1"; }; f(){ echo "FAIL $1"; F=1; }
bash tests/run.sh || F=1
for x in LICENSE bin/tcc-preflight helper/Package.swift helper/Resources/Info.plist scripts/codesign.sh Makefile README.md CREDITS.md site/index.html site/checklist.png; do [[ -e $x ]] && p "file $x" || f "file $x"; done
if grep -rnIE --exclude=verify.sh '(sk-[A-Za-z0-9]{20}|ghp_[A-Za-z0-9]{20}|gho_[A-Za-z0-9]{20}|BEGIN [A-Z ]*PRIVATE KEY|CLOUDFLARE_API_TOKEN=.)' . ; then f secrets; else p "no secrets"; fi
for u in nicolasmertens/macos-permissions-setup sitharaj88/macctl docs.openclaw.ai/platforms/mac/permissions jonathanlewisclark.com/guides/mac-mini-agent-setup-guide.md; do grep -q "$u" README.md && grep -q "$u" CREDITS.md && p "cited $u" || f "cited $u"; done
for k in "responsible" "signature" "macOS 15" "Info.plist usage string" "HDMI dummy plug"; do grep -q "$k" README.md && p "README pitfall: $k" || f "README pitfall: $k"; done
SW=$(command -v swiftc || true)
if [[ -n "$SW" ]]; then "$SW" -typecheck helper/Sources/TCCPreflightHelper/*.swift && p "swiftc typecheck" || f "swiftc typecheck"; else echo "SKIP swiftc typecheck (no toolchain)"; fi
if [[ -z "${SKIP_LIVE:-}" ]]; then python3 scripts/verify-page.py "${PAGES_URL:-https://macos-tcc-preflight.pages.dev/}" outputs/live-390x844.png || F=1; fi
(( F == 0 )) && echo "RESULT: PASS" || { echo "RESULT: FAIL"; exit 1; }
