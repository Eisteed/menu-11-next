# Menu 11 Next

## Windows 11 menu launcher for KDE Plasma 6
Based on [menu 11 plasma6,](https://github.com/adhec/OnzeMenuKDE), with some tweaks & modifications to make it fully working with the most recent kde plasma.
Small design tweaks (moure rounded search bar, no blue underline, light gray background hover app select / buttons)


## Features
- Search bar auto select first result / press enter to start.
- Custom menu position
- Favorite / Pinned applications
- Recent documents
- View more recent document opens recentlyused:/files/
- Shutdown / Restart / Sleep / Lock on bottom right
- User profile / home folder / settings on bottom left

## Fixed
- Arrows UP & DOWN navigation in search results
- 0 width error on first start
- shutdown / restart buttons

## Installation

### Requirements
- KDE Plasma 6+
- `kpackagetool6` (included with KDE)

### Method 2: Manual Install from Source

```bash
# Clone the repository
git clone https://github.com/AlphaGlider25/Swin-11.git
cd Swin-11

# Install the widget
kpackagetool6 --install package/ --type Plasma/Applet
```

To update an existing install:

```bash
kpackagetool6 --upgrade package/ --type Plasma/Applet
```

### Method 3: Install via plasmapkg2 (older systems)

```bash
plasmapkg2 --install package/ --type Plasma/Applet
```

### After Installing
1. Right-click your taskbar → *Add Widgets*
2. Search for **Menu 11 Next**
3. Drag it onto your panel

### Uninstall

```bash
kpackagetool6 --remove com.github.alphglider25.menu11next --type Plasma/Applet
```

---

## Screenshot
![Screenshot 1](https://eisteed.com/linux/menu-11-next/Win11-Next-Demo1.png)

![Screenshot 2](https://eisteed.com/linux/menu-11-next/Win11-Next-Demo2.png)
