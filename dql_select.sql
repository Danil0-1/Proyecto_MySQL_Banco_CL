USE banco_cl;


-- Obtener el listado de todas las tarjetas de los clientes junto con su cuota de manejo.

SELECT t.id, t.saldo, t.estado, cm.id, cm.monto_total, cm.vencimiento_cuota
FROM Tarjetas t
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id;

-- Consultar el historial de pagos de un cliente específico.

SELECT cl.id AS cliente_id, p.fecha_pago, p.total_pago, p.metodo_pago, hp.fecha_cambio, hp.estado_anterior, hp.nuevo_estado
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
WHERE MONTH(vencimiento_cuota) = 4 AND YEAR(vencimiento_cuota) = 2025 AND estado = 'Pago';

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

-- Obtener los clientes con pagos pendientes durante los últimos tres meses.

SELECT cl.id AS cliente_id, cl.nombre, cm.vencimiento_cuota, cm.monto_total, p.total_pago, p.estado
FROM Clientes cl
INNER JOIN Cuentas cu ON cl.id = cu.cliente_id
INNER JOIN Tarjetas t ON cu.id = t.cuenta_id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
INNER JOIN Pagos p ON cm.id = p.cuota_id
WHERE p.estado = 'Pendiente' AND cm.vencimiento_cuota >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH) AND cm.vencimiento_cuota < CURDATE();

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

-- Consultar las tarjetas con el mayor y menor monto de apertura.

SELECT id, numero_tarjeta, monto_apertura
FROM Tarjetas 
WHERE monto_apertura = (SELECT MAX(monto_apertura) FROM Tarjetas)
   OR monto_apertura = (SELECT MIN(monto_apertura) FROM Tarjetas);



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

-- Listar los clientes que tienen más de una tarjeta registrada.

SELECT  cl.id AS cliente_id, cl.nombre, cl.documento, COUNT(t.id) AS cantidad_tarjetas
FROM Tarjetas t
INNER JOIN Cuentas cu ON t.cuenta_id = cu.id
INNER JOIN Clientes cl ON cu.cliente_id = cl.id
GROUP BY cl.id, cl.nombre, cl.documento
HAVING COUNT(t.id) > 1

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

-- Obtener el cliente con el mayor total pagado en cuotas de manejo durante 2024.

SELECT cl.id, SUM(p.total_pago) AS total_pagado
FROM Clientes cl
INNER JOIN Cuentas cu ON cl.id = cu.cliente_id
INNER JOIN Tarjetas t ON cu.id = t.cuenta_id
INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
INNER JOIN Pagos p ON cm.id = p.cuota_id
WHERE YEAR(p.fecha_pago) = 2024 AND p.estado = 'Completado'
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



