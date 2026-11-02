-- ===================================================================
-- Maximarket PV (sede s3): equipo inicial, todos como colaborador y sin
-- puesto habitual (cada uno elige su puesto del día al entrar).
-- Correr en Supabase → proyecto checklist-turno → SQL Editor → Run.
-- Seguro de repetir: no duplica a nadie.
-- Lunes a viernes: Belén Ovando, Francisca Barrías, Yohana Saldivia.
-- Noche lunes a viernes: Diego Fernández.
-- Fin de semana: Mariela Ojeda, Sergio Navarrete, Renato Godoy.
-- ===================================================================

insert into public.usuarios (nombre, rol, activo)
select n, 'colaborador', true
from unnest(array[
  's3:Belén Ovando', 's3:Francisca Barrías', 's3:Yohana Saldivia',
  's3:Diego Fernández',
  's3:Mariela Ojeda', 's3:Sergio Navarrete', 's3:Renato Godoy'
]) as n
where not exists (select 1 from public.usuarios u where u.nombre = n);

-- Revisión: deben aparecer las 7 personas más s3:Ricardo.
select nombre, rol, activo, puesto from public.usuarios
where nombre like 's3:%' order by rol, nombre;
