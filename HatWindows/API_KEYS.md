# Configuración de Claves API para Plugins de IA

Este documento explica cómo configurar las claves API necesarias para los plugins de IA en tu configuración de Neovim para Windows.

## Plugins de IA Configurados

### 1. Avante.nvim (principal)
- **Provider por defecto**: Gemini
- **Configuración**: `HatWindows/nvim/lua/plugins/avante.lua`

### 2. Claude Code
- **Configuración**: `HatWindows/nvim/lua/plugins/claude-code.lua`

### 3. Gemini CLI
- **Configuración**: `HatWindows/nvim/lua/plugins/gemini-cli.lua`

## Variables de Entorno Requeridas

### Para Gemini (Avante)
```powershell
# Agregar a tu perfil de PowerShell
$env:GEMINI_API_KEY = "tu-api-key-aqui"
```

### Para Claude Code
```powershell
$env:ANTHROPIC_API_KEY = "tu-claude-api-key-aqui"
```

### Para OpenAI (opcional, si cambias el provider en Avante)
```powershell
$env:OPENAI_API_KEY = "tu-openai-api-key-aqui"
```

## Configuración Permanente en Windows

### Opción 1: Variables de Entorno del Sistema
1. Abre "Configuración del sistema" → "Propiedades" → "Variables de entorno"
2. Agrega las variables de entorno a nivel de usuario
3. Reinicia PowerShell

### Opción 2: En tu Perfil de PowerShell
Agrega estas líneas a tu perfil de PowerShell (`$PROFILE`):

```powershell
# API Keys para plugins de IA
$env:GEMINI_API_KEY = "tu-gemini-key"
$env:ANTHROPIC_API_KEY = "tu-claude-key"
$env:OPENAI_API_KEY = "tu-openai-key"  # opcional
```

## Cómo Obtener las Claves

### Gemini API Key
1. Ve a [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Crea una nueva API key
3. Copia y pega en tu configuración

### Claude API Key
1. Ve a [Anthropic Console](https://console.anthropic.com/)
2. Regístrate y crea una API key
3. Copia y pega en tu configuración

### OpenAI API Key (opcional)
1. Ve a [OpenAI Platform](https://platform.openai.com/api-keys)
2. Crea una nueva API key
3. Copia y pega en tu configuración

## Verificación

Después de configurar, verifica que las claves estén disponibles:

```powershell
# Verificar variables de entorno
Get-ChildItem Env: | Where-Object Name -like "*API*"
```

Luego reinicia Neovim y prueba los plugins:
- `<leader>aa` - Toggle Avante
- `<leader>ac` - Toggle Claude Code

## Notas de Seguridad

- Nunca commits tu archivo `.env` o claves API directamente
- Considera usar un gestor de secretos si trabajas en equipo
- Las claves se almacenan como variables de entorno locales