import 'package:flutter/material.dart';
import 'device.dart';
import 'ble.dart';

class DoserPage extends StatefulWidget {
  final DoserDevice device;
  final Ble_manager blemanager;

  const DoserPage({
    super.key,
    required this.device,
    required this.blemanager,
  });

  @override
  State<DoserPage> createState() => _DoserPageState();
}

class _DoserPageState extends State<DoserPage> {
  bool? connected;


  @override
  void initState() {
    super.initState();
    connect_device();
  }


  Future<void> connect_device() async {
    final result = await widget.blemanager.connect_to_device(widget.device);

    setState(() {
        connected = result;
    });
  }


  Widget connection_status() {
    String text = "Disconnected";
    if (connected == null) {
      text = "Connecting...";
    } else if (connected!) {
      text = "Connected";
    }

    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: Column(
        children: [
          device_hero(context),

          // Configuration UI will eventually go here
        ],
      ),
    );
  }


  //this has GOT to be factored down. This language is hell
  Widget device_hero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Icon(
                Icons.local_drink,
                size: 100,
              ),
            ),
          ),

          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.device.uuid,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                connection_status(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
