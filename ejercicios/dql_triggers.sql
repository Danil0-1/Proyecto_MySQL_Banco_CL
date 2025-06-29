
USE banco_cl;

-- Al insertar un nuevo pago, actualizar automáticamente el estado de la cuota de manejo.

DELIMITER //

DROP TRIGGER IF EXISTS tr_actualizar_estado_cuota_manejo;
CREATE TRIGGER tr_actualizar_estado_cuota_manejo
AFTER INSERT ON Pagos
FOR EACH ROW
BEGIN
    DECLARE _total_pago DECIMAL(10,2);
    DECLARE _monto_total DECIMAL(10,2);

    SELECT SUM(total_pago) INTO _total_pago
    FROM Pagos 
    WHERE cuota_id = NEW.cuota_id;

    SELECT monto_total INTO _monto_total
    FROM Cuotas_de_manejo 
    WHERE id = NEW.cuota_id;

    IF _total_pago >= _monto_total THEN
        UPDATE Cuotas_de_manejo
        SET estado = 'Pago'
        WHERE id = NEW.cuota_id;
    END IF;
END //
DELIMITER ;

SELECT * FROM Cuotas_de_manejo;

INSERT INTO Pagos (
    cuota_id,
    fecha_pago,
    total_pago,
    metodo_pago,
    estado
) VALUES (
    4, CURDATE(), 47500.00, 'Transferencia', 'Completado'
);

-- Al modificar el monto de apertura de una tarjeta, recalcular la cuota de manejo correspondiente.

DELIMITER //
DROP TRIGGER IF EXISTS tr_recalcular_cuota_manejo;
CREATE TRIGGER tr_recalcular_cuota_manejo
AFTER UPDATE ON Tarjetas
FOR EACH ROW
BEGIN
    IF OLD.monto_apertura <> NEW.monto_apertura THEN
        UPDATE Cuotas_de_manejo
        SET monto_total = NEW.monto_apertura - (NEW.monto_apertura * (
            SELECT descuento 
            FROM Tipo_tarjetas 
            WHERE id = NEW.tipo_tarjeta_id
        ) / 100)
        WHERE tarjeta_id = NEW.id;
    END IF;
END //
DELIMITER ;

SELECT * FROM Cuotas_de_manejo;

UPDATE Tarjetas 
SET monto_apertura = 200000
WHERE id = 1;
