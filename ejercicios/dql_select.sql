USE banco_cl;

-- CONSULTAS GENERALES TABLAS

SELECT *
FROM Clientes;

SELECT *
FROM Cuentas;

SELECT *
FROM Movimientos;

SELECT *
FROM Tipo_movimiento_cuenta;

SELECT *
FROM Tipo_cuentas;

SELECT *
FROM Tarjetas;

SELECT *
FROM Seguridad_tarjetas;

SELECT *
FROM Intereses_tarjetas;

SELECT *
FROM Movimientos_tarjeta;

SELECT *
FROM Tipo_movimiento_tarjeta;

SELECT *
FROM Cuotas_credito;

SELECT *
FROM Pagos_tarjeta;

SELECT *
FROM Categoria_tarjetas;

SELECT *
FROM Tipo_tarjetas;

SELECT *
FROM Cuotas_de_manejo;

SELECT *
FROM Pagos;

SELECT *
FROM Historial_de_pagos;


-- Obtener el listado de todas las tarjetas de los clientes junto con su cuota de manejo.

SELECT t.id, t.saldo, t.estado, cm.id, cm.monto_total, cm.vencimiento_cuota
FROM Tarjetas t
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id;

-- Consultar el historial de pagos de un cliente específico.

SELECT cl.id AS cliente_id, p.fecha_pago, p.total_pago, p.metodo_pago, hp.fecha_cambio, hp.nuevo_estado AS estado
FROM Clientes cl
INNER JOIN Cuentas cu ON cl.id = cu.cliente_id
INNER JOIN Tarjetas t ON cu.id = t.cuenta_id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
INNER JOIN Pagos p ON cm.id = p.cuota_id
INNER JOIN Historial_de_pagos hp ON p.id = hp.pago_id
WHERE cl.id = 3;

-- Obtener el total de cuotas de manejo pagadas durante un mes determinado.

SELECT SUM(monto_total) AS total_pagado
FROM Cuotas_de_manejo
WHERE MONTH(vencimiento_cuota) = 7 AND YEAR(vencimiento_cuota) = 2025 AND estado = 'Pago';
-- Mes 7 ya que solo se tiene registros a partir de ese mes

-- Consultar las cuotas de manejo de los clientes con descuento aplicado.

SELECT cl.id AS cliente_id, cl.nombre, tt.descuento, cm.monto_base, cm.monto_total
FROM Clientes cl
INNER JOIN Cuentas cu ON cl.id = cu.cliente_id
INNER JOIN Tarjetas t ON cu.id = t.cuenta_id
INNER JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id


-- Obtener un reporte mensual de las cuotas de manejo de cada tarjeta.

SELECT t.id AS tarjeta_id, cm.vencimiento_cuota AS mes, SUM(cm.monto_total) AS total_cuotas
FROM Cuotas_de_manejo cm
INNER JOIN Tarjetas t ON cm.tarjeta_id = t.id
GROUP BY t.id, cm.vencimiento_cuota;

-- Obtener los clientes con las cuotas de manejo pendientes durante los últimos tres meses.

SELECT cl.id AS cliente_id, cl.nombre, cm.vencimiento_cuota, cm.monto_total
FROM Clientes cl
INNER JOIN Cuentas cu ON cl.id = cu.cliente_id
INNER JOIN Tarjetas t ON cu.id = t.cuenta_id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
WHERE cm.estado = 'Pendiente' AND cm.vencimiento_cuota >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH) AND cm.vencimiento_cuota < CURDATE();

-- Consultar las cuotas de manejo aplicadas a cada tipo de tarjeta.

SELECT tt.id, tt.nombre, MAX(cm.monto_base) AS monto_base, MAX(cm.monto_total) AS monto_descuento
FROM Cuotas_de_manejo cm
INNER JOIN Tarjetas t ON cm.tarjeta_id = t.id
INNER JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
GROUP BY tt.id, tt.nombre;


-- Generar un reporte con los descuentos aplicados durante un año.

SELECT tt.nombre AS tipo_tarjeta, COUNT(cm.id) AS Total_cuotas, SUM(cm.monto_base - cm.monto_total) AS Total_descuento
FROM Cuotas_de_manejo cm
INNER JOIN Tarjetas t ON cm.tarjeta_id = t.id
INNER JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
WHERE YEAR(cm.vencimiento_cuota) = 2025 AND cm.estado = 'Pago'
GROUP BY tt.nombre;

-- Obtener la suma total de dinero movido por cada tarjeta.

SELECT t.numero_tarjeta,tm.nombre AS tipo_movimiento,SUM(mt.monto) AS total_movido
FROM Tarjetas t
JOIN Movimientos_tarjeta mt ON mt.tarjeta_id = t.id
JOIN Tipo_movimiento_tarjeta tm ON tm.id = mt.tipo_movimiento_tarjeta
GROUP BY t.numero_tarjeta, tm.nombre;




-- Generar un reporte que muestre el total de pagos realizados por tipo de tarjeta.

SELECT tt.id, tt.nombre AS Tipo_tarjeta, COUNT(p.id) AS Total_transacciones, SUM(p.total_pago) AS Total_pagado
FROM Tipo_tarjetas tt
INNER JOIN Tarjetas t ON tt.id = t.tipo_tarjeta_id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
INNER JOIN Pagos p ON cm.id = p.cuota_id
WHERE p.estado = 'Completado'
GROUP BY tt.id, tt.nombre;

-- Obtener el listado de todas las tarjetas activas con su tipo, número y saldo.

SELECT t.id, tt.nombre AS tipo_tarjeta, t.numero_tarjeta, t.saldo, t.estado
FROM Tarjetas t
INNER JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
WHERE estado = 'Activa'

-- -- Listar los clientes junto con el número total de tarjetas que tienen registradas.

SELECT c.id AS cliente_id, c.nombre,COUNT(t.id) AS total_tarjetas
FROM Clientes c
JOIN Cuentas cu ON cu.cliente_id = c.id
JOIN Tarjetas t ON t.cuenta_id = cu.id
GROUP BY c.id, c.nombre;


-- Mostrar las cuotas de manejo vencidas que aún estén pendientes

SELECT id, vencimiento_cuota, monto_total, estado
FROM Cuotas_de_manejo
WHERE vencimiento_cuota < CURDATE() AND estado = 'Pendiente';

-- Consultar el total recaudado por pagos completados por cada método de pago.

SELECT metodo_pago, SUM(total_pago) AS Total
FROM Pagos
WHERE estado = 'Completado'
GROUP BY metodo_pago;


-- Listar las tarjetas cuya fecha de expiración esté dentro de los próximos 2 años junto con el nombre del titular.

SELECT t.id AS id_tarjeta, t.numero_tarjeta, t.fecha_expiracion, cl.nombre AS titular 
FROM Tarjetas t
INNER JOIN Cuentas cu ON t.cuenta_id = cu.id
INNER JOIN Clientes cl ON cu.cliente_id = cl.id
WHERE fecha_expiracion >= CURDATE() AND fecha_expiracion <= CURDATE() + INTERVAL 2 YEAR;

-- Obtener el cliente con el mayor total pagado en cuotas de manejo durante 2025.

SELECT cl.id, SUM(p.total_pago) AS total_pagado
FROM Clientes cl
INNER JOIN Cuentas cu ON cl.id = cu.cliente_id
INNER JOIN Tarjetas t ON cu.id = t.cuenta_id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
INNER JOIN Pagos p ON cm.id = p.cuota_id
WHERE YEAR(p.fecha_pago) = 2025 AND p.estado = 'Completado'
GROUP BY cl.id
ORDER BY total_pagado DESC
LIMIT 1;


-- Generar un ranking de los tipos de tarjeta con mayor monto total de apertura acumulado.

SELECT tt.id, tt.nombre, SUM(cm.monto_total) AS Total_acumulado
FROM Tipo_tarjetas tt
INNER JOIN Tarjetas t ON  tt.id = t.tipo_tarjeta_id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
WHERE cm.estado = 'Pago'
GROUP BY tt.id, tt.nombre;

-- Mostrar el promedio de saldo por estado de tarjeta.

SELECT estado, AVG(saldo) 
FROM Tarjetas
GROUP BY estado;

-- Listar las tarjetas que no han tenido ningún pago registrado.

SELECT t.id, t.cuenta_id, t.numero_tarjeta, cm.vencimiento_cuota, cm.estado
FROM Tarjetas t
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
LEFT JOIN Pagos p ON cm.id = p.cuota_id
WHERE p.id IS NULL;

-- Consultar todos los movimientos realizados con las tarjetas

SELECT t.id AS tarjeta_id, t.numero_tarjeta, tt.nombre AS tipo_tarjeta, ct.nombre AS categoria, mt.fecha,
   tm.nombre AS tipo_movimiento, mt.monto, mt.cuotas
FROM Tarjetas t
JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
JOIN Categoria_tarjetas ct ON t.categoria_tarjeta_id = ct.id
JOIN Movimientos_tarjeta mt ON mt.tarjeta_id = t.id
JOIN Tipo_movimiento_tarjeta tm ON mt.tipo_movimiento_tarjeta = tm.id;


--Listar el número total de cuotas de manejo por cada tarjeta.

SELECT tarjeta_id, COUNT(*) AS total_cuotas
FROM Cuotas_de_manejo
GROUP BY tarjeta_id;

--Obtener los datos de contacto de los clientes que tengan al menos una tarjeta activa.


SELECT DISTINCT cl.id, cl.nombre, cl.correo, cl.telefono
FROM Clientes cl
JOIN Cuentas cu ON cu.cliente_id = cl.id
JOIN Tarjetas t ON t.cuenta_id = cu.id
WHERE t.estado = 'Activa';

-- Listar los intereses generados por tarjeta durante el último mes.

SELECT tarjeta_id, fecha_generacion, monto_interes
FROM Intereses_tarjetas
WHERE fecha_generacion >= CURDATE() - INTERVAL 1 MONTH;


-- Obtener la cantidad de pagos por cada estado (Completado, Rechazado, etc.).

SELECT estado, COUNT(*) AS cantidad
FROM Pagos
GROUP BY estado;


-- Mostrar el total de dinero pagado por cuotas de crédito por cada tarjeta.

SELECT t.id AS tarjeta_id, SUM(pt.monto) AS total_pagado_credito
FROM Pagos_tarjeta pt
JOIN Cuotas_credito cc ON pt.cuota_credito_id = cc.id
JOIN Movimientos_tarjeta mt ON cc.movimiento_id = mt.id
JOIN Tarjetas t ON mt.tarjeta_id = t.id
GROUP BY t.id;


-- Listar las tarjetas vencidas junto con su titular.

SELECT t.numero_tarjeta, t.fecha_expiracion, cl.nombre AS titular
FROM Tarjetas t
JOIN Cuentas cu ON t.cuenta_id = cu.id
JOIN Clientes cl ON cu.cliente_id = cl.id
WHERE t.estado = 'Vencida';

-- Obtener las cuotas de crédito que no han sido pagadas todavía.

SELECT cc.id, cc.numero_cuota, cc.fecha_vencimiento, cc.valor_cuota
FROM Cuotas_credito cc
LEFT JOIN Pagos_tarjeta pt ON pt.cuota_credito_id = cc.id
WHERE pt.id IS NULL OR cc.estado = 'Pendiente';

-- Mostrar cuántas tarjetas tiene cada cliente por categoría (Crédito o Débito).

SELECT cl.id AS cliente_id, cl.nombre, ct.nombre AS categoria, COUNT(t.id) AS total_tarjetas
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Categoria_tarjetas ct ON t.categoria_tarjeta_id = ct.id
GROUP BY cl.id, cl.nombre, ct.nombre;

-- Listar todos los pagos de cuotas de manejo realizados en efectivo.

SELECT p.id, p.total_pago, p.fecha_pago, p.metodo_pago
FROM Pagos p
WHERE p.metodo_pago = 'Efectivo' AND p.estado = 'Completado';


-- Obtener las tarjetas que no tienen PIN registrado aún.

SELECT t.id, t.numero_tarjeta
FROM Tarjetas t
LEFT JOIN Seguridad_tarjetas st ON t.id = st.tarjeta_id
WHERE st.id IS NULL;

-- Mostrar la fecha del primer y último movimiento realizado por cada tarjeta.

SELECT t.id AS tarjeta_id, MIN(mt.fecha) AS primer_movimiento, MAX(mt.fecha) AS ultimo_movimiento
FROM Tarjetas t
JOIN Movimientos_tarjeta mt ON t.id = mt.tarjeta_id
GROUP BY t.id;

-- Obtener el total de intereses generados por cliente durante el año actual.

SELECT cl.id AS cliente_id, cl.nombre, SUM(it.monto_interes) AS total_intereses
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Intereses_tarjetas it ON t.id = it.tarjeta_id
WHERE YEAR(it.fecha_generacion) = YEAR(CURDATE())
GROUP BY cl.id, cl.nombre;

-- Listar los pagos rechazados junto con la fecha en que cambiaron de estado.

SELECT p.id AS pago_id, p.fecha_pago, hp.fecha_cambio, hp.estado_anterior, hp.nuevo_estado
FROM Pagos p
JOIN Historial_de_pagos hp ON p.id = hp.pago_id
WHERE p.estado = 'Rechazado';

-- Mostrar las tarjetas con más de una cuota de manejo pendiente.

SELECT t.id, t.numero_tarjeta, COUNT(cm.id) AS cuotas_pendientes
FROM Tarjetas t
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
WHERE cm.estado = 'Pendiente'
GROUP BY t.id
HAVING COUNT(cm.id) > 1;

-- Obtener la relación entre las tarjetas activas y bloqueadas por cliente.

SELECT cl.id AS cliente_id, cl.nombre,
SUM(CASE WHEN t.estado = 'Activa' THEN 1 ELSE 0 END) AS activas,
SUM(CASE WHEN t.estado = 'Bloqueada' THEN 1 ELSE 0 END) AS bloqueadas
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
GROUP BY cl.id;

-- Mostrar la cantidad de cuotas de crédito pagadas vs pendientes por cada tarjeta.

SELECT t.id AS tarjeta_id,
SUM(CASE WHEN cc.estado = 'Pagada' THEN 1 ELSE 0 END) AS cuotas_pagadas,
SUM(CASE WHEN cc.estado = 'Pendiente' THEN 1 ELSE 0 END) AS cuotas_pendientes
FROM Tarjetas t
JOIN Movimientos_tarjeta mt ON t.id = mt.tarjeta_id
JOIN Cuotas_credito cc ON mt.id = cc.movimiento_id
GROUP BY t.id;

-- Listar todos los clientes que no han generado ningún pago.

SELECT cl.id, cl.nombre
FROM Clientes cl
LEFT JOIN Cuentas cu ON cl.id = cu.cliente_id
LEFT JOIN Tarjetas t ON cu.id = t.cuenta_id
LEFT JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
LEFT JOIN Pagos p ON cm.id = p.cuota_id
WHERE p.id IS NULL;

-- Mostrar cuántos pagos ha hecho cada cliente por cada método de pago.

SELECT cl.id AS cliente_id, cl.nombre, p.metodo_pago, COUNT(p.id) AS cantidad_pagos
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
JOIN Pagos p ON cm.id = p.cuota_id
GROUP BY cl.id, cl.nombre, p.metodo_pago;

-- Obtener la tarjeta con más movimientos registrados.

SELECT t.id, t.numero_tarjeta, COUNT(mt.id) AS total_movimientos
FROM Tarjetas t
JOIN Movimientos_tarjeta mt ON t.id = mt.tarjeta_id
GROUP BY t.id
ORDER BY total_movimientos DESC
LIMIT 1;

-- Listar todas las tarjetas cuyo límite de crédito supera los $2'000.000.

SELECT id, numero_tarjeta, limite_credito
FROM Tarjetas
WHERE limite_credito IS NOT NULL AND limite_credito > 2000000;

-- Mostrar los clientes que tienen más de una cuenta registrada.

SELECT c.id, c.nombre, COUNT(cu.id) AS total_cuentas
FROM Clientes c
JOIN Cuentas cu ON c.id = cu.cliente_id
GROUP BY c.id
HAVING COUNT(cu.id) > 1;

-- Obtener los movimientos de cuenta cuyo nuevo saldo quedó por debajo de $50.000.

SELECT m.id, m.fecha, m.monto, m.nuevo_saldo, c.id AS cuenta_id
FROM Movimientos m
JOIN Cuentas c ON m.cuenta_id = c.id
WHERE m.nuevo_saldo < 50000;

-- Listar los tipos de tarjetas y la cantidad de tarjetas asociadas a cada tipo.

SELECT tt.id, tt.nombre, COUNT(t.id) AS total_tarjetas
FROM Tipo_tarjetas tt
LEFT JOIN Tarjetas t ON tt.id = t.tipo_tarjeta_id
GROUP BY tt.id, tt.nombre;

-- Mostrar cuántos intereses se han generado por cada tarjeta.

SELECT tarjeta_id, COUNT(id) AS total_registros_interes, SUM(monto_interes) AS total_interes
FROM Intereses_tarjetas
GROUP BY tarjeta_id;

-- Obtener el nombre del cliente y la fecha de creación de su cuenta más reciente.

SELECT cl.id AS cliente_id, cl.nombre, MAX(cu.fecha_creacion) AS ultima_cuenta
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
GROUP BY cl.id, cl.nombre;

-- Mostrar los pagos realizados con métodos que contengan la palabra "Transferencia".

SELECT id, fecha_pago, total_pago, metodo_pago
FROM Pagos
WHERE metodo_pago LIKE '%Transferencia%';

-- Obtener todas las tarjetas cuyo estado ha sido “Vencida” y su fecha de expiración ya pasó.

SELECT id, numero_tarjeta, fecha_expiracion, estado
FROM Tarjetas
WHERE estado = 'Vencida' AND fecha_expiracion < CURDATE();

-- Mostrar cuántas cuotas de manejo tiene cada tarjeta, ordenadas por cantidad.

SELECT tarjeta_id, COUNT(id) AS total_cuotas
FROM Cuotas_de_manejo
GROUP BY tarjeta_id
ORDER BY total_cuotas DESC;

-- Listar los pagos con monto mayor al valor base de la cuota (posible error o sobrepago).

SELECT p.id, p.total_pago, cm.monto_base, cm.monto_total
FROM Pagos p
JOIN Cuotas_de_manejo cm ON p.cuota_id = cm.id
WHERE p.total_pago > cm.monto_base;

-- Obtener un listado de clientes sin ninguna tarjeta registrada.

SELECT cl.id, cl.nombre
FROM Clientes cl
LEFT JOIN Cuentas cu ON cl.id = cu.cliente_id
LEFT JOIN Tarjetas t ON cu.id = t.cuenta_id
WHERE t.id IS NULL;

-- Obtener los clientes cuya suma total de pagos (de cuotas de manejo) sea menor al total que deberían haber pagado según las cuotas registradas.

SELECT cl.id, cl.nombre, SUM(p.total_pago) AS total_pagado, SUM(cm.monto_total) AS total_debido
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
LEFT JOIN Pagos p ON cm.id = p.cuota_id AND p.estado = 'Completado'
GROUP BY cl.id, cl.nombre
HAVING total_pagado < total_debido;

-- Mostrar el promedio de valor de cuota por cliente en tarjetas de crédito únicamente.

SELECT cl.id, cl.nombre, AVG(cc.valor_cuota) AS promedio_valor_cuota
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Categoria_tarjetas cat ON t.categoria_tarjeta_id = cat.id
JOIN Movimientos_tarjeta mt ON t.id = mt.tarjeta_id
JOIN Cuotas_credito cc ON mt.id = cc.movimiento_id
WHERE cat.nombre = 'Credito'
GROUP BY cl.id, cl.nombre;

-- Obtener el número total de tarjetas activas, bloqueadas, vencidas e inactivas agrupadas por tipo de tarjeta.

SELECT tt.nombre AS tipo_tarjeta, SUM(t.estado = 'Activa') AS activas, SUM(t.estado = 'Bloqueada') AS bloqueadas,
SUM(t.estado = 'Vencida') AS vencidas, SUM(t.estado = 'Inactiva') AS inactivas
FROM Tipo_tarjetas tt
JOIN Tarjetas t ON tt.id = t.tipo_tarjeta_id
GROUP BY tt.nombre;

-- Reporte de cuotas de manejo: Total mensual por cliente y estado de la cuota.

SELECT cl.id, cl.nombre, MONTH(cm.vencimiento_cuota) AS mes, cm.estado, SUM(cm.monto_total) AS total_mes
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
GROUP BY cl.id, cl.nombre, mes, cm.estado
ORDER BY cl.id, mes;

-- Obtener el valor acumulado de intereses por cliente.

SELECT cl.id AS cliente_id, cl.nombre, SUM(it.monto_interes) AS total_interes
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Intereses_tarjetas it ON t.id = it.tarjeta_id
GROUP BY cl.id, cl.nombre;

-- Obtener los 5 movimientos de cuenta más altos por monto.

SELECT m.*, c.cliente_id
FROM Movimientos m
JOIN Cuentas c ON m.cuenta_id = c.id
ORDER BY m.monto DESC
LIMIT 5;

-- Listar las tarjetas de crédito que no han tenido movimientos en los últimos 6 meses.

SELECT t.id, t.numero_tarjeta
FROM Tarjetas t
JOIN Categoria_tarjetas cat ON t.categoria_tarjeta_id = cat.id
LEFT JOIN Movimientos_tarjeta mt ON t.id = mt.tarjeta_id  AND mt.fecha >= CURDATE() - INTERVAL 6 MONTH
WHERE cat.nombre = 'Credito' AND mt.id IS NULL;

-- Mostrar el ranking de clientes según el total acumulado de cuotas de manejo pagadas.

SELECT cl.id AS cliente_id, cl.nombre, SUM(p.total_pago) AS total_pagado
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
JOIN Pagos p ON cm.id = p.cuota_id
WHERE p.estado = 'Completado'
GROUP BY cl.id
ORDER BY total_pagado DESC;

-- Consultar el promedio de intereses generados por tipo de tarjeta.

SELECT tt.nombre, AVG(it.monto_interes) AS promedio_interes
FROM Intereses_tarjetas it
JOIN Tarjetas t ON it.tarjeta_id = t.id
JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
GROUP BY tt.nombre;

-- Obtener el total mensual de intereses cobrados por tipo de tarjeta en 2025.

SELECT tt.nombre, MONTH(it.fecha_generacion) AS mes, SUM(it.monto_interes) AS total_intereses
FROM Intereses_tarjetas it
JOIN Tarjetas t ON it.tarjeta_id = t.id
JOIN Tipo_tarjetas tt ON t.tipo_tarjeta_id = tt.id
WHERE YEAR(it.fecha_generacion) = 2025
GROUP BY tt.nombre, mes
ORDER BY tt.nombre, mes;

-- Listar las tarjetas que tienen cuotas vencidas y no han recibido ningún pago.

SELECT t.id, t.numero_tarjeta
FROM Tarjetas t
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
LEFT JOIN Pagos p ON cm.id = p.cuota_id
WHERE cm.estado = 'Pendiente' AND cm.vencimiento_cuota < CURDATE() AND p.id IS NULL;

-- Mostrar el total de pagos realizados por cliente en cada trimestre de 2025.

SELECT cl.id AS cliente_id, cl.nombre, QUARTER(p.fecha_pago) AS trimestre, SUM(p.total_pago) AS total_pagado
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
JOIN Pagos p ON cm.id = p.cuota_id
WHERE YEAR(p.fecha_pago) = 2025
GROUP BY cl.id, cl.nombre, trimestre;

-- Obtener la tarjeta con más movimientos realizados.

SELECT t.id, t.numero_tarjeta, COUNT(mt.id) AS total_movimientos
FROM Tarjetas t
JOIN Movimientos_tarjeta mt ON t.id = mt.tarjeta_id
GROUP BY t.id, t.numero_tarjeta
ORDER BY total_movimientos DESC
LIMIT 1;

-- Consultar la diferencia entre monto base y monto total en cuotas de manejo pagadas.

SELECT cm.id, t.numero_tarjeta, (cm.monto_base - cm.monto_total) AS descuento_aplicado
FROM Cuotas_de_manejo cm
JOIN Tarjetas t ON cm.tarjeta_id = t.id
WHERE cm.estado = 'Pago';

-- Obtener el top 3 de clientes con más pagos rechazados.

SELECT cl.id, cl.nombre, COUNT(*) AS pagos_rechazados
FROM Clientes cl
JOIN Cuentas cu ON cl.id = cu.cliente_id
JOIN Tarjetas t ON cu.id = t.cuenta_id
JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
JOIN Pagos p ON cm.id = p.cuota_id
WHERE p.estado = 'Rechazado'
GROUP BY cl.id, cl.nombre
ORDER BY pagos_rechazados DESC
LIMIT 3;

-- Mostrar cuántos pagos han pasado por cada estado en total.

SELECT estado, COUNT(*) AS cantidad
FROM Pagos
GROUP BY estado;

