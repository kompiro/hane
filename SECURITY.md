# Security Policy

## Reporting a vulnerability

If you find a security issue in `hane`, please **do not** file a public issue.
Instead, use GitHub's private vulnerability reporting:

- <https://github.com/kompiro/hane/security/advisories/new>

If that form is unavailable to you, email **kompiro@gmail.com** instead.

`hane` is maintained on a **best-effort, no-SLA** basis as a personal project.
We aim to **acknowledge a report within 7 days** — a best-effort target, not a
guarantee — and there is **no fixed timeline for shipping a fix**. Please
include the affected skill (e.g. `skills/start-dev/SKILL.md`), the plugin
version or commit SHA, and how to reproduce the behavior.

## Supported versions

Only the **latest published release** receives security fixes (see
[Releases](https://github.com/kompiro/hane/releases) and
[CHANGELOG.md](CHANGELOG.md)). Older versions are not patched — update to the
latest tag instead.

## What is in scope

`hane` ships no compiled code and no runtime dependencies. Its security surface
is nonetheless real, because the plugin instructs a coding agent to act inside
your repository:

- **Skill bodies** (`skills/*/SKILL.md`) contain shell commands and procedures
  that an agent executes in the **host repository**. A skill that can be
  induced to run an unintended command, exfiltrate repository contents, or push
  to a remote is a valid report.
- **Hooks** (`hooks/`) run on session lifecycle events on the user's machine.
- **Supply chain**: the plugin is installed from this repository via the
  marketplace manifest (`.claude-plugin/marketplace.json`). Reports about the
  integrity of that distribution path are in scope.
- **Prompt-injection paths**: content a skill is instructed to read (Issue
  bodies, PR descriptions, upstream diffs — e.g. in `dependabot` /
  `security-alert`) that could steer the agent into unsafe actions.

Out of scope: vulnerabilities in the host repository itself, in Claude Code, or
in third-party tools the skills invoke (`gh`, `git`, package managers). Report
those to their respective maintainers.

## Coordinated disclosure

We prefer **coordinated disclosure**. Once a report is received:

- We confirm the issue and develop a fix privately, in the draft GitHub
  Security Advisory.
- The **embargo length is negotiable per report**, agreed with the reporter
  based on severity and the time a fix realistically needs.
- When the fix ships (or the embargo expires), we publish the advisory and
  credit the reporter, unless they ask to remain anonymous.

Please do not disclose the issue publicly before the advisory is published.
