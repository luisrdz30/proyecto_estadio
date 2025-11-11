import 'package:flutter/material.dart';

class ZoneFieldWidget extends StatelessWidget {
  final int index;
  final Map<String, dynamic> zoneData;
  final VoidCallback onDelete;

  const ZoneFieldWidget({
    super.key,
    required this.index,
    required this.zoneData,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              initialValue: zoneData['name'] ?? '',
              decoration: const InputDecoration(labelText: "Nombre de zona"),
              onChanged: (v) => zoneData['name'] = v,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: zoneData['price']?.toString() ?? '0',
                    decoration: const InputDecoration(labelText: "Precio"),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => zoneData['price'] = double.tryParse(v) ?? 0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: zoneData['capacity']?.toString() ?? '0',
                    decoration: const InputDecoration(labelText: "Capacidad"),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => zoneData['capacity'] = int.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text("Eliminar", style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
