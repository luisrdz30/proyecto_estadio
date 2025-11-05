import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  static const LatLng _quitoCenter = LatLng(-0.1807, -78.4678); // Quito centro

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _quitoCenter,
          zoom: 14.5,
        ),
        mapType: MapType.normal,
        zoomControlsEnabled: true,
        myLocationButtonEnabled: false,
      ),
    );
  }
}
