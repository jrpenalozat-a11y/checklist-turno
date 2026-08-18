-- ═══════════════════════════════════════════════════════════════════
--  ARREGLO — que el hash del PIN no se pueda leer
--
--  En PostgreSQL un GRANT SELECT a nivel de TABLA cubre todas las
--  columnas, y un REVOKE sobre una columna suelta no lo anula.
--  Hay que quitar el permiso de la tabla y volver a darlo solo sobre
--  las columnas que la app necesita ver.
--
--  ⚠️  APAGA EL TRADUCTOR DE GOOGLE antes de pegar.
--  Supabase va a volver a avisar de "operaciones destructivas": es por
--  la palabra revoke. No borra ningún dato.
-- ═══════════════════════════════════════════════════════════════════

-- 1) Quitar la lectura de toda la tabla
revoke select on public.usuarios from anon, authenticated;

-- 2) Devolverla solo sobre las columnas que la app usa.
--    pin_hash queda fuera a propósito: nadie lo lee nunca.
grant select (id, nombre, rol, activo, puesto) on public.usuarios to anon, authenticated;

-- 3) Comprobación: la primera debe dar error, la segunda debe funcionar.
--    (Descoméntalas si quieres verlo con tus ojos.)
--
--   select nombre, pin_hash from public.usuarios limit 1;   -- debe FALLAR
--   select nombre, rol      from public.usuarios limit 1;   -- debe funcionar
