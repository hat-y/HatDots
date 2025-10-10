# HatDots — Perfiles para Hyprland 

Perfiles listos para usar en Hyprland. Cada perfil vive en `HatDots/HatArch/themes/<Perfil>/` y contiene su configuración de Waybar, Hyprland, Wofi, SwayNC y wallpapers. Los perfiles se aplican con un solo comando y se pueden revertir igual de fácil.

## Requisitos

- **Hyprland**, **hypridle**, **hyprlock**
- **Waybar** (con módulo hyprland)
- **SwayNC** (daemon de notificaciones)
- **swww** (gestor de fondos)
- **Wofi**
- **grim**, **slurp**, **swappy** (para capturas de pantalla)
- **wl-clipboard**, **cliphist**
- **playerctl**, **brightnessctl**, **pavucontrol** (opcional)
- **Fuentes Nerd Fonts** (ejemplo: IosevkaTerm Nerd Font, para iconos)

### Instalación rápida en Arch Linux:

```sh
pacman -S hyprland waybar swaynotificationcenter swww wofi grim slurp swappy wl-clipboard cliphist playerctl brightnessctl pavucontrol nerd-fonts
```

## Estructura

Cada perfil está organizado de la siguiente manera:

```
HatDots/
└── HatArch/
    └── themes/
        └── <Perfil>/
            ├── waybar/
            ├── hypr/
            ├── wofi/
            ├── swaync/
            └── wallpapers/
```

- **waybar/**: configuración específica de Waybar para el perfil.
- **hypr/**: configuración de Hyprland.
- **wofi/**: temas y configuración de Wofi.
- **swaync/**: configuración de SwayNC.
- **wallpapers/**: fondos de pantalla para el perfil.

---
