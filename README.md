# Checklist para turno · François

Checklist para el **traspaso de turno**: se marca con el dedo y **el estado viaja dentro del link**,
así se comparte por WhatsApp y quien lo recibe lo abre tal cual quedó. Sin cuentas ni base de datos:
es **un solo archivo** (`index.html`).

## Cómo se usa (día a día)

1. **Abrir el link.** Aparece la lista del turno con una barra de avance (ej. `2 de 5`).
2. **Marcar tareas** tocando la casilla. Al marcarla se pinta de verde y se tacha.
3. **Editar textos:** toca el título o cualquier tarea para reescribirla. Enter guarda.
4. **Agregar tarea:** escribe abajo en «Agregar tarea…» y toca el `+` (o Enter).
5. **Borrar una tarea:** con la `×` a la derecha de cada línea.

## Los 4 botones

| Botón | Color | Qué hace |
|-------|-------|----------|
| **Compartir** | verde | Abre WhatsApp con un resumen (✅/⬜) **y un link que lleva adentro todo lo marcado**. El siguiente encargado lo abre y sigue desde ahí. |
| **PDF** | azul | Descarga un PDF del estado actual (fecha, hora y tareas) para archivar en Drive, galería, etc. |
| **Desmarcar** | ámbar | Deja todas las tareas sin marcar para **empezar un turno nuevo** (no borra las tareas). |
| **Vaciar** | rojo | Borra **todas** las tareas (pide confirmación). |

Los colores son suaves y por función: verde = compartir, azul = guardar/descargar,
ámbar = reversible, rojo = destructivo.

## El flujo del traspaso

1. Encargado que **cierra** el turno marca lo hecho → **Compartir** por WhatsApp.
2. Encargado que **entra** abre ese link → ve lo checkeado y sigue marcando.
3. Si quieren dejar constancia del turno → **PDF** para archivar.
4. Turno nuevo → **Desmarcar** y a marcar de nuevo.

> El estado va codificado en la parte `#...` del link. Para un checklist normal
> (10–20 tareas) el link queda cómodo para WhatsApp. También se guarda solo en el
> navegador (`localStorage`), así que si cierras y vuelves a abrir, sigue como lo dejaste.

## Detalles técnicos

- **HTML + CSS + JS puro en un solo `index.html`.** Sin frameworks, sin build, sin backend.
- Única dependencia externa: `jspdf` (por CDN) para generar el PDF.
- Persistencia: `localStorage` (clave `checklist.v1`) + el hash del link.

## Subir a la web (Vercel)

Es un sitio estático de un solo archivo.

1. Sube esta carpeta a un repo de GitHub.
2. En Vercel: **New Project** → importa el repo.
3. Framework Preset: **Other**. Sin build. Output: la raíz.
4. **Deploy** → queda un link tipo `https://tu-proyecto.vercel.app`.

Alternativa por CLI: `npm i -g vercel`, entrar a la carpeta y `vercel`.

## Nota

Si algún día son **muchísimas** tareas, el link se alarga. Ahí conviene pasar a una
versión con base de datos (Vercel KV / Upstash). Para el uso normal de turno no hace falta.
