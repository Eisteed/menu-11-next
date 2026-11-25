# Swin-11

## Windows 11-style application launcher for KDE Plasma 6.5+

A Plasma panel launcher modelled on the Windows 11 Start menu, based on
[Eisteed/menu-11-next](https://github.com/Eisteed/menu-11-next) (which in turn
builds on [adhec/OnzeMenuKDE](https://github.com/adhec/OnzeMenuKDE)) with
ongoing modifications: a command palette with a safe calculator, a weather
card, an update checker, workflow-aware suggestions and Qt6/KF6 fixes.

Design tweaks: more rounded search bar, no blue underline, light gray hover
background for app selection and buttons.

## Features

- Search bar across apps, files, settings and actions via KDE runners
- `/` command palette, including `/calc` arithmetic evaluation
  (bounded parser — no `eval`/`Function`, no shell involved)
- Customizable layout: List, Grid and Category views
- Sorting: A-Z, Z-A, Newest, Oldest and Type
- Folders on the All Apps page with drag-and-drop organization
- Shortcuts:
  - Ctrl + 1-9 to launch pinned apps
  - Alt + 1-9 to launch search results
  - Home / End navigation for grids
  - Tab cycle for keyboard navigation
  - Ctrl+F to focus the search field
- Workflow-aware suggestions based on time-of-day and launch frequency
- Quick launch bar with common system utilities
- Pinned/favorite applications and recent documents
- Optional weather card (Open-Meteo, latitude/longitude configurable)
- Shutdown / Restart / Sleep / Lock / Logout options

## Configuration notes

- `> command` shell execution is **disabled by default**. Enable it under
  *Configure → Advanced* only if you want a shell in the launcher.
- The weather card is off by default. When enabled, it refreshes every
  10 minutes and sends your configured latitude/longitude to Open-Meteo.
- The update checker reads the version from `metadata.json` and looks for
  GitHub releases on this fork. A fork with no releases reports that plainly.
- **Multi-panel sync:** if you place more than one Swin-11 widget on different
  panels, their settings (and favorites) are mirrored through
  `~/.config/swin11-shared.conf`. Each instance polls every 2 seconds, so a
  change made in one panel appears in the others shortly after. The "Sync
  settings across panels" checkbox is local to each instance — turn it off on
  a panel that should keep its own layout. State such as update-check
  throttling and the per-panel migration marker is not synced.

## Installation

### Requirements

- KDE Plasma 6.5+
- `kpackagetool6`
- Optional, only for the (currently unused) weather bridge plugin:
  Qt6 Core/Qml/DBus, KDE Frameworks 6, CMake 3.16+, a C++17 compiler

### From source

```bash
git clone https://github.com/ThatByteGuy/Swin-11.git
cd Swin-11
kpackagetool6 --type Plasma/Applet --install .
```

To update an existing install:

```bash
kpackagetool6 --type Plasma/Applet --upgrade .
```

The KDE Store listing installs the upstream **Menu 11 Next** widget, not this fork.

### After installing

Right-click your panel → *Add Widgets* → search for **Menu 11 Next** (the
plugin ID is still `menu.11.next`) → drag it onto your panel.

### Uninstall

```bash
kpackagetool6 --type Plasma/Applet --remove menu.11.next
```

## Development

- Static checks and calculator unit tests: `./tests/run.sh`
- Add `--smoke` to also install the applet and check journald for QML runtime
  errors (needs a running Plasma session): `./tests/run.sh --smoke`
- Runtime smoke test by hand: `QT_QPA_PLATFORM=xcb plasmawindowed menu.11.next`
- GitHub Actions runs `./tests/run.sh` on every push/PR (`.github/workflows/ci.yml`)

## Compatibility

This widget uses Plasma's **private** Kicker APIs
(`org.kde.plasma.private.kicker`, `org.kde.plasma.private.shell`) for its app
model, favorites, search runners and drag/drop. Those APIs are not stable and
can change between Plasma releases — the same fragility affecting Windows
Start-menu replacements that patch shell internals. `metadata.json` therefore
declares a minimum of Plasma 6.5, and this fork is tested on 6.8.x.

## Repository layout

- `contents/` — the installable Plasmoid
- `tests/` — static checks and smoke test
- `attic/` — preserved-but-unused work (old C++ weather bridge and planning
  docs); see `attic/README.md`

## License

GPL-2.0-or-later. See [LICENSE](LICENSE).

---

## Screenshots

![Screenshot 1](https://github.com/user-attachments/assets/d23167b0-cc04-4cad-bf1d-3a11bca9a0c7)
![Screenshot 2](https://github.com/user-attachments/assets/5d9d59bd-969a-4671-beb2-72a4c40870e0)
![Screenshot 3](https://github.com/user-attachments/assets/77176635-8cac-42a6-b913-f40e715b48be)
