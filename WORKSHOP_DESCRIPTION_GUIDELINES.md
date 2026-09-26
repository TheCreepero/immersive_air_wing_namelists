# Steam Workshop Description Guidelines & Reference

This document provides formatting rules, length limits, and reference templates for maintaining the Steam Workshop listing for **Immersive Air Wing Namelists**.

---

## Core Rules & Invariants

1. **No Emojis**: Strictly avoid emojis anywhere in the description text.
2. **Character Limits**: Steam Workshop descriptions have a max limit of ~17,000 raw BBCode characters. Keep bullet points concise and direct.
3. **No Planned Section**: Do not include speculative 'Planned' sections in the public description.
4. **Valid Steam BBCode**:
   - Headers: \[h1]Title[/h1]\
   - Bold: \[b]Text[/b]\
   - Italics: \[i]Text[/i]\
   - Links: \[url=https://...]Text[/url]\
   - Bullets: Standard hyphen (\- Item\)

---

## Template Description

\\\bcode
[h1]Immersive Air Wing Namelists[/h1]
Immersive Air Wing Namelists for Hearts of Iron IV.

[h1]Features:[/h1]
- Immersive and historically authentic additions.
- Fully compatible with current Hearts of Iron IV version (1.19.*).
- Multiplayer and Ironman compatible.

[h1]Compatibility:[/h1]
- Compatible with all major overhaul and total conversion mods.
- Safe to enable or disable mid-campaign.

[h1]Feedback & Contributions:[/h1]
Please report issues, suggestions, or feedback in the Steam Workshop discussion threads.
\\\
"@

 = @"
# Immersive Air Wing Namelists - Development & Agent Rules

## 1. Mod Architecture & Workspace Layout
- This project follows a two-level mod directory layout:
  - **Outer workspace root**: \$ParentDirectory\
  - **Inner mod repository**: \$innerDirectory\ (Git repository root containing \.git/\)
- **Dual-Path Synchronization Invariant**:
  - \GEMINI.md\ exists in duplicate (at the workspace root and inside the inner mod repository).
  - Whenever updating rules, instructions, or documentation, keep both \GEMINI.md\ copies 100% identical.

## 2. Clausewitz File Format & Syntax Invariants
- **UTF-8 Without BOM**: All Clausewitz script files (\.mod\, \.txt\) must be saved in UTF-8 without BOM. Never use standard Windows PowerShell \Set-Content -Encoding UTF8\ because it writes a BOM (\\ufeff\). Always write text files using:
  \[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))\
- **Key-Value Syntax**: \descriptor.mod\ must strictly follow \key="value"\ without spaces around the \=\ operator.
- **Bracket Balance**: Curly braces \{}\ and double quotes \""\ must always be strictly balanced.
- **No Empty Blocks**: Avoid empty blocks such as \unique = { }\ or \ordered = { }\.

## 3. Build & Automation Protocol
- Always run pre-flight syntax and descriptor checks before declaring work complete:
  \powershell -File .\build.ps1 -ValidateOnly\
- Run the full automated Pester test suite:
  \powershell -File .\build.ps1 -Test\
- Use \.\build.ps1 -DevLink\ for zero-copy live editing directly from the repository.
- Use \.\build.ps1 -Package\ to verify that release packaging strictly excludes \.git\, \.github\, \.vscode\, \	ests\, \wiki\, and developer scripts.

## 4. Git & Commit Guidelines
- Do not commit to the Git repository unless explicitly instructed by the user. The user prefers to review changes before committing.
- **Git Verification Invariant**: After completing changes, always verify \git status\ in the inner mod folder to ensure the working tree reflects expected changes.