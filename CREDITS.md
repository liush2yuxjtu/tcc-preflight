# Credits & license notes

All code in this folder is original. No code was copied from any reference; they informed ideas only (which permissions an agent Mac needs, ordering, the "grant before headless" workflow).

| Source | License (checked 2026-10-22) | What was used |
|---|---|---|
| [nicolasmertens/macos-permissions-setup](https://github.com/nicolasmertens/macos-permissions-setup) | MIT (GitHub license API + LICENSE file) | Idea: walk through the permission list in sequence and open the matching Settings pane. No code copied. |
| [sitharaj88/macctl](https://github.com/sitharaj88/macctl) | Apache-2.0 (LICENSE + NOTICE) | Idea: native helper reporting per-permission status. No code copied, so no NOTICE redistribution needed. |
| [OpenClaw docs · macOS permissions](https://docs.openclaw.ai/platforms/mac/permissions) | Docs page, no explicit content license found (footer "© 2026"); openclaw/openclaw repo is MIT | Facts only: grants tied to signature/path and responsible app; usage strings required. Paraphrased, not copied. |
| [Mac mini agent setup guide (jonathanlewisclark.com)](https://jonathanlewisclark.com/guides/mac-mini-agent-setup-guide.md) | No license found (fetch from the box failed; treated as all-rights-reserved) | Concept only: grant permissions, then HDMI dummy plug, then headless. Nothing copied. |

Apple API names are from Apple's public SDK documentation.
