
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

-- Registrar nuevos clientes y tarjetas automáticamente con los datos de apertura.

DELIMITER //
DROP PROCEDURE IF EXISTS ps_registrar_cliente_tarjeta;
CREATE PROCEDURE ps_registrar_cliente_tarjeta(
    IN p_nombre VARCHAR(100),
    IN p_documento VARCHAR(20),
    IN p_correo VARCHAR(100),
    IN p_telefono VARCHAR(20),
    IN p_tipo_cuenta_id INT,
    IN p_tipo_tarjeta_id INT,
    IN p_categoria_tarjeta_id INT,
    IN p_monto_apertura DECIMAL(10,2),
    IN p_numero_tarjeta VARCHAR(50),
    IN p_limite_credito DECIMAL(10,2)
)
BEGIN
    DECLARE _cliente_id INT;
    DECLARE _cuenta_id INT;

    INSERT INTO Clientes (nombre, documento, correo, fecha_registro, telefono)
    VALUES (p_nombre, p_documento, p_correo, CURDATE(), p_telefono);

    SET _cliente_id = LAST_INSERT_ID();

    INSERT INTO Cuentas (tipo_cuenta_id, cliente_id, saldo, fecha_creacion)
    VALUES (p_tipo_cuenta_id, _cliente_id, 0.00, CURDATE());
    
    SET _cuenta_id = LAST_INSERT_ID();

    INSERT INTO Tarjetas(
        tipo_tarjeta_id,
        categoria_tarjeta_id,
        cuenta_id,
        monto_apertura,
        saldo,
        estado,
        numero_tarjeta,
        fecha_expiracion,
        limite_credito
    ) VALUES (
        p_tipo_tarjeta_id,
        p_categoria_tarjeta_id,
        _cuenta_id,
        p_monto_apertura,
        p_monto_apertura, 
        'Activa',
        p_numero_tarjeta,
        DATE_ADD(CURDATE(), INTERVAL 3 YEAR),
        p_limite_credito
    );
END //
DELIMITER ;

CALL ps_registrar_cliente_tarjeta(
    'Nuevo cliente desde procedimiento', '1905838722', 'procedimiento@gmail.com', 
    '+57 3001234567', 1, 2, 1, 1000000.00, '4278589171712445', 5000000.00);  


-- Listar los movimientos de una cuenta por rango de fechas y tipo de movimiento
DELIMITER //

DROP PROCEDURE IF EXISTS ps_movimientos_cuenta;
CREATE PROCEDURE ps_movimientos_cuenta(IN p_cuenta_id INT, IN p_tipo_movimiento_id INT, IN p_fecha_inicio DATE, IN p_fecha_fin DATE)
BEGIN
    SELECT m.id AS movimiento_id, m.fecha AS fecha_movimiento, tmc.nombre AS tipo_movimiento, m.monto AS monto_movimiento, 
    m.saldo_anterior, m.nuevo_saldo, cl.nombre AS nombre_cliente
    FROM Movimientos m
    INNER JOIN Tipo_movimiento_cuenta tmc ON m.tipo_movimiento = tmc.id
    INNER JOIN Cuentas c ON m.cuenta_id = c.id
    INNER JOIN Clientes cl ON c.cliente_id = cl.id
    WHERE m.cuenta_id = p_cuenta_id AND m.tipo_movimiento = p_tipo_movimiento_id AND m.fecha BETWEEN p_fecha_inicio AND p_fecha_fin;
END //

DELIMITER ;

CALL ps_movimientos_cuenta(1, 3, '2023-01-01', '2023-03-30');