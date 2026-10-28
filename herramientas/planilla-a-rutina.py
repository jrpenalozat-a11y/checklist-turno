"""
Planilla de tareas de una sede -> rutina del Checklist -> SQL para cargarla.

Dos pasos, con una revisión a mano entremedio:

  1) borrador: lee la planilla (.ods, .xlsx o .csv) y escribe la rutina en
     JSON legible, con las reglas de La Florida y Puerto Varas:
       · fila con algo en la 1.ª columna = título de sección;
         «Turno 1» -> sin puesto y [APERTURA]; «Al cierre» -> [CIERRE] en el
         área en curso; cualquier otro título -> el puesto de ese nombre
         (o el que diga --mapa «Título=Puesto»);
       · 2.ª columna = la tarea; 3.ª = la observación, que va tras « — »
         (se descarta si solo dice la frecuencia: «diario», «a diario»…);
       · si la observación nombra días («lunes a jueves»), la tarea va solo
         esos días (en «dias», 0 = domingo … 6 = sábado);
       · ninguna tarea con foto obligatoria (ni req ni pi).
     Las MAYÚSCULAS pasan a minúsculas, pero las tildes y la redacción
     («Limpiar los…», no «LIMPIEZA…») se arreglan a mano en el JSON.
     Lo dudoso (tareas con « / », títulos sin puesto, días raros, hojas
     extra) se imprime para revisarlo.

  2) sql: toma el JSON ya revisado, lo valida contra los puestos de la sede
     (PUESTOS_SEDE en index.html) y escribe el SQL que lo carga en
     <sede>:rutina sin pisar una rutina que ya tenga tareas, y crea
     <sede>:Ricardo (encargado) si falta. Mismo patrón que
     SQL-rutina-puerto-varas.sql. Sale en UTF-8, sin BOM y sin CR.

Ejemplo (Maximarket PV):
  python herramientas/planilla-a-rutina.py borrador "TAREAS MAXIMARKET PV.ods" --sede s3 --prefijo mx -o rutina-maximarket-pv.json
  (revisar y corregir rutina-maximarket-pv.json)
  python herramientas/planilla-a-rutina.py sql rutina-maximarket-pv.json --sede s3 --origen "Planilla TAREAS MAXIMARKET PV" -o SQL-rutina-maximarket-pv.sql
"""
import argparse, csv, json, os, re, sys, unicodedata, zipfile
import xml.etree.ElementTree as ET

AQUI = os.path.dirname(os.path.abspath(__file__))
INDEX = os.path.join(AQUI, "..", "index.html")
DIAS = ["domingo", "lunes", "martes", "miercoles", "jueves", "viernes", "sabado"]
DIAS_TXT = ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"]
# observaciones que solo dicen la frecuencia: no aportan nada en la app
SOLO_FRECUENCIA = {"diario", "a diario", "todos los dias", "debe ser diario", "al cierre", "antes del cierre",
                   "a diario y antes del cierre", "deben de quedar hechas", "deben quedar hechas"}


def norm(s):
    s = unicodedata.normalize("NFD", str(s or "")).encode("ascii", "ignore").decode()
    return re.sub(r"\s+", " ", re.sub(r"\s*/\s*", "/", s)).strip().lower()


# ---------------- lectura de la planilla ----------------
def filas_ods(ruta):
    ns = {"table": "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
          "text": "urn:oasis:names:tc:opendocument:xmlns:text:1.0"}
    T = "{%s}" % ns["table"]
    raiz = ET.fromstring(zipfile.ZipFile(ruta).read("content.xml"))
    hojas = []
    for h in raiz.iter(T + "table"):
        filas = []
        for r in h.iter(T + "table-row"):
            celdas = []
            for c in r:
                if c.tag not in (T + "table-cell", T + "covered-table-cell"):
                    continue
                txt = "\n".join("".join(p.itertext()) for p in c.findall(".//text:p", ns)).strip()
                celdas += [txt] * min(int(c.get(T + "number-columns-repeated", "1")), 20)
            filas.append(celdas)
        hojas.append((h.get(T + "name"), filas))
    return hojas


def filas_xlsx(ruta):
    import openpyxl
    lib = openpyxl.load_workbook(ruta, data_only=True, read_only=True)
    return [(h.title, [["" if v is None else str(v).strip() for v in fila] for fila in h.iter_rows(values_only=True)])
            for h in lib.worksheets]


def filas_csv(ruta):
    with open(ruta, encoding="utf-8-sig", newline="") as f:
        muestra = f.read(4096); f.seek(0)
        sep = ";" if muestra.count(";") > muestra.count(",") else ","
        return [(os.path.basename(ruta), [[c.strip() for c in fila] for fila in csv.reader(f, delimiter=sep)])]


def leer_planilla(ruta):
    ext = os.path.splitext(ruta)[1].lower()
    if ext == ".ods":
        return filas_ods(ruta)
    if ext in (".xlsx", ".xlsm"):
        return filas_xlsx(ruta)
    if ext == ".csv":
        return filas_csv(ruta)
    sys.exit("Formato no reconocido: " + ext + " (sirven .ods, .xlsx o .csv)")


# ---------------- texto ----------------
def oracion(s):
    """«LIMPIAR PISO» -> «Limpiar piso». Si ya viene en minúsculas, se respeta."""
    s = re.sub(r"\s+", " ", str(s)).strip().rstrip(".")
    s = re.sub(r"\s+,", ",", s)
    letras = [c for c in s if c.isalpha()]
    if letras and sum(c.isupper() for c in letras) / len(letras) > 0.6:
        s = s.lower()
    return s[:1].upper() + s[1:]


def dias_de(texto):
    """Días que nombra el texto (0 = domingo). «lunes a jueves» = rango."""
    t = norm(texto)
    if re.search(r"fin(es)? de semana", t):
        return [6, 0]
    nombres = re.findall(r"\b(" + "|".join(DIAS) + r")\b", t)
    if not nombres:
        return []
    m = re.search(r"\b(" + "|".join(DIAS) + r")\b\s+a\s+\b(" + "|".join(DIAS) + r")\b", t)
    if m and len(nombres) == 2:
        a, b = DIAS.index(m.group(1)), DIAS.index(m.group(2))
        a, b = (a or 7), (b or 7)            # el domingo va al final de la semana
        return [d % 7 for d in range(a, b + 1)]
    return sorted({DIAS.index(n) for n in nombres}, key=lambda d: d or 7)


def dias_texto(ds):
    orden = [d or 7 for d in ds]
    if len(ds) >= 3 and orden == list(range(orden[0], orden[-1] + 1)):
        return "Solo de " + DIAS_TXT[ds[0]] + " a " + DIAS_TXT[ds[-1]]
    pl = [DIAS_TXT[d] + ("s" if d in (0, 6) else "") for d in ds]
    return "Solo los " + (pl[0] if len(pl) == 1 else ", ".join(pl[:-1]) + " y " + pl[-1])


# ---------------- puestos de la sede (index.html) ----------------
def puestos_de(sede):
    html = open(INDEX, encoding="utf-8").read()
    bloque = re.search(r"const PUESTOS_SEDE = \{(.*?)\};", html, re.S)
    if not bloque:
        sys.exit("No encontré PUESTOS_SEDE en index.html")
    m = re.search(r"\b" + re.escape(sede) + r"\s*:\s*\[(.*?)\]", bloque.group(1), re.S)
    if not m:
        m = re.search(r"\blf\s*:\s*\[(.*?)\]", bloque.group(1), re.S)
        print("Aviso: «" + sede + "» no tiene puestos propios en PUESTOS_SEDE; uso los de La Florida.")
    return re.findall(r'"([^"]+)"', m.group(1))


# ---------------- paso 1: borrador ----------------
def borrador(a):
    puestos = puestos_de(a.sede)
    por_nombre = {norm(p): p for p in puestos}
    mapa = {}
    for x in a.mapa or []:
        if "=" not in x:
            sys.exit("--mapa va como «Título de la planilla=Puesto»: " + x)
        k, v = x.split("=", 1)
        if v.strip() not in puestos and v.strip() != "":
            sys.exit("«" + v.strip() + "» no es un puesto de " + a.sede + ": " + ", ".join(puestos))
        mapa[norm(k)] = v.strip()   # «=» vacío = sin puesto (Turno 1)

    hojas = leer_planilla(a.planilla)
    nombres = [h[0] for h in hojas]
    # por defecto, la primera hoja con el encabezado «Área | Tareas…»
    tiene_enc = lambda h: any(norm((f + [""])[0]) in ("area", "areas") and norm((f + ["", ""])[1]).startswith("tarea") for f in h[1])
    hoja = next((h for h in hojas if h[0] == a.hoja), None) if a.hoja else next((h for h in hojas if tiene_enc(h)), hojas[0])
    if not hoja:
        sys.exit("No hay hoja «" + a.hoja + "». Hojas: " + ", ".join(nombres))

    base, dias, revisar, vistas = [], {}, [], {}
    area, modo, n = None, "", 0
    sin_puesto = set()
    for i, f in enumerate(hoja[1], 1):
        f = (f + ["", "", ""])[:3]
        tit, tarea, obs = f
        if norm(tit) in ("area", "areas") and norm(tarea).startswith("tarea"):
            continue                                   # encabezado de columnas
        if tit:
            k = norm(tit)
            if re.fullmatch(r"(al )?cierre", k):
                modo = "[CIERRE] "
            elif k in mapa:
                area, modo = mapa[k] or None, ("[APERTURA] " if not mapa[k] else "")
            elif re.fullmatch(r"turno ?1|apertura", k):
                area, modo = None, "[APERTURA] "
            elif k in por_nombre:
                area, modo = por_nombre[k], ""
            else:
                area, modo = tit.strip(), ""
                sin_puesto.add(tit.strip())
            if not tarea or norm(tarea).startswith("tareas"):
                continue                               # título solo, o subtítulo «TAREAS INELUDIBLES…»
        if not tarea:
            continue
        n += 1
        t = oracion(tarea)
        ds = dias_de(obs) or dias_de(tarea)
        o = oracion(obs) if obs and norm(obs) not in SOLO_FRECUENCIA else ""
        if ds:
            o = dias_texto(ds)
        texto = modo + t + (" — " + o if o else "")
        x = {"id": a.prefijo + "%03d" % n, "t": texto}
        if area:
            x["p"] = area
        if re.search(r"\s/|/\s", tarea):              # «A / B» sí; «Barismo/Vitrina» no
            revisar.append("fila %d (%s): ¿son dos tareas? «%s»" % (i, x["id"], tarea))
        k = (area, norm(tarea))
        if k in vistas:
            revisar.append("fila %d (%s): repite la tarea %s del mismo puesto «%s»" % (i, x["id"], vistas[k], tarea))
        vistas.setdefault(k, x["id"])
        if ds:
            for d in ds:
                dias.setdefault(str(d), []).append(dict(x, id=x["id"] + "-" + str(d)))
        else:
            base.append(x)

    rut = {"base": base, "dias": dict(sorted(dias.items()))}
    with open(a.o, "w", encoding="utf-8", newline="\n") as f:
        json.dump(rut, f, ensure_ascii=False, indent=1)
        f.write("\n")

    cuenta = {}
    for x in base:
        cuenta[x.get("p", "Turno 1")] = cuenta.get(x.get("p", "Turno 1"), 0) + 1
    print("Hoja «%s»: %d tareas fijas, %d solo algunos días (%s)." % (hoja[0], len(base),
          len({x["id"].rsplit("-", 1)[0] for v in dias.values() for x in v}), ", ".join(DIAS_TXT[int(d)] for d in rut["dias"]) or "ninguno"))
    print("Por puesto: " + ", ".join("%s %d" % kv for kv in cuenta.items()))
    print("Escrito: " + a.o)
    for t in sorted(sin_puesto):
        revisar.append("título «%s» no es un puesto de %s (%s): agrégalo a PUESTOS_SEDE o usa --mapa «%s=Puesto»"
                       % (t, a.sede, ", ".join(puestos), t))
    otras = [h for h in hojas if h is not hoja and any(any(c for c in f) for f in h[1])]
    for h in otras:
        revisar.append("hoja «%s» con %d filas: leerla a mano (notas, tareas sueltas)" % (h[0], sum(1 for f in h[1] if any(f))))
    if revisar:
        print("\nREVISAR:")
        for r in revisar:
            print("  · " + r)
    print("\nFalta a mano: tildes, redacción («Limpiar los…»), duplicados y si [APERTURA] corresponde a cada tarea de Turno 1.")


# ---------------- paso 2: SQL ----------------
def validar(rut, sede, con_fotos):
    puestos, errores, ids = puestos_de(sede), [], set()
    if not isinstance(rut, dict) or not isinstance(rut.get("base"), list) or not isinstance(rut.get("dias", {}), dict):
        return ["la rutina debe ser {base:[…], dias:{\"0\"…\"6\":[…]}}"]
    todas = [("base", x) for x in rut["base"]]
    for d, L in rut.get("dias", {}).items():
        if d not in [str(i) for i in range(7)]:
            errores.append("día «%s» no existe (0 = domingo … 6 = sábado)" % d)
        todas += [("día " + d, x) for x in L]
    for donde, x in todas:
        i = x.get("id", "")
        if not re.fullmatch(r"[a-z0-9-]{2,20}", i):
            errores.append("%s: id inválido «%s»" % (donde, i))
        if i in ids:
            errores.append("%s: id repetido «%s»" % (donde, i))
        ids.add(i)
        if not str(x.get("t", "")).strip():
            errores.append("%s: %s sin texto" % (donde, i))
        if "p" in x and x["p"] not in puestos:
            errores.append("%s: %s tiene puesto «%s», que no está en %s (%s)" % (donde, i, x["p"], sede, ", ".join(puestos)))
        if (x.get("req") or x.get("pi")) and not con_fotos:
            errores.append("%s: %s pide foto obligatoria (req/pi): sácala o usa --con-fotos si Jaime lo pidió" % (donde, i))
        if set(x) - {"id", "t", "p", "req", "pi"}:
            errores.append("%s: %s tiene campos de más: %s" % (donde, i, ", ".join(sorted(set(x) - {"id", "t", "p", "req", "pi"}))))
        if "$rv$" in str(x.get("t", "")):
            errores.append("%s: %s contiene «$rv$»" % (donde, i))
    return errores


def sql(a):
    if not re.fullmatch(r"[a-z0-9]{2,6}", a.sede) or a.sede in ("lf", "guia", "rutina", "checks"):
        sys.exit("Sede inválida: " + a.sede)
    rut = json.load(open(a.json, encoding="utf-8-sig"))
    rut.setdefault("dias", {})
    errores = validar(rut, a.sede, a.con_fotos)
    if errores:
        sys.exit("No se escribió el SQL:\n  · " + "\n  · ".join(errores))
    fijas = len(rut["base"])
    ndias = len(rut["dias"])
    sueltas = len({x["id"].rsplit("-", 1)[0] for L in rut["dias"].values() for x in L})
    marca = (rut["base"] or [x for L in rut["dias"].values() for x in L])[0]["id"]
    v = json.dumps(rut, ensure_ascii=False, separators=(",", ":"))
    resumen = "%s (%d fijas%s)" % (a.origen, fijas, " + %d solo algunos días" % sueltas if sueltas else "")
    s, nombre = a.sede, a.nombre or a.sede
    def q(t): return t.replace("'", "''")
    txt = f"""-- ===================================================================
-- Rutina de {nombre} (sede {s})
-- Correr UNA vez en Supabase → proyecto checklist-turno → SQL Editor → Run.
-- Seguro de repetir: no pisa una rutina de {nombre} que ya tenga tareas
-- ni duplica a Ricardo.
--
-- Origen: {resumen}.
-- Generado con herramientas/planilla-a-rutina.py; copia legible: {os.path.basename(a.json)}.
-- ===================================================================

do $do$
declare
  v    text := $rv${v}$rv$;
  logv text := '[{{"f":"' || to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
               || '","q":"Ricardo","a":"cargó la rutina inicial","t":"{q(json.dumps(resumen, ensure_ascii=False)[1:-1])}"}}]';
  tipo text;
begin
  -- la app guarda texto (JSON.stringify); se respeta el tipo que tenga la columna
  select data_type into tipo from information_schema.columns
   where table_schema = 'public' and table_name = 'config' and column_name = 'valor';

  if tipo = 'jsonb' then
    insert into public.config (clave, valor, updated_at) values ('{s}:rutina', to_jsonb(v), now())
    on conflict (clave) do update set valor = excluded.valor, updated_at = now()
      where coalesce(config.valor #>> '{{}}', '') in ('', '{{}}', '{{"base":[],"dias":{{}}}}');
    insert into public.config (clave, valor, updated_at) values ('{s}:rutina_log', to_jsonb(logv), now())
    on conflict (clave) do nothing;
  else
    insert into public.config (clave, valor, updated_at) values ('{s}:rutina', v, now())
    on conflict (clave) do update set valor = excluded.valor, updated_at = now()
      where coalesce(config.valor, '') in ('', '{{}}', '{{"base":[],"dias":{{}}}}');
    insert into public.config (clave, valor, updated_at) values ('{s}:rutina_log', logv, now())
    on conflict (clave) do nothing;
  end if;

  -- primera persona de mando de la sede: con ella se entra y, en 👥 Usuarios,
  -- se crea al encargado del local
  insert into public.usuarios (nombre, rol, activo)
  select '{s}:Ricardo', 'encargado', true
  where not exists (select 1 from public.usuarios where nombre = '{s}:Ricardo');
end
$do$;

-- Revisión: debe decir «rutina cargada», {fijas} fijas y {ndias} días, y aparecer {s}:Ricardo.
-- Si dice «ya tenía tareas: no se tocó», avísale a Claude antes de seguir.
with r as (
  select (case when left(valor::text, 1) = '"' then (valor::text)::jsonb #>> '{{}}' else valor::text end)::jsonb as j
  from public.config where clave = '{s}:rutina'
)
select case when j::text like '%"{marca}"%' then 'rutina cargada' else 'ya tenía tareas: no se tocó' end as rutina,
       jsonb_array_length(j -> 'base') as fijas,
       (select count(*) from jsonb_object_keys(j -> 'dias')) as dias,
       (select string_agg(nombre || ' (' || rol || ')', ', ') from public.usuarios where nombre like '{s}:%') as usuarios_sede
from r;
"""
    with open(a.o, "w", encoding="utf-8", newline="\n") as f:
        f.write(txt)
    crudo = open(a.o, "rb").read()
    if b"\r" in crudo or crudo.startswith(b"\xef\xbb\xbf"):
        sys.exit("El SQL salió con CR o BOM: no entregarlo")
    print("SQL escrito: %s · %d fijas, %d días, %d bytes, 0 CR." % (a.o, fijas, ndias, len(crudo)))


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    ap =argparse.ArgumentParser(description="Planilla de tareas -> rutina del Checklist -> SQL")
    sub = ap.add_subparsers(dest="paso", required=True)
    b = sub.add_parser("borrador", help="planilla -> JSON legible para revisar")
    b.add_argument("planilla")
    b.add_argument("--sede", required=True, help="id de la sede, p. ej. s3")
    b.add_argument("--prefijo", required=True, help="prefijo de los id de tareas, p. ej. mx (mx001, mx002…)")
    b.add_argument("--hoja", help="nombre de la hoja (por defecto, la que tiene el encabezado «Área | Tareas…»)")
    b.add_argument("--mapa", nargs="*", help="«Título en la planilla=Puesto» (vacío tras «=» = Turno 1)")
    b.add_argument("-o", required=True, help="JSON de salida")
    b.set_defaults(f=borrador)
    s = sub.add_parser("sql", help="JSON revisado -> SQL para el SQL Editor")
    s.add_argument("json")
    s.add_argument("--sede", required=True)
    s.add_argument("--nombre", help="nombre de la sede para los comentarios, p. ej. «Maximarket PV»")
    s.add_argument("--origen", required=True, help="de dónde salió, p. ej. «Planilla TAREAS MAXIMARKET PV»")
    s.add_argument("--con-fotos", action="store_true", help="permitir req/pi (solo si Jaime lo pidió)")
    s.add_argument("-o", required=True, help="SQL de salida")
    s.set_defaults(f=sql)
    a = ap.parse_args()
    a.f(a)
