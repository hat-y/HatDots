# WezTerm Workspaces - Sistema Simple

## Atajos Principales (Leader = Ctrl+Space)

### Workspaces Básicos ✅
- `Ctrl+Space + h/l` - Navegar entre workspaces
- `Ctrl+Space + w` - Selector de todos los workspaces
- `Ctrl+Space + N` - Crear nuevo workspace con nombre

### Workspaces Predefinidos ✅
- `Ctrl+Space + n` - Workspace "default" (principal)
- `Ctrl+Space + d` - Workspace "development" (desarrollo)
- `Ctrl+Space + s` - Workspace "scratch" (pruebas)

### Atajos de Proyectos ✅
- `Ctrl+Space + 1` - **Nueva tab en Projects/web** (desarrollo web)
- `Ctrl+Space + 2` - **Nueva tab normal** (trabajo general)
- `Ctrl+Space + 3` - **Nueva tab en HatDots** (configuración)
- `Ctrl+Space + 4` - **Nueva tab normal** (uso libre)

## 🚀 Cómo funciona realmente

### Paso 1: Abrir proyecto
```
Ctrl+Space + 1  → Nueva tab en C:\Users\IPF-2025\Projects\web
Ctrl+Space + 3  → Nueva tab en C:\Users\IPF-2025\HatDots
Ctrl+Space + 2  → Nueva tab vacía
```

### Paso 2: Crear tus panes
```
Ctrl+Shift+-    → Dividir verticalmente
Ctrl+Shift+D    → Dividir horizontalmente
```

### Paso 3: Navegar y trabajar
```
Ctrl+Space + ↑↓←→  → Navegar entre panes
nvim archivo.js     → Abrir editor
npm start          → Iniciar servidor
git status         → Ver cambios
```

## 💡 Ejemplo de uso real

### Desarrollo Web:
1. **`Ctrl+Space + 1`** → Abres tab en Projects/web
2. **`Ctrl+Shift+-`** → Divides verticalmente
3. **`Ctrl+Space + ←`** → Te vas al pane izquierdo
4. **Escribes:** `nvim index.js`
5. **`Ctrl+Space + →`** → Te vas al pane derecho
6. **Escribes:** `npm start`

### Configuración:
1. **`Ctrl+Space + 3`** → Abres tab en HatDots
2. **`Ctrl+Shift+-`** → Divides verticalmente
3. **`Ctrl+Space + ←`** → Pane izquierdo
4. **Escribes:** `nvim wezterm.lua`
5. **`Ctrl+Space + →`** → Pane derecho
6. **Escribes:** `wezterm reload-config`

## ✅ Ventajas de este sistema

- **Funciona siempre** - Sin comandos complejos
- **Simple** - Tabs + división manual
- **Flexible** - Tú decides el layout
- **Rápido** - Nuevas teclas al instante

## 🎯 Atajos adicionales útiles

- `Ctrl+Space + -` - Dividir verticalmente
- `Ctrl+Space + =` - Dividir horizontalmente
- `Ctrl+Space + x` - Cerrar pane actual
- `Ctrl+Space + z` - Maximizar/restaurar pane
- `Ctrl+Shift+c` - Copiar
- `Ctrl+Shift+v` - Pegar

## Gestión Avanzada
- `Ctrl+Space + m` - Mover pane actual a nuevo workspace
- `Ctrl+Space + Shift+r` - Renombrar workspace actual

## Navegación de Panes (Leader + flechas)
- `Ctrl+Space + ↑/↓/←/→` - Navegar entre panes
- `Ctrl+Space + -` - Dividir verticalmente
- `Ctrl+Space + =` - Dividir horizontalmente

## Personalización de Proyectos

Para agregar nuevos proyectos, edita `wezterm.lua`:

```lua
local projects = {
  tu-proyecto = {
    path = "C:\\ruta\\a\\tu\\proyecto",
    layout = "nombre-layout",
    description = "Descripción del proyecto"
  }
}
```

## Layouts Disponibles
- `webdev` - Grid 2x2 para desarrollo web
- `datascience` - Notebook + plots + terminal
- `sysops` - Terminal principal + logs + monitor
- `config` - Editor + terminal simple

## Consejos
1. Los workspaces persisten entre sesiones
2. Puedes tener múltiples proyectos abiertos simultáneamente
3. Usa `Ctrl+Space + w` para ver todos los workspaces disponibles
4. La barra de estado muestra: `WS: nombre | Tabs: X | Panes: Y`