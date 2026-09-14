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
  final insta_dose_amount_controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    connect_device();
  }

  @override
  void dispose() {
    dose_controller.dispose();
    seconds_controller.dispose();
    insta_dose_amount_controller.dispose();
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


  Widget manual_dosing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          child: TextField(
            controller: insta_dose_amount_controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(decimal: true,),
          ),
        ),
        const Text("ml"),
        SizedBox(width: 20),
        FilledButton(
          onPressed: (){},
          child: const Text("Dose"),
        ),
      ]
    );

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
    final keyboard_visible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
      ),
      body: ListView(
        keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          device_hero(context),
          const SizedBox(height: 20), //padding
          // Configuration UI will eventually go here
          if((connected != null && connected!) || TEST_FLAG) ...[
            setting_row("Direction", Switch(value: direction, onChanged: (value)=>direction_changed(value)), 3, 7),
            setting_row("Schedule", dose_sched_selector(), 3, 7),
            setting_row("Manual Dosing", manual_dosing(), 5, 5),

          ]
        ],
      ),

      floatingActionButton: keyboard_visible
      ? FloatingActionButton(
        onPressed: commit_changes,
        child: const Icon(Icons.save),
      )
      : FloatingActionButton.extended(
        onPressed: commit_changes,
        label: widget.theme.subtitle_text("Save changes"),
        icon: const Icon(Icons.save),
      ),
    );
  }

  Expanded info_col(){
    return Expanded(
      flex: 6,
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
      flex: 4,
      child: Center(
        child: SizedBox(
          width: 90,
          height: 90,
          child: Image.asset(
            'assets/doser_clipaart.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  //this has GOT to be factored down. This language is hell
  Widget device_hero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 5,
      ),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          icon_col(),
          info_col(),
        ],
      ),
    );
  }


  Widget setting_row(String name, Widget setting, int width1, int width2){
    return Padding(
      padding: const EdgeInsets.symmetric( horizontal: 10, vertical: 14,),
      child: Row(
        children: [
          Expanded( flex: width1, child: widget.theme.subtitle_text(name),),
          Expanded(
            flex: width2,
            child: Align( alignment: Alignment.centerRight, child: setting,),
          ),
        ],
      ),
    );
  }

}
