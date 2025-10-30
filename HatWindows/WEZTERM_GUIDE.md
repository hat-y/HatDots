# Guía de Configuración WezTerm (Windows)

Esta guía explica la configuración mejorada de WezTerm para Windows incluida en HatDots.

## 🎨 **Características Visuales**

### Tema Kanagawa Dragon
- **Colores consistentes**: Fondo `#1F1F28` (waveBlack) en lugar de negro puro
- **High contrast**: Buena legibilidad con colores coordinados
- **Tab bar**: Oculta automáticamente con una sola pestaña
- **Opacidad**: 95% para efecto translúcido sutil

### Fuente y Rendimiento
- **Font**: IosevkaTerm Nerd Font Mono
- **Size**: 18pt (ajustable)
- **FPS**: 120 para animaciones fluidas
- **Frontend**: OpenGL para mejor rendimiento en Windows

## ⌨️ **Atajos de Teclado**

### Leader Key (Ctrl+Space)
Simula el comportamiento de tmux:

```bash
Ctrl+Space h/l        # Cambiar workspace
Ctrl+Space ←↑↓→       # Navegar entre panes
Ctrl+Space -          # Dividir verticalmente
Ctrl+Space +          # Dividir horizontalmente
Ctrl+Space x          # Cerrar pane actual
Ctrl+Space z          # Maximizar/restaurar pane
Ctrl+Space r          # Recargar configuración
Ctrl+Space f          # Buscar en pane actual
```

### Atajos del Sistema

#### Navegación
```bash
Ctrl+Tab              # Siguiente tab
Ctrl+Shift+Tab        # Tab anterior
Ctrl+Shift+t          # Nueva tab
Ctrl+Shift+w          # Cerrar tab (con confirmación)
```

#### Fuente y Zoom
```bash
Ctrl+=                # Aumentar tamaño de fuente
Ctrl+-                # Disminuir tamaño de fuente
Ctrl+0                # Restablecer tamaño de fuente
```

#### Copiado y Pegado
```bash
Ctrl+Shift+c          # Copiar al portapapeles
Ctrl+Shift+v          # Pegar desde portapapeles
Shift+Enter           # Enviar escape + Enter
```

#### Scrolling
```bash
Ctrl+PageUp           # Scroll media página arriba
Ctrl+PageDown         # Scroll media página abajo
```

### Atajos Inteligentes
WezTerm detecta automáticamente si estás en Vim/Neovim:

```bash
Ctrl+h/l              # En Vim: mover cursor
                      # Fuera de Vim: cambiar workspace
```

## 🔧 **Comportamiento de Ventana**

### Inicialización
- **Tamaño inicial**: 120x30 caracteres
- **Decoraciones**: Solo redimensionamiento (sin bordes extra)
- **Confirmación**: Siempre pregunta antes de cerrar
- **Sin auto-resize**: Cambiar fuente no afecta tamaño de ventana

### Launch Menu
Presiona `Ctrl+Shift+L` o haz clic derecho para acceder:

- **PowerShell** (por defecto)
- **PowerShell (Admin)** - con privilegios elevados
- **Command Prompt** - cmd tradicional

## 🎯 **Integración con Neovim**

### Detección Automática
WezTerm detecta automáticamente:
- `vim.exe`, `nvim.exe`
- `vim`, `nvim` (WSL/Linux)
- `neovim`, `nvim` (instancias con otros nombres)

### Comportamiento
- **Dentro de Neovim**: Los atajos se envían a Neovim
- **Fuera de Neovim**: Los atajos ejecutan acciones de WezTerm
- **Transición fluida**: Sin conflictos entre ambos sistemas

## 🚀 **Rendimiento y Optimización**

### Configuración de Rendimiento
```lua
config.max_fps = 120           # Máxima fluidez
config.animation_fps = 60      # Animaciones suaves
config.front_end = "OpenGL"    # Mejor rendimiento en Windows
config.cursor_blink_rate = 800 # Parpadeo de cursor suave
```

### Recomendaciones
1. **Hardware acceleration**: Asegúrate que OpenGL funcione correctamente
2. **Font rendering**: IosevkaTerm Nerd Font Mono ofrece mejor rendimiento
3. **Transparencia**: Si afecta rendimiento, ajusta `window_background_opacity`

## 🛠️ **Personalización**

### Cambiar Colores
Edita `wezterm.lua` y modifica la sección `config.colors`:

```lua
config.colors = {
    foreground = "#tu-color",
    background = "#tu-fondo",
    -- ... otros colores
}
```

### Añadir Atajos Personalizados
Agrega a `config.keys`:

```lua
{
    key = "tu-tecla",
    mods = "TUS-MODS",
    action = act.TuAccion
}
```

### Modificar Menú de Launch
Edita `config.launch_menu` para agregar tus shells preferidos.

## 🔍 **Debug y Troubleshooting**

### Debug Overlay
`Ctrl+Shift+F12` - Muestra información de depuración:
- Procesos activos
- Configuración cargada
- Información de rendimiento

### Problemas Comunes

#### Font no funciona
```bash
# Instalar la fuente
winget install NerdFonts.FiraCode
# O descargar desde https://www.nerdfonts.com/
```

#### Atajos no responden
- Verifica que no entren en conflicto con otras aplicaciones
- Usa `Ctrl+Shift+F12` para ver configuración activa

#### Performance lenta
- Cambia `front_end = "Software"` si OpenGL causa problemas
- Reduce `max_fps` a 60 si hay lag

## 📝 **Notas de Configuración**

- **Workspace indicator**: Muestra workspace actual en la esquina superior derecha
- **Bell deshabilitado**: Sin sonidos de notificación
- **No scrollbar**: Interfaz limpia sin barra de scroll
- **Tab bar auto-hide**: Solo visible con múltiples pestañas

Esta configuración ofrece una experiencia terminal moderna, eficiente y bien integrada con Neovim, optimizada para desarrollo en Windows.