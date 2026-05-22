# Menu 11 Next

## Windows 11 menu launcher for KDE Plasma 6.5
Based on [menu 11 plasma6,](https://github.com/adhec/OnzeMenuKDE), with some tweaks & modifications to make it fully working with the most recent kde plasma.
Small design tweaks (moure rounded search bar, no blue underline, light gray background hover app select / buttons)


## Features
- Search bar: auto-selects first result, supports `/` command mode, `/calc` math evaluation
- Customizable layout: List, Grid, and Category view modes
- Extensive sorting: A-Z, Z-A, Newest, Oldest, and Type
- Organize apps: Folder support for All Apps page with drag-and-drop
- Shortcuts:
  - Ctrl + 1-9 to launch pinned apps
  - Alt + 1-9 to launch search results
  - Home / End navigation for grids
  - Tab cycle for keyboard navigation
- Workflow-aware: Adaptive suggestions based on time and frequency
- Contextual Actions: Quick launch bar with common system utilities
- Pinned/Favorite applications
- Recent documents & files support
- Shutdown / Restart / Sleep / Lock / Logout options

## Fixed
- Alphabetical slider navigation in All Apps
- Search result overlap and scrolling issues
- Correct height calculation for multi-column grids
- Focus ring and tab-cycle navigation
- Plugin-based search provider stability
- Folder management UI and drag-and-drop interactions
- Corrected role mapping for Qt6 compatibility

## Installation

### Requirements
- KDE Plasma 6.5+
- `cmake`, `extra-cmake-modules`, `kpackagetool6`

### Method 1: Install via KDE Store (Recommended)
Search for **Menu 11 Next** in *System Settings → Get New Widgets*.

## Method 2: install via source
0. Download Github project - Code - download zip
1. Right click Select Add Widgets... from desktop menu.
2. Select Get New Widgets -> Install widget from local file
3. Search for the downloaded zip

OR from CLI

```bash
# Clone the repository
git clone https://github.com/Eisteed/menu-11-next.git
cd menu-11-next

# Install the widget
kpackagetool6 --install . --type Plasma/Applet
```

### Method 3: Install via plasmapkg2 (older systems)
```bash
plasmapkg2 --install . --type Plasma/Applet
```

### After Installing
1. Right-click your taskbar → *Add Widgets*
2. Search for **Menu 11 Next**
3. Drag it onto your panel

### Uninstall

```bash
kpackagetool6 --type Plasma/Applet --remove menu.11.next
```

---

## Screenshot
![Screenshot 1](https://github.com/user-attachments/assets/d23167b0-cc04-4cad-bf1d-3a11bca9a0c7)
![Screenshot 2](https://github.com/user-attachments/assets/5d9d59bd-969a-4671-beb2-72a4c40870e0)
![Screenshot 2](https://github.com/user-attachments/assets/77176635-8cac-42a6-b913-f40e715b48be)
