-- =====================================================================
--  Respuestas a los mensajes (13-nov-2026)
--  Ángel, encargado de local de La Florida, puede responder los mensajes
--  que María José manda en La Florida. La respuesta es una fila más de
--  `mensajes`: tipo «respuesta» y `respuesta_a` = el mensaje original.
--  Correr UNA vez en Supabase → SQL Editor. Se puede repetir sin romper nada.
--  ⚠️ Apagar el traductor de Google antes de pegar.
-- =====================================================================

alter table public.mensajes
  add column if not exists respuesta_a uuid references public.mensajes(id);

create index if not exists mensajes_respuesta_idx on public.mensajes (respuesta_a);

alter table public.mensajes drop constraint if exists mensajes_tipo_check;
alter table public.mensajes add constraint mensajes_tipo_check
  check (tipo in ('felicitacion', 'observacion', 'aviso', 'respuesta'));

-- Igual que el resto del mensaje: se puede crear con ese dato, no cambiarlo después.
grant insert (respuesta_a) on public.mensajes to anon, authenticated;

-- Comprobación: debe devolver una fila que diga «respuestas instaladas»
select 'respuestas instaladas' as resultado, count(*) as columna_creada
from information_schema.columns
where table_schema = 'public' and table_name = 'mensajes' and column_name = 'respuesta_a';
