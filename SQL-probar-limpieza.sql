-- ===================================================================
-- Prueba de la limpieza semanal (Edge Function limpiar-antiguos).
-- NO BORRA NADA: le pide a la función que solo cuente lo que borraría.
-- Supabase → proyecto checklist-turno → SQL Editor → Run, esperar 10 segundos
-- y Run OTRA VEZ: la segunda vez aparece el resultado (la primera queda en camino).
--
-- Cómo leerlo: «archivos» y «checklists» van por sede (lf = La Florida,
-- s2 = Puerto Varas) y «sedes» debe decir ["lf","s2"]. «errores» debe ir vacío.
-- Si «estado» sale 401: en la función, Details → apagar «Verify JWT».
-- ===================================================================

select net.http_post(
  url := 'https://zmpiqkbvmjvfvxyvcdhi.supabase.co/functions/v1/limpiar-antiguos',
  headers := '{"Content-Type":"application/json"}'::jsonb,
  body := '{"prueba":true}'::jsonb
) as pedido;

select created as cuando, status_code as estado, content as resultado
from net._http_response
where content like '%"prueba":true%' or status_code <> 200
order by id desc
limit 1;
