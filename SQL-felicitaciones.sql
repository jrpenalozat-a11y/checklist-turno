-- ===================================================================
-- SQL-felicitaciones.sql
-- Felicitaciones del Checklist por local y por área.
--
--   Partida   el primer día que el local marca tareas.
--   30 a 90   promedio de los últimos 7 días cerrados, con 3 días como
--             mínimo. El día en curso no cuenta: sube de 0 a 100 en cada turno.
--   100 local un día con todas las tareas y todas las fotos obligatorias.
--   100 área  7 días seguidos con todas las tareas y todas las fotos.
--   Rachas    7, 14 y 28 días seguidos del local sobre 95 %.
--
-- Cada meta se felicita una sola vez. Si un local salta varias de golpe,
-- se anuncia solo la más alta. Lo ya logrado al instalar queda anotado y no
-- se anuncia: cada sede parte en el escalón donde va.
--
-- Crea dos tablas nuevas. No cambia ningún dato del Checklist.
-- Requiere: SQL-pulso.sql (el-pase/pulso), ya corrido.
--
-- ⚠️  APAGA EL TRADUCTOR DE GOOGLE antes de pegar esto en Supabase.
-- Supabase avisará de "operaciones destructivas": es por las palabras
-- replace y revoke. No borra ningún dato.
--
-- Dónde: Supabase → proyecto checklist-turno → SQL Editor → pegar → Run
-- Seguro de repetir: no duplica nada ni vuelve a anunciar lo anunciado.
-- Debe terminar con la línea: Listo: felicitaciones instaladas, funciones 6.
-- ===================================================================

-- 1) Las metas logradas, y el último día que se revisó cada sede.
create table if not exists public.felicitaciones (
  id         bigserial primary key,
  sede       text not null check (sede in ('lf', 's2', 's3')),
  alcance    text not null,                     -- 'local' o el área ('gen' = Turno 1)
  meta       text not null,                     -- partida, 30, 50, 70, 90, 100, racha7, racha14, racha28
  valor      integer,                           -- el promedio o los días de racha
  dia        date not null,
  personas   jsonb not null default '[]'::jsonb, -- quiénes trabajaron el área; vacío = todo el local
  anunciar   boolean not null default true,     -- false = ya estaba lograda, o la saltó una más alta
  created_at timestamptz not null default now(),
  unique (sede, alcance, meta)
);
create table if not exists public.felicitaciones_revision (
  sede text primary key,
  dia  date not null
);
alter table public.felicitaciones enable row level security;
alter table public.felicitaciones_revision enable row level security;
revoke all on table public.felicitaciones from anon, authenticated;
revoke all on table public.felicitaciones_revision from anon, authenticated;

-- 2) La rutina de una sede. config.valor puede venir como texto o como jsonb.
create or replace function public.felic_rutina(p_sede text)
returns jsonb
language plpgsql
stable
set search_path = public
as $$
declare
  t text;
  v jsonb;
begin
  select btrim(c.valor::text) into t
    from public.config c
   where c.clave = case when p_sede = 'lf' then 'rutina' else p_sede || ':rutina' end;
  if t is null or t = '' then return '{}'::jsonb; end if;
  v := t::jsonb;
  if jsonb_typeof(v) = 'string' then v := (v #>> '{}')::jsonb; end if;
  return case when jsonb_typeof(v) = 'object' then v else '{}'::jsonb end;
exception when others then
  return '{}'::jsonb;
end;
$$;

-- 3) Un día de una sede: lo mismo que resumenDia() de El Pase, más las fotos
--    obligatorias. Explicar por qué no hay foto no reemplaza a la foto.
create or replace function public.felic_dia(p_rutina jsonb, p_pre text, p_dia date)
returns jsonb
language sql
stable
set search_path = public
as $$
  with lista as (
    select e.x->>'id' as id, coalesce(nullif(e.x->>'p', ''), 'gen') as area, e.x->>'t' as tarea,
           public.pulso_si(e.x->'req') or public.pulso_si(e.x->'pi') as exige, e.o
      from jsonb_array_elements(public.pulso_lista(p_rutina->'base')
             || public.pulso_lista(p_rutina->'dias'->(extract(dow from p_dia)::int::text))) with ordinality as e(x, o)
  ),
  registros as (
    select public.pulso_lista(c.estado::jsonb->'tareas') as tareas,
           btrim(regexp_replace(coalesce(c.estado::jsonb->>'entrega', ''), '\s*\([^)]*\)\s*$', '')) as nombre
      from public.checklists c
     where c.codigo like p_pre || 'guia-' || to_char(p_dia, 'YYYY-MM-DD') || '-%'
  ),
  validos as (    -- abrir la app sin marcar nada no es un reporte
    select r.* from registros r
     where exists (select 1 from jsonb_array_elements(r.tareas) t(x)
                    where public.pulso_si(t.x->'ok') or public.pulso_si(t.x->'motivo') or public.pulso_si(t.x->'foto')
                       or jsonb_array_length(public.pulso_lista(t.x->'fotos')) > 0)
       and exists (select 1 from jsonb_array_elements(r.tareas) t(x) join lista l on l.id = t.x->>'id')
  ),
  marcas as (
    select v.nombre, t.x from validos v cross join lateral jsonb_array_elements(v.tareas) t(x)
  ),
  tareas as (
    select m.x->>'id' as id,
           bool_or(public.pulso_si(m.x->'ok')) as ok,
           bool_or(public.pulso_si(m.x->'motivo')) as motivo,
           bool_or(public.pulso_si(m.x->'foto') or jsonb_array_length(public.pulso_lista(m.x->'fotos')) > 0) as foto,
           array_agg(distinct coalesce(nullif(m.x#>>'{por,q}', ''), m.nombre))
             filter (where public.pulso_si(m.x->'ok')) as quienes
      from marcas m
     group by m.x->>'id'
  ),
  cuadro as (
    select l.id, l.area, l.tarea, l.exige, l.o, coalesce(t.ok, false) as ok,
           coalesce(t.motivo, false) as motivo, coalesce(t.foto, false) as foto, t.quienes
      from lista l left join tareas t on t.id = l.id
  ),
  gente as (
    select l.area, jsonb_agg(distinct q.quien) as personas
      from marcas m
      join lista l on l.id = m.x->>'id'
      cross join lateral (select coalesce(nullif(m.x#>>'{por,q}', ''), m.nombre) as quien) q
     where public.pulso_si(m.x->'ok') and q.quien <> ''
     group by l.area
  )
  select jsonb_build_object(
    'f', to_char(p_dia, 'YYYY-MM-DD'),
    'n', (select count(*) from validos),
    'tot', (select count(*) from cuadro),
    'ok', (select count(*) from cuadro c where c.ok),
    'completas', (select count(*) from cuadro c where c.ok and (c.foto or not c.exige)),
    'fotos', coalesce((select jsonb_agg(jsonb_build_object('a', c.area, 't', c.tarea, 'q', to_jsonb(c.quienes)) order by c.o)
                         from cuadro c where c.ok and c.exige and not c.foto), '[]'::jsonb),
    'areas', coalesce((
      select jsonb_agg(jsonb_build_object('a', a.area, 'tot', a.tot, 'ok', a.ok, 'completas', a.completas,
                                          'rep', a.rep, 'personas', coalesce(g.personas, '[]'::jsonb)))
        from (select c.area, count(*) as tot, count(*) filter (where c.ok) as ok,
                     count(*) filter (where c.ok and (c.foto or not c.exige)) as completas,
                     bool_or(c.ok or c.motivo) as rep
                from cuadro c group by c.area) a
        left join gente g on g.area = a.area), '[]'::jsonb));
$$;

-- 4) Anota metas nuevas. Si son varias, solo la última se anuncia.
create or replace function public.felic_anotar(p_sede text, p_alcance text, p_metas text[], p_valor integer,
                                               p_dia date, p_personas jsonb, p_anunciar boolean)
returns void
language plpgsql
set search_path = public
as $$
declare
  nuevas text[];
begin
  select array_agg(u.m order by u.o) into nuevas
    from unnest(p_metas) with ordinality as u(m, o)
   where not exists (select 1 from public.felicitaciones f
                      where f.sede = p_sede and f.alcance = p_alcance and f.meta = u.m);
  if nuevas is null then return; end if;
  insert into public.felicitaciones (sede, alcance, meta, valor, dia, personas, anunciar)
  select p_sede, p_alcance, u.m, p_valor, p_dia, coalesce(p_personas, '[]'::jsonb),
         p_anunciar and u.o = cardinality(nuevas)
    from unnest(nuevas) with ordinality as u(m, o)
  on conflict (sede, alcance, meta) do nothing;
end;
$$;

-- 5) Revisa los días cerrados de una sede. Corre una vez al día por sede.
create or replace function public.felic_revisar(p_sede text, p_anunciar boolean)
returns void
language plpgsql
set search_path = public
as $$
declare
  hoy     date    := public.pulso_hoy();
  pre     text    := case when p_sede = 'lf' then '' else p_sede || '~' end;
  rut     jsonb   := public.felic_rutina(p_sede);
  semana  jsonb[] := '{}';
  ventana jsonb   := '[]'::jsonb;
  d       jsonb;
  a       record;
  nd      integer;
  prom    integer;
  racha   integer := 0;
  gente   jsonb;
  perfecto date;
begin
  for i in 1..7 loop
    d := public.felic_dia(rut, pre, hoy - i);
    semana := semana || d;
    if (d->>'n')::int > 0 and (d->>'tot')::int > 0 then ventana := ventana || d; end if;
  end loop;
  if jsonb_array_length(ventana) = 0 then return; end if;

  perform public.felic_anotar(p_sede, 'local', array['partida'], null, hoy - 1, '[]'::jsonb, p_anunciar);

  select (x->>'f')::date into perfecto
    from jsonb_array_elements(ventana) x
   where x->>'completas' = x->>'tot'
   order by x->>'f' desc limit 1;
  if perfecto is not null then
    perform public.felic_anotar(p_sede, 'local', array['100'], 100, perfecto, '[]'::jsonb, p_anunciar);
  end if;

  select count(*), round(avg((x->>'ok')::numeric * 100 / (x->>'tot')::numeric))::int into nd, prom
    from jsonb_array_elements(ventana) x;
  if nd >= 3 then
    perform public.felic_anotar(p_sede, 'local',
      array(select m::text from unnest(array[30, 50, 70, 90]) m where prom >= m order by m),
      prom, hoy - 1, '[]'::jsonb, p_anunciar);
  end if;

  for a in
    select e->>'a' as area, count(*)::int as dias,
           round(avg((e->>'ok')::numeric * 100 / (e->>'tot')::numeric))::int as prom,
           count(*) filter (where e->>'completas' = e->>'tot')::int as perfectos
      from jsonb_array_elements(ventana) x
      cross join lateral jsonb_array_elements(x->'areas') e
     where (e->>'rep')::boolean
     group by e->>'a'
  loop
    continue when a.dias < 3;
    select coalesce(jsonb_agg(distinct q.v), '[]'::jsonb) into gente
      from jsonb_array_elements(ventana) x
      cross join lateral jsonb_array_elements(x->'areas') e
      cross join lateral jsonb_array_elements_text(e->'personas') q(v)
     where e->>'a' = a.area;
    perform public.felic_anotar(p_sede, a.area,
      array(select m::text from unnest(array[30, 50, 70, 90]) m where a.prom >= m order by m),
      a.prom, hoy - 1, gente, p_anunciar);
    if a.perfectos >= 7 then
      perform public.felic_anotar(p_sede, a.area, array['100'], 100, hoy - 1, gente, p_anunciar);
    end if;
  end loop;

  -- Racha: un día sin reportes no la corta, un día bajo 95 % sí.
  for i in 1..29 loop
    d := case when i <= 7 then semana[i] else public.felic_dia(rut, pre, hoy - i) end;
    continue when (d->>'n')::int = 0 or (d->>'tot')::int = 0;
    exit when (d->>'ok')::numeric * 100 < 95 * (d->>'tot')::numeric;
    racha := racha + 1;
  end loop;
  perform public.felic_anotar(p_sede, 'local',
    array_remove(array[case when racha >= 7 then 'racha7' end,
                       case when racha >= 14 then 'racha14' end,
                       case when racha >= 28 then 'racha28' end], null),
    racha, hoy - 1, '[]'::jsonb, p_anunciar);
end;
$$;

-- 6) Lo que pide la app: revisa si toca, mira el día en curso y devuelve las
--    metas anunciadas de los últimos 7 días y cómo va hoy.
create or replace function public.felicitaciones_leer(p_sede text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  hoy  date := public.pulso_hoy();
  toca integer;
  d    jsonb;
begin
  if p_sede is null or p_sede not in ('lf', 's2', 's3') then
    raise exception 'sede desconocida';
  end if;

  insert into public.felicitaciones_revision as r (sede, dia) values (p_sede, hoy)
  on conflict (sede) do update set dia = excluded.dia where r.dia < excluded.dia
  returning 1 into toca;
  if toca is not null then perform public.felic_revisar(p_sede, true); end if;

  d := public.felic_dia(public.felic_rutina(p_sede),
                        case when p_sede = 'lf' then '' else p_sede || '~' end, hoy);
  if (d->>'n')::int > 0 then
    perform public.felic_anotar(p_sede, 'local', array['partida'], null, hoy, '[]'::jsonb, true);
    if d->>'completas' = d->>'tot' then
      perform public.felic_anotar(p_sede, 'local', array['100'], 100, hoy, '[]'::jsonb, true);
    end if;
  end if;

  return jsonb_build_object('hoy', d, 'hitos', coalesce((
    select jsonb_agg(jsonb_build_object('id', f.id, 'alcance', f.alcance, 'meta', f.meta, 'valor', f.valor,
                                        'dia', f.dia, 'personas', f.personas) order by f.id)
      from public.felicitaciones f
     where f.sede = p_sede and f.anunciar and f.dia >= hoy - 7), '[]'::jsonb));
end;
$$;

-- 7) Al instalar: lo ya logrado queda anotado, sin anunciarlo.
create or replace function public.felic_sembrar()
returns void
language plpgsql
set search_path = public
as $$
declare
  s text;
begin
  foreach s in array array['lf', 's2', 's3'] loop
    if not exists (select 1 from public.felicitaciones_revision r where r.sede = s) then
      perform public.felic_revisar(s, false);
      insert into public.felicitaciones_revision (sede, dia) values (s, public.pulso_hoy());
    end if;
  end loop;
end;
$$;
select public.felic_sembrar();

-- 8) Permisos: la app solo puede llamar a felicitaciones_leer, y con su sesión
--    (trae nombres del equipo: no queda abierta a la llave pública sola).
revoke all on function public.felic_rutina(text) from public, anon, authenticated;
revoke all on function public.felic_dia(jsonb, text, date) from public, anon, authenticated;
revoke all on function public.felic_anotar(text, text, text[], integer, date, jsonb, boolean) from public, anon, authenticated;
revoke all on function public.felic_revisar(text, boolean) from public, anon, authenticated;
revoke all on function public.felic_sembrar() from public, anon, authenticated;
revoke all on function public.felicitaciones_leer(text) from public, anon;
grant execute on function public.felicitaciones_leer(text) to authenticated;

-- 9) Confirmación: funciones tiene que dar 6.
select 'Listo: felicitaciones instaladas' as resultado,
       (select count(*) from pg_proc where proname in ('felic_rutina', 'felic_dia', 'felic_anotar',
          'felic_revisar', 'felic_sembrar', 'felicitaciones_leer')) as funciones,
       (select count(*) from public.felicitaciones) as metas_ya_logradas;
