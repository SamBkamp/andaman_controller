import 'package:flutter/material.dart';
import 'device.dart';
import 'ble.dart';

class NewDevicePopup extends StatefulWidget {
  final DeviceRegistry registry;
  final Ble_manager ble;

  NewDevicePopup({
      super.key,
      required this.registry,
      required this.ble,
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
    final stored_devices = widget.registry.devices_noload();
    //remove devices from dropdown if they've already been saved to nvs
    final available_devices = scanned_devices.where(
      (scanned) => !stored_devices.any(
        (stored) => stored.uuid == scanned.uuid,
      ),
    ).toList();

    setState(() {
        devices = available_devices;
        scanning = false;
    });
  }

//  Future<void> scan_devices() async {
//    setState(() {
//        scanning = true;
//    });
//    final scanned_devices = await widget.ble.scan_devices();
//    setState(() {
//        devices = scanned_devices;
//        scanning = false;
//    });
//  }

  Widget newDeviceContent() {
    if(scanning){
      return const SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }else{ //REMOVE THIS NONSENSE BEFORE SHIPPING
      if(devices.length == 0){
        devices.add(DoserDevice(
            uuid: "123-456-789",
            name: "DUMMY DEVICE",
          ),
        );
      }
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
