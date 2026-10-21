#!/usr/bin/env bash
# Linux-safe tests: mock mode only. Never touches TCC.
set -uo pipefail
cd "$(dirname "$0")/.."
J=$(mktemp); TF=bin/tcc-preflight; T="$BASH $TF";  # run the tool with the same bash as this suite (3.2 in /verify)
 pass=0; fail=0; TR=$(mktemp)
ok(){ if eval "$2"; then echo "PASS $1"; pass=$((pass+1)); else echo "FAIL $1"; fail=$((fail+1)); fi; }
ORDER="camera microphone screen accessibility automation input fulldisk"
ALLG=$(for p in $ORDER; do printf '%s=granted,' $p; done)

: >"$TR"; TCC_PREFLIGHT_MOCK=x=y TCC_PREFLIGHT_TRACE=$TR $T >/dev/null
ok "request mode: check-before-request in fixed order" \
 '[[ "$(tr "\n" " " <"$TR")" == "$(for p in $ORDER; do printf "check %s request %s " $p $p; done)" ]]'

: >"$TR"; out=$(TCC_PREFLIGHT_MOCK=x=y TCC_PREFLIGHT_TRACE=$TR $T --check); rc=$?
ok "--check never calls request paths" '! grep -q "^request" "$TR"'
ok "--check checks all 7 in order" '[[ "$(awk "{print \$2}" "$TR" | tr "\n" " ")" == "$ORDER " ]]'
ok "--check exit 1 when missing" '[[ $rc == 1 ]]'
ok "--check source has no request call outside MODE guard" '[[ $(grep -c "helper request" $TF) == 1 ]] && grep -q "MODE == request" $TF'

: >"$TR"; TCC_PREFLIGHT_MOCK="$ALLG" TCC_PREFLIGHT_TRACE=$TR $T >/dev/null; rc=$?
ok "already granted => no prompts" '! grep -q "^request" "$TR"'
ok "all granted exit 0" '[[ $rc == 0 ]]'

: >"$TR"; TCC_PREFLIGHT_MOCK="camera=granted,microphone=prompt-grants,screen=denied" TCC_PREFLIGHT_TRACE=$TR $T --json >"$J"
ok "only missing ones requested" '! grep -q "request camera" "$TR" && grep -q "request microphone" "$TR"'
ok "json valid + statuses" 'python3 -c "
import json;d=json.load(open(\"$J\"));s={p[\"id\"]:p[\"status\"] for p in d[\"permissions\"]}
assert [p[\"id\"] for p in d[\"permissions\"]]==\"$ORDER\".split()
assert s[\"camera\"]==\"pass\" and s[\"microphone\"]==\"pass\" and s[\"screen\"]==\"missing\"
assert d[\"missing\"]==5 and d[\"ok\"] is False and set(s.values())<={\"pass\",\"missing\"}"'

out=$(TCC_PREFLIGHT_MOCK="camera=granted" $T --check)
ok "table header" 'head -1 <<<"$out" | grep -qE "^#\s+PERMISSION\s+STATUS\s+ACTION"'
ok "table has 7 rows PASS/MISSING" '[[ $(grep -cE "^[1-7] .*(PASS|MISSING)" <<<"$out") == 7 ]]'
ok "table row 1 camera PASS" 'grep -qE "^1 +Camera +PASS" <<<"$out"'
ok "table footer" 'tail -1 <<<"$out" | grep -q "mode=check missing=6"'
ok "non-mac without mock refuses (exit 2)" '[[ "$(uname -s)" == Darwin ]] || { env -u TCC_PREFLIGHT_MOCK $T --check >/dev/null 2>&1; [[ $? == 2 ]]; }'
ok "bad option exit 2" '$T --nope >/dev/null 2>&1; [[ $? == 2 ]]'
ok "no TCC.db / tccutil reset in code" '! grep -rnE "TCC\.db|tccutil +reset" bin helper scripts Makefile'
ok "Info.plist usage strings" 'for k in NSCameraUsageDescription NSMicrophoneUsageDescription NSAppleEventsUsageDescription; do grep -q $k helper/Resources/Info.plist || exit 1; done'
ok "Swift uses required APIs" 'for a in AVCaptureDevice.requestAccess CGRequestScreenCaptureAccess CGPreflightScreenCaptureAccess AXIsProcessTrustedWithOptions AEDeterminePermissionToAutomateTarget IOHIDRequestAccess IOHIDCheckAccess Privacy_AllFiles; do grep -q "$a" helper/Sources/TCCPreflightHelper/main.swift || exit 1; done'
ok "bash -n" '$BASH -n $TF && $BASH -n scripts/codesign.sh && $BASH -n tests/run.sh'
rm -f "$TR"
echo "bash: $BASH_VERSION"; echo "tests: $pass passed, $fail failed"; (( fail == 0 )) && echo "RESULT: PASS" || { echo "RESULT: FAIL"; exit 1; }
