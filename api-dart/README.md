A server app built using [Shelf](https://pub.dev/packages/shelf),
configured to enable running with [Docker](https://www.docker.com/).

# API Dart - ventas y transaccional

Este proyecto expone una API REST con Shelf y MySQL para gestionar productos, clientes y ventas.

## ¿Qué es un transaccional?

Un transaccional es un bloque de operaciones que deben ejecutarse como una sola unidad.

Si una de las operaciones falla, todo se revierte para que la base de datos quede consistente.

En una venta real, por ejemplo, no queremos esto:
- guardar la venta,
- pero fallar al guardar el detalle,
- quedando el sistema en un estado parcialmente guardado.

Por eso se usa una transacción:
- inicia la transacción;
- inserta la venta;
- inserta cada detalle;
- si todo sale bien, confirma (COMMIT);
- si algo falla, revierte (ROLLBACK).

Esto garantiza consistencia y evita estados sucios en la base de datos.

## ¿Por qué es importante para una venta?

Una venta normalmente implica varias tablas:
- ventas
- detalle_venta
- productos
- clientes

Si la inserción de la cabecera de la venta se realiza y luego falla el detalle, la base de datos puede quedar corrupta.

Con transacción se asegura:
- que la venta solo quede registrada si todo está bien;
- que ni el detalle ni la cabecera queden incompletos;
- que se manejen errores controlados con rollback.

## Endpoint transaccional implementado

Se agregó la ruta:

POST /api/ventas/transaccional

Ejemplo de body:

```json
{
  "cliente_id": 1,
  "estado": "pendiente",
  "items": [
    { "producto_id": 1, "cantidad": 2 },
    { "producto_id": 2, "cantidad": 1 }
  ]
}
```

### Qué hace internamente

1. valida que el cliente exista;
2. valida que cada producto exista;
3. calcula el total de la venta;
4. inicia una transacción;
5. inserta la venta;
6. inserta cada detalle de venta;
7. confirma la transacción;
8. devuelve la venta creada y su detalle.

Si falla alguna validación o alguna inserción, se ejecuta rollback y la venta no queda registrada.

## Cómo correr el proyecto

```bash
dart run bin/server.dart
```

El servidor queda en:

- http://localhost:8080/
- http://localhost:8080/api/productos
- http://localhost:8080/api/clientes
- http://localhost:8080/api/ventas
- http://localhost:8080/api/detalle-ventas
- http://localhost:8080/api/ventas/transaccional

## Proceso de una venta transaccional

```text
cliente solicita compra
      ↓
validar cliente
validar productos
calcular total
      ↓
START TRANSACTION
      ↓
INSERT INTO ventas
INSERT INTO detalle_venta
      ↓
COMMIT
      ↓
venta creada correctamente
```

Si ocurre un error en cualquier punto:

```text
START TRANSACTION
      ↓
error detectado
      ↓
ROLLBACK
      ↓
base de datos sin cambios parciales
```

## Resumen

La venta transaccional no es solo una forma elegante de programar; es una práctica de integridad de datos.

Es la diferencia entre:
- guardar medio pedido por error,
- y asegurar que la operación completa se registre o no se registre nada.
