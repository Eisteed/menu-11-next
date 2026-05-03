# Menu 11 Next

## Windows 11 menu launcher for KDE Plasma 6.5
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
- KDE Plasma 6.5+
- `cmake`, `extra-cmake-modules`, `kpackagetool6`

### Method 1: Install via KDE Store (Recommended)
Search for **Menu 11 Next** in *System Settings → Get New Widgets*.

## Method 2: install via source
```bash
# Clone the repository
git clone https://github.com/Eisteed/menu-11-next.git
cd menu-11-next

# Install the widget
kpackagetool6 --install package/ --type Plasma/Applet
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
kpackagetool6 --type Plasma/Applet --remove menu.11.next
```

---

## Screenshot
![Screenshot 1] <img width="613" height="730" alt="Screenshot_20260501_224736" src="https://github.com/user-attachments/assets/d23167b0-cc04-4cad-bf1d-3a11bca9a0c7" />

![Screenshot 2] <img width="611" height="728" alt="Screenshot_20260501_224717" src="https://github.com/user-attachments/assets/e92a5883-11f1-4dd7-977b-2217dcef973d" />

![Screenshot 2] <img width="605" height="721" alt="Screenshot_20260501_224749" src="https://github.com/user-attachments/assets/f9ea63b1-664e-48f5-ad38-9d201548a1e3" />

