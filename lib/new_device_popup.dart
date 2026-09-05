import 'package:flutter/material.dart';
import 'device.dart';
import 'ble.dart';

class NewDevicePopup extends StatefulWidget {
  final DeviceRegistry registry;
  final Ble_manager ble = const Ble_manager();

  const NewDevicePopup({
      super.key,
      required this.registry,
  });

  @override
  State<NewDevicePopup> createState() => _NewDevicePopupState();
}

class _NewDevicePopupState extends State<NewDevicePopup> {
  bool scanning = false;
  List<DoserDevice> devices = [];
  DoserDevice? selectedDevice;

  Future<void> scan_devices() async {
    setState(() {
        scanning = true;
    });
    final scanned_devices = await widget.ble.scan_devices();
    setState(() {
        devices = scanned_devices;
        scanning = false;
    });
  }
  
  Widget newDeviceContent() {
    if(scanning){
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    
    return DropdownButton<DoserDevice>(
      hint: const Text("Select a device"),
      value: selectedDevice,
      isExpanded: true,
      items: devices.map((device) {
          return DropdownMenuItem<DoserDevice>(
            value: device,
            child: Text(device.name),
          );
      }).toList(),
      onChanged: (value) {
        setState(() {
            selectedDevice = value;
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Device"),
      content: newDeviceContent(),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            if(selectedDevice == null){
              return;
            }

            await widget.registry.add(selectedDevice!);

            Navigator.of(context).pop();
          },
          child: const Text("Add"),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    scan_devices();
  }
}
