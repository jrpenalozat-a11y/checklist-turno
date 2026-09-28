-- ═══════════════════════════════════════════════════════════════════
--  URGENTE — que nadie pueda escribir el PIN directamente
--
--  crear_pin y reiniciar_pin comprueban quién eres, pero la columna
--  pin_hash quedó escribible desde la app con la llave pública: se
--  podían saltar las dos funciones y ponerle un PIN a cualquiera.
--
--  Igual que con la lectura: un GRANT a nivel de TABLA cubre todas las
--  columnas. Hay que quitarlo y devolverlo solo sobre las que la app
--  necesita escribir. pin_hash queda fuera, y solo lo tocan las
--  funciones (que corren como dueñas de la tabla).
--
--  ⚠️  APAGA EL TRADUCTOR DE GOOGLE antes de pegar.
--  Supabase avisará de "operaciones destructivas": es por revoke.
--  No borra ningún dato.
-- ═══════════════════════════════════════════════════════════════════

-- 1) Quitar escritura sobre toda la tabla
revoke update on public.usuarios from anon, authenticated;
revoke insert on public.usuarios from anon, authenticated;

-- 2) Devolverla solo sobre las columnas que la app usa.
--    pin_hash NO está: solo crear_pin y reiniciar_pin pueden tocarlo.
grant update (nombre, rol, activo, puesto) on public.usuarios to anon, authenticated;
grant insert (nombre, rol, activo, puesto) on public.usuarios to anon, authenticated;


-- ═══════════════════════════════════════════════════════════════════
--  COMPROBACIÓN — descomenta si quieres verlo con tus ojos
-- ═══════════════════════════════════════════════════════════════════
--
--   -- debe FALLAR:
--   update public.usuarios set pin_hash = 'x' where nombre = 'Ricardo';
--
--   -- debe funcionar:
--   update public.usuarios set puesto = puesto where nombre = 'Ricardo';
