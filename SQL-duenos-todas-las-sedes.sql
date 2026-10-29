-- =====================================================================
--  Dueños únicos para las tres sedes (María José y Maximiliano)
--  Correr UNA vez en Supabase → SQL Editor. Se puede repetir sin romper nada.
--  ⚠️ Apagar el traductor de Google antes de pegar.
--
--  Desde la versión cf-v70 la app muestra en TODAS las sedes a los dueños
--  cuyo registro no lleva prefijo (el de La Florida), con el mismo nombre y
--  el mismo PIN. Este SQL deja sólo ese registro activo y desactiva las
--  copias por sede («s2:María Jose», «s3:Maximiliano»…) para que no salgan
--  dos veces en la lista de quién entra. No borra nada.
--
--  Cómo empareja: por el nombre sin prefijo, sin tildes, sin espacios de más
--  y sin distinguir mayúsculas. «s2:María Jose» y «María José» son la misma.
-- =====================================================================

-- 1) MIRAR ANTES DE TOCAR. Salen todos los dueños, con lo que va a pasar:
--      · dueño global (queda) ............... el registro sin prefijo, activo: vale para todo
--      · copia por sede (se desactiva) ...... sobra: ya hay un dueño global con ese nombre
--      · copia sin dueño global activo (revisar) ... no se toca. Si es un dueño de verdad,
--                                              agrégalo desde 👥 Usuarios con rol Dueño (desde
--                                              cf-v70 se guarda sin prefijo) y vuelve a correr esto
--      · dueño global INACTIVO (revisar) .... no se toca nada de ese nombre (sus copias siguen
--                                              activas): actívalo en 👥 Usuarios de La Florida
--                                              si corresponde y vuelve a correr esto
with base as (
  select id, nombre, rol, activo, pin_hash,
         lower(regexp_replace(btrim(translate(regexp_replace(nombre, '^[a-z0-9]{2,6}:', ''),
                                              'áéíóúüÁÉÍÓÚÜñÑ', 'aeiouuAEIOUUnN')), '\s+', ' ', 'g')) as clave,
         nombre ~ '^[a-z0-9]{2,6}:' as con_prefijo
  from public.usuarios
  where lower(rol) = 'dueño'
), globales as (
  select clave from base where not con_prefijo and coalesce(activo, true)
)
select case
         when not con_prefijo and coalesce(activo, true) then 'dueño global (queda)'
         when not con_prefijo                            then 'dueño global INACTIVO (revisar)'
         when clave in (select clave from globales)      then 'copia por sede (se desactiva)'
         else 'copia sin dueño global activo (revisar)'
       end as que_pasa,
       nombre, activo, (pin_hash is not null) as tiene_pin, id
from base
order by clave, con_prefijo, nombre;

-- 2) Si el dueño global todavía no tiene PIN y alguna copia sí, se le traspasa
--    ese PIN: así sigue entrando con el que ya usaba. (Si hubiera más de una
--    copia con PIN distinto, se toma la primera por nombre, p. ej. la de s2.)
with base as (
  select id, nombre, activo, pin_hash,
         lower(regexp_replace(btrim(translate(regexp_replace(nombre, '^[a-z0-9]{2,6}:', ''),
                                              'áéíóúüÁÉÍÓÚÜñÑ', 'aeiouuAEIOUUnN')), '\s+', ' ', 'g')) as clave,
         nombre ~ '^[a-z0-9]{2,6}:' as con_prefijo
  from public.usuarios
  where lower(rol) = 'dueño'
)
update public.usuarios u
   set pin_hash = (select c.pin_hash from base c
                    where c.con_prefijo and c.clave = g.clave and c.pin_hash is not null
                    order by c.nombre limit 1)
  from base g
 where u.id = g.id
   and not g.con_prefijo
   and coalesce(g.activo, true)
   and g.pin_hash is null
   and exists (select 1 from base c where c.con_prefijo and c.clave = g.clave and c.pin_hash is not null);

-- 3) Desactivar las copias por sede de cada dueño global activo.
with base as (
  select id, nombre, activo,
         lower(regexp_replace(btrim(translate(regexp_replace(nombre, '^[a-z0-9]{2,6}:', ''),
                                              'áéíóúüÁÉÍÓÚÜñÑ', 'aeiouuAEIOUUnN')), '\s+', ' ', 'g')) as clave,
         nombre ~ '^[a-z0-9]{2,6}:' as con_prefijo
  from public.usuarios
  where lower(rol) = 'dueño'
)
update public.usuarios u
   set activo = false
  from base b
 where u.id = b.id
   and b.con_prefijo
   and coalesce(u.activo, true)
   and b.clave in (select clave from base where not con_prefijo and coalesce(activo, true));

-- 4) Comprobación: cada dueño debe salir UNA sola vez activo y sin prefijo,
--    con tiene_pin = true si ya tenía PIN (si no, lo crea al entrar).
select nombre, rol, activo, (pin_hash is not null) as tiene_pin
from public.usuarios
where lower(rol) = 'dueño'
order by activo desc nulls first, nombre;
