# Immersive Air Wing Namelists (IAWN) - Agent Rules

Shared rules for every mod in this tree (file encodings, build commands, engine knowledge, git) are in the Modding Manager's `../../AGENTS.md`; `CLAUDE.md` and `GEMINI.md` import this file. The long form (file structure, archetypes, linguistics, localisation, branding) is `docs/iawn-agent-guide.md`.

## What this mod is
- Air wing name lists: one pair of files per nation, `common/units/names/iawn_<TAG>_names.txt` [NAM-014] and `localisation/english/iawn_<TAG>_l_english.yml`; not yet on the Workshop.

## Mod invariants
- A national list covers all eighteen equipment archetypes [NAM-015] (`$RequiredArchetypes` in `tests/AirWingNames.Helpers.ps1` enforces the list); `jet_strategic_bomber_equipment` is a vanilla typo, never a key.
- Localisation keys start with `IAWN_<TAG>_`, never `AIR_WING_NAME_<TAG>_*` (vanilla's namespace). The only tokens are `$NUMBER$` and `$TYPE$` in templates and `$NR$` and `$NAME$` in patterns [NAM-016].
- Author the English file only and run `build.ps1 -SyncLoc` for the other nine languages, which the game does not fall back from [LOC-001]; never edit the generated files.
- Never put a `$TOKEN$` inside a PowerShell double-quoted string or expanding here-string: it is expanded away.
- Formations are named at the level closest to a 100-aircraft wing (Finland's squadrons are the documented exception); `unique` is never padded with invented units.

## Commands beyond build.ps1
- `build.ps1 -SyncLoc` after any change under `localisation/english/`.

## Read when
| Task | Read |
|---|---|
| Authoring a nation | `docs/iawn-agent-guide.md` sections 1 to 4 |
| Thumbnail or branding | guide section 7, with the `mod-thumbnail-generator` skill |

## Engine Knowledge
- Engine facts live in the Modding Manager's register, reached through the user-level `hoi4-modding-knowledge` skill: search it before a new kind of file and before asking for a game launch, cite ids here, never write a fact into this repository.
- Topics this mod leans on: `namelists`, `localisation`, `encoding-and-syntax`, `loading-and-overrides`.
- `tests/Knowledge.Tests.ps1` runs the register's audit for this repository; it is a copy the Manager keeps current.

