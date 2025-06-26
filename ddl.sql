USE banco_cl;
DROP DATABASE banco_cl;

CREATE DATABASE banco_cl;

CREATE TABLE Clientes(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    documento VARCHAR(100) NOT NULL,
    correo VARCHAR(100) NOT NULL,
    fecha_registro DATE NOT NULL DEFAULT (CURRENT_DATE),
    telefono VARCHAR(30) NOT NULL,
    UNIQUE (documento)
);

CREATE TABLE Tipo_cuentas(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre ENUM('Ahorro', 'Corriente') NOT NULL
);

CREATE TABLE Cuentas(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tipo_cuenta_id INT NOT NULL,
    cliente_id INT NOT NULL,
    saldo DECIMAL(10, 2) NOT NULL,
    fecha_creacion DATE NOT NULL,
    FOREIGN KEY (cliente_id) REFERENCES Clientes(id) ON DELETE CASCADE,
    FOREIGN KEY (tipo_cuenta_id) REFERENCES Tipo_cuentas(id)
);

CREATE TABLE Categoria_tarjetas(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre ENUM('Credito', 'Debito') NOT NULL
);

CREATE TABLE Tipo_tarjetas(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre ENUM('Joven', 'Nomina', 'Visa') NOT NULL,
    descuento DECIMAL(5, 2) NOT NULL
);

CREATE TABLE Tarjetas(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tipo_tarjeta_id INT NOT NULL,
    categoria_tarjeta_id INT NOT NULL,
    cuenta_id INT NOT NULL,
    monto_apertura DECIMAL(10, 2) NOT NULL,
    saldo DECIMAL(10, 2) NOT NULL,
    estado ENUM('Activa', 'Inactiva', 'Bloqueada', 'Vencida') NOT NULL,
    numero_tarjeta VARCHAR(50) NOT NULL,
    fecha_expiracion DATE NOT NULL,
    limite_credito DECIMAL(10, 2) NULL,
    FOREIGN KEY (cuenta_id) REFERENCES Cuentas(id) ON DELETE CASCADE,
    FOREIGN KEY (tipo_tarjeta_id) REFERENCES Tipo_tarjetas(id),
    FOREIGN KEY (categoria_tarjeta_id) REFERENCES Categoria_tarjetas(id)
);

CREATE TABLE Cuotas_de_manejo(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tarjeta_id INT NOT NULL,
    monto_base DECIMAL(10, 2) NOT NULL,
    monto_total DECIMAL(10, 2) NOT NULL,
    vencimiento_cuota DATE NOT NULL,
    estado ENUM('Pago', 'Pendiente') NOT NULL,
    FOREIGN KEY (tarjeta_id) REFERENCES Tarjetas(id) ON DELETE CASCADE
);

CREATE TABLE Pagos(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cuota_id INT NOT NULL,
    fecha_pago DATE NOT NULL,
    total_pago DECIMAL(10, 2) NOT NULL,
    metodo_pago VARCHAR(50) NOT NULL,
    estado ENUM('Completado', 'Rechazado', 'Pendiente', 'Cancelado') NOT NULL,
    FOREIGN KEY (cuota_id) REFERENCES Cuotas_de_manejo(id) ON DELETE CASCADE
);

CREATE TABLE Historial_de_pagos(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    pago_id INT NOT NULL,
    fecha_cambio DATE NOT NULL,
    estado_anterior ENUM('Completado', 'Rechazado', 'Pendiente', 'Cancelado', 'Inicio') NOT NULL,
    nuevo_estado ENUM('Completado', 'Rechazado', 'Pendiente', 'Cancelado') NOT NULL,
    FOREIGN KEY (pago_id) REFERENCES Pagos(id) ON DELETE CASCADE
);

CREATE TABLE Seguridad_tarjetas(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tarjeta_id INT NOT NULL,
    pin VARCHAR(50) NOT NULL,
    fecha_creacion DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (tarjeta_id) REFERENCES Tarjetas(id) ON DELETE CASCADE
);

CREATE TABLE Tipo_movimiento_cuenta(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre ENUM('Deposito', 'Nomina', 'Retiro', 'Retiro tarjeta')
);


CREATE TABLE Movimientos(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    cuenta_id INT NOT NULL,
    tipo_movimiento INT NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    fecha DATE NOT NULL DEFAULT(CURRENT_DATE),
    saldo_anterior DECIMAL(10,2) NOT NULL,
    nuevo_saldo DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (cuenta_id) REFERENCES Cuentas(id),
    FOREIGN KEY (tipo_movimiento) REFERENCES Tipo_movimiento_cuenta(id)
);

CREATE TABLE Tipo_movimiento_tarjeta(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre ENUM('Compra', 'Retiro', 'Devolucion', 'Pago') NOT NULL
);

CREATE TABLE Movimientos_tarjeta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo_movimiento_tarjeta INT NOT NULL,
    tarjeta_id INT NOT NULL,
    fecha DATE NOT NULL DEFAULT (CURRENT_DATE),
    monto DECIMAL(10,2) NOT NULL,
    cuotas INT NOT NULL DEFAULT 1,
    FOREIGN KEY (tarjeta_id) REFERENCES Tarjetas(id) ON DELETE CASCADE,
    FOREIGN KEY (tipo_movimiento_tarjeta) REFERENCES Tipo_movimiento_tarjeta(id)
);

CREATE TABLE Cuotas_credito (
    id INT AUTO_INCREMENT PRIMARY KEY,
    movimiento_id INT NOT NULL,
    numero_cuota INT NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    valor_cuota DECIMAL(10,2) NOT NULL,
    estado ENUM('Pendiente', 'Pagada', 'Deposito') DEFAULT 'Pendiente',
    FOREIGN KEY (movimiento_id) REFERENCES Movimientos_tarjeta(id) ON DELETE CASCADE
);

CREATE TABLE Intereses_tarjetas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tarjeta_id INT NOT NULL,
    fecha_generacion DATE NOT NULL DEFAULT (CURRENT_DATE),
    monto_base DECIMAL(10,2) NOT NULL,
    tasa DECIMAL(5,2) NOT NULL, 
    monto_interes DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (tarjeta_id) REFERENCES Tarjetas(id)
);

CREATE TABLE Pagos_tarjeta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cuota_credito_id INT NOT NULL,
    fecha_pago DATE NOT NULL DEFAULT (CURRENT_DATE),
    monto DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (cuota_credito_id) REFERENCES Cuotas_credito(id)
);