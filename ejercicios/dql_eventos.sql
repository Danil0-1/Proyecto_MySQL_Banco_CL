
USE banco_cl;

SET GLOBAL event_scheduler = ON;


-- Evento para actualizar el estado de las tarjetas vencidas

DELIMITER //

DROP EVENT IF EXISTS ev_actualizar_tarjetas_vencidas;
CREATE EVENT IF NOT EXISTS ev_actualizar_tarjetas_vencidas
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE Tarjetas
    SET estado = 'Vencida'
    WHERE fecha_expiracion < CURDATE() AND estado <> 'Vencida';
END //

DELIMITER ;


-- Eliminar pagos cancelados antiguos

DELIMITER //

DROP EVENT IF EXISTS ev_eliminar_pagos_rechazados;
CREATE EVENT IF NOT EXISTS ev_eliminar_pagos_rechazados
ON SCHEDULE EVERY 1 MONTH
DO
BEGIN
    DELETE FROM Pagos
    WHERE estado = 'Rechazado' AND fecha_pago < CURDATE() - INTERVAL 6 MONTH;
END //

DELIMITER ;


--  Cambiar automaticamente el estado de las cuotas de manejo si no se han pagado
DELIMITER //

DROP EVENT IF EXISTS ev_actualizar_estado_cuotas_manejo;
CREATE EVENT IF NOT EXISTS ev_actualizar_estado_cuotas_manejo
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE Cuotas_de_manejo
    SET estado = 'Pendiente'
    WHERE vencimiento_cuota < CURDATE() AND estado <> 'Pago';
END //

DELIMITER ;


-- Cambiar estado a 'Bloqueada' si la tarjeta tiene saldo negativo

DELIMITER //

DROP EVENT IF EXISTS ev_bloquear_tarjetas_saldo_negativo;
CREATE EVENT IF NOT EXISTS ev_bloquear_tarjetas_saldo_negativo
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE Tarjetas
    SET estado = 'Bloqueada'
    WHERE saldo < 0 AND estado = 'Activa';
END //

DELIMITER ;
