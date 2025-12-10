import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../services/cart_service.dart';
import 'personal_data_screen.dart';
import '../theme_sync.dart';
import '../main.dart'; // donde está routeObserver


class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with RouteAware {
  final CartService _cartService = CartService();
  final _uuid = const Uuid();
  bool _wantsInvoice = false;
  String? _userName;
  String? _userIdNumber;

  @override
  void initState() {
    super.initState();
    _loadUserInfo(); // 🔥 cargamos nombre/cedula apenas entra
  }
 @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }
@override
  void didPopNext() {
    // 👈 Esto corre SIEMPRE al regresar a CartScreen
    _loadUserInfo();
    setState(() {});
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme;
    ThemeSync.applyThemeSilently(ThemeSync.isDarkMode);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: const Center(
            child: Text("Debes iniciar sesión para ver tu carrito."),
          ),
        ),
      );
    }

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          toolbarHeight: 75, // 🔥 Hace la barra grande como las demás
          centerTitle: true,
          title: const Text(
            "Tu Carrito 🛒",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('cart')
                  .snapshots(),
              builder: (context, snapshot) {
                final hasItems = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                return IconButton(
                  tooltip: hasItems ? "Vaciar carrito" : "Carrito vacío",
                  icon: Icon(
                    Icons.delete_forever,
                    color: hasItems ? Colors.white : Colors.white54, // deshabilitado
                    size: 30,
                  ),
                  onPressed: hasItems
                      ? () async => _confirmEmptyCart()   // 🔥 NUEVA FUNCIÓN
                      : null,
                );
              },
            ),
          ],
        ),

        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('cart')
              .orderBy('addedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("Tu carrito está vacío 😔"));
            }

            final docs = snapshot.data!.docs;
            double totalGeneral = 0;
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              totalGeneral += (data['total'] ?? 0).toDouble();
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final title = data['title'] ?? '';
                      final image = data['image'] ?? '';
                      final date = data['date'] ?? '';
                      final time = data['time'] ?? '';
                      final zones = (data['zones'] as List<dynamic>?) ?? [];
                      final total = (data['total'] ?? 0).toDouble();

                      return Card(
                        elevation: 3,
                        color: theme.colorScheme.surface,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (image.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        image,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$date • $time",
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.redAccent),
                                    onPressed: () async {
                                      await _cartService.removeFromCart(title);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text("$title eliminado del carrito."),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const Divider(),
                              ...zones.map((z) {
                                final zone = Map<String, dynamic>.from(z);
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          zone['name'],
                                          style: TextStyle(
                                              color: theme.colorScheme.onSurface),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              color: Colors.redAccent, size: 22),
                                          onPressed: () async {
                                            await _updateZoneCount(
                                                uid, title, zone['name'], -1);
                                          },
                                        ),
                                        Text("${zone['count']}x",
                                            style: TextStyle(
                                                color:
                                                    theme.colorScheme.onSurface)),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle,
                                              color: Colors.green, size: 22),
                                          onPressed: () async {
                                            await _updateZoneCount(
                                                uid, title, zone['name'], 1);
                                          },
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "\$${(zone['subtotal'] ?? 0).toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              const Divider(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "Total evento: \$${total.toStringAsFixed(2)}",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
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

                // ✅ Pie de pago
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total general:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "\$${totalGeneral.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ------------------------------------
                      // 🔥 BLOQUE ANIMADO DE FACTURA
                      // ------------------------------------
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              value: _wantsInvoice,
                              onChanged: (v) => setState(() => _wantsInvoice = v ?? false),
                              title: Text(
                                "¿Desea factura?",
                                style: TextStyle(color: theme.colorScheme.onSurface),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),

                            // 👇 Mostrar datos personales con animación si quiere factura
                            if (_wantsInvoice)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Datos para la factura:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),

                                        // 🔄 Botón de recargar
                                        IconButton(
                                          tooltip: "Actualizar datos",
                                          icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                                          onPressed: () async {
                                            await _loadUserInfo();
                                            
                                          },
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),
                                    Text(
                                      "Nombre: ${_userName ?? 'No registrado'}",
                                      style: TextStyle(color: theme.colorScheme.onSurface),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Cédula: ${_userIdNumber ?? 'No registrada'}",
                                      style: TextStyle(color: theme.colorScheme.onSurface),
                                    ),
                                    const SizedBox(height: 10),
                                    TextButton(
                                      onPressed: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const PersonalDataScreen(),
                                          ),
                                        );

                                        // 👇 Recargar datos al volver del formulario
                                        await _loadUserInfo();

                                        // 👇 Refrescar UI inmediatamente
                                        if (mounted) setState(() {});
                                      },
                                      child: Text(
                                        "Editar datos personales",
                                        style: TextStyle(color: theme.colorScheme.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: totalGeneral > 0
                            ? () async => _handlePayment(
                                context, uid, totalGeneral)
                            : null,
                        icon: const Icon(Icons.payment),
                        label: const Text("Proceder al pago"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

Future<void> _confirmEmptyCart() async {
    final theme = ThemeSync.currentTheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Theme(
        data: theme,
        child: AlertDialog(
          title: const Text("Vaciar carrito"),
          content: const Text("¿Deseas eliminar todos los productos del carrito?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Vaciar"),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await _cartService.clearCart();
      _showCartEmptiedPopup(); // 🔥 popup pro
    }
  }
  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('personalData')
        .doc('info')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _userName = data['name'] ?? '';
        _userIdNumber = data['idNumber'] ?? '';
      });
    }
  }


  Future<void> _showCartEmptiedPopup() async {
    final theme = ThemeSync.currentTheme;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Theme(
          data: theme,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ❌ cerrar
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Icon(Icons.delete_sweep, color: Colors.redAccent, size: 60),

                  const SizedBox(height: 15),

                  Text(
                    "Carrito vaciado",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Todos los artículos fueron eliminados correctamente.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Actualizar cantidad (+ o -)
  Future<void> _updateZoneCount(
      String uid, String eventTitle, String zoneName, int delta) async {
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .doc(eventTitle);

    final doc = await cartRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final zones =
        (data['zones'] as List).map((z) => Map<String, dynamic>.from(z)).toList();

    for (final zone in zones) {
      if (zone['name'] == zoneName) {
        zone['count'] = (zone['count'] ?? 0) + delta;
        if (zone['count'] < 1) {
          zones.remove(zone);
          break;
        }
        zone['subtotal'] =
            (zone['price'] ?? 0) * (zone['count'] ?? 0);
        break;
      }
    }

    final total =
        zones.fold<double>(0, (sum, z) => sum + (z['subtotal'] ?? 0));

    if (zones.isEmpty) {
      await cartRef.delete();
    } else {
      await cartRef.update({'zones': zones, 'total': total});
    }
  }
void _showCapacityErrorPopup(BuildContext context, String error) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("No se pudo completar la compra"),
      content: Text(error),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Entendido"),
        ),
      ],
    ),
  );
}


void _showMandatoryInvoicePopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            SizedBox(width: 10),
            Text("Factura obligatoria"),
          ],
        ),
        content: const Text(
          "Para compras mayores a 50 es obligatorio solicitar factura.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendido"),
          ),
        ],
      );
    },
  );
}

 // 🔹 Manejo del pago
  Future<void> _handlePayment(
      BuildContext context, String uid, double totalGeneral) async {

    // 🚨 NUEVO: Si el total es >= 50, la factura es obligatoria
    // 🚨 NUEVO: Si el total es >= 50, la factura es obligatoria
    if (totalGeneral >= 50 && !_wantsInvoice) {
      _showMandatoryInvoicePopup(context);  // 👈 popup elegante
      return;
    }


    // ✅ Si desea factura, validar datos personales
    if (_wantsInvoice) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('personalData')
          .doc('info')
          .get();

      if (!doc.exists || (doc.data()?['name'] ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Debes llenar tus datos personales para generar factura."),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PersonalDataScreen()),
        );
        return;
      }
    }
    final cartSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {

        for (final doc in cartSnapshot.docs) {
          final data = doc.data();
          final eventTitle = data['title'];
          final zones = (data['zones'] as List<dynamic>?) ?? [];

          // obtener el evento por título
          final eventQuery = await FirebaseFirestore.instance
              .collection('events')
              .where('title', isEqualTo: eventTitle)
              .limit(1)
              .get();

          if (eventQuery.docs.isEmpty) {
            throw Exception("El evento no existe.");
          }

          final eventRef = eventQuery.docs.first.reference;
          final eventSnap = await transaction.get(eventRef);
          final eventData = eventSnap.data() as Map<String, dynamic>;

          final eventZones = (eventData['zones'] as List<dynamic>)
              .map((z) => Map<String, dynamic>.from(z))
              .toList();

          // recorrer las zonas que el usuario quiere comprar
          for (final zone in zones) {
            final zoneName = zone['name'];
            final countToBuy = zone['count'];

            final zoneInEvent = eventZones.firstWhere(
              (z) => z['name'] == zoneName,
              orElse: () => throw Exception("La localidad $zoneName no existe."),
            );

            final currentCapacity = (zoneInEvent['capacity'] ?? 0).toInt();

            // 🚨 no hay suficientes cupos
            if (currentCapacity < countToBuy) {
              throw Exception(
                  "La localidad $zoneName ya no tiene suficientes cupos disponibles.");
            }

            // 🔥 restar capacidad
            zoneInEvent['capacity'] = currentCapacity - countToBuy;
          }

          // 🔥 guardar nueva capacidad en Firestore
          transaction.update(eventRef, {'zones': eventZones});
        }
      });
    } catch (e) {
      _showCapacityErrorPopup(context, e.toString());
      return;
    }

    // ✅ Generar tickets y factura (aunque no haya solicitado)
    await _generateTickets(uid);
    await _createInvoice(uid, totalGeneral, wantsInvoice: _wantsInvoice);
    _showPaymentPopup(context, uid);
  }

  // 🔹 Crear factura
  Future<void> _createInvoice(String uid, double totalGeneral,
      {bool wantsInvoice = false}) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final personalDataSnap =
          await userRef.collection('personalData').doc('info').get();
      final cartDocs = await userRef.collection('cart').get();

      final personalData = personalDataSnap.data() ?? {};
      final email = personalData['email'] ??
          FirebaseAuth.instance.currentUser?.email ??
          'sin-correo';

      // ✅ Si no quiere factura, usar datos de consumidor final
      final bool isConsumerFinal = !wantsInvoice;

      final String userName =
          isConsumerFinal ? 'Consumidor Final' : (personalData['name'] ?? '');
      final String idNumber =
          isConsumerFinal ? '9999999999' : (personalData['idNumber'] ?? '');
      final String phone =
          isConsumerFinal ? '0000000000' : (personalData['phone'] ?? '');
      final String address =
          isConsumerFinal ? 'S/N' : (personalData['address'] ?? '');

      await FirebaseFirestore.instance.collection('facturas').add({
        'userId': uid,
        'userName': userName,
        'email': email,
        'idNumber': idNumber,
        'phone': phone,
        'address': address,
        'total': totalGeneral,
        'createdAt': FieldValue.serverTimestamp(),
        'items': cartDocs.docs.map((e) => e.data()).toList(),
        'tipoFactura':
            isConsumerFinal ? 'consumidor_final' : 'personalizada', // 👈 identificador
      });
    } catch (e) {
      debugPrint("❌ Error creando factura: $e");
    }
  }

  // 🔹 Generar tickets (timestamp real)
  Future<void> _generateTickets(String uid) async {
    final userCart = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart')
        .get();

    for (final doc in userCart.docs) {
      final data = doc.data();
      final title = data['title'];
      final dateStr = data['date'] ?? '';
      final timeStr = data['time'] ?? '';
      final image = data['image'];
      final type = data['type'] ?? '';
      final zones = (data['zones'] as List<dynamic>?) ?? [];

      DateTime? parsedDate;
      try {
        final meses = {
          'enero': 1,
          'febrero': 2,
          'marzo': 3,
          'abril': 4,
          'mayo': 5,
          'junio': 6,
          'julio': 7,
          'agosto': 8,
          'septiembre': 9,
          'octubre': 10,
          'noviembre': 11,
          'diciembre': 12,
        };

        final partes = dateStr.split(' ');
        if (partes.length >= 4) {
          final dia = int.tryParse(partes[0]) ?? 1;
          final mes = meses[partes[2].toLowerCase()] ?? 1;
          final anio = int.tryParse(partes[3]) ?? DateTime.now().year;

          int hora = 0, minuto = 0;
          if (timeStr.contains(':')) {
            final partesHora = timeStr.split(':');
            hora = int.tryParse(partesHora[0]) ?? 0;
            minuto = int.tryParse(partesHora[1]) ?? 0;
          }

          parsedDate = DateTime(anio, mes, dia, hora, minuto);
        }
      } catch (e) {
        debugPrint("⚠️ Error parseando fecha: $e");
      }

      for (final z in zones) {
        final zone = Map<String, dynamic>.from(z);
        final count = (zone['count'] ?? 1) as int;

        for (int i = 0; i < count; i++) {
          final qrId = _uuid.v4();
          final qrData = "$uid|$title|${zone['name']}|$qrId";

          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('tickets')
              .add({
            'eventTitle': title,
            'eventType': type,
            'eventDateTime': parsedDate != null
                ? Timestamp.fromDate(parsedDate)
                : FieldValue.serverTimestamp(),
            'date': dateStr,
            'time': timeStr,
            'image': image,
            'zone': zone['name'],
            'price': zone['price'],
            'count': count,
            'qrId': qrId,
            'qrData': qrData,
            'used': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  // 🔹 Popup animado
  void _showPaymentPopup(BuildContext context, String uid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isProcessing = true;

        return StatefulBuilder(
          builder: (context, setState) {
            Future.microtask(() async {
              if (isProcessing) {
                await Future.delayed(const Duration(seconds: 3));
                await _cartService.clearCart();
                await Future.delayed(const Duration(seconds: 2));
                if (context.mounted) setState(() => isProcessing = false);
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.all(24),
              content: SizedBox(
                width: 300,
                height: 300,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: isProcessing
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text("Procesando pago...",
                                style: TextStyle(fontSize: 16)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 90),
                            const SizedBox(height: 16),
                            const Text(
                              "¡Compra realizada con éxito! Su factura se la enviara por correo!",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(
                                    context, '/my_tickets_screen');
                              },
                              icon: const Icon(Icons.confirmation_num),
                              label: const Text("Ver mis entradas"),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
