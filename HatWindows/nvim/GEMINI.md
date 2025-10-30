# Gemini CLI Integration for Neovim (HatWindows)

This document outlines how to effectively use the Gemini CLI within your Neovim setup, specifically tailored for the `HatWindows` environment and leveraging `LazyVim` for plugin management.

## 1. Configuración del Plugin `gemini-cli.lua`

Asegúrate de que el plugin `gemini-cli.lua` esté correctamente configurado en tu `LazyVim`.

**Ruta esperada:** `lua/plugins/gemini-cli.lua`

Un ejemplo básico de configuración podría ser:

```lua
return {
  "your-gemini-cli-plugin-repo/gemini-cli.nvim", -- Reemplaza con el repositorio real si es un plugin externo
  name = "gemini-cli",
  cmd = { "Gemini" }, -- Comando principal para invocar Gemini
  config = function()
    require("gemini-cli").setup({
      -- Aquí puedes añadir opciones de configuración específicas de Gemini CLI
      -- Por ejemplo, si el plugin permite configurar la API key directamente o el modelo a usar.
      -- api_key = os.getenv("GEMINI_API_KEY"), -- Se recomienda usar variables de entorno
      -- default_model = "gemini-pro",
    })
  end,
}
```

**Importante:** Si tu plugin `gemini-cli.lua` es un archivo local y no un repositorio de LazyVim, asegúrate de que esté cargado correctamente. LazyVim cargará automáticamente los archivos en `lua/plugins/`.

## 2. Configuración de la API Key de Gemini

Por seguridad, es altamente recomendable gestionar tu API Key de Gemini como una variable de entorno y no codificarla directamente en tus archivos de configuración.

### En Windows (HatWindows):

1.  **Temporal (para la sesión actual de CMD/PowerShell):**
    ```cmd
    set GEMINI_API_KEY=TU_API_KEY_AQUI
    ```
    ```powershell
    $env:GEMINI_API_KEY="TU_API_KEY_AQUI"
    ```

2.  **Permanente (a través de las propiedades del sistema):**
    *   Busca "Editar las variables de entorno del sistema" en el menú de inicio.
    *   Haz clic en "Variables de entorno...".
    *   En la sección "Variables de usuario" o "Variables del sistema", haz clic en "Nueva...".
    *   **Nombre de la variable:** `GEMINI_API_KEY`
    *   **Valor de la variable:** `TU_API_KEY_AQUI`
    *   Reinicia Neovim (y tu terminal si es necesario) para que los cambios surtan efecto.

Tu plugin `gemini-cli.lua` debería ser capaz de leer esta variable de entorno usando `os.getenv("GEMINI_API_KEY")`.

## 3. Uso Básico de Gemini CLI en Neovim

Una vez configurado, puedes interactuar con Gemini directamente desde Neovim.

### Comandos Comunes:

*   **`:Gemini <tu pregunta>`**: Envía una pregunta o instrucción a Gemini y muestra la respuesta en un buffer o ventana emergente.
    *   Ejemplo: `:Gemini Explica el concepto de closures en Lua.`

*   **`:GeminiCode <tu instrucción>`**: Similar a `:Gemini`, pero optimizado para generar o refactorizar código. Puede tomar el código del buffer actual o de una selección visual.
    *   Ejemplo: `:GeminiCode Refactoriza esta función para que sea más eficiente.` (con la función seleccionada visualmente)

*   **`:GeminiChat`**: Inicia una sesión de chat interactiva con Gemini en un buffer dedicado.

*(Nota: Los nombres exactos de los comandos pueden variar ligeramente dependiendo de la implementación específica de tu plugin `gemini-cli.lua`.)*

### Integración con Selecciones Visuales:

Muchos plugins de IA para Neovim permiten enviar el texto seleccionado visualmente a la IA. Si tu plugin `gemini-cli.lua` lo soporta, puedes:

1.  Seleccionar un bloque de código o texto en modo visual (`v` o `V`).
2.  Ejecutar un comando como `:GeminiCode Refactoriza esto.` o `:Gemini Explica este fragmento.`

## 4. Optimización con LazyVim y Neovim

### Mapeos de Teclas (Keymaps):

Define mapeos de teclas convenientes en tu `lazy.lua` o en un archivo de configuración específico para Gemini para agilizar el uso.

**Ejemplo en `lua/config/lazy.lua` o similar:**

```lua
-- En tu archivo de configuración de keymaps o en el config de gemini-cli.lua

vim.keymap.set("n", "<leader>gi", ":Gemini ", { desc = "Gemini Inline Query" })
vim.keymap.set("v", "<leader>gc", ":<C-U>GeminiCode ", { desc = "Gemini Code Refactor (Visual)" })
vim.keymap.set("n", "<leader>gt", ":GeminiChat<CR>", { desc = "Gemini Chat" })
```

*   `<leader>gi`: Para consultas rápidas en línea.
*   `<leader>gc`: Para refactorizar o analizar código seleccionado visualmente.
*   `<leader>gt`: Para iniciar un chat interactivo.

### Contexto del Proyecto:

Cuando uses Gemini para tareas de codificación, considera proporcionarle contexto sobre tu proyecto. Aunque el CLI no puede "leer" todo tu proyecto automáticamente, puedes:

*   **Copiar/Pegar fragmentos relevantes:** Si necesitas que Gemini entienda una parte específica de tu base de código, cópiala y pégala en tu prompt.
*   **Describir la estructura:** En prompts más complejos, puedes describir brevemente la estructura de archivos o las convenciones que sigues.

### Uso de Comentarios y Documentación:

Gemini es excelente para generar comentarios y documentación. Utiliza `GeminiCode` o `Gemini` para:

*   Generar docstrings para funciones.
*   Explicar bloques de código complejos.
*   Crear resúmenes de archivos.

### Integración con `oil.nvim` o `nvim-tree`:

Si utilizas plugins como `oil.nvim` o `nvim-tree` para la navegación de archivos, puedes combinarlos con Gemini para tareas como:

*   **Generar `README.md`:** Pídele a Gemini que genere un `README.md` basado en la estructura de tu directorio actual.
*   **Resumir archivos:** Abre un archivo con `oil.nvim` y luego usa Gemini para resumir su contenido.

## 5. Resolución de Problemas Comunes

*   **"API Key not found"**: Verifica que la variable de entorno `GEMINI_API_KEY` esté configurada correctamente y que Neovim (y la terminal) se hayan reiniciado.
*   **"Command not found"**: Asegúrate de que el plugin `gemini-cli.lua` esté instalado y cargado por LazyVim. Ejecuta `:Lazy sync` o `:Lazy clean` si es necesario.
*   **Respuestas irrelevantes**: Intenta ser más específico en tus prompts. Proporciona ejemplos o contexto si es posible.

¡Con esta configuración, deberías poder aprovechar al máximo la potencia de Gemini directamente desde tu entorno de desarrollo Neovim en HatWindows!
