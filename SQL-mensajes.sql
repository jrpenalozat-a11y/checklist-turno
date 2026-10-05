-- =====================================================================
--  Mensajes del supervisor a quien sacó una foto (felicitación / observación)
--  Correr UNA vez en Supabase → SQL Editor. Se puede repetir sin romper nada.
--  ⚠️ Apagar el traductor de Google antes de pegar.
-- =====================================================================

create table if not exists public.mensajes (
  id         uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  de         text not null,                       -- quién lo escribe (mando)
  para       text not null,                       -- quién lo recibe (quien sacó la foto)
  tipo       text not null default 'observacion'
             check (tipo in ('felicitacion', 'observacion')),
  texto      text not null check (char_length(texto) between 1 and 500),
  foto       text,                                -- ruta de la foto en el bucket (opcional)
  tarea      text,                                -- texto de la tarea, para mostrarlo
  tarea_id   text,
  dia        date,                                -- día de la tarea comentada
  leido_at   timestamptz                          -- null = todavía no lo abre
);

create index if not exists mensajes_para_idx on public.mensajes (para, leido_at);
create index if not exists mensajes_foto_idx on public.mensajes (foto);

alter table public.mensajes enable row level security;

drop policy if exists "mensajes select" on public.mensajes;
drop policy if exists "mensajes insert" on public.mensajes;
drop policy if exists "mensajes leer"   on public.mensajes;

create policy "mensajes select" on public.mensajes
  for select to anon, authenticated using (true);
create policy "mensajes insert" on public.mensajes
  for insert to anon, authenticated with check (true);
create policy "mensajes leer" on public.mensajes
  for update to anon, authenticated using (true) with check (true);

-- Permisos: desde la app se puede leer, crear y marcar como leído. Nada más.
-- (Un GRANT a nivel de tabla cubre todas las columnas: por eso se quita todo
--  y se vuelve a dar solo lo necesario, con UPDATE únicamente sobre leido_at.)
revoke all on public.mensajes from anon, authenticated;
grant select on public.mensajes to anon, authenticated;
grant insert (de, para, tipo, texto, foto, tarea, tarea_id, dia) on public.mensajes to anon, authenticated;
grant update (leido_at) on public.mensajes to anon, authenticated;

-- Comprobación: debe devolver una fila con 0
select count(*) as mensajes from public.mensajes;

-- ---------------------------------------------------------------------
--  6-oct-2026: tercer tipo de mensaje, «aviso» (novedades generales)
-- ---------------------------------------------------------------------
alter table public.mensajes drop constraint if exists mensajes_tipo_check;
alter table public.mensajes add constraint mensajes_tipo_check
  check (tipo in ('felicitacion', 'observacion', 'aviso'));
