# Immersive Air Wing Namelists

Immersive Air Wing Namelists for Hearts of Iron IV.

## Overview

- **Game**: Hearts of Iron IV
- **Supported Version**: $SupportedVersion
- **Mod Version**: $ModVersion
- **Tags**: Historical, Military


---

## Directory Architecture

This repository adheres to the standard two-level Hearts of Iron IV mod architecture:
- **Outer Root**: Contains workspace build tools, dev assets, and launch configurations.
- **Inner Mod Root** (\$ModDirectoryName/\): The actual mod repository containing content files, descriptors, tests, and build engine.

\\\
C:\dev\immersive-air-wing-namelists/
â”œâ”€â”€ build.ps1                       # Root build forwarding script
â”œâ”€â”€ build.bat                       # Quick packaging shortcut
â”œâ”€â”€ build_and_deploy.bat            # Quick deploy shortcut
â”œâ”€â”€ assets/                         # Raw graphics and art assets
â””â”€â”€ immersive_air_wing_namelists/              # Git repository root & mod content
    â”œâ”€â”€ descriptor.mod              # Clausewitz engine descriptor
    â”œâ”€â”€ thumbnail.png               # Steam Workshop thumbnail (512x512)
    â”œâ”€â”€ build.ps1                   # Core build and lifecycle engine
    â”œâ”€â”€ common/                     # Game content and scripts
    â”œâ”€â”€ tests/                      # Automated Pester test suites
    â””â”€â”€ wiki/                       # GitHub documentation wiki
\\\

---

## Development & Automation Commands

All lifecycle tasks are managed through \uild.ps1\:

\\\powershell
# 1. Deploy mod to local Paradox Interactive Hearts of Iron IV mod folder
.\build.ps1 -Deploy

# 2. Configure zero-copy DevLink (instant hot-reload for live testing)
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
\\\

---

## Automated Testing

Unit tests are written with [Pester](https://pester.dev) and located in \	ests/\. Execute tests using:

\\\powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-Tests.ps1
\\\

---

## Author & License

- **Author**: TheCreepero