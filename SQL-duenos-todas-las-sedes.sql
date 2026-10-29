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
-- =====================================================================

-- 1) Mirar antes de tocar. «dueño global (queda)» = el registro que vale para
--    todo; «copia por sede (se desactiva)» = la que sobra. Si un dueño NO sale
--    como global, agrégalo desde 👥 Usuarios con rol Dueño (desde cf-v70 se
--    guarda sin prefijo) y vuelve a correr este SQL.
with base as (
  select id, nombre, rol, activo,
         lower(translate(regexp_replace(nombre, '^[a-z0-9]{2,6}:', ''), 'áéíóúüÁÉÍÓÚÜñÑ', 'aeiouuAEIOUUnN')) as clave,
         nombre ~ '^[a-z0-9]{2,6}:' as con_prefijo
  from public.usuarios
  where rol = 'dueño'
)
select case when con_prefijo then 'copia por sede (se desactiva)' else 'dueño global (queda)' end as que_es,
       id, nombre, activo
from base
where not con_prefijo
   or clave in (select clave from base where not con_prefijo)
order by clave, con_prefijo;

-- 2) Desactivar las copias por sede de cada dueño global (mismo nombre sin
--    tildes ni prefijo). El PIN que vale es el del registro global.
with base as (
  select id, nombre, rol, activo,
         lower(translate(regexp_replace(nombre, '^[a-z0-9]{2,6}:', ''), 'áéíóúüÁÉÍÓÚÜñÑ', 'aeiouuAEIOUUnN')) as clave,
         nombre ~ '^[a-z0-9]{2,6}:' as con_prefijo
  from public.usuarios
  where rol = 'dueño'
)
update public.usuarios u
   set activo = false
  from base b
 where u.id = b.id
   and b.con_prefijo
   and b.clave in (select clave from base where not con_prefijo);

-- 3) Comprobación: cada dueño debe salir UNA sola vez activo y sin prefijo,
--    con tiene_pin = true si ya creó su PIN (si no, lo crea al entrar).
select nombre, rol, activo, (pin_hash is not null) as tiene_pin
from public.usuarios
where rol = 'dueño'
order by activo desc, nombre;
