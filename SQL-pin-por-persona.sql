-- ═══════════════════════════════════════════════════════════════════
--  PIN POR PERSONA para la Supervisión de François
--  Reemplaza la clave compartida. El hash del PIN se guarda en la base
--  y NUNCA sale de ella: la app pregunta y el servidor responde sí o no.
--
--  ⚠️  APAGA EL TRADUCTOR DE GOOGLE antes de pegar esto en Supabase,
--      o traduce las palabras clave y rompe la consulta.
--
--  Dónde: Supabase → proyecto François → SQL Editor → pegar → Run
-- ═══════════════════════════════════════════════════════════════════

-- 1) Columna para el hash del PIN. Nunca se guarda el PIN en claro.
alter table public.usuarios add column if not exists pin_hash text;

-- 2) Que ese hash NO se pueda leer desde la app, ni con la llave pública.
revoke select (pin_hash) on public.usuarios from anon, authenticated;

-- 3) Verificar un PIN. Entra nombre + hash, sale true o false.
--    Solo pasa si la persona está activa Y tiene rol de mando.
create or replace function public.verificar_pin(p_nombre text, p_hash text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.usuarios
    where nombre = p_nombre
      and coalesce(activo, true) = true
      and rol in ('dueño', 'encargado', 'encargado de local', 'jefe de local')
      and pin_hash is not null
      and pin_hash = p_hash
  );
$$;

-- 4) ¿Esta persona ya tiene PIN? Para saber si hay que pedirle que lo cree.
create or replace function public.tiene_pin(p_nombre text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select coalesce(
    (select pin_hash is not null from public.usuarios where nombre = p_nombre),
    false
  );
$$;

-- 5) Crear el PIN la primera vez.
--    Solo funciona si la persona AÚN NO tiene uno: así nadie puede pisar
--    el PIN de otro desde la app. Para reiniciar uno, ver el final.
create or replace function public.crear_pin(p_nombre text, p_hash text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare n int;
begin
  update public.usuarios set pin_hash = p_hash
   where nombre = p_nombre
     and coalesce(activo, true) = true
     and rol in ('dueño', 'encargado', 'encargado de local', 'jefe de local')
     and pin_hash is null;
  get diagnostics n = row_count;
  return n > 0;
end;
$$;

-- 6) Registro de accesos: quién abrió la Supervisión y cuándo.
create table if not exists public.accesos_supervision (
  id     bigserial primary key,
  nombre text not null,
  ts     timestamptz not null default now()
);
alter table public.accesos_supervision enable row level security;

drop policy if exists "accesos insert" on public.accesos_supervision;
create policy "accesos insert" on public.accesos_supervision
  for insert to anon, authenticated with check (true);

drop policy if exists "accesos select" on public.accesos_supervision;
create policy "accesos select" on public.accesos_supervision
  for select to anon, authenticated using (true);

-- 7) Permisos para llamar a las funciones desde la app.
grant execute on function public.verificar_pin(text, text) to anon, authenticated;
grant execute on function public.tiene_pin(text)            to anon, authenticated;
grant execute on function public.crear_pin(text, text)      to anon, authenticated;


-- ═══════════════════════════════════════════════════════════════════
--  PARA DESPUÉS — no hace falta correrlo ahora
-- ═══════════════════════════════════════════════════════════════════

-- Si alguien olvida su PIN, se lo borras acá y la app le pedirá crear
-- uno nuevo la próxima vez. A propósito NO se puede hacer desde la app:
-- si se pudiera, cualquiera reiniciaría el PIN de otro.
--
--   update public.usuarios set pin_hash = null where nombre = 'Ángel Magallanes';

-- Para quitarle el acceso a alguien que se va del local:
--
--   update public.usuarios set activo = false where nombre = 'Fulano';

-- Para ver quién ha entrado a la Supervisión:
--
--   select nombre, ts from public.accesos_supervision order by ts desc limit 50;
