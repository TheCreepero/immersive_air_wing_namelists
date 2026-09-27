# Steam Workshop Description Guidelines & Reference

This document serves as an instruction and reference guide for maintaining and updating the Steam Workshop description for **Immersive Air Wing Names Expanded**.

---

## Core Rules & Constraints

1. **No Emojis**: Strictly avoid adding any emojis or emoticons to the description.
2. **Character & Length Limits**:
   - Steam Workshop descriptions have a strict character limit (~17,000 characters raw BBCode).
   - Keep bullet points concise and avoid lengthy narrative blocks.
   - Monitor the overall character count of the BBCode text when adding new nations.
3. **Writing Style & Tone**:
   - Keep the tone concise, informative, direct, and enthusiastic, matching the author's original voice.
   - Use straightforward bullet points and structured section headings.
   - Do not over-embellish or use marketing buzzwords.
4. **Preserve Custom Author Sections**:
   - Keep the header pitch, companion mod links, and Info section consistent with the rest of the Immersive Expanded series.
   - When updating the workshop description for newly implemented nations, update the `[h1]Included nations:[/h1]` block and the Repository Cross-Reference table.
5. **No Speculative Planned Section**:
   - Do not include speculative 'Planned' sections in the public description.
6. **Language & Grammar**:
   - Fix typos, misspellings, formatting anomalies, or broken English.
   - Use proper diacritics and accents for historical air wing designations.
7. **Steam Formatting (BBCode)**:
   - Always format the description using Steam's supported BBCode tags:
     - Section headings: `[h1]Heading Text[/h1]`
     - Bold text: `[b]...[/b]`
     - Italics: `[i]...[/i]`
     - URLs: `[url=https://...]link text[/url]`
     - Lists: Standard hyphen bullets (`- Item`).
   - Ensure clean line breaks between sections and blocks.

---

## Structure of the Description

1. **Header Pitch & Companion Mods**:
   - Concise authentic intro noting historical air wing coverage, and links to companion mods (*Immersive Namelists Expanded* and *Immersive Ship Names Expanded*).
2. **[h1]Info:[/h1]**:
   - Save game compatibility.
   - Road to 56 (RT56) and vanilla compatibility.
   - By Blood Alone (BBA) air designer and non-DLC compatibility.
   - Permissions note.
3. **[h1]Included nations:[/h1]**:
   - Grouped by nation in bold (`[b]Nation[/b]`).
   - Concise summary of archetype coverage (fighters, CAS, naval bombers, heavy fighters, tactical/strategic bombers, reconnaissance, transports, carrier aviation).
4. **Call to Action**:
   - Prompt to rate, favorite, and share suggestions in discussions.

---

## Repository Cross-Reference (`common/units/names/`)

| File | Nation | Tag | Status in Description |
| :--- | :--- | :--- | :--- |
| `iawn_FIN_names.txt` | Finland | `FIN` | Included (Fighters, CAS, NAV, Heavy Fighters, Tactical/Strategic Bombers, Transports, Carrier Wings) |

---

## Active Steam Workshop Description (BBCode Format)

```bbcode
More namelists! Historically authentic air wing, squadron, and group namelists for Hearts of Iron IV.

Check out my other mods:
- [url=https://steamcommunity.com/workshop/filedetails/?id=2967389401]Immersive Namelists Expanded[/url]
- [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3807415216]Immersive Ship Names Expanded[/url]

If you have any ideas for air wing namelists, please leave them in the discussion thread!

[h1]Info:[/h1]
- [b]Save Game Compatible:[/b] Can be added or removed from ongoing games without issues.
- [b]Compatible with Road to 56 (RT56) and vanilla.[/b]
- Fully compatible with the By Blood Alone (BBA) air designer as well as non-DLC air systems.
- No hard incompatibilities. Namelists from other mods might override namelists from this mod in some cases.
- Feel free to use this mod however you wish.

[h1]Included nations:[/h1]
[b]Finland[/b]
- Land Fighters & Interceptors: Historic fighter squadrons (e.g. [i]Hävittäjälentolaivue 24[/i], [i]26[/i], [i]28[/i], [i]30[/i], [i]32[/i], [i]34[/i]) and wartime reserve/training units.
- Close Air Support (CAS): Dedicated dive bomber and ground support squadrons ([i]Rynnäkkölentolaivue[/i], [i]Syöksypommituslaivue[/i], [i]Maataistelulentolaivue[/i]).
- Naval Bombers: Maritime torpedo and patrol units ([i]Merilentolaivue[/i], [i]Torpedolentolaivue[/i], [i]Lentolaivue 6[/i]).
- Medium & Heavy Aircraft: Heavy fighters ([i]Raskas Hävittäjälaivue[/i]), tactical bomber squadrons ([i]Pommituslentolaivue[/i]), and scout wings ([i]Tiedustelulentolaivue[/i]).
- Strategic & Transport Aviation: Heavy long-range bombers ([i]Raskas Pommituslentolaivue[/i]), maritime patrol ([i]Merivalvontalaivue[/i]), and air transport ([i]Kuljetuslentolaivue[/i]).
- Carrier Aviation: Full carrier-capable fighter, dive bomber, and torpedo squadrons.

If you enjoy the mod, please give it a thumbs up and favorite!
```