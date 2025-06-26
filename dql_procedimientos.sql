
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
