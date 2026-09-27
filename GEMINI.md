# Immersive Air Wing Namelists (IAWN) Development Rules

> Claude Code uses `CLAUDE.md` as its counterpart to this file. Both files describe the same project rules — when one changes, update the other to match.

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
- `jet_strat_bomber_equipment` — Jet Strategic Bombers (also aliased as `jet_strategic_bomber_equipment`)

## 3. Historical & Linguistic Standards
- **Historical Plausibility over Rigid Accuracy**: As with naval namelists, prioritize immersion and gameplay scalability. While historical lists anchor unique squadrons (e.g., Finnish Lentolaivue, British RAF Squadrons, German Geschwader), plausible generic templates (`generic = { ... }` with authentic sequential patterns) ensure players who produce large wartime air forces never fall back to generic "1st Fighter Wing" labels.
- **Linguistic Authenticity**: Preserve native orthography, special characters, and diacritics (e.g., `ä`, `ö`, `é`, `ø`, `ß`).
- **Prefix Consistency**: When `prefix = "..."` is used, always include a trailing space if it should be separated from the formation title.

## 4. Localisation & Encoding Rules
- Any custom `generic_pattern` or `air_wing_names_template` keys must be defined in `localisation/english/` (e.g., `iawn_names_l_english.yml`).
- **Paradox Encoding Invariants**:
  - Script files (`common/**/*.txt`): **UTF-8 without BOM**.
  - Localisation files (`localisation/**/*.yml`): **UTF-8 with BOM** (standard Clausewitz engine requirement).
- Localization format tokens:
  - `$NR$` / `$NUMBER$` — Sequential formation number.
  - `$NAME$` — String selected from the `generic = { ... }` pool.
  - `$TYPE$` — Equipment archetype display name.

## 5. Build, Validation & Testing Protocol
Always validate changes before completing tasks:
1. **Syntax & Bracket Validation**:
   ```powershell
   powershell -File .\build.ps1 -ValidateOnly
   ```
2. **Automated Pester Tests**:
   ```powershell
   powershell -File .\build.ps1 -Test
   ```
3. **Deployment / DevLink for In-Game Testing**:
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
- **Canonical Generation Command**:
  ```powershell
  python "W:\Antigravity\Mod Thumbnail Generator\generate_branding.py" `
    --descriptor "descriptor.mod" `
    --title "IMMERSIVE`nAIR WING`nNAMELISTS" `
    --bg-image "assets\thumbnail_raw.png" `
    --theme paradox_red `
    --accent-match "AIR WING" `
    --text-pos top `
    --hoi4 `
    --out-dirs ".,assets" `
    --preview-filename "thumbnail.png"
  ```

