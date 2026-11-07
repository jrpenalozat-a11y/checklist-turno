-- ═══════════════════════════════════════════════════════════════════
--  ESCRITURA SEGURA · PARTE 1 de 2 — solo AGREGA, no cierra nada
--
--  Hasta ahora la clave de mando se revisaba en el teléfono: la base
--  aceptaba que cualquiera con sesión cambiara roles, borrara gente o
--  reescribiera la config. Esta parte crea "puertas con llave": funciones
--  que exigen el PIN de una persona de mando y lo revisan DENTRO de la base.
--
--  También agrega el bloqueo: 5 PIN malos seguidos → 15 minutos de espera
--  (igual que Mi Turno). Vale para el panel (verificar_pin) y para
--  reiniciar_pin.
--
--  Después de correr esto todo sigue funcionando igual. La PARTE 2 (cerrar
--  las escrituras directas) va recién cuando el checklist nuevo lleve un día
--  publicado.
--
--  ⚠️  APAGA EL TRADUCTOR DE GOOGLE antes de pegar.
-- ═══════════════════════════════════════════════════════════════════

-- 1) Registro de intentos fallidos (nadie lo lee desde las apps)
create table if not exists public.pin_intentos (
  nombre          text primary key,
  fallos          int not null default 0,
  bloqueado_hasta timestamptz
);
alter table public.pin_intentos enable row level security;
revoke all on public.pin_intentos from anon, authenticated;

-- 2) El corazón: ¿este PIN es de esta persona? Con bloqueo.
--    Bloqueado → avisa con la hora. PIN malo → suma un fallo. PIN bueno → limpia.
create or replace function public.pin_valido(p_nombre text, p_hash text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare i public.pin_intentos%rowtype; ok boolean;
begin
  if p_nombre is null or p_hash is null then return false; end if;
  if not exists (select 1 from public.usuarios where nombre = p_nombre) then return false; end if;

  select * into i from public.pin_intentos where nombre = p_nombre;
  if found and i.bloqueado_hasta > now() then
    raise exception 'Demasiados intentos. Prueba de nuevo a las %.',
      to_char(i.bloqueado_hasta at time zone 'America/Santiago', 'HH24:MI');
  end if;

  select exists (
    select 1 from public.usuarios
     where nombre = p_nombre and coalesce(activo, true) = true
       and pin_hash is not null and pin_hash = p_hash
  ) into ok;

  if ok then
    delete from public.pin_intentos where nombre = p_nombre;
  else
    insert into public.pin_intentos (nombre, fallos) values (p_nombre, 1)
      on conflict (nombre) do update
        set fallos = case when public.pin_intentos.bloqueado_hasta <= now() then 1 else public.pin_intentos.fallos + 1 end,
            bloqueado_hasta = case
              when (case when public.pin_intentos.bloqueado_hasta <= now() then 1 else public.pin_intentos.fallos + 1 end) >= 5
              then now() + interval '15 minutes' else null end;
  end if;
  return ok;
end;
$$;
revoke all on function public.pin_valido(text, text) from public, anon, authenticated;

-- 3) verificar_pin (panel y checklist) ahora pasa por el bloqueo. Misma firma.
create or replace function public.verificar_pin(p_nombre text, p_hash text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  return public.pin_valido(p_nombre, p_hash);
end;
$$;

-- 4) reiniciar_pin: mismo comportamiento, con bloqueo para el PIN de quien lo pide
create or replace function public.reiniciar_pin(p_nombre text, p_admin text, p_hash_admin text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare n int;
begin
  if not public.pin_valido(p_admin, p_hash_admin) then return false; end if;
  if not exists (
    select 1 from public.usuarios
     where nombre = p_admin and coalesce(activo, true) = true
       and rol in ('dueño', 'encargado', 'encargado de local', 'jefe de local')
  ) then return false; end if;
  update public.usuarios set pin_hash = null where nombre = p_nombre;
  get diagnostics n = row_count;
  return n > 0;
end;
$$;

-- 5) Ayudantes: prefijo de sede ("s2:Ana" → "s2"; La Florida → '') y el rol de mando
create or replace function public.cl_sede(p text)
returns text language sql immutable as $$
  select coalesce(substring(coalesce(p, '') from '^([a-z0-9]{2,6}):'), '')
$$;

-- Devuelve el rol si quien pide es de mando y su PIN es correcto; si no, corta con error.
create or replace function public.cl_mando(p_admin text, p_hash text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare r text;
begin
  if not public.pin_valido(p_admin, p_hash) then raise exception 'PIN incorrecto'; end if;
  select case when rol = 'jefe de local' then 'encargado de local' else rol end into r
    from public.usuarios
   where nombre = p_admin and coalesce(activo, true) = true
     and rol in ('dueño', 'encargado', 'encargado de local', 'jefe de local');
  if r is null then raise exception 'Solo los dueños y encargados pueden hacer esto'; end if;
  return r;
end;
$$;
revoke all on function public.cl_mando(text, text) from public, anon, authenticated;

-- ¿Puede este admin tocar a esta persona/clave? Dueño de los tres locales: todo.
-- El resto: solo lo de su propio local.
create or replace function public.cl_alcance(p_admin text, p_rol text, p_objetivo text)
returns boolean language sql immutable as $$
  select (p_rol = 'dueño' and public.cl_sede(p_admin) = '')
      or public.cl_sede(p_admin) = public.cl_sede(p_objetivo)
$$;

-- 6) USUARIOS — crear
create or replace function public.cl_usr_crear(p_admin text, p_hash text, p_nombre text, p_rol text,
                                               p_nombres text, p_apellidos text, p_puesto text default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare r text; nuevo uuid;
begin
  r := public.cl_mando(p_admin, p_hash);
  -- un dueño nuevo va sin prefijo (es de los tres locales): lo crean dueños o el encargado
  if p_rol = 'dueño' then
    if r not in ('dueño', 'encargado') then raise exception 'Solo los dueños y el encargado crean dueños'; end if;
  elsif not public.cl_alcance(p_admin, r, p_nombre) then
    raise exception 'Esa persona es de otro local';
  end if;
  insert into public.usuarios (nombre, rol, nombres, apellidos, puesto)
    values (p_nombre, p_rol, p_nombres, p_apellidos, nullif(p_puesto, ''))
    returning id into nuevo;
  return nuevo;
end;
$$;

-- 7) USUARIOS — editar (nombres, apellidos, activo, rol, puesto; lo que venga)
create or replace function public.cl_usr_editar(p_admin text, p_hash text, p_id uuid, p_campos jsonb)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare r text; obj text;
begin
  r := public.cl_mando(p_admin, p_hash);
  select nombre into obj from public.usuarios where id = p_id;
  if obj is null then return false; end if;
  if not public.cl_alcance(p_admin, r, obj) then raise exception 'Esa persona es de otro local'; end if;
  update public.usuarios set
    nombres   = case when p_campos ? 'nombres'   then p_campos->>'nombres'   else nombres end,
    apellidos = case when p_campos ? 'apellidos' then p_campos->>'apellidos' else apellidos end,
    activo    = case when p_campos ? 'activo'    then (p_campos->>'activo')::boolean else activo end,
    rol       = case when p_campos ? 'rol'       then p_campos->>'rol'       else rol end,
    puesto    = case when p_campos ? 'puesto'    then nullif(p_campos->>'puesto', '') else puesto end
  where id = p_id;
  return true;
end;
$$;

-- 8) USUARIOS — borrar. Devuelve {id, nombre} como antes, o null si no existía.
create or replace function public.cl_usr_borrar(p_admin text, p_hash text, p_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare r text; obj text;
begin
  r := public.cl_mando(p_admin, p_hash);
  select nombre into obj from public.usuarios where id = p_id;
  if obj is null then return null; end if;
  if not public.cl_alcance(p_admin, r, obj) then raise exception 'Esa persona es de otro local'; end if;
  delete from public.usuarios where id = p_id;
  return jsonb_build_object('id', p_id, 'nombre', obj);
end;
$$;

-- 9) CONFIG — guardar (rutina, historial de la rutina, número de informes, clave vieja).
--    La rutina también la toca María en La Florida (marca PI), igual que en la app.
create or replace function public.cl_config_guardar(p_admin text, p_hash text, p_clave text, p_valor text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare r text; base text := regexp_replace(coalesce(p_clave, ''), '^[a-z0-9]{2,6}:', '');
begin
  if p_admin = 'María' and public.cl_sede(p_clave) = '' and base in ('rutina', 'rutina_log') then
    if not public.pin_valido(p_admin, p_hash) then raise exception 'PIN incorrecto'; end if;
  else
    r := public.cl_mando(p_admin, p_hash);
    if not public.cl_alcance(p_admin, r, p_clave) then raise exception 'Esa configuración es de otro local'; end if;
  end if;
  insert into public.config (clave, valor, updated_at) values (p_clave, p_valor, now())
    on conflict (clave) do update set valor = excluded.valor, updated_at = now();
  return true;
end;
$$;

-- 10) Que las apps puedan llamar a las puertas nuevas
grant execute on function public.cl_usr_crear(text, text, text, text, text, text, text) to anon, authenticated;
grant execute on function public.cl_usr_editar(text, text, uuid, jsonb)              to anon, authenticated;
grant execute on function public.cl_usr_borrar(text, text, uuid)                     to anon, authenticated;
grant execute on function public.cl_config_guardar(text, text, text, text)           to anon, authenticated;
