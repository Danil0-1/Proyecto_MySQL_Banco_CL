
USE banco_cl;

-- Registrar una nueva cuota de manejo calculando automáticamente el descuento.

SELECT * FROM Cuotas_de_manejo;
DELIMITER //
DROP PROCEDURE IF EXISTS ps_registro_cuota;
CREATE PROCEDURE ps_registro_cuota(IN p_tarjeta_id INT)
BEGIN 
    DECLARE _descuento_tarjeta DECIMAL(5,2);
    DECLARE _total decimal(10,2);

    SELECT tt.descuento INTO _descuento_tarjeta
    FROM Tarjetas t
    INNER JOIN Tipo_tarjetas tt ON tt.id = t.tipo_tarjeta_id
    WHERE t.id = p_tarjeta_id;

    SET _total = 50000.00 - (50000.00 * _descuento_tarjeta / 100);


    INSERT INTO Cuotas_de_manejo(
        tarjeta_id,
        monto_base,
        monto_total,
        vencimiento_cuota,
        estado
        ) VALUES
    (p_tarjeta_id, 50000.00, _total, DATE_ADD(CURDATE(), INTERVAL 1 MONTH), 'Pendiente');
    

END //
DELIMITER ;

CALL ps_registro_cuota(1);



-- Procesar pagos y actualizar el historial de pagos de los clientes.
DELIMITER //
DROP PROCEDURE IF EXISTS ps_procesar_pago;
CREATE PROCEDURE ps_procesar_pago(IN p_pago_id INT)
BEGIN
    DECLARE _estado_anterior ENUM('Completado', 'Rechazado', 'Pendiente', 'Cancelado', 'Inicio');

    SELECT estado INTO _estado_anterior
    FROM Pagos
    WHERE id = p_pago_id;

    UPDATE Pagos
    SET estado = 'Completado', fecha_pago = CURDATE()
    WHERE id = p_pago_id;

    INSERT INTO Historial_de_pagos (pago_id, fecha_cambio, estado_anterior, nuevo_estado)
    VALUES (p_pago_id, CURDATE(), _estado_anterior, 'Completado');

END //
DELIMITER ;

CALL ps_procesar_pago(5);

-- Generar reportes mensuales de cuotas de manejo.
DELIMITER //
DROP PROCEDURE IF EXISTS ps_reporte_cuotas_mensual;
CREATE PROCEDURE ps_reporte_cuotas_mensual(IN p_anio INT, IN p_mes INT)
BEGIN
    SELECT cdm.id AS cuota_id, cdm.tarjeta_id, cl.nombre AS cliente, cdm.monto_base, cdm.monto_total,
        cdm.estado,cdm.vencimiento_cuota
    FROM Cuotas_de_manejo cdm
    INNER JOIN Tarjetas t ON cdm.tarjeta_id = t.id
    INNER JOIN Cuentas cu ON t.cuenta_id = cu.id
    INNER JOIN Clientes cl ON cu.cliente_id = cl.id
    WHERE YEAR(cdm.vencimiento_cuota) = p_anio AND MONTH(cdm.vencimiento_cuota) = p_mes
    ORDER BY cdm.vencimiento_cuota ASC;
END //
DELIMITER ;

CALL ps_reporte_cuotas_mensual(2025, 7)

-- Actualizar los descuentos en caso de cambio en las políticas bancarias.

DELIMITER //

DROP PROCEDURE IF EXISTS ps_actualizar_descuentos;
CREATE PROCEDURE ps_actualizar_descuentos(IN p_nuevo_descuento DECIMAL(5,2), IN p_tipo_tarjeta_id INT)
BEGIN
    UPDATE Tipo_tarjetas
    SET descuento = p_nuevo_descuento
    WHERE id = p_tipo_tarjeta_id;
END //
DELIMITER ;

CALL ps_actualizar_descuentos(20.00, 1);
