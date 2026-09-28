-- ═══════════════════════════════════════════════════════════════════
--  Que el encargado de local (Ángel) también pueda reiniciar PIN
--
--  La función solo aceptaba a dueños y encargado. Ahora los tres roles
--  de mando tienen acceso completo, igual que en la app.
--
--  ⚠️  APAGA EL TRADUCTOR DE GOOGLE antes de pegar.
-- ═══════════════════════════════════════════════════════════════════

create or replace function public.reiniciar_pin(p_nombre text, p_admin text, p_hash_admin text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare n int;
begin
  -- quien lo pide debe ser de mando y dar SU propio PIN
  if not exists (
    select 1 from public.usuarios
     where nombre = p_admin
       and coalesce(activo, true) = true
       and rol in ('dueño', 'encargado', 'encargado de local', 'jefe de local')
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

grant execute on function public.reiniciar_pin(text, text, text) to anon, authenticated;
