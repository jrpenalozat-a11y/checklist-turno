# Checklist para turno · François

Checklist para el **traspaso de turno**: se marca con el dedo y **el estado viaja dentro del link**,
así se comparte por WhatsApp y quien lo recibe lo abre tal cual quedó. Sin cuentas ni base de datos:
es **un solo archivo** (`index.html`).

## Cómo se usa (día a día)

1. **Abrir el link.** Aparece la lista del turno con una barra de avance (ej. `2 de 5`).
2. **Anotar quién entrega y quién recibe** en los dos campos de arriba (queda registrado).
3. **Marcar tareas** tocando la casilla. Al marcarla se pinta de verde y se tacha.
4. **Editar textos:** toca el título o cualquier tarea para reescribirla. Enter guarda.
5. **Agregar tarea:** escribe abajo en «Agregar tarea…» y toca el `+` (o Enter).
6. **Borrar una tarea:** con la `×` a la derecha de cada línea.

## Los botones

| Botón | Color | Qué hace |
|-------|-------|----------|
| **Registrar y enviar** | verde François | **Guarda el traspaso** (quién entrega, quién recibe, fecha/hora y % de avance) y abre WhatsApp con el resumen + un link que lleva todo adentro. Un traspaso = un envío. |
| **PDF** | cobre | Descarga un PDF del checklist actual (con entrega/recibe, fecha y tareas) para archivar. |
| **Registro semanal** | verde pino | Abre el panel con los traspasos de la semana y la **efectividad** (% promedio de avance). Desde ahí se descarga PDF y se exporta/importa. |
| **Desmarcar** | oro | Deja todas las tareas sin marcar para **empezar un turno nuevo** (no borra las tareas). |
| **Vaciar** | ladrillo | Borra **todas** las tareas (pide confirmación). |

Paleta institucional François (verde bosque + crema + cobre), tipografía Inter y el
emblema de la taza en el encabezado. Colores por función: verde = acción principal,
cobre = guardar/descargar, verde pino = reportes, oro = reversible, ladrillo = destructivo.

## El flujo del traspaso

1. Encargado que **cierra** anota su nombre en *Entrega* y el del que sigue en *Recibe*,
   marca lo hecho → **Registrar y enviar** por WhatsApp.
2. Encargado que **entra** abre ese link → ve lo checkeado, sigue marcando y al cerrar
   vuelve a **Registrar y enviar**.
3. Cuando quieran, **Registro semanal** muestra cuántos traspasos hubo y con qué % de
   efectividad promedio; sirve para ver el nivel del equipo.
4. Turno nuevo → **Desmarcar** y a marcar de nuevo.

## Registro semanal y efectividad

- Cada vez que alguien toca **Registrar y enviar**, se guarda un traspaso con la fecha,
  quién entrega, quién recibe y el % de tareas completadas en ese momento.
- El panel **Registro semanal** agrupa los traspasos de la semana (lunes a domingo),
  muestra la **efectividad promedio** (verde ≥80 %, ámbar 50–79 %, rojo <50 %) y permite
  **descargar un PDF** del reporte.
- **Consolidación automática, sin servidor:** los traspasos recientes viajan **dentro del
  link** de WhatsApp. Cuando el que recibe abre el link, su app **fusiona** los registros
  (sin duplicar). Así, si el equipo se pasa el link en cadena, el registro semanal se junta
  solo en cada teléfono.
- **Respaldo manual:** dentro del panel hay **Exportar** (descarga un `.json`) e **Importar**
  (fusiona un `.json`), por si quieren juntar registros de varios equipos a mano.

## Detalles técnicos

- **HTML + CSS + JS puro en un solo `index.html`.** Sin frameworks, sin build, sin backend.
- Única dependencia externa: `jspdf` (por CDN) para generar los PDF.
- Persistencia: `localStorage` — checklist en `checklist.v1`, registro de traspasos en
  `checklist.reg.v1` — más el estado en el hash del link.

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
