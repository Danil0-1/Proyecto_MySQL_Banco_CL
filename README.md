# Banco CampusLands

El objetivo de este proyecto es el de recrear un sistema bancario que permita gestionar de manera eficiente todas las operaciones relacionadas con el sistema de cuotas de manejo del banco, movimientos en la cuenta, tarjeta, etc.


## Software necesario 

Este proyecto está pensado para desarrollarse en las versiones posteriores de MySQL 8.0.

## Instrucciones de instalación y configuración

- Lo primero que se necesita hacer es ir al archivo ddl.sql y cargar todas las tablas de la base de datos.
- En el archivo dml se encuentran todos los datos necesarios para empezar a trabajar en el proyecto.
- Una vez cargado la base de datos, puede cargar los scripts Select, Procedimientos, Triggers, Funciones y Eventos.

## Estructura de la base de datos

| Tabla                         | Descripción                                                                     |
| ----------------------------- | ------------------------------------------------------------------------------- |
| **Clientes**                  | Almacena los datos personales de cada cliente.                                  |
| **Tipo_cuentas**              | Establece el tipo de cuenta, como ahorro o corriente.                           |
| **Cuentas**                   | Relaciona al cliente con sus cuentas bancarias, incluyendo saldo y tipo.        |
| **Categoria_tarjetas**        | Distingue entre tarjetas de crédito y débito.                                   |
| **Tipo_tarjetas**             | Define tipos de tarjetas como Visa, Nómina, Joven, e incluye descuento.         |
| **Tarjetas**                  | Contiene las tarjetas asociadas a cada cuenta, con su estado, saldo y tipo.     |
| **Cuotas_de_manejo**          | Cuotas mensuales aplicadas a las tarjetas según el tipo y categoría.            |
| **Pagos**                     | Registra los pagos realizados hacia las cuotas de manejo.                       |
| **Historial_de_pagos**        | Guarda el historial de cambios de estado de cada pago.                          |
| **Seguridad_tarjetas**        | Almacena el PIN y fecha de creación de cada tarjeta para seguridad.             |
| **Tipo_movimiento_cuenta**    | Define los tipos de movimientos en cuentas: depósito, retiro, etc.              |
| **Movimientos**               | Registra los movimientos que afectan directamente a las cuentas.                |
| **Tipo_movimiento_tarjeta**   | Define los tipos de movimientos con tarjeta: compra, retiro, pago.              |
| **Movimientos_tarjeta**       | Registro de operaciones realizadas con las tarjetas.                            |
| **Cuotas_credito**            | Detalla los pagos fraccionados de compras realizadas a crédito.                 |
| **Pagos_tarjeta**             | Pagos efectuados sobre las cuotas de crédito de los movimientos a plazos.       |
| **Intereses_tarjetas**        | Registra los intereses generados periódicamente sobre el saldo de las tarjetas. |
