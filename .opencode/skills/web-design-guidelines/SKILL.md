---
name: web-design-guidelines
description: Review UI code for Web Interface Guidelines compliance. Use when asked to "review my UI", "check accessibility", "audit design", "review UX", or "check my site against best practices".
metadata:
  author: vercel
  version: "1.0.0"
---

# Web Interface Guidelines (vendored)

Review files for compliance with the rules in `references/web-interface-guidelines.md` — **the local, vendored copy**. Do not fetch the rules from the network; if the file is missing or seems truncated, tell the tech-lead instead of downloading.

## Workflow

1. Skim `references/web-interface-guidelines.md` for the sections relevant to the files under review.
2. Read the specified files (or ask the user for files/patterns).
3. Check against all applicable rules for that file type.
4. Output findings in the terse `file:line` format the guidelines specify.

## Scope tips

- Prioritize: accessibility rules > forms > focus states > anti-patterns > the rest.
- A clean pass is reported as `✓ pass` per file, not silence.
