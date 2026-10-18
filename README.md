# Immersive Air Wing Names Expanded

Immersive Air Wing Names Expanded provides historically authentic air wing, squadron, and group namelists for Hearts of Iron IV.

## Overview

- **Game**: Hearts of Iron IV
- **Supported Version**: 1.19.*
- **Mod Version**: 1.0
- **Tags**: Historical, Military, Alternative History

---

## Directory Architecture

This repository uses a **single-root** architecture: the workspace root and the Git repository root are the same directory. All mod content, automation, tests, and assets live directly under it.

`
immersive-air-wing-namelists/          # Repository root (mods\immersive-air-wing-namelists under the Modding Manager)
|-- descriptor.mod                  # Clausewitz engine descriptor
|-- thumbnail.png                   # Steam Workshop thumbnail (512x512)
|-- build.ps1                       # Core build and lifecycle engine
|-- build.bat                       # Quick packaging shortcut
|-- build_and_deploy.bat            # Quick deploy shortcut
|-- assets/                         # Raw graphics and art assets
|-- common/                         # Game content and scripts
|-- localisation/                   # Localisation keys
|-- tests/                          # Automated Pester test suites
-- wiki/                           # GitHub documentation wiki
`

---

## Development & Automation Commands

All lifecycle tasks are managed through uild.ps1:

`powershell
# 1. Deploy mod to local Paradox Interactive Hearts of Iron IV mod folder
.\build.ps1 -Deploy

# 2. Configure zero-copy DevLink (the launcher loads this folder itself; restart the game to see a change)
.\build.ps1 -DevLink

# 3. Validate syntax and bracket balance without deploying
.\build.ps1 -ValidateOnly

# 4. Run automated test suites (Pester)
.\build.ps1 -Test

# 5. Package clean release zip archive
.\build.ps1 -Package

# 6. Publish to Steam Workshop (Dry Run preview)
.\build.ps1 -PublishSteam -DryRun

# 7. Clean deployed mod files and temporary archives
.\build.ps1 -Clean

# 8. Generate the other nine game languages from localisation/english/ (commit the result)
.\build.ps1 -SyncLoc
`

---

## Automated Testing

Unit tests are written with [Pester](https://pester.dev) and located in 	ests/. Execute tests using:

`powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
`

---

## Author & License

- **Author**: TheCreepero