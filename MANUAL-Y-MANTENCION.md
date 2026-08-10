# Checklist de Turno · François
### Qué alcanza a hacer, cómo se cuida y por qué depende de todos

**App:** https://checklist-turno.vercel.app
**Última actualización de este documento:** 10 de agosto de 2026

---

## 1. Para qué existe

Antes, lo que había que hacer en cada turno vivía en tres lugares a la vez: una planilla
impresa, un tablero de Trello y la memoria de cada uno. El resultado conocido: tareas que
"alguien creía que ya estaban hechas", cierres a medias que aparecían recién a la mañana
siguiente, y ninguna forma de saber **por qué** algo no se hizo.

Esta app junta eso en un solo lugar y agrega lo que faltaba: **el motivo**.

No reemplaza al equipo ni a la jefatura. Ordena la información para que las conversaciones
sean sobre lo importante, no sobre quién dijo qué.

---

## 2. Qué hace hoy (alcances reales)

### La rutina del local
Las **90 tareas** de la planilla de Ángel, repartidas por área tal como estaban ahí:

| Área | Tareas | Durante el turno | Al cierre |
|---|---:|---:|---:|
| 🌅 Turno 1 (apertura) | 12 | — | — |
| Cocina | 27 | 11 | 16 |
| Barismo/Vitrina | 22 | 9 | 13 |
| Caja | 17 | 11 | 6 |
| Salón | 12 | 5 | 7 |

Cada persona elige su **puesto del día** al entrar y ve su lista corta. Nadie tiene que
leer 90 tareas para encontrar las suyas.

### Lo que se puede hacer
- **Marcar** cada tarea al hacerla, y dejar **foto** como prueba.
- Lo que **no se marca queda pendiente** automáticamente, con su **motivo**.
- **Agregar en el día**: una tarea extra que se realizó, un pendiente nuevo o una nota.
- **Enviar informe** por WhatsApp del área, que no deja enviarse si falta algún motivo.
- El supervisor ve todo en **🔑 Supervisor → 📋 Informe del día**, sin que nadie se lo mande.
- **Traspaso verificado** con foto en vivo, ubicación y hora del servidor.
- Funciona **sin conexión** y se instala como app en el teléfono.

### Lo que NO hace (y conviene saberlo)
- **No sabe de turnos, solo de puestos.** Las tareas de apertura están agrupadas aparte,
  pero la app no distingue "turno 1" de "turno 2" como tal. Si alguien rota, elige el
  puesto que le toca ese día y listo.
- **El informe es por dispositivo y por día.** Si dos personas usan la misma tablet en el
  mismo puesto, comparten registro.
- **No manda el informe solo a un destinatario.** Abre WhatsApp y cada uno elige a quién.
  (Se puede mejorar; ver sección 6.)
- **No controla horarios ni asistencia.** No es un reloj de control.
- **No reemplaza la supervisión presencial.** Una foto prueba que algo se hizo, no que se
  hizo bien.

---

## 3. Por qué ayuda al trabajo bien organizado

El valor real no es la lista. Es lo que la lista provoca.

**Saca las cosas de la cabeza.** Nadie debería empezar el turno tratando de recordar qué
tocaba. La app se lo dice, y esa energía queda libre para atender bien a la gente.

**Convierte "no alcancé" en información útil.** Un pendiente sin explicación es un
reproche. Un pendiente con motivo es un dato: si "faltaba insumo" aparece tres veces en la
semana, el problema no es la persona, es el pedido. Si "había clientes en el sector" se
repite en la limpieza de baños, el problema es el horario en que se programó, no la
voluntad de quien no lo hizo.

**Protege a quien hace bien su trabajo.** Quedan registrados los extras que nadie pidió:
la bodega ordenada, el pollo descongelado para el día siguiente. Ese trabajo antes se
perdía; ahora se ve.

**Hace que el que llega encuentre lo que le dejaron.** Un cierre completo es un regalo al
turno siguiente. Un cierre a medias es un problema heredado. Ahora se sabe cuál de los dos
fue, y por qué.

**Ordena la conversación de la semana.** En vez de discutir impresiones, se mira lo que
pasó.

---

## 4. Es una herramienta. El resultado depende de todos

Esto conviene decirlo sin rodeos:

> **Una app no limpia un baño ni hornea un pan. Ordena, recuerda y deja constancia.
> El trabajo sigue siendo del equipo.**

Y tiene una debilidad honesta: **funciona con la verdad**. Marcar una tarea que no se hizo
no engaña a la app, engaña al que llega después y se encuentra con el problema. La app no
tiene forma de detectarlo, y no debería tenerla: se sostiene en la confianza.

Cuatro compromisos simples:

1. **Marcar lo que de verdad se hizo**, ni más ni menos.
2. **Poner el motivo cuando algo queda pendiente.** No es una excusa que hay que justificar:
   es la información que permite arreglar el problema de fondo.
3. **Anotar lo extra y lo que se nota** (una máquina con ruido raro, algo que se está
   acabando). Eso vale tanto como la tarea marcada.
4. **Revisarlo desde jefatura.** Si nadie mira los informes, en dos semanas nadie los llena.
   Esto es lo que más rápido mata una herramienta así.

Y al revés: si el equipo la usa bien pero las decisiones no cambian —el pedido que siempre
falta sigue faltando— la app se vuelve burocracia. **La herramienta sirve si alguien actúa
con lo que muestra.**

---

## 5. Cómo mantenerla sana (para quien la modifica)

### Cómo está hecha
- **Un solo archivo:** `index.html` contiene todo (estructura, estilos y lógica).
- **Sin compilación, sin dependencias.** No hay `npm install` ni build. Se abre y funciona.
- **PWA:** `manifest.json` + `sw.js` para instalación y uso sin conexión.
- **Datos en Supabase** (proyecto François): usuarios, rutina, informes del día y fotos.
- **Deploy:** `git push` a `master` → Vercel publica solo. No hay paso intermedio.

### Dónde vive cada cosa (importante antes de tocar nada)

| Dato | Dónde | Se borra si… |
|---|---|---|
| La rutina (las 90 tareas) | Supabase, tabla `config`, clave `rutina` | alguien la edita en Semanal |
| Usuarios y puestos | Supabase, tabla `usuarios` | se eliminan desde Supervisor |
| Informe del día | Supabase, tabla `checklists` | pasa 90 días |
| Fotos | Supabase Storage | pasa 90 días (las de referencia, nunca) |
| Marcado del día, motivos, extras | `localStorage` del teléfono | se borran los **datos del sitio** |

**La distinción que más importa:** actualizar la app renueva la *caché de archivos*, que es
otra cosa distinta del *localStorage*. Por eso una actualización **nunca** desmarca tareas.

### Reglas para modificar sin romper

1. **Probar en local antes de publicar.** Servir la carpeta con un estático y revisar ahí.
   Nunca "probar en producción a ver qué pasa": la usa el equipo en turno.
2. **Subir la versión del caché** en `sw.js` (`cf-v7` → `cf-v8`) cada vez que se cambie el
   `index.html`. Si no, algunos equipos pueden quedarse con archivos viejos.
3. **Un cambio a la vez, con su commit.** Si algo falla, se sabe cuál fue y se vuelve atrás.
4. **Respaldar la rutina antes de reemplazarla en masa.** Es un solo JSON: se copia y se
   guarda. Ya existe un respaldo de la versión anterior.
5. **No borrar tareas para "limpiar".** Si una tarea ya no aplica, sacarla desde Semanal
   como parte de una decisión, no de un arreglo técnico.
6. **Revisar en teléfono, no solo en computador.** El 90% del uso es en pantalla chica y con
   las manos ocupadas.
7. **Mantener este documento y la 📖 Ayuda de la app al día.** Una función que nadie sabe
   que existe es una función que no existe.

### Qué NO hacer
- ❌ Decirle a alguien que **"borre la caché"** o los datos del sitio. Eso sí borra lo
  marcado del día. La app se actualiza sola: basta cerrarla y abrirla.
- ❌ Cambiar los nombres de los **puestos** sin actualizar las tareas ya asignadas: quedarían
  huérfanas y no aparecerían en ninguna pestaña.
- ❌ Editar la rutina directamente en la base sin respaldo previo.
- ❌ Agregar funciones "por si acaso". Cada botón nuevo es una decisión menos obvia para
  quien la usa apurado en medio de un turno.

### La regla de fondo
> **Si una función no le ahorra tiempo o problemas a alguien concreto del equipo, sobra.**

Esta app es útil porque es corta. La forma más segura de arruinarla es llenarla de cosas.

---

## 6. Mejoras posibles (no urgentes)

- **Envío directo del informe** a un destinatario fijo. Requiere agregar el teléfono a los
  usuarios: `alter table public.usuarios add column if not exists telefono text;`
- **Distinguir turno 1 y turno 2** de verdad, si la rotación lo pide.
- **Resumen semanal por área**: cuáles son los motivos que más se repiten. Ahí está la
  información más valiosa para tomar decisiones.
- **Extender los usos de las fotos de referencia** para estandarizar cómo debe quedar cada
  cosa.

---

## 7. Si algo falla

| Síntoma | Qué hacer |
|---|---|
| No aparece la versión nueva | Cerrar la app y volver a abrirla. **Nunca borrar caché.** |
| No aparecen las tareas | Revisar conexión. Sin señal muestra lo último guardado. |
| No sale mi nombre | Que un supervisor lo agregue en Supervisor → Usuarios. |
| No deja enviar el informe | Falta poner el motivo de algún pendiente. Es a propósito. |
| No reproduce / no toma foto | Dar permiso de cámara al navegador. La foto debe ser en vivo. |

---

*Este documento vive en el repositorio junto a la app. Si algo cambia en el funcionamiento,
cambia también aquí.*
