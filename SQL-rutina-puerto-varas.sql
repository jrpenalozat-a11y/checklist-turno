-- ===================================================================
-- Rutina de Puerto Varas (sede s2) + acceso de mando para crear al encargado
-- Correr UNA vez en Supabase → proyecto checklist-turno → SQL Editor → Run.
-- Seguro de repetir: no pisa una rutina de Puerto Varas que ya tenga tareas
-- ni duplica a Ricardo.
--
-- Origen: «TAREAS DIARIAS FRANCOIS PV.ods» (27-oct-2026), traducida con las
-- mismas reglas de La Florida: Turno 1 = sin puesto y [APERTURA];
-- Turno 2 general = Salón; Barra/caja = Caja; Cafetería/pastelería =
-- Barismo/Vitrina; Heladería = puesto propio de Puerto Varas; «Al cierre» =
-- [CIERRE]; la observación va tras « — ». 75 tareas fijas + «Dejar la
-- máquina de helados descongelando» solo de lunes a jueves.
-- Copia legible: archivo rutina-puerto-varas.json, en la carpeta «checklist puerto varas» del Escritorio.
-- ===================================================================

do $do$
declare
  v    text := $rv${"base":[{"id":"pv001","t":"[APERTURA] Encender las máquinas y vitrinas, incluido el termo hervidor — Llenar el hervidor si es necesario"},{"id":"pv002","t":"[APERTURA] Limpiar los ventanales y las manillas y listones de la puerta — Sacudir o aspirar la alfombra si es necesario"},{"id":"pv003","t":"[APERTURA] Barrer la calle"},{"id":"pv004","t":"[APERTURA] Limpiar a fondo las máquinas pasteleras y la vitrina de galletas"},{"id":"pv005","t":"[APERTURA] Revisar servilletas, azucareros y cubiertos — Reponer si es necesario"},{"id":"pv006","t":"[APERTURA] Reponer y peinar los helados"},{"id":"pv007","t":"[APERTURA] Revisar el stock de vasos, conos y paletas — Reponer si es necesario"},{"id":"pv008","t":"[APERTURA] Dejar el lavaplatos limpio y sin loza"},{"id":"pv009","t":"[APERTURA] Limpiar a fondo la máquina de leches"},{"id":"pv010","t":"[APERTURA] Revisar el stock de queso, jamón, tomate y lechuga — Si falta algo, pedirlo a Maximarket"},{"id":"pv011","t":"[APERTURA] Reponer las vitrinas de productos dulces y salados — Si falta bollería, pedirla a Maximarket"},{"id":"pv012","t":"[APERTURA] Hacer el aseo del baño del personal — Le toca a quien indica el horario de aseo de ese día"},{"id":"pv013","t":"Mantener limpios el piso, las mesas y las sillas — Limpiar las mesas solo cuando no haya clientes en ellas"},{"id":"pv014","t":"Informar las novedades al entregar el turno"},{"id":"pv015","t":"Revisar servilletas, tapas de café y cubiertos — Reponer si es necesario","p":"Salón"},{"id":"pv016","t":"Barrer la sala de ventas — Mantener el piso sin migas ni suciedad","p":"Salón"},{"id":"pv017","t":"Limpiar los espejos y los vidrios de las vitrinas — Durante el turno, cada vez que sea necesario","p":"Salón"},{"id":"pv018","t":"Ordenar las mesas y sillas — Repetirlo varias veces al día si es necesario: al limpiar las mesas, las migas caen y ensucian las sillas","p":"Salón"},{"id":"pv019","t":"Sacar la basura y las cajas a la calle — Para que no se acumulen","p":"Salón"},{"id":"pv020","t":"Mantener limpias las bandejas de tortas y galletas","p":"Salón"},{"id":"pv021","t":"[CIERRE] Limpiar el baño, el comedor del segundo piso y la escalera","p":"Salón"},{"id":"pv022","t":"[CIERRE] Sacar la basura del primer y del segundo piso — Dejar puesta una bolsa nueva","p":"Salón"},{"id":"pv023","t":"[CIERRE] Limpiar las mesas y ordenar las sillas — Las mesas en orden y las sillas limpias, cada una en su mesa","p":"Salón"},{"id":"pv024","t":"[CIERRE] Limpiar los vidrios de la vitrina de exposición — Sin manchas ni huellas","p":"Salón"},{"id":"pv025","t":"[CIERRE] Limpiar el piso de la sala de ventas","p":"Salón"},{"id":"pv026","t":"[CIERRE] Apagar las luces del primer y del segundo piso — Antes de irnos","p":"Salón"},{"id":"pv027","t":"Ordenar y reponer el cooler — Revisar el stock en bodega y avisar si algo se está acabando","p":"Caja"},{"id":"pv028","t":"Reponer las vitrinas y mantenerlas limpias","p":"Caja"},{"id":"pv029","t":"Limpiar a fondo el escritorio y la pantalla del computador — Sacar el polvo acumulado","p":"Caja"},{"id":"pv030","t":"Limpiar las repisas de galletas de la caja — Sacudir también las bolsas si tienen polvo","p":"Caja"},{"id":"pv031","t":"Ayudar a traer productos de Maximarket — Coordinar con Grace","p":"Caja"},{"id":"pv032","t":"Mantener limpio y ordenado el mesón de empaque","p":"Caja"},{"id":"pv033","t":"Reponer las bolsas de papel","p":"Caja"},{"id":"pv034","t":"Cortar papel François para empaque — Tenerlo listo para las horas de más público","p":"Caja"},{"id":"pv035","t":"Armar cajas para la entrega de productos — Tenerlas listas para las horas de más público","p":"Caja"},{"id":"pv036","t":"[CIERRE] Limpiar los vidrios de las vitrinas","p":"Caja"},{"id":"pv037","t":"[CIERRE] Limpiar los mesones de empaque","p":"Caja"},{"id":"pv038","t":"[CIERRE] Enviar fotos de la vitrina a la jefa","p":"Caja"},{"id":"pv039","t":"[CIERRE] Apagar las luces de las vitrinas","p":"Caja"},{"id":"pv040","t":"Revisar que el molinillo tenga café — Reponer si es necesario","p":"Barismo/Vitrina"},{"id":"pv041","t":"Revisar qué tortas y kuchen hay que impulsar en la venta — Según la lista de rotación","p":"Barismo/Vitrina"},{"id":"pv042","t":"Mantener repuesta la vitrina de productos dulces y salados — Hacer croissants si faltan","p":"Barismo/Vitrina"},{"id":"pv043","t":"Mantener limpios la máquina de café y los paños","p":"Barismo/Vitrina"},{"id":"pv044","t":"Mantener el lavaplatos limpio y sin loza","p":"Barismo/Vitrina"},{"id":"pv045","t":"Revisar los siropes y limpiar su sector","p":"Barismo/Vitrina"},{"id":"pv046","t":"Revisar la salsa de chocolate y el remojo de cuatro leches — Reponer si es necesario","p":"Barismo/Vitrina"},{"id":"pv047","t":"Ordenar la loza de la cafetería — Mantenerla limpia y en su lugar","p":"Barismo/Vitrina"},{"id":"pv048","t":"Revisar la nevera de leches — Reponer si es necesario","p":"Barismo/Vitrina"},{"id":"pv049","t":"[CIERRE] Reponer la leche y lavar las jarras de vaporizar — Las leches deben quedar listas para la mañana","p":"Barismo/Vitrina"},{"id":"pv050","t":"[CIERRE] Bajar café en grano de la bodega — Si es necesario","p":"Barismo/Vitrina"},{"id":"pv051","t":"[CIERRE] Reponer los vasos de café y las tapas — Si no hay, bajarlos de la bodega","p":"Barismo/Vitrina"},{"id":"pv052","t":"[CIERRE] Dejar ordenada la loza de la cafetera","p":"Barismo/Vitrina"},{"id":"pv053","t":"[CIERRE] Dejar ordenadas las tazas de café","p":"Barismo/Vitrina"},{"id":"pv054","t":"[CIERRE] Reponer el azúcar y los endulzantes en sobre","p":"Barismo/Vitrina"},{"id":"pv055","t":"[CIERRE] Limpiar la goma negra (alfombra antifatiga)","p":"Barismo/Vitrina"},{"id":"pv056","t":"[CIERRE] Dejar limpio y despejado el piso de la barra y la cafetería","p":"Barismo/Vitrina"},{"id":"pv057","t":"[CIERRE] Dejar la máquina de café apagada y limpia","p":"Barismo/Vitrina"},{"id":"pv058","t":"[CIERRE] Dejar el termo de agua para el té apagado y lleno","p":"Barismo/Vitrina"},{"id":"pv059","t":"[CIERRE] Dejar limpios las espátulas y los cuchillos","p":"Barismo/Vitrina"},{"id":"pv060","t":"[CIERRE] Dejar el lavaplatos sin loza y sin residuos","p":"Barismo/Vitrina"},{"id":"pv061","t":"[CIERRE] Revisar el papel Nova y el jabón — Reponer si es necesario","p":"Barismo/Vitrina"},{"id":"pv062","t":"[CIERRE] Dejar vacía la lavaloza","p":"Barismo/Vitrina"},{"id":"pv063","t":"[CIERRE] Limpiar los mesones y el exterior del Merrychef","p":"Barismo/Vitrina"},{"id":"pv064","t":"[CIERRE] Limpiar a fondo el Merrychef — Incluida la malla del ventilador","p":"Barismo/Vitrina"},{"id":"pv065","t":"Reponer y peinar los helados — Si es necesario","p":"Heladería"},{"id":"pv066","t":"Mantener limpios las rejillas y los vidrios de las máquinas de helado","p":"Heladería"},{"id":"pv067","t":"Mantener repuestos los conos, vasos y paletas","p":"Heladería"},{"id":"pv068","t":"Ayudar a traer productos de Maximarket","p":"Heladería"},{"id":"pv069","t":"Mantener limpias las repisas","p":"Heladería"},{"id":"pv070","t":"Mantener limpio el lavamanos","p":"Heladería"},{"id":"pv071","t":"[CIERRE] Dejar limpios los vidrios de las máquinas de helado","p":"Heladería"},{"id":"pv072","t":"[CIERRE] Dejar los tachos de basura limpios y con bolsa nueva","p":"Heladería"},{"id":"pv073","t":"[CIERRE] Dejar lavadas las paletas","p":"Heladería"},{"id":"pv074","t":"[CIERRE] Dejar limpio el piso de la heladería","p":"Heladería"},{"id":"pv075","t":"[CIERRE] Revisar el jabón y el papel Nova — Reponer si es necesario","p":"Heladería"}],"dias":{"1":[{"id":"pv076-1","t":"[CIERRE] Dejar la máquina de helados descongelando — Solo de lunes a jueves","p":"Heladería"}],"2":[{"id":"pv076-2","t":"[CIERRE] Dejar la máquina de helados descongelando — Solo de lunes a jueves","p":"Heladería"}],"3":[{"id":"pv076-3","t":"[CIERRE] Dejar la máquina de helados descongelando — Solo de lunes a jueves","p":"Heladería"}],"4":[{"id":"pv076-4","t":"[CIERRE] Dejar la máquina de helados descongelando — Solo de lunes a jueves","p":"Heladería"}]}}$rv$;
  logv text := '[{"f":"' || to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
               || '","q":"Ricardo","a":"cargó la rutina inicial","t":"Planilla TAREAS DIARIAS FRANCOIS PV (75 fijas + lunes a jueves)"}]';
  tipo text;
begin
  -- la app guarda texto (JSON.stringify); se respeta el tipo que tenga la columna
  select data_type into tipo from information_schema.columns
   where table_schema = 'public' and table_name = 'config' and column_name = 'valor';

  if tipo = 'jsonb' then
    insert into public.config (clave, valor, updated_at) values ('s2:rutina', to_jsonb(v), now())
    on conflict (clave) do update set valor = excluded.valor, updated_at = now()
      where coalesce(config.valor #>> '{}', '') in ('', '{}', '{"base":[],"dias":{}}');
    insert into public.config (clave, valor, updated_at) values ('s2:rutina_log', to_jsonb(logv), now())
    on conflict (clave) do nothing;
  else
    insert into public.config (clave, valor, updated_at) values ('s2:rutina', v, now())
    on conflict (clave) do update set valor = excluded.valor, updated_at = now()
      where coalesce(config.valor, '') in ('', '{}', '{"base":[],"dias":{}}');
    insert into public.config (clave, valor, updated_at) values ('s2:rutina_log', logv, now())
    on conflict (clave) do nothing;
  end if;

  -- primera persona de mando de Puerto Varas: con ella se entra a la sede y,
  -- en 👥 Usuarios, se crea al encargado del local
  insert into public.usuarios (nombre, rol, activo)
  select 's2:Ricardo', 'encargado', true
  where not exists (select 1 from public.usuarios where nombre = 's2:Ricardo');
end
$do$;

-- Revisión: debe decir «rutina cargada», 75 fijas y 4 días, y aparecer s2:Ricardo.
-- Si dice «ya tenía tareas: no se tocó», avísale a Claude antes de seguir.
with r as (
  select (case when left(valor::text, 1) = '"' then (valor::text)::jsonb #>> '{}' else valor::text end)::jsonb as j
  from public.config where clave = 's2:rutina'
)
select case when j::text like '%"pv001"%' then 'rutina cargada' else 'ya tenía tareas: no se tocó' end as rutina,
       jsonb_array_length(j -> 'base') as fijas,
       (select count(*) from jsonb_object_keys(j -> 'dias')) as dias,
       (select string_agg(nombre || ' (' || rol || ')', ', ') from public.usuarios where nombre like 's2:%') as usuarios_puerto_varas
from r;
