import 'package:flutter/material.dart';
import 'device.dart';
import 'ble.dart';
import 'theme_data.dart';

class DoserPage extends StatefulWidget {
  final DoserDevice device;
  final Ble_manager blemanager;
  final Theme_data theme = const Theme_data();

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
  bool direction = false;
  bool TEST_FLAG = true;
  final dose_controller = TextEditingController();
  final seconds_controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    connect_device();
  }

  @override
  void dispose() {
    dose_controller.dispose();
    seconds_controller.dispose();
    super.dispose();
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

    return widget.theme.small_text_bold(text);
  }


  void direction_changed(dir){
    setState(() {
        direction = dir;
    });
  }


  Widget dose_sched_selector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          child: TextField(
            controller: dose_controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true,),
          ),
        ),

        const Text("ml every"),

        SizedBox(
          width: 100,
          child: TextField(
            controller: seconds_controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
          ),
        ),

        const Text("seconds"),
      ],
    );
  }

  Future<void> commit_changes() async {
    //await widget.ble.commit_changes(widget.device);

    // Whatever you want to do after the device confirms it.
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
          const SizedBox(height: 20), //padding
          // Configuration UI will eventually go here
          if((connected != null && connected!) || TEST_FLAG) ...[
            setting_row("Direction", Switch(value: direction, onChanged: (value)=>direction_changed(value))),
            setting_row("Schedule", dose_sched_selector())
          ]
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: commit_changes,
        label: widget.theme.subtitle_text("Save changes"),
        icon: const Icon(Icons.save),
      ),
    );
  }

  Expanded info_col(){
    return Expanded(
      flex: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.theme.title_text(widget.device.name),
          const SizedBox(height: 8),
          widget.theme.small_text(widget.device.uuid),
          const SizedBox(height: 12),
          connection_status(),
        ],
      ),
    );
  }

  Expanded icon_col(){
    return Expanded(
      flex: 3,
      child: Center(
        child: Icon(Icons.local_drink, size: 100,),
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
          icon_col(),
          info_col(),
        ],
      ),
    );
  }


  Widget setting_row(String name, Widget setting){
    return Padding(
      padding: const EdgeInsets.symmetric( horizontal: 10, vertical: 8,),
      child: Row(
        children: [
          Expanded( flex: 3, child: widget.theme.subtitle_text(name),),
          Expanded(
            flex: 7,
            child: Align( alignment: Alignment.centerRight, child: setting,),
          ),
        ],
      ),
    );
  }

}
