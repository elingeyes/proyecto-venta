import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'models/producto.dart';
import 'services/producto_api.dart';
import 'models/cliente.dart';
import 'services/venta_api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productos y ventas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff3c8dbc),
          primary: const Color(0xff3c8dbc),
        ),
        scaffoldBackgroundColor: const Color(0xffecf0f5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff3c8dbc),
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 1,
          margin: EdgeInsets.zero,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administración'),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Perfil',
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700 ? 3 : 2;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inicio',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Resumen general del sistema de ventas',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.55,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _DashboardCard(
                          title: 'Productos',
                          description: 'Administrar catálogo',
                          icon: Icons.inventory_2_outlined,
                          color: const Color(0xff00a65a),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProductosPage(),
                              ),
                            );
                          },
                        ),
                        const _DashboardCard(
                          title: 'Clientes',
                          description: 'Próximamente',
                          icon: Icons.people_outline,
                          color: Color(0xff00c0ef),
                        ),
                        _DashboardCard(
                          title: 'Ventas',
                          description: 'Registrar venta',
                          icon: Icons.point_of_sale_outlined,
                          color: Color(0xfff39c12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VentaPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: const Icon(
                          Icons.info_outline,
                          color: Color(0xff3c8dbc),
                        ),
                        title: const Text('Accesos rápidos'),
                        subtitle: const Text(
                          'Selecciona un módulo para comenzar a trabajar.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              width: 76,
              height: double.infinity,
              color: color,
              child: Icon(icon, color: Colors.white, size: 34),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _apiBaseUrl() {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured;
  return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
}

class VentaPage extends StatefulWidget {
  const VentaPage({super.key});

  @override
  State<VentaPage> createState() => _VentaPageState();
}

class _VentaPageState extends State<VentaPage> {
  late final VentaApi _api;
  late final ProductoApi _productoApi;
  late final Future<List<Cliente>> _clientes;
  late final Future<List<Producto>> _productos;
  Cliente? _cliente;
  Producto? _producto;
  int _cantidad = 1;
  final List<DetalleCarrito> _carrito = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _api = VentaApi(baseUrl: _apiBaseUrl());
    _productoApi = ProductoApi(baseUrl: _apiBaseUrl());
    _clientes = _api.obtenerClientes();
    _productos = _productoApi.obtenerProductos();
  }

  @override
  void dispose() {
    _api.dispose();
    _productoApi.dispose();
    super.dispose();
  }

  double get _total => _carrito.fold(0, (total, item) => total + item.subtotal);

  void _agregarAlCarrito() {
    if (_producto == null) return;
    final indice = _carrito.indexWhere(
      (item) => item.producto.id == _producto!.id,
    );
    setState(() {
      if (indice >= 0) {
        final actual = _carrito[indice];
        _carrito[indice] = DetalleCarrito(
          producto: actual.producto,
          cantidad: actual.cantidad + _cantidad,
        );
      } else {
        _carrito.add(DetalleCarrito(producto: _producto!, cantidad: _cantidad));
      }
      _producto = null;
      _cantidad = 1;
    });
  }

  Future<void> _guardarVenta() async {
    if (_cliente == null || _carrito.isEmpty) {
      _mensaje('Selecciona un cliente y agrega al menos un producto.');
      return;
    }
    setState(() => _guardando = true);
    try {
      await _api.crearVentaTransaccional(
        clienteId: _cliente!.id,
        items:
            _carrito
                .map(
                  (item) => DetalleVentaRequest(
                    productoId: item.producto.id,
                    cantidad: item.cantidad,
                  ),
                )
                .toList(),
      );
      if (!mounted) return;
      setState(() {
        _carrito.clear();
        _cliente = null;
      });
      _mensaje('Venta registrada con cabecera y detalle.');
    } catch (error) {
      _mensaje('No se pudo registrar la venta: $error');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Nueva venta transaccional'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_clientes, _productos]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              onRetry: () => setState(() {}),
              message:
                  'No se pudieron cargar clientes y productos.\n\n${snapshot.error}',
            );
          }
          final clientes = snapshot.data![0] as List<Cliente>;
          final productos = snapshot.data![1] as List<Producto>;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionTitle(
                icon: Icons.receipt_long_outlined,
                title: 'Cabecera de la venta',
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<Cliente>(
                    initialValue: _cliente,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        clientes
                            .map(
                              (cliente) => DropdownMenuItem(
                                value: cliente,
                                child: Text(cliente.nombreCompleto),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _cliente = value),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _SectionTitle(
                icon: Icons.shopping_cart_outlined,
                title: 'Detalle de productos',
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Producto>(
                          initialValue: _producto,
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              productos
                                  .map(
                                    (producto) => DropdownMenuItem(
                                      value: producto,
                                      child: Text(
                                        '${producto.nombre} - \$${producto.precio.toStringAsFixed(2)}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) => setState(() => _producto = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: '1',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _cantidad = int.tryParse(value) ?? 1;
                            if (_cantidad < 1) _cantidad = 1;
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: _agregarAlCarrito,
                        tooltip: 'Agregar detalle',
                        icon: const Icon(Icons.add_circle),
                        color: const Color(0xff00a65a),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._carrito.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.producto.nombre),
                    subtitle: Text(
                      '${item.cantidad} x \$${item.producto.precio.toStringAsFixed(2)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\$${item.subtotal.toStringAsFixed(2)}'),
                        IconButton(
                          onPressed:
                              () => setState(() => _carrito.remove(item)),
                          icon: const Icon(Icons.delete_outline),
                          color: const Color(0xffdd4b39),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xfff8f9fa),
                child: ListTile(
                  title: const Text('Total'),
                  trailing: Text(
                    '\$${_total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xff00a65a),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardarVenta,
                icon:
                    _guardando
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check),
                label: Text(_guardando ? 'Guardando...' : 'Registrar venta'),
              ),
              const SizedBox(height: 8),
              const Text(
                'La API validará cliente y productos y guardará la cabecera y sus detalles dentro de una única transacción.',
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff3c8dbc)),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final ProductoApi _api = ProductoApi();
  late Future<List<Producto>> _productos;

  @override
  void initState() {
    super.initState();
    _productos = _api.obtenerProductos();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      _productos = _api.obtenerProductos();
    });
  }

  Future<void> _crearProducto() async {
    final datos = await _mostrarFormulario();
    if (datos == null) return;

    try {
      await _api.crearProducto(nombre: datos.nombre, precio: datos.precio);
      _recargar();
      _mostrarMensaje('Producto creado correctamente.');
    } catch (error) {
      _mostrarMensaje('No se pudo crear el producto: $error');
    }
  }

  Future<void> _editarProducto(Producto producto) async {
    final datos = await _mostrarFormulario(producto: producto);
    if (datos == null) return;

    try {
      await _api.actualizarProducto(
        id: producto.id,
        nombre: datos.nombre,
        precio: datos.precio,
      );
      _recargar();
      _mostrarMensaje('Producto actualizado correctamente.');
    } catch (error) {
      _mostrarMensaje('No se pudo actualizar el producto: $error');
    }
  }

  Future<void> _eliminarProducto(Producto producto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar producto'),
            content: Text('¿Quieres eliminar "${producto.nombre}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (confirmar != true) return;

    try {
      await _api.eliminarProducto(producto.id);
      _recargar();
      _mostrarMensaje('Producto eliminado correctamente.');
    } catch (error) {
      _mostrarMensaje('No se pudo eliminar el producto: $error');
    }
  }

  Future<_ProductoFormData?> _mostrarFormulario({Producto? producto}) {
    return showDialog<_ProductoFormData>(
      context: context,
      builder: (_) => _ProductoDialog(producto: producto),
    );
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver al inicio',
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Productos'),
        actions: [
          IconButton(
            onPressed: _recargar,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _crearProducto,
            tooltip: 'Crear producto',
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Producto>>(
        future: _productos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorView(
              onRetry: _recargar,
              message:
                  'No se pudieron cargar los productos.\n\n${snapshot.error}',
            );
          }

          final productos = snapshot.data ?? const <Producto>[];
          if (productos.isEmpty) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 52,
                        color: Color(0xff3c8dbc),
                      ),
                      const SizedBox(height: 12),
                      const Text('No hay productos registrados.'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _crearProducto,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear producto'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xff3c8dbc),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Catálogo de productos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _crearProducto,
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final future = _api.obtenerProductos();
                    setState(() {
                      _productos = future;
                    });
                    await future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: productos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final producto = productos[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                color: const Color(0xff00a65a),
                              ),
                              Expanded(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xff3c8dbc),
                                    foregroundColor: Colors.white,
                                    child: Text('${producto.id}'),
                                  ),
                                  title: Text(
                                    producto.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text('Código: ${producto.id}'),
                                  trailing: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        '\$${producto.precio.toStringAsFixed(2)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          color: const Color(0xff00a65a),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed:
                                            () => _editarProducto(producto),
                                        tooltip: 'Editar producto',
                                        color: const Color(0xff3c8dbc),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        onPressed:
                                            () => _eliminarProducto(producto),
                                        tooltip: 'Eliminar producto',
                                        color: const Color(0xffdd4b39),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, required this.message});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductoFormData {
  const _ProductoFormData({required this.nombre, required this.precio});

  final String nombre;
  final double precio;
}

class _ProductoDialog extends StatefulWidget {
  const _ProductoDialog({this.producto});

  final Producto? producto;

  @override
  State<_ProductoDialog> createState() => _ProductoDialogState();
}

class _ProductoDialogState extends State<_ProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _precioController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.producto?.nombre);
    _precioController = TextEditingController(
      text: widget.producto?.precio.toString(),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      _ProductoFormData(
        nombre: _nombreController.text.trim(),
        precio: double.parse(
          _precioController.text.trim().replaceAll(',', '.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.producto != null;
    return AlertDialog(
      title: Text(editando ? 'Editar producto' : 'Nuevo producto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              autofocus: !editando,
              decoration: const InputDecoration(labelText: 'Nombre'),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el nombre';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final precio = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (precio == null || precio <= 0) {
                  return 'Ingresa un precio válido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: Text(editando ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }
}
