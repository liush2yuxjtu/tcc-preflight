# tcc-preflight — macOS TCC permission preflight

Grant every macOS privacy (TCC) permission an agent needs **while a human and a monitor are still there**, then go headless.

Live explainer: https://macos-tcc-preflight.pages.dev/ · License: MIT

## Install (macOS, needs Xcode Command Line Tools)

```bash
git clone https://github.com/liush2yuxjtu/tcc-preflight && cd tcc-preflight && make && bin/tcc-preflight
```

Try it anywhere without touching TCC (mock mode, e.g. on Linux):

```bash
git clone https://github.com/liush2yuxjtu/tcc-preflight && cd tcc-preflight && TCC_PREFLIGHT_MOCK=camera=granted bin/tcc-preflight --check
```

## Usage

```bash
make            # swift build + .app bundle (Info.plist usage strings) + ad-hoc codesign
bin/tcc-preflight          # check each, request only missing ones, print checklist
bin/tcc-preflight --check  # read-only: status/preflight APIs only, never prompts
bin/tcc-preflight --json   # machine-readable
CODESIGN_IDENTITY="Developer ID Application: You (TEAMID)" make sign   # optional, from env, nothing committed
```

Order (each step first checks; already-granted steps are skipped, never re-prompted):

| # | Permission | Check (used by `--check`) | Request |
|---|---|---|---|
| 1 | Camera | `AVCaptureDevice.authorizationStatus` | `AVCaptureDevice.requestAccess(.video)` |
| 2 | Microphone | `AVCaptureDevice.authorizationStatus` | `AVCaptureDevice.requestAccess(.audio)` |
| 3 | Screen Recording | `CGPreflightScreenCaptureAccess` | `CGRequestScreenCaptureAccess` + opens pane |
| 4 | Accessibility | `AXIsProcessTrustedWithOptions(prompt:false)` | `…(prompt:true)` |
| 5 | Automation → System Events | `AEDeterminePermissionToAutomateTarget(askUserIfNeeded:false)` | `…(true)` |
| 6 | Input Monitoring | `IOHIDCheckAccess` | `IOHIDRequestAccess` |
| 7 | Full Disk Access | read-only probe of a protected path (`~/Library/Safari`, `Mail`, `Messages`) | opens *Privacy_AllFiles* pane (no API exists) |

Final output is a **PASS / MISSING** checklist. Exit 0 = all pass, 1 = something missing, 2 = error.
The tool never reads or writes the TCC database and never runs `tccutil reset`.

## Go-headless order

1. Attach a real monitor + keyboard, run `bin/tcc-preflight`, approve every prompt / toggle in System Settings.
2. Run `bin/tcc-preflight --check` until it is all PASS.
3. **Then** plug in the HDMI dummy plug.
4. **Then** go headless (unplug monitor, use SSH / Screen Sharing).

## Four pitfalls

1. **Grants are recorded under the requesting (responsible) app**, not the script. Run from Terminal → Terminal/iTerm gets the grant; run from your agent's launchd job → that binary does. Run the preflight from the *same* host process your agent will use.
2. **Changing the path or code signature invalidates grants.** Moving the `.app`, rebuilding with a different identity, or ad-hoc re-signing makes TCC treat it as a new app. Keep a fixed install path and a stable `CODESIGN_IDENTITY`.
3. **macOS 15 Sequoia re-asks for Screen Recording periodically (monthly)** for many apps — a headless box will silently lose it. Schedule `tcc-preflight --check` and alert on MISSING.
4. **No Info.plist usage string ⇒ no prompt.** Without `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSAppleEventsUsageDescription` the request fails/crashes instead of prompting; that's why the helper ships as a bundle (`helper/Resources/Info.plist`).

## Tests (Linux-safe, mock mode)

`TCC_PREFLIGHT_MOCK="camera=granted,microphone=prompt-grants,screen=denied"` emulates the helper (unlisted = missing). `TCC_PREFLIGHT_TRACE=file` logs every `check`/`request` call.

```bash
bash tests/run.sh      # ordering, --check never requests, granted ⇒ no prompt, table + JSON format
bash scripts/verify.sh # tests + swiftc typecheck (if available) + live Pages 390×844 check
```

## /verify

Self-contained gate (Linux or macOS, mock mode only, never prompts):

```bash
bash scripts/verify.sh               # tests + file/secret/citation checks + swiftc typecheck (if on PATH) + live Pages 390×844
SKIP_LIVE=1 bash scripts/verify.sh   # offline
```

Green: every line `PASS`, final `RESULT: PASS`, exit 0. Live check needs python3 + `playwright` (Chromium). Pages deploy: `node scripts/deploy-gen.mjs` writes a Cloudflare API script that publishes `site/`.

## Not verified

Real macOS behaviour (actual prompts, Sequoia re-approval cadence, FDA probe reliability, Automation return codes) is **untested** — everything here ran on Linux. The macOS-only `#if os(macOS)` code was syntax-reviewed and parsed, but only the platform-independent part was typechecked (Swift 6.0.3 on Linux).

## References

- https://github.com/nicolasmertens/macos-permissions-setup (MIT)
- https://github.com/sitharaj88/macctl (Apache-2.0)
- https://docs.openclaw.ai/platforms/mac/permissions
- https://jonathanlewisclark.com/guides/mac-mini-agent-setup-guide.md

See [CREDITS.md](CREDITS.md).
