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

  final devices = [
    DoserDevice(name: "Doser 1", uuid: "1234123"),
    DoserDevice(name: "Doser 2", uuid: "1234123"),
    DoserDevice(name: "Doser 3", uuid: "1234123"),
  ];
  DoserDevice? selectedDevice;

  void scan_devices() async {
    await widget.ble.scan_devices();
  }
  
  Widget newDeviceContent() {
    scan_devices();
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
}
