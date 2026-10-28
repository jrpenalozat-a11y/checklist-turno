-- ===================================================================
-- Maximarket PV (sede s3): primera persona de mando
-- Correr UNA vez en Supabase → proyecto checklist-turno → SQL Editor → Run.
-- Seguro de repetir: no duplica a Ricardo ni toca a nadie más.
--
-- La sede parte vacía (sin tareas, sin registros y sin equipo). Con
-- s3:Ricardo se entra a Maximarket PV, se crea el PIN y, en 👥 Usuarios,
-- se agrega al encargado del local con rol «Encargado de local».
-- La rutina se cargará después, con su propio SQL, cuando llegue la planilla.
-- ===================================================================

insert into public.usuarios (nombre, rol, activo)
select 's3:Ricardo', 'encargado', true
where not exists (select 1 from public.usuarios where nombre = 's3:Ricardo');

-- Revisión: debe aparecer «s3:Ricardo (encargado)» y rutina «vacía».
select (select string_agg(nombre || ' (' || rol || ')', ', ') from public.usuarios where nombre like 's3:%') as usuarios_maximarket,
       coalesce((select 'ya tiene rutina' from public.config where clave = 's3:rutina'), 'vacía') as rutina;
