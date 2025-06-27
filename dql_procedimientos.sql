
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

-- Calcular y registrar intereses mensuales de tarjetas de crédito

DELIMITER //

DROP PROCEDURE IF EXISTS ps_calcular_intereses_tarjetas;

CREATE PROCEDURE ps_calcular_intereses_tarjetas(IN p_tasa DECIMAL(5,2))
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE _tarjeta_id INT;
    DECLARE _saldo DECIMAL(10,2);
    DECLARE _total DECIMAL(10,2);

    DECLARE cur CURSOR FOR
        SELECT t.id, t.saldo
        FROM Tarjetas t
        INNER JOIN Categoria_tarjetas ct ON t.categoria_tarjeta_id = ct.id
        WHERE ct.nombre = 'Credito' AND t.estado = 'Activa';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO _tarjeta_id, _saldo;
        IF done THEN
            LEAVE read_loop;
        END IF;

        SET _total = _saldo * p_tasa / 100;

        INSERT INTO Intereses_tarjetas(tarjeta_id, monto_base, tasa, monto_interes)
        VALUES (_tarjeta_id, _saldo, p_tasa, _total);
    END LOOP;

    CLOSE cur;
END //

DELIMITER ;

CALL ps_calcular_intereses_tarjetas(27);

-- Bloquear automáticamente tarjetas con más de 3 cuotas vencidas

DELIMITER //
DROP PROCEDURE IF EXISTS ps_bloquear_tarjetas_vencidas;
CREATE PROCEDURE ps_bloquear_tarjetas_vencidas()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE _tarjeta_id INT;
    DECLARE cur CURSOR FOR
        SELECT t.id
        FROM Tarjetas t
        INNER JOIN Cuotas_de_manejo cm ON t.id = cm.tarjeta_id
        WHERE cm.estado = 'Pendiente' 
        GROUP BY t.id
        HAVING COUNT(cm.id) >= 3;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;
    tarjetas_loop: LOOP
        FETCH cur INTO _tarjeta_id;
        IF done THEN
            LEAVE tarjetas_loop;
        END IF;

        UPDATE Tarjetas
        SET estado = 'Bloqueada'
        WHERE id = _tarjeta_id;
    END LOOP tarjetas_loop;
    CLOSE cur;
END //

DELIMITER ;

CALL ps_bloquear_tarjetas_vencidas();

-- Generar un resumen financiero de un cliente

DELIMITER //
DROP PROCEDURE IF EXISTS ps_resumen_financiero_cliente;
CREATE PROCEDURE ps_resumen_financiero_cliente(IN p_cliente_id INT)
BEGIN
    DECLARE _saldo_total_cuentas DECIMAL(10,2);
    DECLARE _cantidad_tarjetas INT;
    DECLARE _saldo_total_tarjetas DECIMAL(10,2);
    DECLARE _deuda_total_cuotas DECIMAL(10,2);

    SELECT SUM(saldo)
    INTO _saldo_total_cuentas
    FROM Cuentas
    WHERE cliente_id = p_cliente_id;

    SELECT COUNT(*)
    INTO _cantidad_tarjetas
    FROM Tarjetas t
    INNER JOIN Cuentas c ON t.cuenta_id = c.id
    WHERE c.cliente_id = p_cliente_id;

    SELECT SUM(t.saldo)
    INTO _saldo_total_tarjetas
    FROM Tarjetas t
    INNER JOIN Cuentas c ON t.cuenta_id = c.id
    WHERE c.cliente_id = p_cliente_id;

    SELECT SUM(cc.valor_cuota)
    INTO _deuda_total_cuotas
    FROM Cuotas_credito cc
    INNER JOIN Movimientos_tarjeta mt ON cc.movimiento_id = mt.id
    INNER JOIN Tarjetas t ON mt.tarjeta_id = t.id
    INNER JOIN Cuentas c ON t.cuenta_id = c.id
    WHERE c.cliente_id = p_cliente_id AND cc.estado = 'Pendiente';

    SELECT _saldo_total_cuentas AS saldo_total_cuentas, _cantidad_tarjetas AS cantidad_tarjetas,
        _saldo_total_tarjetas AS saldo_total_tarjetas, _deuda_total_cuotas AS deuda_total_cuotas;
END //
DELIMITER ;

CALL ps_resumen_financiero_cliente(1);


-- Asignar automáticamente una tarjeta de débito a una cuenta de ahorro

DELIMITER //
DROP PROCEDURE IF EXISTS ps_asignar_tarjeta_debito;
CREATE PROCEDURE ps_asignar_tarjeta_debito(IN p_cuenta_id INT)
BEGIN
    DECLARE _tipo_cuenta INT;

    SELECT tipo_cuenta_id INTO _tipo_cuenta
    FROM Cuentas
    WHERE id = p_cuenta_id;

    IF _tipo_cuenta = 1 THEN
        INSERT INTO Tarjetas (
            tipo_tarjeta_id,
            categoria_tarjeta_id,   
            cuenta_id,
            monto_apertura,
            saldo,
            estado,
            numero_tarjeta,
            fecha_expiracion
        ) VALUES 
        (1, 2, p_cuenta_id, 0, 0, 'Activa', 0, DATE_ADD(CURDATE(), INTERVAL 3 YEAR));

    ELSE
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La cuenta no es de credito';
    END IF;
END //
DELIMITER ;
CALL ps_asignar_tarjeta_debito(1);


-- Registrar un retiro por cajero y actualizar saldo
DELIMITER //
DROP PROCEDURE IF EXISTS ps_retiro_cajero;
CREATE PROCEDURE ps_retiro_cajero(IN p_cuenta_id INT, IN p_monto DECIMAL(10,2))
BEGIN
    DECLARE _saldo_actual DECIMAL(10,2);

    SELECT saldo INTO _saldo_actual FROM Cuentas WHERE id = p_cuenta_id;

    IF _saldo_actual < p_monto THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Saldo insuficiente';
    ELSE
        UPDATE Cuentas 
        SET saldo = saldo - p_monto 
        WHERE id = p_cuenta_id;

        INSERT INTO Movimientos (cuenta_id, tipo_movimiento, monto, saldo_anterior, nuevo_saldo)
        VALUES (p_cuenta_id, 3, p_monto, _saldo_actual, _saldo_actual - p_monto);
    END IF;
END //

DELIMITER ;
CALL ps_retiro_cajero(51, 123456)


-- Consultar clientes con tarjetas vencidas y sin pagos recientes

DELIMITER //
DROP PROCEDURE IF EXISTS ps_clientes_tarjetas_vencidas_sin_pago;
CREATE PROCEDURE ps_clientes_tarjetas_vencidas_sin_pago()
BEGIN
    SELECT DISTINCT cli.id AS cliente_id, cli.nombre, cli.documento, cli.correo
    FROM Clientes cli
    JOIN Cuentas cu ON cu.cliente_id = cli.id
    JOIN Tarjetas t ON t.cuenta_id = cu.id
    LEFT JOIN Cuotas_de_manejo cm ON cm.tarjeta_id = t.id
    LEFT JOIN Pagos p ON p.cuota_id = cm.id
    WHERE t.fecha_expiracion < CURDATE() AND p.id IS NULL;
END //
DELIMITER ;

CALL ps_clientes_tarjetas_vencidas_sin_pago()
