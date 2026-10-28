// Edge Function «limpiar-antiguos» (Supabase → Edge Functions). Copia del código publicado.
// Borra fotos y registros con más de 30 días, en TODAS las sedes (La Florida sin prefijo,
// las demás con el suyo: s2 = Puerto Varas). Nunca toca las fotos de referencia de la
// rutina: rutina/ ni <sede>/rutina/.
// La llama cada lunes 08:00 UTC el cron `limpiar-antiguos-semanal` (body {}).
// Con body {"prueba":true} solo cuenta lo que borraría, sin borrar nada.
import { createClient } from "npm:@supabase/supabase-js@2";

const DIAS = 30;
const BUCKET = "traspasos";
const FECHA = /^\d{4}-\d{2}-\d{2}$/;
const SEDE = /^[a-z0-9]{2,6}$/;                       // carpeta de otra sede en la raíz: s2/…
const NO_SEDE = ["guia", "rutina", "checks"];         // carpetas de La Florida en la raíz
const REFERENCIA = /^(?:[a-z0-9]{2,6}\/)?rutina\//;    // fotos de referencia: jamás

Deno.serve(async (req) => {
  const prueba = !!(await req.json().catch(() => ({})))?.prueba;
  const sb = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );
  const corteISO = new Date(Date.now() - DIAS * 864e5).toISOString();
  const corteFecha = corteISO.slice(0, 10);
  const resumen = {
    prueba, dias: DIAS, corte: corteFecha, sedes: ["lf"] as string[], traspasos: 0,
    checklists: {} as Record<string, number>, archivos: {} as Record<string, number>,
    errores: [] as string[],
  };
  const suma = (o: Record<string, number>, k: string) => { o[k] = (o[k] ?? 0) + 1; };
  const sedeDeCodigo = (c: string) => { const m = /^([a-z0-9]{2,6})~/.exec(c); return m ? m[1] : "lf"; };
  const sedeDeRuta = (p: string) => {
    const m = /^([a-z0-9]{2,6})\//.exec(p);
    return m && !NO_SEDE.includes(m[1]) ? m[1] : "lf";
  };

  const vistos = new Set<string>();                     // en prueba no se borra: no contar dos veces
  const borrarArchivos = async (paths: string[]) => {
    const nuevos = [...new Set(paths)].filter(p => !vistos.has(p) && !REFERENCIA.test(p));
    nuevos.forEach(p => vistos.add(p));
    for (let i = 0; i < nuevos.length; i += 100) {
      const lote = nuevos.slice(i, i + 100);
      if (prueba) { lote.forEach(p => suma(resumen.archivos, sedeDeRuta(p))); continue; }
      const { data, error } = await sb.storage.from(BUCKET).remove(lote);
      if (error) resumen.errores.push("storage: " + error.message);
      else (data ?? []).forEach(o => suma(resumen.archivos, sedeDeRuta(o.name)));
    }
  };
  const listar = async (ruta: string) => {
    const todo: { name: string; id: string | null }[] = [];
    for (let desde = 0; ; desde += 1000) {
      const { data, error } = await sb.storage.from(BUCKET).list(ruta, { limit: 1000, offset: desde });
      if (error) { resumen.errores.push("list " + (ruta || "raíz") + ": " + error.message); break; }
      todo.push(...(data ?? []));
      if (!data || data.length < 1000) break;
    }
    return todo;
  };

  // 1) Traspasos verificados viejos: sus fotos y sus filas
  const { data: tras, error: e1 } = await sb.from("traspasos_turno")
    .select("id,archivo").lt("created_at", corteISO).limit(1000);
  if (e1) resumen.errores.push("traspasos: " + e1.message);
  if (tras?.length) {
    await borrarArchivos(tras.map(t => t.archivo).filter(Boolean));
    if (prueba) resumen.traspasos = tras.length;
    else {
      const { error } = await sb.from("traspasos_turno").delete().lt("created_at", corteISO);
      if (error) resumen.errores.push("del traspasos: " + error.message);
      else resumen.traspasos = tras.length;
    }
  }

  // 2) Registros del día viejos, de todas las sedes (guia-… y s2~guia-…):
  //    sus fotos (la primera en «foto», todas en «fotos») y sus filas
  const filas: Record<string, number> = {};
  const fotos: string[] = [];
  for (let desde = 0; ; desde += 1000) {
    const { data, error } = await sb.from("checklists").select("codigo,estado")
      .lt("updated_at", corteISO).order("codigo").range(desde, desde + 999);
    if (error) { resumen.errores.push("checklists: " + error.message); break; }
    for (const c of data ?? []) {
      suma(filas, sedeDeCodigo(c.codigo));
      for (const t of (c.estado?.tareas ?? []))
        for (const f of [t.foto, ...(Array.isArray(t.fotos) ? t.fotos : [])])
          if (f) fotos.push(String(f));
    }
    if (!data || data.length < 1000) break;
  }
  await borrarArchivos(fotos);
  if (Object.keys(filas).length) {
    if (prueba) resumen.checklists = filas;
    else {
      const { error } = await sb.from("checklists").delete().lt("updated_at", corteISO);
      if (error) resumen.errores.push("del checklists: " + error.message);
      else resumen.checklists = filas;
    }
  }

  // 3) Carpetas por fecha: fotos que no figuran en ningún registro (las quitadas del día,
  //    las de traspasos). La Florida: raíz y guia/. Cada otra sede: <sede>/ y <sede>/guia/.
  const carpetasFecha = async (prefijo: string) => {
    for (const it of await listar(prefijo)) {
      if (it.id || !FECHA.test(it.name) || it.name >= corteFecha) continue;
      const ruta = prefijo ? prefijo + "/" + it.name : it.name;
      await borrarArchivos((await listar(ruta)).filter(f => f.id).map(f => ruta + "/" + f.name));
    }
  };
  const otras = (await listar(""))
    .filter(it => !it.id && SEDE.test(it.name) && !NO_SEDE.includes(it.name)).map(it => it.name);
  resumen.sedes.push(...otras);
  for (const pre of ["", ...otras]) {
    await carpetasFecha(pre);
    await carpetasFecha(pre ? pre + "/guia" : "guia");
  }

  return new Response(JSON.stringify(resumen), { headers: { "Content-Type": "application/json" } });
});
