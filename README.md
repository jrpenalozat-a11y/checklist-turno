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

## Traspaso verificado (foto en vivo + ubicación) — Supabase

Tarjeta **📸 Traspaso verificado**: registra un traspaso con **foto tomada en vivo con la
cámara** (no se puede elegir de la galería), **ubicación** del momento y **hora puesta por
el servidor**. Como esta app es vanilla (sin build), usa `supabase-js` cargado por CDN.

### 1) Configura tus credenciales
En `index.html`, bloque `CONFIG` (busca `SUPABASE_URL`):
```js
const SUPABASE_URL      = "https://TU-PROYECTO.supabase.co";
const SUPABASE_ANON_KEY = "TU_ANON_KEY";   // pública por diseño; la protege RLS
```
Hasta configurarlo, la tarjeta muestra “Falta configurar Supabase” y el resto de la app
funciona igual.

### 2) Crea la tabla
```sql
create table if not exists public.traspasos_turno (
  id           uuid primary key default gen_random_uuid(),
  archivo      text not null,
  colaborador  text,
  turno        text,
  lat          float8,
  lng          float8,
  precision_m  float8,
  created_at   timestamptz not null default now()   -- la HORA la pone el servidor
);
alter table public.traspasos_turno enable row level security;

create policy "insert autenticado" on public.traspasos_turno
  for insert to authenticated with check (true);
create policy "select autenticado" on public.traspasos_turno
  for select to authenticated using (true);
```

### 3) Crea el bucket de Storage y sus políticas
```sql
insert into storage.buckets (id, name, public)
values ('traspasos','traspasos', false)
on conflict (id) do nothing;

create policy "subir traspasos" on storage.objects
  for insert to authenticated with check (bucket_id = 'traspasos');
create policy "ver traspasos" on storage.objects
  for select to authenticated using (bucket_id = 'traspasos');
```

### 4) Habilita sesión anónima
La app no tiene login; para cumplir el RLS `authenticated` usa **sesión anónima**.
En Supabase: **Authentication → Sign In / Providers → Anonymous sign-ins = ON**.

### 5) HTTPS obligatorio
La cámara (`getUserMedia`) y la ubicación (`geolocation`) **solo funcionan en HTTPS**
(o `localhost`). La app ya está en HTTPS en Vercel, así que ✅.

### Seguridad (por qué así)
- **Foto:** solo `navigator.mediaDevices.getUserMedia` (cámara en vivo). Sin
  `<input type="file">` ni `capture` → no se puede subir de la galería.
- **Hora:** `created_at timestamptz default now()` en el servidor; nunca la fecha del
  teléfono.
- **Ubicación:** `getCurrentPosition({enableHighAccuracy:true, timeout:8000})` en el mismo
  momento de la captura. Si el usuario la niega o expira, el traspaso **igual se registra**
  con `lat/lng = null` y muestra “sin ubicación”.
- **Opcional (comentado):** geocerca de 150 m del local para marcar “fuera del local”.

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
