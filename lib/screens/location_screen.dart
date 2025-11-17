import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../theme_sync.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _mapController;
  bool _isMapReady = false;

  static const LatLng _stadiumLatLng = LatLng(-0.1778, -78.4769);
  final String _stadiumName = "Estadio Olímpico Atahualpa";
  final String _stadiumAddress =
      "Av. 6 de Diciembre y Naciones Unidas, Quito, Ecuador";

  Future<void> _openGoogleMaps() async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${_stadiumLatLng.latitude},${_stadiumLatLng.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showDialog('No se pudo abrir Google Maps');
    }
  }

  void _showDialog(String message) {
    final theme = ThemeSync.currentTheme;
    showDialog(
      context: context,
      builder: (_) => Theme(
        data: theme,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Aviso', style: TextStyle(color: theme.colorScheme.primary)),
          content: Text(
            message,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar',
                  style: TextStyle(color: theme.colorScheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _centerMap() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(target: _stadiumLatLng, zoom: 15.8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeSync.currentTheme;
    ThemeSync.applyThemeSilently(ThemeSync.isDarkMode);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Ubicación del Estadio"),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // 🗺️ MAPA
              Container(
                margin: const EdgeInsets.all(16),
                height: screenHeight * 0.6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) {
                        _mapController = controller;
                        setState(() => _isMapReady = true);
                      },
                      initialCameraPosition: const CameraPosition(
                        target: _stadiumLatLng,
                        zoom: 15.8,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId("stadium"),
                          position: _stadiumLatLng,
                          infoWindow: const InfoWindow(
                            title: "Estadio Olímpico Atahualpa",
                          ),
                        ),
                      },
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                      mapType: MapType.normal,
                    ),

                    // 🌐 BOTÓN DE CENTRAR MAPA
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.white,
                        elevation: 4,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.hardEdge,
                        child: InkWell(
                          onTap: _centerMap,
                          child: const SizedBox(
                            width: 45,
                            height: 45,
                            child: Icon(
                              Icons.my_location,
                              color: Colors.blueAccent,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ⏳ LOADING DEL MAPA
                    if (!_isMapReady)
                      Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),

              // 📌 INFO DEL ESTADIO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: theme.colorScheme.surface,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stadiumName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _stadiumAddress,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? Colors.grey[300]
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: const [
                            Icon(Icons.people_alt_outlined, size: 22),
                            SizedBox(width: 8),
                            Text("Capacidad: 35.000 personas"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔘 BOTONES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openGoogleMaps,
                        icon: const Icon(Icons.directions_outlined),
                        label: const Text("Cómo llegar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Share.share(
                            '📍 $_stadiumName\n$_stadiumAddress\nhttps://maps.google.com/?q=${_stadiumLatLng.latitude},${_stadiumLatLng.longitude}',
                          );
                        },
                        icon: const Icon(Icons.share),
                        label: const Text("Compartir"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                              color: theme.colorScheme.primary, width: 2),
                          foregroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
