local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

return {
  -- Callouts (Obsidian syntax: > [!type])
  s("call", {
    t("> [!note] "),
    i(1),
  }, {
    desc = "Generic callout (tab to select type)"
  }),

  s("note", {
    t("> [!note]\n> "),
    i(1),
  }, {
    desc = "Note callout"
  }),

  s("warn", {
    t("> [!warning]\n> "),
    i(1),
  }, {
    desc = "Warning callout"
  }),

  s("tip", {
    t("> [!tip]\n> "),
    i(1),
  }, {
    desc = "Tip callout"
  }),

  s("imp", {
    t("> [!important]\n> "),
    i(1),
  }, {
    desc = "Important callout"
  }),

  s("todo", {
    t("> [!todo]\n> "),
    i(1),
  }, {
    desc = "Todo callout"
  }),

  s("ques", {
    t("> [!question]\n> "),
    i(1),
  }, {
    desc = "Question callout"
  }),

  s("quote", {
    t("> [!quote]\n> "),
    i(1),
  }, {
    desc = "Quote callout"
  }),

  -- YAML Frontmatter
  s("fm", {
    t("---"),
    t({ "", "title: " }),
    i(1),
    t({ "", "date: " }),
    i(2),
    t({ "", "tags: [" }),
    i(3),
    t({ "]" }),
    t({ "", "aliases: [" }),
    i(4),
    t({ "]" }),
    t({ "", "---", "" }),
    i(0),
  }, {
    desc = "YAML frontmatter template"
  }),

  -- Templates
  s("daily", {
    t({ "", "## ", f(function(args, snip)
      local date = os.date("%Y-%m-%d")
      return date
    end, {}), "" }),
    t({ "", "", "### Tasks", "" }),
    t({ "", "- [ ] ", i(1) }),
    t({ "", "- [ ] ", i(2) }),
    t({ "", "- [ ] ", i(3) }),
    t({ "", "", "### Notes", "" }),
    i(0),
  }, {
    desc = "Daily note template"
  }),

  s("meet", {
    t({ "", "# Meeting Notes", "" }),
    t({ "", "## Date", "" }),
    t({ "", "📅 " }),
    i(1),
    t({ "", "", "## Attendees", "" }),
    t({ "", "- " }),
    i(2),
    t({ "", "", "## Agenda", "" }),
    i(3),
    t({ "", "", "## Notes", "" }),
    i(4),
    t({ "", "", "## Action Items", "" }),
    t({ "", "- [ ] " }),
    i(5),
    t({ "", "- [ ] " }),
    i(6),
    t({ "", "- [ ] " }),
    i(0),
  }, {
    desc = "Meeting notes template"
  }),

  s("book", {
    t({ "", "# Book Notes", "" }),
    t({ "", "## Title", "" }),
    t({ "", "" }),
    i(1),
    t({ "", "", "## Author", "" }),
    t({ "", "" }),
    i(2),
    t({ "", "", "## Summary", "" }),
    i(3),
    t({ "", "", "## Highlights", "" }),
    i(4),
    i(0),
  }, {
    desc = "Book notes template"
  }),

  -- Other useful snippets
  s("code", {
    t("``` "),
    i(1),
    t({ "", "" }),
    i(0),
    t({ "", "```" }),
  }, {
    desc = "Code block with language placeholder"
  }),

  s("task", {
    t("- [ ] "),
    i(1),
  }, {
    desc = "Checkbox task"
  }),

  s("tasks", {
    t({ "", "- [ ] " }),
    i(1),
    t({ "", "- [ ] " }),
    i(2),
    t({ "", "- [ ] " }),
    i(3),
    t({ "", "- [ ] " }),
    i(4),
    i(0),
  }, {
    desc = "Multiple checkbox tasks"
  }),

  s("link", {
    t("[" ),
    i(1),
    t("](" ),
    i(2),
    t(")" ),
  }, {
    desc = "Markdown link"
  }),

  -- Tables
  s("table", {
    t({ "| Header 1 | Header 2 | Header 3 |" }),
    t({ "| --------- | --------- | --------- |" }),
    t({ "| Cell 1   | Cell 2   | Cell 3   |" }),
    t({ "| Cell 4   | Cell 5   | Cell 6   |" }),
    i(0),
  }, {
    desc = "Markdown table (3 columns)",
  }),

  s("table2", {
    t({ "| Header 1 | Header 2 |" }),
    t({ "| --------- | --------- |" }),
    t({ "| Cell 1   | Cell 2   |" }),
    t({ "| Cell 2   | Cell 3   |" }),
    i(0),
  }, {
    desc = "Markdown table (2 columns)",
  }),

  s("table4", {
    t({ "| Header 1 | Header 2 | Header 3 | Header 4 |" }),
    t({ "| --------- | --------- | --------- | --------- |" }),
    t({ "| Cell 1   | Cell 2   | Cell 3   | Cell 4   |" }),
    i(0),
  }, {
    desc = "Markdown table (4 columns)",
  }),

  -- ============================================
  -- LIBRO / LECTURA - Sistema de Segundo Cerebro
  -- ============================================

  -- Metadata de libro
  s("libro", {
    t({ "---", "titulo: " }),
    i(1, "Título del Libro"),
    t({ "", "autor: ", "" }),
    i(2, "Autor"),
    t({ "", "isbn: ", "", "paginas: ", "" }),
    i(3, "Páginas"),
    t({ "", "año: ", "" }),
    i(4, "Año"),
    t({ "", "estado: leyendo", "", "inicio: " }),
    f(function(args, snip)
      return os.date("%Y-%m-%d")
    end, {}),
    t({ "", "progreso: 0", "", "---", "", "## Por qué elegí este libro", "" }),
    i(5, "Mi motivación"),
    t({ "", "", "## Temas que espero aprender", "- " }),
    i(6, "Tema 1"),
  }, {
    desc = "Metadata de libro",
  }),

  -- Sesión de lectura completa (pre + post + brain dump)
  s("lectura", {
    t({ "---", "tipo: Sesion-Lectura", "sesion: " }),
    i(1, "1"),
    t({ "", "fecha: " }),
    f(function(args, snip)
      return os.date("%Y-%m-%d")
    end, {}),
    t({ "", "rango_paginas: ", "" }),
    i(2, "1-20"),
    t({ "", "duracion: 20min", "---", "", "# Sesión " }),
    i(1, "1"),
    t(": "),
    i(3, "Tema"),
    t({ "", "", "## PRE-PREGUNTAS", "1. " }),
    i(4, "¿Qué quiero aprender?"),
    t({ "", "2. ", "" }),
    i(5, "Segunda pregunta"),
    t({ "", "3. ", "" }),
    i(6, "Tercera pregunta"),
    t({ "", "4. ", "" }),
    i(7, "Cuarta pregunta"),
    t({ "", "", "---", "## POST-PREGUNTAS", "1. **" }),
    i(4, "Pregunta 1"),
    t({ "**", "   - Resp: ", "", "   - Ref: p.", "" }),
    t("2. **"),
    i(5, "Pregunta 2"),
    t({ "**", "   - Resp: ", "", "   - Ref: p.", "" }),
    t({ "", "---", "## BRAIN DUMP", "### Lo que entendí (en mis palabras)", "" }),
    i(8, "Escribe con tus propias palabras..."),
    t({ "", "", "### Conceptos clave", "- " }),
    i(9, "Concepto clave 1"),
    t({ "", "- " }),
    i(10, "Concepto clave 2"),
    t({ "", "", "### Qué no entendí bien", "- " }),
    i(11, "Algo confuso"),
    t({ "", "", "### Aplicación práctica", "- " }),
    i(12, "Cómo aplicar esto"),
  }, {
    desc = "Sesión de lectura completa",
  }),

  -- Brain dump rápido
  s("braindump", {
    t({ "# Brain Dump: " }),
    i(1, "Tema de hoy"),
    t({ "", "", "## Lo que entendí", "" }),
    i(2, "En mis palabras..."),
    t({ "", "", "## Conceptos clave", "- " }),
    i(3, "Concepto 1"),
    t({ "", "- " }),
    i(4, "Concepto 2"),
    t({ "", "", "## Qué no entendí", "- " }),
    i(5, "?"),
    t({ "", "", "## Aplicación", "- " }),
    i(6, "Uso práctico"),
  }, {
    desc = "Brain dump rápido",
  }),

  -- Resumen final de libro
  s("resumenlibro", {
    t({ "---", "tipo: Resumen-Libro", "libro: " }),
    i(1, "Título"),
    t({ "", "fecha_fin: " }),
    f(function(args, snip)
      return os.date("%Y-%m-%d")
    end, {}),
    t({ "", "rating: ", "---", "", "# Resumen: " }),
    i(1, "Título"),
    t({ "", "", "## Las 3 ideas principales", "1. " }),
    i(2, "Idea 1"),
    t({ "", "2. ", "" }),
    i(3, "Idea 2"),
    t({ "", "3. ", "" }),
    i(4, "Idea 3"),
    t({ "", "", "## Resumen por tema", "### Tema 1", "- Idea central: ", "" }),
    i(5, "..."),
    t({ "", "- Aplicación: ", "" }),
    i(6, "..."),
    t({ "", "", "## Plan de acción", "- [ ] " }),
    i(7, "Acción 1"),
    t({ "", "- [ ] " }),
    i(8, "Acción 2"),
  }, {
    desc = "Resumen final de libro",
  }),
}