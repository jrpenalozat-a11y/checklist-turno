-- ═══════════════════════════════════════════════════════════════════
--  PIN PARA TODOS LOS USUARIOS (no solo los de mando)
--
--  Cada persona entra con su PIN. Se pide una vez por teléfono.
--  El hash sigue viviendo en la base y no se puede leer desde la app.
--
--  ⚠️  APAGA EL TRADUCTOR DE GOOGLE antes de pegar.
--  Supabase avisará de "operaciones destructivas": es por la palabra
--  replace. No borra ningún dato.
--
--  Supabase → proyecto François → SQL Editor → pegar → Run
-- ═══════════════════════════════════════════════════════════════════

-- 1) Verificar el PIN de cualquier usuario activo (antes solo los de mando)
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
      and pin_hash is not null
      and pin_hash = p_hash
  );
$$;

-- 2) Crear el PIN la primera vez, para cualquier usuario activo.
--    Solo funciona si aún no tiene uno: nadie puede pisar el de otro.
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
     and pin_hash is null;
  get diagnostics n = row_count;
  return n > 0;
end;
$$;

-- 3) Reiniciar el PIN de alguien que lo olvidó.
--    Lo pide un dueño o el encargado, y tiene que dar SU PROPIO PIN:
--    así nadie reinicia el de otro desde la app sin ser quien dice ser.
create or replace function public.reiniciar_pin(p_nombre text, p_admin text, p_hash_admin text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare n int;
begin
  if not exists (
    select 1 from public.usuarios
     where nombre = p_admin
       and coalesce(activo, true) = true
       and rol in ('dueño', 'encargado')
       and pin_hash is not null
       and pin_hash = p_hash_admin
  ) then
    return false;
  end if;

  update public.usuarios set pin_hash = null where nombre = p_nombre;
  get diagnostics n = row_count;
  return n > 0;
end;
$$;

grant execute on function public.verificar_pin(text, text)         to anon, authenticated;
grant execute on function public.tiene_pin(text)                   to anon, authenticated;
grant execute on function public.crear_pin(text, text)             to anon, authenticated;
grant execute on function public.reiniciar_pin(text, text, text)   to anon, authenticated;


-- ═══════════════════════════════════════════════════════════════════
--  PARA DESPUÉS — no hace falta ahora
-- ═══════════════════════════════════════════════════════════════════

-- Reiniciar un PIN a mano (alternativa al botón de la app):
--   update public.usuarios set pin_hash = null where nombre = 'Alison';

-- Ver quién ya tiene PIN creado:
--   select nombre, rol, (pin_hash is not null) as tiene_pin
--     from public.usuarios where coalesce(activo,true) order by rol, nombre;

-- Quitarle el acceso a alguien que se va:
--   update public.usuarios set activo = false where nombre = 'Fulano';
