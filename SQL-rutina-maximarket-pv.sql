-- ===================================================================
-- Rutina de Maximarket PV (sede s3)
-- Correr UNA vez en Supabase → proyecto checklist-turno → SQL Editor → Run.
-- Seguro de repetir: no pisa una rutina de Maximarket PV que ya tenga tareas
-- ni duplica a Ricardo.
--
-- Origen: Planilla TAREAS DIARIAS Y DE CIERRE MAXIMARKET (74 fijas + 2 solo algunos días).
-- Generado con herramientas/planilla-a-rutina.py; copia legible: rutina-maximarket-pv.json.
-- ===================================================================

do $do$
declare
  v    text := $rv${"base":[{"id":"mx001","t":"[APERTURA] Contar los cigarros en la planilla al iniciar el turno"},{"id":"mx002","t":"[APERTURA] Reponer productos, pan, salchichas y vitrinas del sector de caja"},{"id":"mx003","t":"[APERTURA] Reponer el salsero de completos"},{"id":"mx004","t":"[APERTURA] Limpiar y ordenar el salón de comida — Revisar si hay que reponer la cafetera, los servilleteros o la bebida refill"},{"id":"mx005","t":"[APERTURA] Reponer los líquidos — En todas las máquinas: bebidas, jugos y alcohólicas"},{"id":"mx006","t":"[APERTURA] Reponer los snacks — Everscryp y Marco Polo"},{"id":"mx007","t":"[APERTURA] Revisar la basura y cambiar la bolsa cada vez que sea necesario"},{"id":"mx008","t":"[APERTURA] Limpiar el salchichero — A una hora tranquila, sin flujo de clientes"},{"id":"mx009","t":"[APERTURA] Limpiar el horno — A una hora tranquila, sin flujo de clientes"},{"id":"mx010","t":"[APERTURA] Limpiar los vidrios de las máquinas y las superficies"},{"id":"mx011","t":"[APERTURA] Revisar el baño a mitad de turno — Reponer confort o toalla Nova, o higienizarlo si hace falta"},{"id":"mx012","t":"[APERTURA] Revisar las fechas de vencimiento"},{"id":"mx013","t":"[APERTURA] Hacer pan para la venta — Reponer antes de las 6 AM y cada vez que sea necesario"},{"id":"mx014","t":"Contar los cigarros al terminar el turno"},{"id":"mx015","t":"Limpiar los baños al terminar el turno"},{"id":"mx016","t":"Contar los cigarros al iniciar el turno","p":"Turno 2"},{"id":"mx017","t":"Hacer la limpieza digital de la cafetera","p":"Turno 2"},{"id":"mx018","t":"Hornear la bollería de François","p":"Turno 2"},{"id":"mx019","t":"Hornear la bollería de Maximarket","p":"Turno 2"},{"id":"mx020","t":"Hornear pan para la venta — Hallulla, marraqueta y dobladita","p":"Turno 2"},{"id":"mx021","t":"Revisar la basura y cambiar la bolsa cada vez que sea necesario","p":"Turno 2"},{"id":"mx022","t":"Reponer la vitrina salada — Fajitas, croissants, empanadas, etc.","p":"Turno 2"},{"id":"mx023","t":"Reponer la vitrina dulce — Producción de pastelería, bollería congelada, strudel, etc.","p":"Turno 2"},{"id":"mx024","t":"Reponer los líquidos — Bebidas, jugos, cervezas, espumantes, licores, etc.","p":"Turno 2"},{"id":"mx025","t":"Reponer las góndolas — Everscryp, Marco Polo, Soprole, abarrotes e Ideal","p":"Turno 2"},{"id":"mx027","t":"Limpiar el salón — Higienizar salseros, bebida refill, máquinas de café, mesas y salón","p":"Turno 2"},{"id":"mx028","t":"Reponer los insumos — Azúcar, stevia, tapas de café, cubiertos, servilletas y revolvedores","p":"Turno 2"},{"id":"mx029","t":"Cambiar el letrero a las 12:00","p":"Turno 2"},{"id":"mx030","t":"Revisar las fechas de vencimiento — Anotar las fechas próximas y avisar lo que esté por vencer","p":"Turno 2"},{"id":"mx031","t":"Contar los cigarros al terminar el turno","p":"Turno 2"},{"id":"mx032","t":"Cerrar la caja y entregar el turno a las 15:15","p":"Turno 2"},{"id":"mx033","t":"Limpiar el baño al terminar el turno, antes de salir a colación","p":"Turno 2"},{"id":"mx034","t":"Contar los cigarros al iniciar el turno","p":"Turno 3"},{"id":"mx035","t":"Hornear la bollería de François","p":"Turno 3"},{"id":"mx036","t":"Revisar la basura y cambiar la bolsa cada vez que sea necesario","p":"Turno 3"},{"id":"mx037","t":"Hornear pan para el turno de la tarde — Hallulla, marraqueta y dobladita","p":"Turno 3"},{"id":"mx038","t":"Reponer la vitrina salada — Fajitas, croissants, empanadas, etc.","p":"Turno 3"},{"id":"mx039","t":"Reponer la vitrina dulce — Producción de pastelería, bollería congelada, strudel, etc.","p":"Turno 3"},{"id":"mx040","t":"Limpiar la cafetera","p":"Turno 3"},{"id":"mx042","t":"Reponer la confitería","p":"Turno 3"},{"id":"mx043","t":"Limpiar el horno","p":"Turno 3"},{"id":"mx044","t":"Limpiar el salsero","p":"Turno 3"},{"id":"mx045","t":"Reponer el salchichero","p":"Turno 3"},{"id":"mx046","t":"Reponer las cecinas Llanquihue","p":"Turno 3"},{"id":"mx047","t":"Revisar las fechas de vencimiento — Todo el sector de caja: anotar las fechas y avisar lo que esté por vencer","p":"Turno 3"},{"id":"mx048","t":"Reponer los precios — Revisar las góndolas","p":"Turno 3"},{"id":"mx049","t":"Revisar e higienizar los baños — Reponer toalla Nova y confort en ambos baños","p":"Reposición"},{"id":"mx050","t":"Reponer los líquidos — Aguas, jugos, bebidas y alcohol","p":"Reposición"},{"id":"mx051","t":"Reponer los snacks — Marco Polo, Everscryp y galletas","p":"Reposición"},{"id":"mx052","t":"Reponer Soprole — Yogur, lácteos y leche","p":"Reposición"},{"id":"mx053","t":"Reponer los abarrotes — Binder, Ideal y Dimak","p":"Reposición"},{"id":"mx054","t":"Limpiar las góndolas","p":"Reposición"},{"id":"mx055","t":"Limpiar el salón y las mesas","p":"Reposición"},{"id":"mx056","t":"Ordenar la bodega — Ordenarla o mantener el orden","p":"Reposición"},{"id":"mx057","t":"Limpiar el carro de reposición","p":"Reposición"},{"id":"mx058","t":"Limpiar los vidrios y las superficies","p":"Reposición"},{"id":"mx059","t":"Limpiar la máquina refill","p":"Reposición"},{"id":"mx060","t":"Limpiar el frontis de Maximarket","p":"Reposición"},{"id":"mx061","t":"Barrer y trapear el local","p":"Reposición"},{"id":"mx062","t":"Revisar la basura y cambiar la bolsa cada vez que sea necesario","p":"Reposición"},{"id":"mx063","t":"Revisar las fechas de vencimiento — Anotar las fechas próximas y avisar lo que esté por vencer","p":"Reposición"},{"id":"mx064","t":"Limpiar el comedor — Limpiarlo o mantenerlo limpio","p":"Reposición"},{"id":"mx065","t":"Limpiar el cuarto frío — Limpiarlo o mantenerlo limpio","p":"Reposición"},{"id":"mx066","t":"[CIERRE] Limpiar las cafeteras y reponer los productos — Dejar repuestos los polvos para la mañana","p":"Cafetería"},{"id":"mx067","t":"[CIERRE] Reponer los vasos de café y las tapas","p":"Cafetería"},{"id":"mx068","t":"[CIERRE] Dejar ordenados los vasos de café, espresso y bebida","p":"Cafetería"},{"id":"mx069","t":"[CIERRE] Dejar limpio y ordenado el piso de la cocina y la caja","p":"Cafetería"},{"id":"mx070","t":"[CIERRE] Dejar limpios el salón y la cafetería — Reponer si es necesario","p":"Cafetería"},{"id":"mx071","t":"[CIERRE] Dejar los tachos de basura limpios y con bolsa nueva","p":"Horno/Cocina"},{"id":"mx072","t":"[CIERRE] Hacer los sándwiches","p":"Horno/Cocina"},{"id":"mx073","t":"[CIERRE] Abastecer el pan","p":"Horno/Cocina"},{"id":"mx074","t":"[CIERRE] Dejar limpios el salchichero, el horno y el Merrychef","p":"Horno/Cocina"},{"id":"mx075","t":"[CIERRE] Dejar limpio el mesón de la cocina","p":"Horno/Cocina"},{"id":"mx076","t":"[CIERRE] Dejar limpios la lonchera y los mesones","p":"Horno/Cocina"}],"dias":{"1":[{"id":"mx026-1","t":"Limpiar los salseros de completos — Solo los lunes y viernes","p":"Turno 2"}],"3":[{"id":"mx041-3","t":"Limpiar el salsero — Solo los miércoles","p":"Turno 3"}],"5":[{"id":"mx026-5","t":"Limpiar los salseros de completos — Solo los lunes y viernes","p":"Turno 2"}]}}$rv$;
  logv text := '[{"f":"' || to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
               || '","q":"Ricardo","a":"cargó la rutina inicial","t":"Planilla TAREAS DIARIAS Y DE CIERRE MAXIMARKET (74 fijas + 2 solo algunos días)"}]';
  tipo text;
begin
  -- la app guarda texto (JSON.stringify); se respeta el tipo que tenga la columna
  select data_type into tipo from information_schema.columns
   where table_schema = 'public' and table_name = 'config' and column_name = 'valor';

  if tipo = 'jsonb' then
    insert into public.config (clave, valor, updated_at) values ('s3:rutina', to_jsonb(v), now())
    on conflict (clave) do update set valor = excluded.valor, updated_at = now()
      where coalesce(config.valor #>> '{}', '') in ('', '{}', '{"base":[],"dias":{}}');
    insert into public.config (clave, valor, updated_at) values ('s3:rutina_log', to_jsonb(logv), now())
    on conflict (clave) do nothing;
  else
    insert into public.config (clave, valor, updated_at) values ('s3:rutina', v, now())
    on conflict (clave) do update set valor = excluded.valor, updated_at = now()
      where coalesce(config.valor, '') in ('', '{}', '{"base":[],"dias":{}}');
    insert into public.config (clave, valor, updated_at) values ('s3:rutina_log', logv, now())
    on conflict (clave) do nothing;
  end if;

  -- primera persona de mando de la sede: con ella se entra y, en 👥 Usuarios,
  -- se crea al encargado del local
  insert into public.usuarios (nombre, rol, activo)
  select 's3:Ricardo', 'encargado', true
  where not exists (select 1 from public.usuarios where nombre = 's3:Ricardo');
end
$do$;

-- Revisión: debe decir «rutina cargada», 74 fijas y 3 días, y aparecer s3:Ricardo.
-- Si dice «ya tenía tareas: no se tocó», avísale a Claude antes de seguir.
with r as (
  select (case when left(valor::text, 1) = '"' then (valor::text)::jsonb #>> '{}' else valor::text end)::jsonb as j
  from public.config where clave = 's3:rutina'
)
select case when j::text like '%"mx001"%' then 'rutina cargada' else 'ya tenía tareas: no se tocó' end as rutina,
       jsonb_array_length(j -> 'base') as fijas,
       (select count(*) from jsonb_object_keys(j -> 'dias')) as dias,
       (select string_agg(nombre || ' (' || rol || ')', ', ') from public.usuarios where nombre like 's3:%') as usuarios_sede
from r;
