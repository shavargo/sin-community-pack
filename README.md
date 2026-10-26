# SiN Community Asset Pack

Clean, sanitized community multiplayer asset package for **SiN Reloaded** and **Classic SiN / Wages of SiN**.

Automated GitHub Actions builds assemble this pure community asset tree into drop-in SPAK archives:
- **`pak4.sin`**: Drop-in archive for **SiN Reloaded** (Nightdive remaster).
- **`pak9_community.sin`**: Drop-in archive for **Classic SiN 1998 / Wages of SiN / Source Ports**.

---

## Overview

The original SiN Community Pack bundled custom multiplayer content, but also mixed in official commercial expansion files (*Wages of SiN* and CTF expansion packs) and legacy client binaries.

This repository collects and preserves **strictly pure community-created assets** recovered from historic SiN community hubs (Ritualistic, PlanetSiN, and Rocket Arena SiN leagues), verified via binary and file-path diffs against official retail releases (`base/`, `2015/`, and `ctf/`):

| Asset Type | Count | Description |
|---|---|---|
| **Maps (`maps/`)** | **36** | Community Rocket Arena, Deathmatch, and CTF maps (`.bsp`, `.pth`, `.scr`, `.json`) |
| **Audio (`sound/`, `music/`)** | **120+** | Custom map audio plus classic multi-kill announcer packs (Blade, Elexis, JC, Custom) |
| **Models (`models/`)** | **60+** | Community weapons, player models, and custom props (`.sam`, `.sbm`, `.def`) |
| **Textures & Art (`textures/`, `pics/`)** | **85+** | Custom level textures and map preview shots (`.swl`, `.tga`, `.pal`) |
| **Total Archive Size** | **~60 MB** | Zero proprietary base game or expansion assets |

---

## Installation

### For SiN Reloaded (Nightdive Remaster)
1. Download **`pak4.sin`** from the [Latest Release](../../releases/latest).
2. Place `pak4.sin` directly into your `SiN Reloaded/base/` directory alongside `pak0.sin` through `pak3.sin`:
   ```text
   SiN Reloaded/
   └── base/
       ├── pak0.sin
       ├── pak1.sin
       ├── pak2.sin
       ├── pak3.sin
       └── pak4.sin
   ```
3. Launch SiN Reloaded directly through Steam. The engine mounts `pak4.sin` automatically, and all community maps appear in the in-game Multiplayer menu with proper titles and authors.

### For Classic SiN / Wages of SiN / Source Ports
1. Download **`pak9_community.sin`** from the [Latest Release](../../releases/latest).
2. Place `pak9_community.sin` into your game's `base/` directory alongside `pak0.sin`:
   ```text
   SiN/
   └── base/
       ├── pak0.sin
       └── pak9_community.sin
   ```
3. Launch the game or dedicated server. The engine automatically mounts `pak9_community.sin` and makes the community maps and announcer sounds available.

---

## Map List

See [`maplist.txt`](maplist.txt) for the complete list:
- **Rocket Arena & Tournament (19 maps)**: `hex_ra2`, `hex_ra4`, `hex_ra5`, `jungle_ra`, `RA101`, `ra3map2`, `ra3map3`, `ra3map7`, `RAbeam`, `ra_cliff`, `ra_icetech1`, `ra_palm_beach`, `ra_river`, `ra_sands1a`, `ra_sands2a`, `ra_sands3a`, `ra_stone`, `wickra`, `wickra2`
- **Deathmatch (12 maps)**: `Arena`, `city`, `darkdm1`, `dm_vertical`, `flameorama`, `highiron`, `MortaL`, `Posey9`, `Sin1kcd`, `Sin1q3a`, `Sin1rock`, `trap`
- **Capture The Flag (5 maps)**: `BaSctf1`, `ctf_prox`, `kungfuctf`, `millenium`, `spryctf`

---

## Building Locally

You can build the archives locally using PowerShell (`pwsh`) on Windows, Linux, or macOS:

```powershell
pwsh ./tools/pack_spak.ps1 -InputDir . -OutputFile dist/pak4.sin
```

---

## License & Disclaimer

All included maps, models, textures, and sounds are community-created assets authored by the SiN multiplayer community between 1999 and 2020. *SiN* is a trademark of Ritual Entertainment / Nightdive Studios / Activision. No commercial retail assets or binaries are distributed in this repository.
