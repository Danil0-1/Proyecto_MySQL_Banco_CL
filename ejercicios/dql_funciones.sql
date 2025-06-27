
USE banco_cl;

-- Calcular la cuota de manejo para un cliente según su tipo de tarjeta y monto de apertura.

DELIMITER //

DROP FUNCTION IF EXISTS fn_calcular_cuota_manejo;
CREATE FUNCTION fn_calcular_cuota_manejo(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _cuota_manejo DECIMAL(10,2);
    DECLARE _descuento_tarjeta DECIMAL(5,2);
    DECLARE _monto_apertura DECIMAL(10,2);

    SELECT tt.descuento INTO _descuento_tarjeta
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    INNER JOIN Tipo_tarjetas tt ON tt.id = t.tipo_tarjeta_id
    WHERE cl.id = p_cliente_id;

    SELECT t.monto_apertura INTO _monto_apertura
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    WHERE cl.id = p_cliente_id;

    SET _cuota_manejo = _monto_apertura - (_monto_apertura * _descuento_tarjeta / 100);

    RETURN _cuota_manejo;

END //

DELIMITER ;

SELECT fn_calcular_cuota_manejo(1) AS Total_a_pagar;

-- Calcular el total pendiente de cuota de manejo de pago de un cliente.

DELIMITER //

DROP FUNCTION IF EXISTS fn_saldo_pendiente;
CREATE FUNCTION fn_saldo_pendiente(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE _total_cuota DECIMAL(10,2);
    DECLARE _id_cuota INT;
    DECLARE _total_restante DECIMAL(10,2);
    DECLARE _pagos_clientes DECIMAL(10,2) DEFAULT 0.00;
    DECLARE _pago_individual DECIMAL(10,2);

    DECLARE cur CURSOR FOR
        SELECT IFNULL(p.total_pago, 0)
        FROM Clientes cl
        INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
        INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
        LEFT JOIN Cuotas_de_manejo cm ON cm.tarjeta_id = t.id
        LEFT JOIN Pagos p ON p.cuota_id = cm.id
        WHERE cl.id = p_cliente_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SELECT IFNULL(SUM(cm.monto_total), 0) INTO _total_cuota
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    LEFT JOIN Cuotas_de_manejo cm ON cm.tarjeta_id = t.id
    WHERE cl.id = p_cliente_id;

    IF _total_cuota = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente no paga cuota de manejo';
    END IF;

    OPEN cur;
        read_loop: LOOP
            FETCH cur INTO _pago_individual;
            IF done THEN
                LEAVE read_loop;
            END IF;
            SET _pagos_clientes = _pagos_clientes + IFNULL(_pago_individual, 0);
        END LOOP;

        SET _total_restante = _total_cuota - _pagos_clientes;
    CLOSE cur;

    IF _total_restante < 0 THEN
        SET _total_restante = 0;
    END IF;

    RETURN _total_restante;


END //
DELIMITER ;

SELECT fn_saldo_pendiente(1) AS Total_pendiente;


-- Calcular el total pendiente de las cuotas de credito de un cliente.

DELIMITER //

DROP FUNCTION IF EXISTS fn_cuotas_credito;
CREATE FUNCTION fn_cuotas_credito(p_cliente_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _total_deuda DECIMAL(10,2) DEFAULT 0;

    SELECT IFNULL(SUM(cc.valor_cuota), 0) INTO _total_deuda
    FROM Clientes cl
    INNER JOIN Cuentas cu ON cu.cliente_id = cl.id
    INNER JOIN Tarjetas t ON t.cuenta_id = cu.id
    INNER JOIN Movimientos_tarjeta mt ON mt.tarjeta_id = t.id
    LEFT JOIN Cuotas_credito cc ON cc.movimiento_id = mt.id
    WHERE cl.id = p_cliente_id AND cc.estado = 'Pendiente';

    RETURN _total_deuda;
END //

DELIMITER ;

SELECT fn_cuotas_credito(1) AS Total_deuda;

-- Estimar el total de pagos realizados por tipo de tarjeta durante un período determinado.

DELIMITER //

DROP FUNCTION IF EXISTS fn_total_pagos_por_tipo;
CREATE FUNCTION fn_total_pagos_por_tipo(p_tipo_tarjeta_id INT, p_fecha_inicio DATE, p_fecha_fin DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE _total DECIMAL(10,2) DEFAULT 0;

    SELECT IFNULL(SUM(pt.monto), 0) INTO _total
    FROM Pagos_tarjeta pt
    INNER JOIN Cuotas_credito cc ON pt.cuota_credito_id = cc.id
    INNER JOIN Movimientos_tarjeta mt ON cc.movimiento_id = mt.id
    INNER JOIN Tarjetas t ON mt.tarjeta_id = t.id
    WHERE t.tipo_tarjeta_id = p_tipo_tarjeta_id AND pt.fecha_pago BETWEEN p_fecha_inicio AND p_fecha_fin;

    RETURN _total;
END //

DELIMITER ;

SELECT fn_total_pagos_por_tipo(1, '2020-01-01', '2026-01-01')
