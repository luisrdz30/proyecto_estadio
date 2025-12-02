import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../screens/my_tickets_screen.dart';

class ConnectionGuard extends StatefulWidget {
  final Widget child;

  const ConnectionGuard({super.key, required this.child});

  @override
  State<ConnectionGuard> createState() => _ConnectionGuardState();
}

class _ConnectionGuardState extends State<ConnectionGuard> {
  bool _hasConnection = true;
  late final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  bool _showTickets = false; // 👈 Modo “solo ver entradas offline”

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();

    _checkInitial();

    _subscription = _connectivity.onConnectivityChanged.listen((statusList) {
      final status = statusList.isNotEmpty ? statusList.first : ConnectivityResult.none;

      final connected =
          status == ConnectivityResult.mobile || status == ConnectivityResult.wifi;

      if (!connected) {
        setState(() => _hasConnection = false);
      } else {
        if (!_hasConnection) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Conexión restaurada")),
          );
        }
        setState(() {
          _hasConnection = true;
          _showTickets = false; // al volver internet, se habilita toda la app
        });
      }
    });
  }

  Future<void> _checkInitial() async {
    final list = await _connectivity.checkConnectivity();
    final status = list.isNotEmpty ? list.first : ConnectivityResult.none;

    final connected =
        status == ConnectivityResult.mobile || status == ConnectivityResult.wifi;

    setState(() => _hasConnection = connected);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // 🔥 Cuando está offline y el usuario eligió ver entradas
        if (!_hasConnection && _showTickets)
          const Material(
            color: Colors.transparent,
            child: MyTicketsScreen(), // SOLO ENTRADAS
          ),

        // 🔴 Cuando está offline y NO se ha elegido aún
        if (!_hasConnection && !_showTickets)
          _OfflineOverlay(
            onSeeTickets: () {
              setState(() => _showTickets = true);
            },
          ),
      ],
    );
  }
}

class _OfflineOverlay extends StatelessWidget {
  final VoidCallback onSeeTickets;

  const _OfflineOverlay({super.key, required this.onSeeTickets});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xD9000000), // oscurece sin borrar el árbol detrás
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 80),
              const SizedBox(height: 16),
              const Text(
                "Sin conexión a internet",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Puedes ver tus entradas, pero no usar el resto de la app.",
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: onSeeTickets,
                icon: const Icon(Icons.confirmation_num),
                label: const Text("Ver mis entradas"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
