# Banco de preguntas — API Dart (proyecto-venta)

Basado en el código actual de `api-dart`: `bin/`, `lib/models`, `lib/services`, `lib/routes`, `lib/database`, `test/`.

---

## 1. Arquitectura y stack general

**1. ¿Qué paquetes usa el proyecto para levantar el servidor HTTP y por qué se usan juntos (`shelf` y `shelf_router`)?**
`shelf` provee el servidor HTTP base, el modelo de `Request`/`Response` y el sistema de `Pipeline`/`Middleware`. `shelf_router` añade sobre `shelf` un enrutador con soporte de path params (`<id>`) y verbos HTTP (`get`, `post`, `put`, `delete`), algo que `shelf` por sí solo no ofrece.

**2. ¿Qué patrón de capas sigue el proyecto (routes → services → database) y qué responsabilidad tiene cada capa?**
`routes/`: recibe la petición HTTP, valida/parsea el input y arma la respuesta JSON. `services/`: contiene la lógica de acceso a datos (SQL parametrizado) y reglas de negocio (ej. `crearTransaccional`). `database/`: gestiona la conexión, el esquema y las migraciones/seeders. Los modelos (`models/`) son estructuras de datos usadas para mapear filas de MySQL, aunque en la práctica las rutas casi siempre construyen los `Map` a mano en vez de usar los modelos.

**3. ¿Qué paquete se usa para conectarse a MySQL y qué método estático expone la clase `Database` para crear la conexión?**
Se usa `mysql_client` (`MySQLConnection`). La clase `Database` expone `Database.connect()`, que crea la conexión (`MySQLConnection.createConnection`), la conecta (`connection.connect()`) y luego llama a `ensureSchema()`.

**4. ¿En qué archivo se define el `main()` que arranca el servidor y qué hace exactamente al iniciar?**
En `bin/server.dart`. Conecta a la base de datos con `Database.connect()`, crea un `Router`, define la ruta raíz `/`, monta las rutas de productos/clientes/ventas/detalle-ventas, arma el `Pipeline` con CORS + logging, y levanta el servidor con `serve()` en el puerto configurado.

**5. ¿De dónde toma el servidor el puerto en el que corre, y qué valor usa por defecto si no está definida esa variable?**
De la variable de entorno `PORT` (`Platform.environment['PORT']`), con `'8080'` como valor por defecto si no está definida.

**6. ¿Qué hace `Pipeline()` en `server.dart` y en qué orden se aplican los middlewares?**
`Pipeline()` encadena middlewares alrededor del handler final. En este proyecto se aplica primero `_corsMiddleware()` y luego `logRequests()`, y finalmente `.addHandler(router.call)`. Es decir, la petición entra primero por CORS y después por el logger antes de llegar al router.

**7. ¿Qué es `InternetAddress.anyIPv4` y por qué se usa al llamar a `serve()`?**
Es la dirección `0.0.0.0`, que hace que el servidor escuche en todas las interfaces de red IPv4 disponibles (no solo `localhost`), permitiendo conexiones desde otras máquinas/contenedores.

**8. ¿Qué versión mínima de SDK de Dart exige el `pubspec.yaml` y qué dependencias de producción declara?**
`sdk: ^3.7.2`. Dependencias de producción: `mysql_client`, `shelf`, `shelf_router`.

**9. ¿Qué diferencia hay entre las dependencias listadas en `dependencies` y las de `dev_dependencies` en este proyecto?**
`dependencies` (`mysql_client`, `shelf`, `shelf_router`) son necesarias para que la API corra en producción. `dev_dependencies` (`http`, `lints`, `test`) solo se usan en desarrollo: `http` para hacer peticiones desde los tests, `test` como framework de pruebas y `lints` para reglas de análisis estático.

**10. ¿Qué hace `router.mount('/', ...)` y por qué todas las rutas se montan sobre `'/'` en vez de un prefijo distinto por recurso?**
`mount` incrusta un sub-router dentro del router principal bajo un prefijo de path. Aquí se monta en `'/'` porque cada sub-router ya define su propio path completo (`/api/productos`, `/api/clientes`, etc.), así que no hace falta un prefijo adicional; si se montaran con otro prefijo, las rutas quedarían duplicadas (ej. `/api/api/productos`).

## 2. Modelos (`lib/models`)

**11. ¿Qué diferencia hay entre `Producto.fromMap` y `Producto.toMap`, y para qué se usa cada uno?**
`fromMap` es un factory constructor que convierte un `Map<String, dynamic>` (típicamente proveniente de una fila de MySQL) en una instancia de `Producto`. `toMap` hace lo inverso: convierte la instancia en un `Map` serializable a JSON. En la práctica actual del proyecto, ninguno de los dos se usa en las rutas (que arman los mapas manualmente desde `IResultSet`).

**12. ¿Por qué `Cliente` tiene campos anulables (`String?`) para `apellido`, `telefono` y `email` pero `nombre` no?**
Porque en el esquema SQL (`database.dart`) esas columnas se declaran sin `NOT NULL` (`apellido VARCHAR(150)`, etc.), mientras que `nombre VARCHAR(150) NOT NULL` es obligatorio. El modelo refleja esa restricción de negocio: un cliente siempre debe tener nombre, pero el resto de datos de contacto son opcionales.

**13. En `DetalleVenta.fromMap`, ¿por qué se usa `int.tryParse(map['venta_id']?.toString() ?? '') ?? 0` en lugar de un cast directo `as int`?**
Porque el driver `mysql_client` puede devolver valores numéricos como `String`, `BigInt` u otro tipo según la columna, y un cast directo `as int` fallaría con una excepción si el tipo no coincide exactamente. Convertir a `String` y luego usar `tryParse` con un valor por defecto (`0`) hace el parseo tolerante a esas variaciones, a costa de silenciar errores de parseo (un valor inválido se convierte silenciosamente en `0`).

**14. ¿Qué tipo de dato tiene el campo `fecha` en el modelo `Venta` y cómo se parsea desde el resultado de la base de datos?**
Es `DateTime?` (anulable). Se parsea con `DateTime.tryParse(map['fecha'].toString())` solo si `map['fecha']` no es `null`; si es `null`, el campo queda como `null`.

**15. ¿Qué valores puede tomar el campo `estado` en `Venta` según el modelo y según el esquema SQL?**
En el modelo, `estado` es un `String` sin restricción de valores en Dart (solo tiene un default `'pendiente'` si viene `null` desde el map). En el esquema SQL, la columna es un `ENUM('pendiente', 'pagada', 'cancelada') NOT NULL DEFAULT 'pendiente'`, por lo que MySQL sí restringe los valores posibles a esos tres, aunque Dart no valida eso antes de insertar.

**16. ¿Por qué `Producto.fromMap` usa `map['nombre'] as String` (cast directo) mientras otros modelos usan `?.toString()`? ¿Qué riesgo introduce esa inconsistencia?**
Es una inconsistencia de estilo entre archivos del proyecto, no una decisión deliberada documentada. El riesgo es que si `nombre` llega como `null` o con un tipo distinto de `String` (por ejemplo si el driver devuelve otro tipo), `Producto.fromMap` lanzará una excepción no controlada (`TypeError`), mientras que los otros modelos degradan a un valor por defecto (`''` o `0`) sin lanzar error.

**17. ¿Qué representa la clase `DetalleVenta` en el dominio del negocio y qué relación tiene con `Venta` y `Producto`?**
Representa una línea de una venta: qué producto se vendió, en qué cantidad, a qué precio unitario y su subtotal. Se relaciona con `Venta` mediante `ventaId` (muchos detalles pertenecen a una venta) y con `Producto` mediante `productoId` (cada detalle referencia un producto), formando la relación clásica cabecera-detalle.

**18. ¿Los modelos tienen métodos para conectarse directamente a la base de datos? Justifica con el código.**
No. Ninguno de los archivos en `lib/models` importa `mysql_client` ni recibe una conexión; solo tienen constructores, `fromMap` y `toMap`. Toda la interacción con la base de datos vive en `lib/services`.

**19. ¿Qué pasaría si `precio` llegara como `null` a `Producto.fromMap`? ¿Se maneja ese caso?**
No se maneja: `double.parse(map['precio'].toString())` sobre `null` produce el string `'null'`, y `double.parse('null')` lanza un `FormatException`. No hay un `tryParse` con valor por defecto como en otros modelos.

**20. ¿Cómo se serializa un modelo a JSON en las rutas? ¿Se usa `toMap()` o se construyen mapas manualmente en `routes`?**
En la práctica actual, las rutas no usan los modelos ni `toMap()`; construyen mapas manualmente leyendo columnas por índice desde el `IResultSet` (ej. `row.colAt(0)`, `row.colAt(1)`, ...) y los serializan con `jsonEncode`.

## 3. Servicios (`lib/services`)

**21. ¿Qué tipo de retorno tienen los métodos de los servicios (`ProductoService`, `ClienteService`, etc.) y qué representa `IResultSet`?**
Casi todos devuelven `Future<IResultSet>` (la excepción es `crearTransaccional`, que devuelve `Future<Map<String, dynamic>>`). `IResultSet` es la interfaz de `mysql_client` que representa el resultado crudo de una consulta SQL: filas (`rows`), `affectedRows`, `lastInsertID`, etc.

**22. ¿Por qué los servicios reciben `MySQLConnection` en su constructor en vez de crear su propia conexión?**
Para reutilizar una única conexión compartida por toda la aplicación (creada una vez en `server.dart` con `Database.connect()`), en vez de abrir una conexión nueva por cada servicio o petición, lo cual sería más costoso y difícil de gestionar.

**23. ¿Qué hace exactamente `ProductoService.obtenerTodos()` y en qué orden devuelve los resultados?**
Ejecuta `SELECT id, nombre, precio FROM productos ORDER BY id DESC`, devolviendo todos los productos ordenados por `id` descendente (los más recientes primero).

**24. ¿Cómo se protege el código contra inyección SQL en los métodos `crear`, `actualizar` y `eliminar`?**
Usando consultas parametrizadas con placeholders con nombre (`:nombre`, `:precio`, `:id`, etc.) y pasando los valores en un `Map` como segundo argumento de `connection.execute(...)`, en vez de interpolar los valores directamente en el string SQL.

**25. ¿Qué diferencia hay entre `VentaService.crear()` y `VentaService.crearTransaccional()`?**
`crear()` solo inserta una fila en `ventas` con un `total` ya calculado externamente, sin tocar `detalle_venta`. `crearTransaccional()` recibe una lista de `items` (producto + cantidad), valida cliente y productos, calcula el `total` y cada `subtotal` internamente, e inserta la venta junto con todas sus filas de `detalle_venta` dentro de una única transacción de base de datos (`connection.transactional`).

**26. Dentro de `crearTransaccional`, ¿qué validaciones se hacen antes de insertar la venta (cliente, items, cantidad)?**
Verifica que el `clienteId` exista en la tabla `clientes`; que `items` no esté vacío; que cada item tenga un `producto_id` y `cantidad` válidos (parseables y `cantidad > 0`); y que cada `producto_id` exista en la tabla `productos`. Si alguna falla, lanza `MySQLClientException`.

**27. ¿Qué excepción se lanza si el cliente no existe en `crearTransaccional`, y de qué paquete proviene esa excepción?**
Se lanza `MySQLClientException('Cliente no encontrado')`, que proviene de `package:mysql_client/exception.dart`.

**28. ¿Cómo se calcula el `subtotal` de cada `detalle_venta` dentro de la transacción, y quién es responsable de ese cálculo: el cliente HTTP o el servicio?**
El servicio consulta el `precio` real del producto en la base de datos (no confía en un precio enviado por el cliente) y calcula `subtotal = precio * cantidad`; el `total` de la venta es la suma de todos los subtotales. El cálculo lo hace enteramente el servicio (`VentaService.crearTransaccional`), no el cliente HTTP.

**29. ¿Qué hace `connection.transactional((conn) async {...})` y qué garantiza en caso de que ocurra un error a mitad del proceso?**
Ejecuta el bloque dentro de una transacción SQL: todas las operaciones (insertar venta + insertar cada detalle) se confirman juntas (`COMMIT`) solo si todo el bloque termina sin errores; si se lanza una excepción en cualquier punto (por ejemplo un producto no encontrado a mitad de la iteración), la transacción se revierte (`ROLLBACK`) y no queda ninguna fila insertada a medias.

**30. ¿Cómo obtiene `crearTransaccional` el `ventaId` recién insertado para poder crear los detalles asociados?**
A partir de `ventaResult.lastInsertID` (el ID autogenerado por el `INSERT` en `ventas`), convertido a `int` con `int.tryParse(ventaResult.lastInsertID.toString()) ?? 0`.

**31. ¿Qué hace `DetalleVentaService.obtenerTodos()` de distinto respecto a una simple consulta a la tabla `detalle_venta` (pista: el `INNER JOIN`)?**
Hace un `INNER JOIN` con `productos` para traer también el nombre del producto (`p.nombre AS producto`) en cada fila, en vez de devolver solo el `producto_id` crudo.

**32. ¿Qué diferencia hay entre `VentaService.obtenerPorId()` y `VentaService.obtenerConDetalle()`?**
`obtenerPorId()` trae solo la fila de la tabla `ventas`. `obtenerConDetalle()` hace un `LEFT JOIN` con `detalle_venta` y `productos` para traer, en una sola consulta, la cabecera de la venta repetida en cada fila junto con cada línea de su detalle (patrón típico de "una fila por línea de detalle").

**33. ¿Por qué `obtenerConDetalle` usa `LEFT JOIN` en vez de `INNER JOIN` para traer el detalle de una venta?**
Para que la venta se siga devolviendo aunque no tenga ningún detalle asociado todavía (por ejemplo, una venta recién creada con `crear()` sin items). Con `INNER JOIN`, una venta sin filas en `detalle_venta` no aparecería en el resultado.

**34. ¿Qué pasaría con `obtenerConDetalle` si una venta no tiene ningún detalle asociado? ¿Cuántas filas devolvería la consulta?**
Devolvería exactamente una fila, con los datos de la venta y todas las columnas provenientes de `detalle_venta`/`productos` en `NULL` (por eso `venta_routes.dart` filtra con `.where((row) => row.colAt(5) != null)` antes de armar la lista `detalle`).

**35. ¿Los servicios validan los datos de entrada (por ejemplo, que `cantidad` sea mayor a 0) o esa validación está en otra capa?**
Depende del servicio: `VentaService.crearTransaccional` sí valida (`cantidad <= 0` lanza excepción) porque orquesta lógica de negocio compleja. Los servicios CRUD simples (`ProductoService`, `ClienteService`, `DetalleVentaService.crear/actualizar`) no validan nada; esa validación básica (campos obligatorios, formato numérico) se hace en la capa de `routes` antes de llamar al servicio.

## 4. Rutas / endpoints HTTP (`lib/routes`)

**36. ¿Qué endpoints expone `producto_routes.dart` y qué método HTTP corresponde a cada uno?**
`GET /api/productos` (listar), `GET /api/productos/<id>` (obtener uno), `POST /api/productos` (crear), `PUT /api/productos/<id>` (actualizar), `DELETE /api/productos/<id>` (eliminar).

**37. ¿Cómo valida `producto_routes.dart` que el `id` recibido en la URL sea numérico, y qué responde si no lo es?**
Con `int.tryParse(request.params['id']!)`. Si el resultado es `null` (no era numérico), responde `Response.badRequest` con `{'error': 'El ID debe ser numérico'}` en JSON.

**38. ¿Qué código de estado HTTP se devuelve al crear un recurso exitosamente (POST) y cuál al no encontrar un recurso (`GET/PUT/DELETE` con id inexistente)?**
`201` al crear exitosamente (`Response(201, ...)`), y `404` (`Response.notFound`) cuando el recurso no existe.

**39. ¿Cómo se determina si una actualización (`PUT`) no encontró el recurso, dado que la consulta SQL no lanza error por sí sola?**
Revisando `resultado.affectedRows`: si es `0`, significa que el `UPDATE ... WHERE id = :id` no afectó ninguna fila (el id no existe), y la ruta responde `404`. Si es mayor a `0`, responde `200` con mensaje de éxito.

**40. ¿Qué endpoint permite crear una venta junto con su detalle en una sola petición, y qué formato debe tener el body?**
`POST /api/ventas/transaccional`. El body debe ser un JSON con `cliente_id` (obligatorio), `estado` (opcional, default `'pendiente'`) e `items`: una lista no vacía de objetos, cada uno con `producto_id` y `cantidad`.

**41. ¿Qué endpoint devuelve una venta junto con su detalle de productos, y qué estructura JSON retorna (`venta` + `detalle`)?**
`GET /api/ventas/<id>/detalle`. Retorna `{"venta": {...datos de la venta...}, "detalle": [...lista de líneas con producto, cantidad, precio_unitario, subtotal...]}`.

**42. ¿Cómo maneja `venta_routes.dart` los errores de negocio lanzados por `MySQLClientException` en el endpoint transaccional, frente a otros errores inesperados?**
Con un `try/catch` específico: si se captura `MySQLClientException`, responde `400 Bad Request` con el mensaje de la excepción (`e.message`) como error de negocio/validación. Cualquier otra excepción cae en un `catch` genérico que responde `500 Internal Server Error` con un mensaje genérico, sin exponer detalles internos.

**43. ¿Qué validaciones tiene `cliente_routes.dart` sobre el campo `nombre` al crear o actualizar un cliente?**
Que exista y no esté vacío tras hacer `trim()` (`(data['nombre'] ?? '').toString().trim()`); si queda vacío, responde `400` con `{'error': 'El nombre es obligatorio'}`. Los demás campos (`apellido`, `telefono`, `email`) son opcionales y no se validan.

**44. ¿Qué pasa si el body de una petición POST/PUT no es un JSON válido? Da un ejemplo de qué archivo lo maneja y cómo.**
En `producto_routes.dart` (y `cliente_routes.dart` en el POST) el `jsonDecode(body)` está envuelto en un `try/catch`; si falla, responde `400` con `{'error': 'JSON inválido'}`. Nota: no todas las rutas tienen este `try/catch` explícito (por ejemplo, `venta_routes.dart` y `detalle_venta_routes.dart` llaman a `jsonDecode` sin capturar el error, por lo que un JSON malformado ahí produciría una excepción no controlada / error 500 en vez de un `400` limpio).

**45. ¿Por qué las rutas usan `int.tryParse` en vez de `int.parse` al leer parámetros de la URL?**
Porque `int.parse` lanza una excepción (`FormatException`) si el string no es un entero válido, lo que rompería la petición con un error no controlado. `int.tryParse` devuelve `null` en ese caso, permitiendo a la ruta responder de forma controlada con un `400 Bad Request`.

## 5. Base de datos, migraciones y seeders

**46. ¿Qué hace `Database.ensureSchema()` y en qué momento del ciclo de vida de la app se ejecuta?**
Ejecuta una serie de sentencias `CREATE TABLE IF NOT EXISTS` para `productos`, `clientes`, `ventas` y `detalle_venta` (con sus foreign keys). Se ejecuta automáticamente dentro de `Database.connect()`, es decir, cada vez que arranca el servidor (`bin/server.dart`) se asegura de que el esquema exista antes de continuar.

**47. ¿Qué relación de llaves foráneas existen entre `ventas`, `clientes`, `detalle_venta` y `productos`, y qué ocurre al borrar una venta (`ON DELETE CASCADE`)?**
`ventas.cliente_id` referencia a `clientes.id`; `detalle_venta.venta_id` referencia a `ventas.id` con `ON DELETE CASCADE` (si se borra una venta, se borran automáticamente sus detalles); `detalle_venta.producto_id` referencia a `productos.id` sin cascada.

**48. ¿Qué hace `bin/migrate.dart` para evitar ejecutar dos veces la misma migración?**
Crea (si no existe) una tabla `migrations` con columna única `migration VARCHAR(255) UNIQUE`. Antes de ejecutar cada archivo `.sql` en `lib/database/migrations`, consulta si ya existe un registro con ese nombre de archivo; si existe, la salta (`ya ejecutada`); si no, ejecuta el SQL y luego inserta un registro en `migrations` para marcarla como ejecutada.

**49. ¿Qué diferencia hay entre lo que crea `Database.ensureSchema()` y lo que hace la migración `001_create_productos.sql`? ¿Hay redundancia?**
Sí hay redundancia: `ensureSchema()` ya crea la tabla `productos` (junto con las demás) usando `CREATE TABLE IF NOT EXISTS` cada vez que arranca el servidor, mientras que `001_create_productos.sql` crea la misma tabla `productos` (con ligeras diferencias, como `VARCHAR(100)` en vez de `VARCHAR(150)`) a través del sistema de migraciones. Son dos mecanismos distintos logrando en parte lo mismo, lo que puede generar inconsistencias si se modifica uno y no el otro.

**50. ¿Qué inserta `ProductoSeeder.run()` y cómo se ejecuta desde la línea de comandos (`bin/seed.dart`)?**
Inserta dos productos fijos: `Arroz` (12.50) y `Azúcar` (8.50). Se ejecuta corriendo `dart run bin/seed.dart`, que conecta a la base de datos, llama a `ProductoSeeder.run(connection)` y cierra la conexión al finalizar (en un bloque `try/finally`).

---

## 6. Parametrización y transacciones (énfasis especial — el mismo concepto que en Laravel)

Esta sección profundiza en los dos temas centrales que enseñaste: **consultas parametrizadas** (prevención de inyección SQL) y **transacciones** (atomicidad). La idea clave para remarcar en clase: esto no es "una cosa de Dart" ni "una cosa de Laravel" — es un concepto de bases de datos/SQL que cada lenguaje expone con su propia sintaxis (`mysql_client` con `:nombre` aquí, PDO con `?`/`:nombre` o el query builder de Laravel allá, `DB::transaction()` en Laravel vs `connection.transactional()` en Dart).

**51. ¿Qué es una consulta parametrizada (prepared statement) y qué problema concreto resuelve?**
Es una consulta SQL donde los valores variables no se insertan como texto directamente en el string SQL, sino que se envían por separado como parámetros (placeholders como `:nombre` o `?`), y el motor/driver los combina de forma segura antes de ejecutar. Resuelve la inyección SQL: evita que un valor de entrada (por ejemplo, `nombre`) pueda alterar la estructura de la consulta si contiene comillas, `;`, `OR 1=1`, etc.

**52. Muestra con código del proyecto un ejemplo de consulta parametrizada y explica cada parte.**
De `ProductoService.crear`:
```dart
await connection.execute(
  'INSERT INTO productos (nombre, precio) VALUES (:nombre, :precio)',
  {'nombre': nombre, 'precio': precio},
);
```
El string SQL define placeholders con nombre (`:nombre`, `:precio`); el segundo argumento es un `Map` que asocia cada placeholder con su valor real. El driver `mysql_client` envía la consulta y los valores en pasos separados al servidor MySQL (o los escapa correctamente), nunca concatenando texto.

**53. ¿Cómo se vería el mismo `INSERT` de productos si estuviera hecho de forma insegura (concatenando strings), y por qué eso es peligroso?**
Se vería así (código que **no** existe en el proyecto, pero sirve para contraste):
```dart
await connection.execute(
  "INSERT INTO productos (nombre, precio) VALUES ('$nombre', $precio)",
);
```
Es peligroso porque si `nombre` llegara como `Arroz'); DROP TABLE productos; --`, el string final cambiaría la intención original de la consulta y ejecutaría comandos SQL arbitrarios inyectados por el atacante.

**54. En este proyecto, ¿qué tipo de placeholders usa `mysql_client`: posicionales (`?`) o con nombre (`:campo`)? Da un ejemplo.**
Usa placeholders con nombre, por ejemplo `:id` en `ClienteService.eliminar`: `'DELETE FROM clientes WHERE id = :id'` junto con `{'id': id}`. Esto es análogo a los bindings con nombre que se pueden usar en Laravel/PDO (`WHERE id = :id`, `['id' => $id]`), en vez del estilo posicional (`WHERE id = ?`, `[$id]`).

**55. ¿En qué parte del código de `venta_service.dart` se ve que el precio del producto NUNCA se confía al cliente HTTP, sino que se re-consulta parametrizadamente? ¿Por qué es una buena práctica de seguridad/negocio, más allá de la inyección SQL?**
En `crearTransaccional`, para cada item se ejecuta `SELECT id, nombre, precio FROM productos WHERE id = :id` con el `productoId` recibido, y el `precio` usado para el `subtotal` sale de esa fila, no del body de la petición. Es buena práctica porque, aunque no es directamente sobre inyección SQL, evita que un cliente malicioso envíe un `precio_unitario` manipulado y pague menos de lo debido — la fuente de verdad del precio siempre es la base de datos.

**56. ¿Qué diferencia de fondo hay (y qué similitud) entre usar `:nombre` en `mysql_client` (Dart) y usar el query builder de Laravel (`DB::table('productos')->insert([...])`) o Eloquent (`Producto::create([...])`)?**
La similitud es conceptual: en ambos casos, internamente se generan consultas parametrizadas — nunca se concatena el valor del usuario directamente en el SQL. La diferencia es de nivel de abstracción: en Dart aquí se escribe el SQL a mano y se pasan los parámetros explícitamente; en Laravel, el query builder/Eloquent generan el SQL parametrizado por ti a partir de métodos como `->insert()` o `->where()`, ocultando el placeholder. El riesgo de inyección solo reaparece en Laravel si se usa `DB::raw()` o `whereRaw()` concatenando strings manualmente, igual que pasaría en Dart si se concatenara el SQL a mano.

**57. ¿Qué es una transacción de base de datos y qué garantiza (piensa en atomicidad)?**
Es un conjunto de operaciones SQL que se ejecutan como una sola unidad indivisible: o se aplican **todas** (`COMMIT`) o no se aplica **ninguna** (`ROLLBACK`) si algo falla en el camino. La garantía clave que se usa en este proyecto es la **atomicidad** (la "A" de ACID): no puede quedar una venta creada sin su detalle, ni un detalle sin su venta.

**58. ¿Qué método expone `mysql_client` para ejecutar código dentro de una transacción, y cómo se compara con `DB::transaction(function () {...})` de Laravel?**
`connection.transactional((conn) async { ... })`. Es conceptualmente igual a `DB::transaction(function () { ... })` de Laravel: ambos reciben una función/closure con el código a ejecutar, ambos hacen `COMMIT` automático si la función termina bien, y ambos hacen `ROLLBACK` automático si se lanza una excepción dentro del closure — la diferencia es solo de sintaxis (callback con `conn` en Dart vs closure implícito sobre la conexión global en Laravel).

**59. Dentro de `crearTransaccional`, ¿por qué todas las consultas usan el parámetro `conn` del callback (`conn.execute(...)`) y no la variable `connection` original del servicio?**
Porque `conn` es la conexión "amarrada" a esa transacción específica; si dentro del callback se usara por error la `connection` original (fuera de la transacción), esas consultas se ejecutarían fuera del contexto transaccional, sin la garantía de atomicidad ni de aislamiento — es un error común y sutil que rompe la transacción silenciosamente (el código sigue "funcionando" pero deja de ser atómico).

**60. Explica paso a paso qué pasaría si, dentro de `crearTransaccional`, el segundo producto de la lista `items` no existe en la tabla `productos`. ¿Queda la venta a medias en la base de datos?**
No. Se inserta la venta y el primer detalle en memoria/dentro de la transacción, pero al no encontrar el segundo producto se lanza `MySQLClientException('Producto no encontrado: $productoId')` **antes** de terminar el callback; como la excepción escapa del bloque `transactional`, MySQL revierte (`ROLLBACK`) todo lo que se había hecho hasta ese punto dentro de esa transacción — ni la venta ni el primer detalle quedan guardados.

**61. ¿Por qué es importante calcular el `total` de la venta SUMANDO los subtotales dentro de la misma transacción, en vez de calcularlo con una consulta aparte después de insertar los detalles?**
Porque así se evita una condición de carrera y una consulta extra: el total se calcula en memoria a partir de los mismos datos (`precio` recién leído, `cantidad` recibida) que se van a insertar, garantizando que el valor guardado en `ventas.total` sea exactamente la suma de lo que efectivamente se insertó en `detalle_venta`, sin depender de una lectura posterior que podría ver un estado inconsistente si hubiera otra transacción concurrente.

**62. ¿Qué endpoints del proyecto NO usan transacciones a pesar de hacer una sola operación (y por qué no las necesitan)?**
Casi todos los CRUD simples (`ProductoService.crear`, `ClienteService.actualizar`, `DetalleVentaService.eliminar`, etc.) no usan `transactional` porque cada uno ejecuta una única sentencia SQL (`INSERT`, `UPDATE` o `DELETE`); una sola sentencia ya es atómica por sí misma en MySQL, por lo que envolverla en una transacción explícita no aporta nada adicional. La transacción explícita solo se necesita cuando hay **múltiples** sentencias que deben tener éxito u ocurrir todas juntas, como en `crearTransaccional`.

**63. Si tuvieras que agregar un endpoint "cancelar venta" que (a) cambia el estado de la venta a `cancelada` y (b) borra su detalle, ¿necesitarías una transacción? Justifica usando lo que ya existe en el esquema.**
Para el borrado del detalle no haría falta hacerlo manualmente gracias al `ON DELETE CASCADE` en `detalle_venta.venta_id` — pero como aquí NO se borra la venta, sino que se actualiza su estado, sí convendría envolver el `UPDATE ventas SET estado = 'cancelada'` junto con cualquier otra operación relacionada (por ejemplo, restituir stock si existiera) en una transacción, para que ambas operaciones se apliquen juntas o ninguna lo haga.

**64. ¿Qué le explicarías a un estudiante que ya vio esto en Laravel sobre la relación entre "Eloquent/Query Builder + `DB::transaction`" y "`mysql_client` + `connection.transactional`"? ¿Cuál es la idea que se transfiere entre frameworks/lenguajes?**
La idea que se transfiere es que **parametrización** y **transacciones** son conceptos de la capa de base de datos (SQL/ACID), no características de un framework: cualquier lenguaje que hable con una base de datos relacional (Dart, PHP/Laravel, Python, Java, etc.) necesita (1) nunca concatenar input del usuario en el SQL, usando placeholders/bindings, y (2) agrupar operaciones relacionadas en una transacción cuando la atomicidad importa. Lo que cambia entre Laravel y Dart es solo la sintaxis con la que se accede a esas dos garantías, no el concepto.

**65. ¿Qué pasaría en `crearTransaccional` si se te olvidara pasar `estado` y usaras el valor por defecto `'pendiente'`, y cómo se relaciona esto con la restricción `ENUM` de la tabla `ventas`? ¿Qué protege a la aplicación de insertar un estado inválido como `'enviado'`?**
Si no se envía `estado`, el parámetro con valor por defecto `'pendiente'` de `crearTransaccional({..., String estado = 'pendiente'})` se usaría automáticamente. Si alguien pasara un estado inválido como `'enviado'`, la aplicación Dart no lo valida antes de insertar (no hay chequeo contra una lista de estados permitidos en el código), pero la columna `estado ENUM('pendiente', 'pagada', 'cancelada')` en MySQL rechazaría el `INSERT`/`UPDATE` a nivel de base de datos, lanzando un error — es la propia base de datos, no la capa Dart, la que actúa como última línea de defensa de esa regla de negocio.

---

## 7. CORS y middlewares

**66. ¿Qué es un middleware en el contexto de `shelf`, y qué firma tiene (`Middleware`) según se ve en `_corsMiddleware()`?**
Un middleware es una función que envuelve un `Handler` y devuelve otro `Handler`: recibe la petición antes (o en vez) de que llegue al handler final, puede modificarla, cortocircuitar la respuesta, o dejar pasar la petición y luego modificar la respuesta antes de devolverla. En `shelf`, el tipo `Middleware` es literalmente `Handler Function(Handler innerHandler)`; así está tipada `_corsMiddleware()` en `server.dart`, que retorna una función `(Handler handler) => (Request request) async {...}`.

**67. ¿Qué es CORS (Cross-Origin Resource Sharing) y por qué una API necesita configurarlo si el frontend (por ejemplo la app Flutter web, o un cliente en otro dominio/puerto) corre en un origen distinto?**
CORS es el mecanismo del navegador que restringe si una página cargada desde un origen (dominio+puerto+protocolo) puede hacer peticiones a una API en otro origen. Sin las cabeceras CORS adecuadas, el navegador bloquearía las respuestas de esta API cuando un frontend web corriendo en otro puerto (ej. `http://localhost:5173`) intente consumirla, aunque el servidor sí procese la petición correctamente.

**68. ¿Qué tres headers agrega `_corsMiddleware()` a cada respuesta y qué controla cada uno?**
`Access-Control-Allow-Origin: '*'` (permite que cualquier origen consuma la API), `Access-Control-Allow-Methods: 'GET, POST, PUT, DELETE, OPTIONS'` (qué verbos HTTP están permitidos desde otro origen) y `Access-Control-Allow-Headers: 'Origin, Content-Type, Accept'` (qué headers puede enviar el cliente en la petición, por ejemplo `Content-Type: application/json`).

**69. ¿Por qué `_corsMiddleware()` maneja de forma especial las peticiones `OPTIONS`, respondiendo `200` inmediatamente sin llamar a `handler(request)`?**
Porque `OPTIONS` es la petición de "preflight" que el navegador envía automáticamente antes de un `POST`/`PUT`/`DELETE` "no simple" (por ejemplo con `Content-Type: application/json`), solo para preguntarle al servidor si el origen/método/headers están permitidos. El servidor no debe ejecutar lógica de negocio para esa petición; basta con responder `200` con los headers CORS para que el navegador luego sí envíe la petición real.

**70. En el código `final response = await handler(request); return response.change(headers: {...response.headers, ...corsHeaders});`, ¿qué hace `response.change()` y por qué no se modifican los headers del `response` original directamente?**
`response.change()` crea una **nueva** instancia de `Response` copiando la original pero con los headers indicados sobreescritos/añadidos. No se modifican "directamente" porque en `shelf` los objetos `Request`/`Response` son inmutables — no tienen setters para sus headers — así que la única forma de "agregar" headers a una respuesta ya construida es pedir una copia modificada con `change()`.

**71. ¿Qué pasaría si `_corsMiddleware()` se aplicara DESPUÉS de `logRequests()` en el `Pipeline` en vez de antes? ¿Cambiaría el comportamiento observable para el cliente?**
El orden de un `Pipeline` en `shelf` determina en qué secuencia se van envolviendo los handlers: el middleware añadido primero es el que se ejecuta más "afuera" (ve la petición primero y la respuesta al final). Cambiar el orden entre CORS y logging no afectaría lo que ve el cliente final (los headers CORS se seguirían agregando en la respuesta), pero sí afectaría qué se loggea: con `logRequests()` más externo, se loggearían también las peticiones `OPTIONS` cortadas por CORS; con el orden actual (CORS primero), esas peticiones `OPTIONS` nunca llegan a `logRequests()`.

**72. ¿Qué hace el middleware `logRequests()` que usa `server.dart`, y de qué paquete proviene?**
Proviene del propio paquete `shelf` (`package:shelf/shelf.dart`). Es un middleware que registra en la salida estándar cada petición recibida (método, path, código de estado de la respuesta y tiempo que tomó procesarla), útil para depuración básica sin necesidad de un logger externo.

**73. ¿Por qué la configuración de CORS usada (`Access-Control-Allow-Origin: '*'`) sería insegura o inadecuada si la API manejara cookies de sesión o credenciales, y qué normalmente se hace distinto en ese caso?**
`Access-Control-Allow-Origin: '*'` permite que **cualquier** sitio web haga peticiones a la API desde el navegador del usuario. Si la API dependiera de cookies de sesión (`Access-Control-Allow-Credentials: true`), el estándar CORS ni siquiera permite combinar `'*'` con credenciales — habría que devolver el origen específico del cliente (no `'*'`) y mantener una lista blanca de orígenes permitidos, en vez de aceptar cualquiera. Como esta API no usa cookies (probablemente usa, o debería usar, tokens en headers), `'*'` es una simplificación razonable solo para desarrollo/pruebas.

**74. Si quisieras agregar autenticación (por ejemplo, validar un header `Authorization: Bearer <token>`) a toda la API sin tocar cada ruta una por una, ¿cómo encaja eso con el patrón de `Middleware` que ya usa el proyecto?**
Se agregaría un nuevo middleware (similar en forma a `_corsMiddleware()`) que intercepte la petición antes del router, revise el header `Authorization`, y si no es válido corte la cadena devolviendo `401` sin llamar a `handler(request)`; si es válido, deje pasar la petición llamando a `handler(request)`. Se añadiría al `Pipeline` con `.addMiddleware(_authMiddleware())`, típicamente después de CORS (para que los preflights `OPTIONS` sigan sin requerir auth) y antes o después de `logRequests()` según si se quiere loggear también los intentos no autenticados.

**75. ¿Qué diferencia hay entre resolver CORS con un middleware manual (como hace este proyecto) y usar un paquete dedicado como `shelf_cors_headers`? ¿Qué gana o pierde el proyecto al implementarlo a mano?**
Un paquete dedicado ya maneja casos borde (listas de orígenes permitidos, cacheo de preflight con `Access-Control-Max-Age`, headers adicionales como `Access-Control-Allow-Credentials`) de forma más completa y probada. Implementarlo a mano, como aquí, da control total y cero dependencias extra, pero es más fácil dejar casos sin cubrir (por ejemplo, no se envía `Access-Control-Max-Age`, por lo que el navegador repetirá el preflight en cada petición no "simple" en vez de cachearlo).

**¿Cómo están escritos los tests en `test/server_test.dart` (arrancan un proceso real del servidor o usan mocks)?**
Son pruebas de integración reales: en `setUp` se levanta un proceso real (`Process.start('dart', ['run', 'bin/server.dart'], ...)`) escuchando en el puerto `8080`, y en `tearDown` se mata el proceso. Los tests hacen peticiones HTTP reales con el paquete `http` contra ese servidor; no hay mocks.

**¿Qué verifica el test "Venta transaccional crea cabecera y detalle en una sola operación"?**
Crea un cliente, luego llama a `POST /api/ventas/transaccional` con dos items (`producto_id` 1 y 2), y verifica que la respuesta sea `201`, que `venta.cliente_id` coincida con el cliente creado, y que `venta.detalle` sea una lista con exactamente 2 elementos.

**¿Qué pasaría si dos peticiones concurrentes crean una venta transaccional para el mismo cliente? ¿Hay algún bloqueo?**
Cada llamada a `crearTransaccional` abre su propia transacción (`connection.transactional`), por lo que MySQL gestiona el aislamiento entre ambas a nivel de motor de base de datos. El código Dart no implementa bloqueos explícitos adicionales; ambas ventas se crearían de forma independiente y correcta siempre que MySQL maneje bien la concurrencia (no hay condición de carrera relevante porque no se comparte estado mutable entre ellas, solo se leen precios de productos y se insertan filas nuevas).

**¿Qué credenciales de base de datos están hardcodeadas en `database.dart` y qué riesgo de seguridad implica eso en producción?**
`host: '127.0.0.1'`, `port: 3306`, `userName: 'root'`, `password: ''` (vacía), `databaseName: 'api_dart'`. Esto es aceptable solo en desarrollo local; en producción implica un riesgo serio (usuario root sin contraseña) y además impide apuntar a distintos entornos (dev/staging/prod) sin recompilar, ya que no se usan variables de entorno para la configuración de conexión.
