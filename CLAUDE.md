# Immersive Air Wing Namelists (IAWN) Development Rules

> This is the Claude Code counterpart to `GEMINI.md` (used by Google Antigravity). Both files describe the same project rules — when one changes, update the other to match.

## 1. File Structure & Engine Path
- All air wing namelist files must reside in `common/units/names/`.
- Air wing names are scoped by country tag at root:
  ```pdx
  <TAG> = {
      air_wing_names_template = <FALLBACK_LOCALIZATION_KEY>

      <air_archetype> = {
          prefix = ""
          generic = { "..." }
          generic_pattern = <LOCALIZATION_KEY>
          unique = {
              "..." "..."
          }
      }
  }
  ```
- All content files in `common/units/names/` must be saved in **UTF-8 without BOM** and maintain strictly balanced curly brackets `{}` and quotes `"`.

## 2. Airframe & Archetype Taxonomy (Game-File Verified)
In Hearts of Iron IV, air wings can only be named through archetype (`#Air wings can only be named through archetype`, verified in `common/units/names/*.txt`). When authoring national lists, ensure complete coverage across all verified airframe archetypes:

### Light Airframes (Small)
- `small_plane_airframe` — Land Fighters & Interceptors
- `small_plane_cas_airframe` — Close Air Support (CAS)
- `small_plane_naval_bomber_airframe` — Naval Bombers (NAV)
- `small_plane_suicide_airframe` — Suicide Craft / Kamikaze (e.g., Japan)
- `cv_small_plane_airframe` — Carrier Fighters
- `cv_small_plane_cas_airframe` — Carrier CAS
- `cv_small_plane_naval_bomber_airframe` — Carrier NAV
- `cv_small_plane_suicide_airframe` — Carrier Suicide Craft

### Medium Airframes
- `medium_plane_fighter_airframe` — Heavy Fighters / Twin-Engine Interceptors
- `medium_plane_airframe` — Tactical Bombers
- `medium_plane_scout_plane_airframe` — Reconnaissance / Scout Planes

### Heavy Airframes & Logistics (Large)
- `large_plane_airframe` — Strategic Bombers
- `large_plane_maritime_patrol_plane_airframe` — Maritime Patrol Aircraft
- `transport_plane_equipment` — Airborne Transport Planes

### Advanced / Rocket & Jet Era
- `rocket_interceptor_equipment` — Rocket Interceptors
- `jet_fighter_equipment` — Jet Fighters
- `jet_tac_bomber_equipment` — Jet Tactical Bombers
- `jet_strat_bomber_equipment` — Jet Strategic Bombers

`jet_strategic_bomber_equipment` is **not** a valid archetype (it is a typo in vanilla's SOV file, not an alias). Never use it as a key; the only valid spelling is `jet_strat_bomber_equipment`.

## 3. Historical & Linguistic Standards
- **Historical Plausibility over Rigid Accuracy**: As with naval namelists, prioritize immersion and gameplay scalability. While historical lists anchor unique squadrons (e.g., Finnish Lentolaivue, British RAF Squadrons, German Geschwader), plausible generic templates (`generic = { ... }` with authentic sequential patterns) ensure players who produce large wartime air forces never fall back to generic "1st Fighter Wing" labels.
- **Linguistic Authenticity**: Preserve native orthography, special characters, and diacritics (e.g., `ä`, `ö`, `é`, `ø`, `ß`).
- **Prefix Consistency**: When `prefix = "..."` is used, always include a trailing space if it should be separated from the formation title.
- **Unit Scale**: New nations name formations at the level closest to a 100-aircraft wing: Geschwader (Germany), aviation division (USSR), Stormo (Italy), Flygflottilj (Sweden), RAF Wing/Group (Britain), Hikōdan/Kōkūtai (Japan). Finland's squadron-level list (Lentolaivue) is a documented exception: Finland had only five flying regiments (Lentorykmentti), too few to fill the pools.
- **Orthography**:
  - Soviet names use Latin transliteration, with ordinals carrying the `-ya` (feminine) or `-y` (masculine) ending of the unit noun.
  - Japanese names use Hepburn romaji with macrons (e.g., `Kōkūtai`, `Hikōdan`) and `Dai-N` numbering.
  - Honorific and nickname designations go in single quotes inside the name; double quotes would terminate the pdx string.
- **No Padding**: Never invent units to pad a pool. If a nation has few historical formations for an archetype, keep `unique` short (or empty) and let `generic` carry the rest.

## 4. Localisation & Encoding Rules
- **One Pair of Files per Nation**: `common/units/names/iawn_<TAG>_names.txt` plus `localisation/english/iawn_<TAG>_l_english.yml`. The tag in the filename must equal the single root tag block in the namelist.
- **Key Namespace**: Every key this mod defines starts with `IAWN_<TAG>_`: `IAWN_<TAG>_FALLBACK` for `air_wing_names_template` and `IAWN_<TAG>_<PATTERN>` for each `generic_pattern` (e.g., `IAWN_FIN_FALLBACK`, `IAWN_FIN_GENERIC`). Never use `AIR_WING_NAME_<TAG>_*`: vanilla owns that namespace (including `AIR_WING_NAME_FIN_FALLBACK`), so reusing it would clash with vanilla keys.
  ```yaml
  l_english:
   IAWN_<TAG>_FALLBACK: "$NUMBER$. <Formation>"
   IAWN_<TAG>_GENERIC: "$NAME$ $NR$"
  ```
- **Token Rule** (only these tokens exist; there is no ordinal token):
  - `air_wing_names_template` strings use `$NUMBER$` (sequential formation number) and optionally `$TYPE$` (equipment archetype display name).
  - `generic_pattern` strings use `$NR$` (sequential formation number) and `$NAME$` (string selected from the `generic = { ... }` pool).
- **All Languages**: The game does not fall back to English for a missing key, so every vanilla language folder needs the keys (`braz_por`, `french`, `german`, `japanese`, `korean`, `polish`, `russian`, `simp_chinese`, `spanish`). Author only the English file, then run `.\build.ps1 -SyncLoc` to generate `localisation/<lang>/iawn_<TAG>_l_<lang>.yml` (English text, header changed to `l_<lang>:`) for the other nine languages and to remove stale ones. Commit the generated files; never edit them by hand.
- **PowerShell Quoting**: A PowerShell double-quoted string or expanding here-string treats `$NR$`, `$NAME$`, etc. as variables and silently deletes them, leaving broken values such as `"$ $"`. Never put a `$TOKEN$` in one, in scripts, tests or one-off commands. Use single quotes, or read and write file bytes.
- **Paradox Encoding Invariants**:
  - Script files (`common/**/*.txt`): **UTF-8 without BOM**.
  - Localisation files (`localisation/**/*.yml`): **UTF-8 with BOM** (standard Clausewitz engine requirement), first line `l_<language>:`.

## 5. Build, Validation & Testing Protocol
Always validate changes before completing tasks:
1. **Localisation Sync** (after any change to `localisation/english/`):
   ```powershell
   powershell -File .\build.ps1 -SyncLoc
   ```
2. **Syntax & Bracket Validation**:
   ```powershell
   powershell -File .\build.ps1 -ValidateOnly
   ```
3. **Automated Pester Tests**:
   ```powershell
   powershell -File .\build.ps1 -Test
   ```
4. **Deployment / DevLink for In-Game Testing**:
   - `.\build.ps1 -Deploy` — Copy mod files to the Paradox user mod folder.
   - `.\build.ps1 -DevLink` — Create zero-copy NTFS junction for live hot-reloading.

## 6. Repository Architecture & Single-Root Guidelines
- **Single-Root Architecture**:
  - Unified Workspace Root (`C:\dev\immersive-air-wing-namelists\`): The workspace root is the Git repository root (`.git/`).
  - All mod content (`descriptor.mod`, `thumbnail.png`, `common/`, `localisation/`), automation (`build.ps1`), test suites (`tests/`), assets (`assets/`), and metadata reside in this unified repository structure.
- **Git Working Tree Invariant**:
  - After modifying rules, skills, or game content, verify that changes appear in the Git working tree:
    ```powershell
    git status
    ```

## 7. Branding & Thumbnail Standards
- **Namelist Mod Suite Visual Taxonomy**:
  - **Ground / Divisions** (*Immersive Namelists Expanded*): `--theme amber` (`#E5A93C`)
  - **Naval / Ships** (*Immersive Ship Names Expanded*): `--theme cyan` (`#63B3ED`)
  - **Aviation / Air Wings** (*Immersive Air Wing Namelists*): `--theme paradox_red` (`#DE5646`), accenting `AIR WING`
- **Asset Directory Invariants**:
  - `assets/thumbnail_raw.png`: Original, uncompressed high-resolution artwork (1920×1440).
  - `assets/thumbnail_master.png`: Cropped 512×512 branded master.
  - `thumbnail.png`: Active in-game/Steam Workshop distribution asset (< 1 MB).
- **Thumbnail Generation**: Use the `mod-thumbnail-generator` skill (not an external script) with the following parameters:
  - descriptor: `descriptor.mod`
  - title: `IMMERSIVE\nAIR WING\nNAMELISTS`
  - background image: `assets\thumbnail_raw.png`
  - theme: `paradox_red`
  - accent match: `AIR WING`
  - text position: `top`
  - game: HOI4
  - output dirs: `.`, `assets`
  - preview filename: `thumbnail.png`
